import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:http/http.dart' as http;

import '../request/requestWoker.dart';
import 'baseurl.dart';


class ServiceDataFetcher {
  // Base URL desde la configuración de la API
  final String baseUrl = ApiConfiguration.baseUrl;

  // Obtener los detalles del trabajador
  Future<WorkerDetails?> fetchWorkerDetails(String? workerId) async {
    if (workerId == null || workerId.isEmpty) {
      null;
      return null;
    }

    try {
      // Obtener el token de autenticación
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();

      if (token == null) {
        null;
        return null;
      }

      // Construir la URL de la API
      final url = '$baseUrl/workers/$workerId';
      null;

      // Realizar la solicitud GET con el token en los encabezados
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token', // Enviar el token en el encabezado
          'Content-Type': 'application/json',
        },
      );

      // Validar respuesta de la API
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        null;
        null;

        // Verificar específicamente si imagePath existe en los datos
        null;
        null;

        // Listar todos los campos disponibles para referencia
        null;

        // Crear el objeto WorkerDetails
        final workerDetails = WorkerDetails.fromMap(data);

        // Verificar si imagePath se mapeó correctamente
        null;

        return workerDetails;
      } else {
        null;
        null;
      }
    } catch (e) {
      null;
    }

    return null;
  }


  // Obtener el precio ofertado para un servicio específico
  Future<double?> fetchOfferedPrice(String? serviceId) async {
    if (serviceId == null || serviceId.isEmpty) {
      null;
      return null;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('serviceId', isEqualTo: serviceId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final offerData = querySnapshot.docs.first.data();
        return double.tryParse(offerData['offeredPrice'].toString());
      } else {
        null;
      }
    } catch (e) {
      null;
    }
    return null;
  }
}
