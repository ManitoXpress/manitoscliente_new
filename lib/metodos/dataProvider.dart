import 'dart:convert';

import 'package:http/src/response.dart';
import 'package:manitoscliente_new/ServicesResponse/ResponseGet.dart';
import 'package:manitoscliente_new/ServicesResponse/resquest.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiDataProvider {
  Future<List<ServiceRequest>> fetchDataForUserId() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String userId = user.uid;
        String? token = await user.getIdToken();

        // Definir los valores de los parámetros de filtrado
        String column = "";
        String value = "";
        String type = "";

        final Response serviceResponse = await ApiService2().getByUserId(
          userId,
          token!,
          column,
          value,
          type,
        );

        print('Respuesta del servidor: ${serviceResponse.body}');

        if (serviceResponse.statusCode == 200) {
          try {
            final List<dynamic> jsonDataList =
                json.decode(serviceResponse.body);

            final List<ServiceRequest> serviceRequestsList = jsonDataList
                .map((item) => ServiceRequest(
                      id: item['id'],
                      expertises: item['expertises'],
                      serviceDateTime: item['serviceDateTime'],
                      description: item['description'],
                      images: List<String>.from(item['images']),
                      location: Map<String, double>.from(
                        item['location']?.map((key, value) {
                              if (value is int) {
                                return MapEntry(key, value.toDouble());
                              } else {
                                return MapEntry(key, value);
                              }
                            }) ??
                            {},
                      ),
                      offeredPrice:
                          (item['offeredPrice'] as num?)?.toDouble() ?? 0.0,
                      userId: item['userId'],
                      isFavorite: item['isFavorite'] as bool? ?? false,
                      acceptedTerms: item['acceptedTerms'] as bool? ?? false,
                      serviceType: ServiceType(
                          name: item['serviceType'],
                          id: '',
                          selectedDate: '',
                          selectedTime: ''),
                      status: item['status'],
                    ))
                .toList();

            print(
                'Servicios cargados con éxito. Total de servicios obtenidos del backend: ${serviceRequestsList.length}');

            return serviceRequestsList;
          } catch (e) {
            print('Error al decodificar la respuesta JSON: $e');
            return [];
          }
        } else {
          print(
              'Error al obtener datos del backend. Código de estado: ${serviceResponse.statusCode}');
          return [];
        }
      } else {
        print('Usuario no autenticado');
        return [];
      }
    } catch (e) {
      print('Error en la solicitud HTTP: $e');
      return [];
    }
  }
}
