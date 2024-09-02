import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:manitoscliente_new/Historial.dart';
import 'package:manitoscliente_new/ServicesResponse/ResponsePost.dart';
import 'package:manitoscliente_new/Styles/stilo.dart';
import 'package:manitoscliente_new/home.dart';
import 'package:manitoscliente_new/metodos/auth_utils.dart';
import 'package:manitoscliente_new/utils/status.dart';
import 'package:manitoscliente_new/wizards/dataservice.dart';
import 'package:manitoscliente_new/wizards/datetime.dart';
import 'package:manitoscliente_new/ServicesResponse/resquest.dart';
import 'package:manitoscliente_new/categorias/terms.dart';
import 'package:manitoscliente_new/wizards/datalocation.dart';
import 'package:manitoscliente_new/metodos/Routes.dart';

import 'package:manitoscliente_new/metodos/dataProvider.dart';

class ServiceFormPage extends StatefulWidget {
  final ServiceRequest serviceRequest;
  final bool acceptTerms;
  late final List<ServiceRequest> serviceRequests;
  final DateTime? selectedDate;
  final String selectedServiceTitle;
  final String token;
  final String categoryId; // Agregar esta variable
  final String subcategoryId; // Agregar esta variable
  final String subcategoryName;

  ServiceFormPage({
    Key? key,
    required this.serviceRequest,
    required this.acceptTerms,
    required this.serviceRequests,
    required this.selectedDate,
    required this.selectedServiceTitle,
    required this.token, required String selectedTime,
    required this.categoryId, // Definir esta variable en el constructor
    required this.subcategoryId, // Definir esta variable en el constructor
    required this.subcategoryName,
  }) : super(key: key);

  @override
  _ServiceFormPageState createState() => _ServiceFormPageState();
}

class _ServiceFormPageState extends State<ServiceFormPage> {
  int currentStep = 0;
  late ServiceDataWizard dataWizard;
  late DateTimeSelectionWizard dateTimeWizard;
  late TermsAndConditionsWizard termsWizard;
  late LocationAndFavoritesWizard locationAndFavoritesWizard;
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? token; // Variable para almacenar el token de autenticación
  final ApiDataProvider apiDataProvider = ApiDataProvider();
  bool isSubmitting = false;
  

  bool validateServiceData() {
    final serviceRequest = widget.serviceRequest;

    if (serviceRequest.isServiceNameEmpty()) {
      return false;
    }

    if (serviceRequest.isServiceTypeEmpty()) {
      return false;
    }

    return true;
  }

