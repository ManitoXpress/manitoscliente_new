import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../controller/auth_utils.dart';
import '../request/ResponseGet.dart';
import '../request/ResponsePost.dart';
import '../request/dataprofile.dart';
import '../Styles/stilo.dart';
import '../home.dart';
import '../controller/RegisController.dart';
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
  String? fcmToken;
  LatLng? location;
  @override
  void initState() {
    super.initState();

    // Obtener el FCM Token
    FirebaseMessaging.instance.getToken().then((value) {
      setState(() {
        fcmToken = value;
      });
    });

    setState(() {
      registrationData = RegistrationData(
        userId: '',
        displayName: '',
        phoneNumber: '',
        location: {},
        email: '',
        selectedCountryCode: '',
        paymentType: '',
        devicesId: '',
        fcmToken: '',
        points: 0,
      );

      userData = UserData(
        userId: '',
        displayName: '',
        email: '',
        phoneNumber: '',
        location: {},
        paymentType: '',
        selectedCountryCode: '',
        registrationData: registrationData,
        getToken: '',
        referrerUserId: '', // Add appropriate value
        referralCode: '', // Add appropriate value
        points: 0, // Add appropriate value
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

  Future<void> _requestNotificationPermission() async {
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Permiso de notificaciones concedido');
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('Permiso de notificaciones denegado');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('Permiso provisional concedido');
    }
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
        print(
            'Completa todos los campos obligatorios antes de pasar al siguiente paso.');
        return;
      }
    }

    setState(() {
      if (currentStep < 1) {
        currentStep += 1;
      }
    });
  }

  Future<String?> _getFirebaseMessagingToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        print('FCM Token obtenido: $token');
      } else {
        print('FCM Token es nulo');
      }
      return token;
    } catch (e) {
      print('Error al obtener el FCM Token: $e');
      return null;
    }
  }

  Future<void> _registerReferralInFirestore(
      String userId, String referralCode) async {
    User? user = FirebaseAuth.instance.currentUser;
    try {
      if (referralCode.isEmpty) {
        print('No hay código de referido para registrar.');
        return;
      }

      final workersCollection = FirebaseFirestore.instance.collection('users');
      final querySnapshot = await workersCollection
          .where('codeReferral', isEqualTo: referralCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('No se encontró un trabajador con este código de referido.');
        return;
      }
      String? token = await user?.getIdToken();

      final referrerDoc = querySnapshot.docs.first;
      final referrerId = referrerDoc.id;

      // Guardar la relación de referido en Firestore
      final referralsCollection =
          FirebaseFirestore.instance.collection('referrals');
      await referralsCollection.add({
        'referrerId': referrerId,
        'referrerCodeReferral': referralCode,
        'referredUserId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'processed': false
      });

      // Llamar al backend para actualizar los puntos
      final apiService = ApiService2();
      await apiService.updateWorkerPoints(referrerId, token!);
    } catch (e) {
      print('Error al registrar el referido: $e');
    }
  }

  Future<void> _completeRegistration() async {
    print('Entrando a _completeRegistration');

    try {
      final apiService = ApiService();
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        print('Advertencia: Usuario no autenticado');
        return;
      }

      if (currentStep < 1) {
        print(
            'Completa todos los pasos del formulario antes de completar el registro.');
        return;
      }

      // Obtener Device ID y FCM Token con manejo de errores mejorado
      String? devicesId;
      String? fcmToken;

      try {
        devicesId = await AuthUtils.getDeviceId();

        // Solicitar permiso explícitamente antes de obtener el token
        NotificationSettings settings =
            await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          fcmToken = await _getFirebaseMessagingToken();
        } else {
          print('El usuario no ha concedido permisos de notificación');
          fcmToken = null;
        }
      } catch (e) {
        print('Error obteniendo Device ID o FCM Token: $e');
        devicesId = null;
        fcmToken = null;
      }

      // Validar que los valores no sean nulos
      if (devicesId == null) {
        devicesId = 'unknown_device_id';
      }

      if (fcmToken == null) {
        fcmToken = 'no_fcm_token';
      }

      registrationData = RegistrationData.fromForm(
        userId: user.uid,
        displayName: userData.displayName,
        phoneNumber: userData.phoneNumber,
        location: userData.location,
        email: userData.email,
        paymentType: userData.paymentType,
        selectedCountryCode: '',
        devicesId: devicesId,
        fcmToken: fcmToken,
        points: 0,
      );

      print('Device ID: $devicesId');
      print('FCM Token: $fcmToken');

      String? token = await user.getIdToken();

      if (token == null) {
        print('Error: No se pudo obtener el token de autenticación');
        return;
      }
      // Registrar el referido si hay un código válido
      if (userData.referralCode.isNotEmpty &&
          userData.referrerUserId.isNotEmpty) {
        await _registerReferralInFirestore(user.uid, userData.referralCode);
      }

      // Obtener los puntos actualizados del trabajador
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final points = userDoc.data()?['points'] ?? 0;
      registrationData.points =
          points; // Asignar los puntos al registrationData

      final response = await apiService.updateUser(
        user.uid,
        registrationData,
        token,
        devicesId,
        fcmToken,
      );

      if (response.statusCode == 200) {
        print('Usuario actualizado con éxito');
        widget.completeRegistrationCallback();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(userData: userData!,)),
        );
      } else {
        print('Error en la respuesta del servidor: ${response.statusCode}');
      }
    } catch (error, stackTrace) {
      print('Error durante el proceso de registro: $error');
      print(stackTrace);
    }
  }

// Método personalizado para obtener el token con múltiples intentos

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Registro de Usuario',
          style: MyTextStyles.buttonTextStyle,
        ),
        backgroundColor: const Color(0xFF1A819A),
      ),
      body: Theme(
        data: ThemeData(
          colorScheme: ColorScheme.light(primary: Color(0xFF1A819A)),
        ),
        child: Stepper(
          type: StepperType.vertical,
          currentStep: currentStep,
          onStepContinue: () {
            if (currentStep < 1) {
              _nextStep();
            } else {
              _completeRegistration();
            }
          },
          onStepCancel: () {
            if (currentStep > 0) {
              setState(() {
                currentStep -= 1;
              });
            }
          },
          controlsBuilder: (BuildContext context, ControlsDetails details) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                if (currentStep > 0)
                  ElevatedButton(
                    onPressed: details.onStepCancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A819A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: MyTextStyles.drawerButtonLabelTextStyle,
                    ),
                  ),
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A819A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: loadingCompleteRegistration
                      ? CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Text(
                          currentStep == 1 ? 'Completar Registro' : 'Continuar',
                          style: MyTextStyles.drawerButtonLabelTextStyle,
                        ),
                ),
              ],
            );
          },
          steps: <Step>[
            Step(
              title: Text(
                'Datos del Servicio',
                style: MyTextStyles.drawerButtonTextStyle3,
              ),
              content: step1Data,
              isActive: currentStep >= 0,
              state: currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: Text(
                'Ubicación',
                style: MyTextStyles.drawerButtonTextStyle3,
              ),
              content: step2Location,
              isActive: currentStep >= 1,
              state: currentStep > 1 ? StepState.complete : StepState.indexed,
            ),
          ],
          stepIconBuilder: (int stepIndex, StepState state) {
            return CircleAvatar(
              backgroundColor: Color(0xFF1A819A),
              child: Text(
                '${stepIndex + 1}',
                style: MyTextStyles.tabTextStyle1,
              ),
            );
          },
        ),
      ),
    );
  }
}