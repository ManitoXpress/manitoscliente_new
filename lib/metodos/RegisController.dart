import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wizard/flutter_wizard.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RegistrationController {
  RegistrationData registrationData = RegistrationData(
    userId: '',
    displayName: '',
    phoneNumber: '',
    location: {},
    paymentType: '',
    devicesId: '',
    email: '',
    selectedCountryCode: '',
    fcmToken: '',
    points: 0,
  );
  TextEditingController displayNameController = TextEditingController();
  TextEditingController idDocumentController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();

  // Asegúrate de inicializarla con un valor predeterminado si es necesario

  String imagePath = '';
  LatLng? location;

  void nextStep() {
    // Implementa la lógica para avanzar al siguiente paso del registro.
    // Puedes realizar validaciones u otras acciones necesarias aquí.
  }

  void completeRegistration() {
    // Implementa la lógica para completar el registro.
    // Accede a los datos almacenados en registrationData y envíalos al backend u otras acciones necesarias.

    // Aquí puedes llamar a un servicio que envíe los datos al backend
    // por ejemplo, registrationService.completeRegistration(registrationData);

    // Después de enviar los datos, puedes realizar otras acciones como navegar a la página de inicio.
  }

  void updateRegistrationData({
    String? displayName,
    String? phoneNumber,
    String? imagePath,
    LatLng? location,
    required String paymentType,
    required String referralCode,
  }) {
    if (displayName != null) registrationData.displayName = displayName;

    if (phoneNumber != null) registrationData.phoneNumber = phoneNumber;

    if (location != null) {
      registrationData.location = {
        'lat': location.latitude,
        'lng': location.longitude,
      };
    }
  }
}

class RegistrationData {
  String userId;
  String displayName;

  String phoneNumber;
  String paymentType;
  String selectedCountryCode;
  String devicesId;
  String fcmToken;
  int points;

  Map<String, double?>? location;
  String email;

  // Constructor con valores predeterminados desde el formulario
  RegistrationData.fromForm({
    required String userId,
    required String displayName,
    required String phoneNumber,
    required String paymentType,
    required String selectedCountryCode,
    required String devicesId,
    required String fcmToken,
    required Map<String, double?>? location,
    required String email,
    required int points,
  })  : userId = userId,
        displayName = displayName,
        phoneNumber = phoneNumber,
        paymentType = paymentType,
        selectedCountryCode = selectedCountryCode,
        email = email,
        devicesId = devicesId,
        fcmToken = fcmToken,
        location = location,
        points = points;

  // Constructor adicional para inicializar desde el formulario
  RegistrationData({
    required this.userId,
    required this.displayName,
    required this.devicesId,
    required this.fcmToken,
    required this.phoneNumber,
    required this.paymentType,
    required this.selectedCountryCode,
    required this.email,
    required this.location,
    required this.points,
  });
}