  bool validateDateTime() {
    final serviceRequest = widget.serviceRequest;

    if (serviceRequest.selectedDate == null) {
      return false;
    }

    if (serviceRequest.selectedTime == null) {
      return false;
    }

    return true;
  }
  void onSubmit() async {
    if (widget.acceptTerms && token != null && !isSubmitting) {
      setState(() {
        isSubmitting = true; // Bloquear envío adicional
      });

      final apiService = ApiService();
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        widget.serviceRequest.userId = user.uid;
        widget.serviceRequest.status = StatusUtils.getStatusById('available');

        try {
          final expertisesJson = jsonEncode(
            widget.serviceRequest.expertises.map((e) => e.toMap()).toList(),
          );

          final formData = {
            'Profesional': widget.subcategoryName,
            'serviceDateTime': widget.serviceRequest.selectedDate ?? '',
            'description': widget.serviceRequest.description ?? '',
            'images': widget.serviceRequest.images ?? [],
            'location': widget.serviceRequest.location ?? {},
            'offeredPrice': widget.serviceRequest.offeredPrice ?? 0,
            'userId': widget.serviceRequest.userId ?? '',
            'status': widget.serviceRequest.status.id ?? '',
            'expertises': expertisesJson,
            'categoryId': widget.categoryId,
            'subcategoryId': widget.subcategoryId,
          };

          final response = await apiService.sendDataToBackend(
            widget.serviceRequest,
            token!,
            widget.serviceRequest.status.id,
            expertisesJson,
            widget.categoryId,
            widget.subcategoryId,
            widget.serviceRequest.status,
            widget.subcategoryName,
          );

          if (response.statusCode == 200) {
            for (var image in widget.serviceRequest.images) {
              final file = File(image);
              await apiService.uploadImageToFirebaseStorage(file, user.uid);
            }

            
          } else {
            // Mostrar el cuadro de diálogo de éxito
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('¡Servicio creado con éxito!'),
                  content: const Text('Tu servicio ha sido creado con éxito.'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomeScreen(initialPageIndex: 2), 
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text('Ir a Historial'),
                    ),
                  ],
                );
              },
            );
            
          }
        } catch (error) {
          // Manejo de errores
          // Mostrar un cuadro de diálogo de error en caso de fallo
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Error al crear el servicio'),
                  content: const Text('Hubo un error al crear el servicio. Inténtalo nuevamente.'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cerrar'),
                    ),
                  ],
                );
              },
            );
        } finally {
          setState(() {
            isSubmitting = false; // Desbloquear después de enviar
          });
        }
      }
    }
  }






  Future<void> fetchDataForUserId() async {
    final List<ServiceRequest> data = await apiDataProvider.fetchDataForUserId();
    setState(() {
      widget.serviceRequests = data;
    });

    // Esperar a que la interfaz de usuario se actualice antes de acceder al valor
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      // Acceder a widget.serviceRequest.offeredPrice aquí
    });
  }

  @override
  void initState() {
    super.initState();

    // Llama a la función para obtener el token de autenticación
    AuthUtils.getToken().then((value) {
      setState(() {
        token = value;
      });
    });

    dataWizard = ServiceDataWizard(
      selectedServiceTitle: widget.selectedServiceTitle,
      serviceRequest: widget.serviceRequest,
      onImageSelected: (image) {
        setState(() {
          if (image != null && widget.serviceRequest.images.length < 3) {
            widget.serviceRequest.images.add(image as String);
          }
        });
      },
      onPriceSelected: (price) {
        widget.serviceRequest.offeredPrice = price as double;
      },
      onNextStep: () {
        // Aquí puedes definir qué hacer cuando se avance al siguiente paso.
      },
      services: widget.serviceRequests,
      maxImageCount: 3,
    );

    dateTimeWizard = DateTimeSelectionWizard(
      selectedDate: widget.selectedDate,
      onDateSelected: (date) {
        if (date != null) {
          setState(() {
            widget.serviceRequest.selectedDate = date.toIso8601String();
          });
        }
      },
      onTimeSelected: (time) {
        if (time != null) {
          final now = DateTime.now();
          final selectedTime = DateTime(
            now.year,
            now.month,
            now.day,
            time.hour,
            time.minute,
          );

          setState(() {
            widget.serviceRequest.selectedTime = selectedTime.toIso8601String();
          });
        }
      },
      onNextStep: () {
        // Aquí puedes definir qué hacer cuando se avance al siguiente paso.
      },
      selectedTime: null,
    );

    locationAndFavoritesWizard = LocationAndFavoritesWizard(
      onLocationSelected: (location) {
        widget.serviceRequest.location = {
          'lat': location.latitude,
          'lng': location.longitude,
        };
      },
      onFavoritesSelected: (favorite) {
        widget.serviceRequest.isFavorite = favorite;
      },
      onNextStep: () {
        // Aquí puedes definir qué hacer cuando se avance al siguiente paso.
      },
      location: widget.serviceRequest.location,  // Pasa la ubicación aquí
    );

    termsWizard = TermsAndConditionsWizard(
      isChecked: false,
      onAcceptTerms: (accepted) {
        widget.serviceRequest.acceptedTerms = accepted;
      },
      onNextStep: () {
        // Aquí puedes definir qué hacer cuando se avance al siguiente paso.
      },
    );
  }

  Widget _customStepperButton(
      {required String label, required VoidCallback onPressed}) {
    return TextButton(
      onPressed: onPressed,
      child: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white, shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        backgroundColor: Color(0xFF1A819A),
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formulario de Servicio',
          style: MyTextStyles.buttonTextStyle,),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: currentStep,
          controlsBuilder: (BuildContext context, ControlsDetails controlsDetails) {
            return Row(
              children: <Widget>[
                _customStepperButton(
                  label: 'Cancelar',
                  onPressed: currentStep > 0
                      ? () {
                    setState(() {
                      currentStep -= 1;
                    });
                  }
                      : () {},
                ),
                SizedBox(width: 8.0),
                _customStepperButton(
                  label: currentStep < 3 ? 'Continuar' : 'Enviar', // Cambio de etiqueta en el último paso
                  onPressed: () {
                    setState(() {
                      if (currentStep == 0 && !validateServiceData()) {
                        return;
                      }
                      if (currentStep == 1 && !validateDateTime()) {
                        return;
                      }
                      if (currentStep < 2) {
                        currentStep += 1;
                      } else {
                        onSubmit(); // Llama a onSubmit en el último paso
                      }
                    });
                  },
                ),
              ],
            );
          },
          steps: [
            Step(
              title: const Text('Datos del Servicio',
                style: MyTextStyles.servicesButtonTextStyle,
              ),
              content: dataWizard,
              isActive: currentStep == 0,
            ),
            Step(
              title: const Text('Fecha y Hora',
                style: MyTextStyles.servicesButtonTextStyle,
              ),
              content: dateTimeWizard,
              isActive: currentStep == 1,
            ),
            Step(
              title: const Text('Ubicación y Favoritos',
                style: MyTextStyles.servicesButtonTextStyle,
              ),
              content: locationAndFavoritesWizard,
              isActive: currentStep == 2,
            ),
          ],
        ),
      ),
    );
  }
}