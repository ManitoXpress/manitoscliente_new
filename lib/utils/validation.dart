
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../ServicesResponse/ResponseGet.dart';
import '../ServicesResponse/ResponsePost.dart';
import '../ServicesResponse/dataprofile.dart';
import '../Styles/stilo.dart';
import '../home.dart';
import '../metodos/RegisController.dart';
import '../wizards/datalocation.dart';
import '../wizards/userData.dart';

class RegistrationScreen extends StatefulWidget {
  final RegistrationController registrationController;
  final VoidCallback completeRegistrationCallback;
  final ApiService2 apiService2;

  RegistrationScreen({
    required this.registrationController,
    required this.completeRegistrationCallback,
    required this.apiService2,
  });

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  int currentStep = 0;
  late UserData userData;
  late RegistrationData registrationData;
  bool loadingCompleteRegistration = false;
  late userDataWizard step1Data;
  late LocationAndFavoritesWizard step2Location;
  late RegistrationController registrationController;
  bool formCompleted = false;
  LatLng? location;
  @override
  void initState() {
    super.initState();

    setState(() {
      registrationData = RegistrationData(
        userId: '',
        displayName: '',
        phoneNumber: '',

        location: {},
        email: '',
        selectedCountryCode: '', paymentType: '',
      );

      userData = UserData(
        userId: '',
        displayName: '',

        email: '',
        phoneNumber: '',

        location: {}, paymentType: '', selectedCountryCode: '', registrationData: registrationData, getToken: '',


      );
      registrationController = widget.registrationController;
      step1Data = userDataWizard(
        onNextStep: _nextStep,
        registrationData: registrationData,
        registrationController: registrationController,
        userData: userData,
      );
    });

    step2Location = LocationAndFavoritesWizard(
      onLocationSelected: (location) {
        setState(() {
          if (location != null) {
            userData.location = {
              'lat': location.latitude,
              'lng': location.longitude,
            };
          }
        });
      },
      onFavoritesSelected: (favorite) {
        // Puedes manejar si se selecciona como favorito, si es necesario
      },
      onNextStep: () {
        if (userData.location != null) {
          _nextStep();
        } else {
          // Mostrar mensaje o realizar alguna acción indicando que la ubicación es obligatoria.
          print('Selecciona una ubicación antes de pasar al siguiente paso.');
        }
      },
      location: {},
    );

  }

  void restoreFormState() {
    // Lógica para cargar datos previos del formulario si es necesario
  }

  void restoreFormCompletedState() {
    // Lógica para cargar el estado de la bandera si es necesario
  }
  void _nextStep() {
    // Validar el primer paso
    if (currentStep == 0) {
      if (!step1Data.isStep1Valid()) {
        print('Completa todos los campos obligatorios antes de pasar al siguiente paso.');
        return;
      }
    }

    setState(() {
      if (currentStep < 1) {
        currentStep += 1;
      }
    });

  }

  Future<void> _completeRegistration() async {
    print('Entrando a _completeRegistration');

    try {
      final apiService = ApiService();
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        if (currentStep < 1) {
          print('Completa todos los pasos del formulario antes de completar el registro.');
          return;
        }

        registrationData.userId = user.uid;
        registrationData.location = {
          'lat': location?.latitude ?? 0.0,
          'lng': location?.longitude ?? 0.0,
        };

        registrationData = RegistrationData.fromForm(
          userId: user.uid,
          displayName: userData.displayName, // Utiliza el displayName del userData
          phoneNumber: userData.phoneNumber,
          location: userData.location,
          email: userData.email,
          paymentType: userData.paymentType,
          selectedCountryCode: '',

        );

        print('Después de RegistrationData.fromForm:');
        String? token = await user.getIdToken();

        final response = await apiService.updateUser(
          user.uid,
          registrationData,
          token!,
        );

        widget.completeRegistrationCallback();

        if (response.statusCode == 200) {
          print('Usuario actualizado con éxito');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          print('Error en la respuesta del servidor: ${response.statusCode}');
        }
      } else {
        print(
            'Advertencia: usuario es nulo. Asegúrate de que el usuario esté autenticado correctamente.'
        );
      }
    } catch (error) {
      print('Error durante el proceso de registro: $error');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Registro de Usuario',
          style: MyTextStyles.buttonTextStyle,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (currentStep == 0) ...[
              step1Data,
            ] else if (currentStep == 1) ...[
              step2Location,
            ],

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (currentStep == 1) {

                  setState(() {
                    loadingCompleteRegistration = true;
                  });
                  _completeRegistration().then((_) {
                    setState(() {
                      loadingCompleteRegistration = false;
                    });
                  });
                } else {
                  _nextStep();
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                backgroundColor: Color(0xFF1A819A),
                minimumSize: Size(double.infinity, 50),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!loadingCompleteRegistration)
                      Text(
                        currentStep == 1 ? 'Completar Registro' : 'Siguiente Paso',
                        style: MyTextStyles.buttonTextStyle.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    if (loadingCompleteRegistration)
                      CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.0,
                      ),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
