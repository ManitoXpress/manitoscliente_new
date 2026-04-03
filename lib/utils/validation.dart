import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

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
          null;
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
      null;
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      null;
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      null;
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
        null;
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
        null;
      } else {
        null;
      }
      return token;
    } catch (e) {
      null;
      return null;
    }
  }

  Future<void> _registerReferralInFirestore(
      String userId, String referralCode) async {
    User? user = FirebaseAuth.instance.currentUser;
    try {
      if (referralCode.isEmpty) {
        null;
        return;
      }

      final workersCollection = FirebaseFirestore.instance.collection('users');
      final querySnapshot = await workersCollection
          .where('codeReferral', isEqualTo: referralCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        null;
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
      null;
    }
  }

  Future<void> _completeRegistration() async {
    null;

    try {
      final apiService = ApiService();
      final apiService2 = ApiService2();
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        null;
        return;
      }

      if (currentStep < 1) {
        null;
        return;
      }

      setState(() => loadingCompleteRegistration = true);

      // Obtener Device ID y FCM Token
      String? devicesId;
      String? fcmToken;
      try {
        devicesId = await AuthUtils.getDeviceId();
        final NotificationSettings settings =
            await FirebaseMessaging.instance.requestPermission(
          alert: true, badge: true, sound: true, provisional: false,
        );
        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          fcmToken = await _getFirebaseMessagingToken();
        }
      } catch (e) {
        null;
      }

      devicesId ??= 'unknown_device_id';
      fcmToken ??= 'no_fcm_token';

      // Obtener token fresco de Firebase Auth
      final String? token = await user.getIdToken(true);
      if (token == null) {
        null;
        setState(() => loadingCompleteRegistration = false);
        return;
      }

      // Obtener puntos actuales de Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();
      final int points = userDoc.data()?['points'] ?? 0;

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
        points: points,
      );

      null;
      null;

      // MEJORA-01: Verificar si el usuario ya existe en el backend antes de PATCH
      bool userExistsInBackend = false;
      try {
        final existingUser = await apiService2.fetchUserData(user.uid, token);
        userExistsInBackend = existingUser.userId.isNotEmpty;
        null;
      } catch (e) {
        null;
        userExistsInBackend = false;
      }

      // Si no existe en el backend, crear primero con POST /users
      if (!userExistsInBackend) {
        null;
        final createResponse = await apiService.sendTokenAndUserDataToServer(
          token: token,
          displayName: user.displayName ?? userData.displayName,
          email: user.email ?? userData.email,
          phoneNumber: userData.phoneNumber,
          imagePath: user.photoURL,
        );
        null;
        if (createResponse.statusCode != 200 && createResponse.statusCode != 201) {
          null;
          // Continuar igualmente con el PATCH por si el trigger ya lo creó
        }
      }

      // Registrar referido si aplica
      if (userData.referralCode.isNotEmpty && userData.referrerUserId.isNotEmpty) {
        await _registerReferralInFirestore(user.uid, userData.referralCode);
      }

      // PATCH para actualizar datos completos de perfil
      final response = await apiService.updateUser(
        user.uid, registrationData, token, devicesId, fcmToken,
      );

      setState(() => loadingCompleteRegistration = false);

      if (response.statusCode == 200) {
        null;
        widget.completeRegistrationCallback();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(userData: userData!)),
        );
      } else {
        null;
      }
    } catch (error, stackTrace) {
      setState(() => loadingCompleteRegistration = false);
      null;
      null;
    }
  }


// Método personalizado para obtener el token con múltiples intentos

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF115E70)),
        title: Text(
          'Registro de Usuario',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF115E70),
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Theme(
        data: ThemeData(
          colorScheme: const ColorScheme.light(primary: Color(0xFF115E70)),
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
            return Column(
              children: [
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    if (currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: details.onStepCancel,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFF115E70), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            'CANCELAR',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF115E70),
                            ),
                          ),
                        ),
                      ),
                    if (currentStep > 0) const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF115E70),
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: loadingCompleteRegistration
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : Text(
                                currentStep == 1 ? 'COMPLETAR REGISTRO' : 'CONTINUAR',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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
