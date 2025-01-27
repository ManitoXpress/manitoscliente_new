import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:manitoscliente_new/categorias/Service_DetailsScreen.dart';
import 'package:manitoscliente_new/metodos/auth_utils.dart';
import 'package:manitoscliente_new/ServicesResponse/resquest.dart';
// Importa la ubicación correcta de ServiceRequest
import 'package:flutter/material.dart';
import 'package:manitoscliente_new/metodos/auth_utils.dart';

class NavigationUtils {
  static void openServiceFormPage(
      BuildContext context, Map<String, dynamic> map, String buttonText) async {
    // Obtiene el token
    String? token = await AuthUtils.getToken();

    if (token != null) {
      print('Token: $token');

      // Obtén el valor correcto para serviceType
      String serviceTypeId = map['serviceType']['id'];
      String serviceTypeName = map['serviceType']['name'];
      ServiceType serviceType = ServiceType(
          id: serviceTypeId,
          name: serviceTypeName,
          selectedDate: '',
          selectedTime: '');

      DateTime? selectedDate = map['selectedDate'] != null
          ? DateTime.parse(map['selectedDate'])
          : null;

      var serviceRequest = ServiceRequest(
        expertises: map['expertises'] ?? '',
        devicesId: map['devicesId'] ?? '',
        serviceDateTime: map['serviceDateTime'] ?? '',
        description: map['description'] ?? '',
        images: List<String>.from(map['images'] ?? []),
        location: Map<String, double>.from(map['location'] ?? {}),
        offeredPrice: map['offeredPrice']?.toDouble() ?? 0.0,
        serviceType: serviceType, // Asignamos el objeto ServiceType
        userId: map['userId'] ?? '',
        workerId: map['workerId'] ?? '',
        selectedDate: selectedDate
            ?.toIso8601String(), // Convertimos DateTime a String ISO8601
        selectedTime: map['selectedTime'] ?? '',
        isFavorite: map['isFavorite'] ?? false,
        acceptedTerms: true, id: '', status: map['status'] ?? '',
        subcategoryName: map['subcategoryName'] ??
            '', hasOffer: false, offers: [], 
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ServiceFormPage(
            serviceRequest: serviceRequest,
            acceptTerms: true,
            serviceRequests: [], // Cambia 'services' a 'serviceRequests'
            selectedDate: selectedDate,
            token: token, selectedServiceTitle: '', selectedTime: '',
            categoryId: '', subcategoryId: '', subcategoryName: '',
          ),
        ),
      );
    } else {
      print('No se pudo obtener el token.');
    }
  }
}
