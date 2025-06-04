import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:manitoscliente_new/request/dataprofile.dart';

import '../categorias/Service_DetailsScreen.dart';
import '../request/requestServiceType.dart';
import '../request/resquest.dart';
import 'auth_utils.dart';

class NavigationUtils {
  /// Abre ServiceFormPage, ahora recibiendo userData y callback
  static void openServiceFormPage(
      BuildContext context,
      Map<String, dynamic> map,
      String buttonText,
      UserData userData,
      VoidCallback onTabTapped,
      ) async {
    // Obtiene el token
    String? token = await AuthUtils.getToken();

    if (token != null) {
      print('Token: $token');

      // Construye ServiceType
      String serviceTypeId = map['serviceType']['id'];
      String serviceTypeName = map['serviceType']['name'];
      ServiceType serviceType = ServiceType(
        id: serviceTypeId,
        name: serviceTypeName,
        selectedDate: '',
        selectedTime: '',
      );

      DateTime? selectedDate = map['selectedDate'] != null
          ? DateTime.parse(map['selectedDate'])
          : null;

      var serviceRequest = ServiceRequest(
        expertises: map['expertises'] ?? [],
        devicesId: map['devicesId'] ?? '',
        serviceDateTime: map['serviceDateTime'] ?? '',
        description: map['description'] ?? '',
        images: List<String>.from(map['images'] ?? []),
        location: Map<String, double>.from(map['location'] ?? {}),
        offeredPrice: map['offeredPrice']?.toDouble() ?? 0.0,
        serviceType: serviceType,
        userId: map['userId'] ?? '',
        workerId: map['workerId'] ?? '',
        selectedDate: selectedDate?.toIso8601String(),
        selectedTime: map['selectedTime'] ?? '',
        isFavorite: map['isFavorite'] ?? false,
        acceptedTerms: true,
        id: map['id'] ?? '',
        status: map['status'] ?? '',
        hasOffer: false,
        offers: [],
        subcategoryName: map['subcategoryName'] ?? '',
        createdAt: DateTime.now(),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ServiceFormPage(
            serviceRequest: serviceRequest,
            acceptTerms: true,
            serviceRequests: [],
            selectedDate: selectedDate,
            token: token,
            selectedServiceTitle: buttonText,
            selectedTime: map['selectedTime'] ?? '',
            categoryId: map['categoryId'] ?? '',
            expertiseId: map['expertiseId'] ?? '',
            expertiseName: map['expertiseName'] ?? '',
            userData: userData, // ← importante: lo pasamos aquí

          ),
        ),
      );
    } else {
      print('No se pudo obtener el token.');
    }
  }
}