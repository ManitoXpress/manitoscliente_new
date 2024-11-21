import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:manitoscliente_new/Historial.dart';
import 'package:manitoscliente_new/ServicesResponse/ResponsePost.dart';
import 'package:manitoscliente_new/Styles/stilo.dart';
import 'package:manitoscliente_new/home.dart';
import 'package:manitoscliente_new/metodos/auth_utils.dart';
import 'package:manitoscliente_new/utils/compres.dart';
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
  final String categoryId;
  final String subcategoryId;
  final String subcategoryName;

  ServiceFormPage({
    Key? key,
    required this.serviceRequest,
    required this.acceptTerms,
    required this.serviceRequests,
    required this.selectedDate,
    required this.selectedServiceTitle,
    required this.token,
    required this.categoryId,
    required this.subcategoryId,
    required this.subcategoryName, required String selectedTime,
  }) : super(key: key);

  @override
  _ServiceFormPageState createState() => _ServiceFormPageState();
}

class _ServiceFormPageState extends State<ServiceFormPage> {
  int currentStep = 0;
  late ServiceDataWizard dataWizard;
  late DateTimeSelectionWizard dateTimeWizard;
  late TermsAndConditionsWizard termsWizard;
  late final LocationAndFavoritesWizard locationAndFavoritesWizard;
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? token; // Variable para almacenar el token de autenticación
  String? fcmToken; // Variable para almacenar el fcmToken
  final ApiDataProvider apiDataProvider = ApiDataProvider();
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // Obtener el token de autenticación
    AuthUtils.getToken().then((value) {
      setState(() {
        token = value;
      });
    });

    // Obtener el FCM Token
    FirebaseMessaging.instance.getToken().then((value) {
      setState(() {
        fcmToken = value;
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
      onNextStep: () {},
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
      onNextStep: () {},
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
      onNextStep: () {},
      location: widget.serviceRequest.location,
    );

    termsWizard = TermsAndConditionsWizard(
      isChecked: false,
      onAcceptTerms: (accepted) {
        widget.serviceRequest.acceptedTerms = accepted;
      },
      onNextStep: () {},
    );
  }

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

      // Mostrar un cuadro de diálogo de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Enviando datos..."),
                ],
              ),
            ),
          );
        },
      );

      final apiService = ApiService();
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        widget.serviceRequest.userId = user.uid;
        widget.serviceRequest.status = StatusUtils.getStatusById('available');

        try {
          final expertisesJson = jsonEncode(
            widget.serviceRequest.expertises.map((e) => e.toMap()).toList(),
          );

          // Nueva lista para almacenar URLs de imágenes
          List<String> imageUrls = [];

          // Filtrar las imágenes con rutas válidas
          List<String> validImagePaths = widget.serviceRequest.images.where((path) => path.isNotEmpty).toList();

          // Subir imágenes a Firebase Storage y obtener las URLs
          for (var imagePath in validImagePaths) {
            try {
              final file = File(imagePath);
              final compressedFile = await compressAndResizeImage(file);

              // Subir la imagen y obtener la URL
              String downloadUrl = await apiService.uploadImageToFirebaseStorage(compressedFile, user.uid);
              imageUrls.add(downloadUrl); // Almacenar la URL descargable
            } catch (e) {
              print('Error al cargar imagen: $e');
            }
          }

          if (imageUrls.isEmpty) {
            Navigator.of(context).pop(); // Cerrar el diálogo de carga
            showErrorDialog(context, 'Error: No se subió ninguna imagen.');
            return;
          }

          // Obtener el devicesId y fcmToken
          String? devicesId = await AuthUtils.getDeviceId();

          // Enviar datos al backend
          final response = await apiService.sendDataToBackend(
            widget.serviceRequest,
            token!,
            widget.serviceRequest.status.id,
            expertisesJson,
            widget.categoryId,
            widget.subcategoryId,
            widget.serviceRequest.status,
            widget.subcategoryName,
            imageUrls,
            devicesId,
            fcmToken, // Pasar el fcmToken al backend
          );

          Navigator.of(context).pop(); // Cerrar el diálogo de carga

          if (response.statusCode == 201) {
            showSuccessDialog(context, 'Servicio creado con éxito.');
          } else {
            showErrorDialog(context, 'Error al crear el servicio. Código: ${response.statusCode}');
          }
        } catch (error) {
          Navigator.of(context).pop(); // Cerrar el diálogo de carga
          showErrorDialog(context, 'Error durante la creación del servicio: $error');
        } finally {
          setState(() {
            isSubmitting = false; // Desbloquear después de enviar
          });
        }
      } else {
        Navigator.of(context).pop(); // Cerrar el diálogo de carga
        showErrorDialog(context, 'Error: No hay usuario autenticado.');
      }
    } else {
      showErrorDialog(context, 'Error: Términos no aceptados, token nulo o ya se está enviando.');
    }
  }

  void showSuccessDialog(BuildContext context, String s) {
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
                    builder: (context) => HomeScreen(initialPageIndex: 1), // Redirige a Historial
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

  void showErrorDialog(BuildContext context, String s) {
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
  }

  Widget _customStepperButton(
      {required String label, required VoidCallback onPressed}) {
    return TextButton(
      onPressed: onPressed,
      child: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
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
        title: const Text('Formulario de Servicio'),
        actions: <Widget>[
          if (currentStep == 2)
            _customStepperButton(
              label: 'Enviar',
              onPressed: onSubmit,
            ),
        ],
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: currentStep,
        onStepContinue: () {
          if (currentStep < 2) {
            setState(() {
              currentStep++;
            });
          } else {
            onSubmit();
          }
        },
        onStepCancel: () {
          if (currentStep > 0) {
            setState(() {
              currentStep--;
            });
          }
        },
        steps: <Step>[
          Step(
            title: Text('Datos del servicio'),
            content: dataWizard,
            isActive: currentStep >= 0,
            state: currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: Text('Fecha y hora'),
            content: dateTimeWizard,
            isActive: currentStep >= 1,
            state: currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: Text('Ubicación'),
            content: locationAndFavoritesWizard,
            isActive: currentStep >= 2,
            state: currentStep > 2 ? StepState.complete : StepState.indexed,
          ),
        ],
      ),
    );
  }
}