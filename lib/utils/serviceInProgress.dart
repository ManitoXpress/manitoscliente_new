import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:manitoscliente_new/ServicesResponse/ResponseGet.dart';
import 'package:manitoscliente_new/ServicesResponse/ResponsePost.dart';
import 'package:manitoscliente_new/ServicesResponse/resquest.dart';
import 'package:manitoscliente_new/main.dart';
import 'package:manitoscliente_new/metodos/baseurl.dart';
import 'package:manitoscliente_new/utils/cacheLocal.dart';

class ServiceRepository2 {
  final ApiService2 apiService;
  final FirebaseFirestore firestore;
  final String baseUrl = ApiConfiguration.baseUrl;

  ServiceRepository2({required this.apiService, required this.firestore});

  Future<List<ServiceRequest>> fetchServicesByInProgress(
    String status,
    String userId,
    String column,
    String token,
    List<Offer> offers, // Agregado el parámetro de ofertas
  ) async {
    // Obtener la lista de estados válidos desde Firestore
    List<String> validStatuses = await _getValidStatusesFromFirestore();
    ServiceRequest service = ServiceRequest(
      id: '',
      serviceDateTime: DateTime.now().toString(),
      description: '',
      expertises: [],
      images: [],
      location: {},
      offeredPrice: 0.0,
      userId: userId,
      workerId: '',
      status: Status(id: status, name: Status.getNameById(status)),
      isFavorite: false,
      acceptedTerms: false,
      serviceType:
          ServiceType(name: '', id: '', selectedDate: '', selectedTime: ''),
      subcategoryName: '',
      devicesId: '',
      hasOffer: false,
      offers: [],
    );

    // Validar el estado proporcionado con los valores de Firestore
    if (!validStatuses.contains(status)) {
      throw ArgumentError('Estado no válido: $status');
    }

    // Llamar al método privado para realizar la lógica principal
    return await _fetchServicesByInprogress(status, column, userId, token, offers);
   
  }

  // Método privado para obtener los estados válidos desde Firestore
  Future<List<String>> _getValidStatusesFromFirestore() async {
    try {
      QuerySnapshot querySnapshot =
          await firestore.collection('services').get();

      Set<String> statusSet = {};

      for (var doc in querySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('status')) {
          statusSet.add(data['status'] as String);
        }
      }

      if (statusSet.isNotEmpty) {
        return statusSet.toList();
      } else {
        throw Exception('No se encontraron estados válidos en Firestore.');
      }
    } catch (e) {
      throw Exception('Error al obtener estados desde Firestore: $e');
    }
  }

  Future<List<ServiceRequest>> _fetchServicesByInprogress(
  String type,
  String column,
  String userId,
  String token,
  List<Offer> offers,
) async {
  try {
    final cachedRequest = await LocalCacheService.getCachedServiceRequest(userId);
    
    // Verificar si el caché es válido para 'in_progress'
    if (cachedRequest != null) {
      if (cachedRequest.status.id == 'in_progress') { // Cambiado de 'available' a 'in_progress'
        print('Datos en caché (in_progress) encontrados: ${cachedRequest.id}');
        return [cachedRequest];
      } else {
        print('Datos en caché no tienen estado in_progress...');
        return [];
      }
    } else {
      final deviceId = await obtenerDeviceId();

      // Debug: Parámetros de la solicitud
      print('''
      |--> Llamando a API para in_progress:
      | Tipo: $type
      | Columna: $column
      | UserID: $userId
      | DeviceID: $deviceId
      ''');

      final response = await ApiService2().getAllServices(
        token,
        column,
        userId,
        type,
        deviceId,
      );

      // Debug: Respuesta cruda del API
      print('Respuesta del API (raw): ${response.body}');

      if (response.statusCode == 200) {
        final List<Map<String, dynamic>> servicesData =
            List<Map<String, dynamic>>.from(json.decode(response.body));

        if (servicesData.isEmpty) {
          print('No hay servicios in_progress.');
          return [];
        }

        final List<ServiceRequest> serviceRequestsList = servicesData.map((item) {
          // Debug: Item completo
          print('Procesando item: ${item.toString()}');

          // Mapeo robusto de workerId
          final workerId = item['workerId'] ?? item['worker_id'] ?? ''; // Soporta múltiples nombres de campo
          final statusName = item['status'] as String? ?? 'in_progress';

          return ServiceRequest(
            id: item['id']?.toString() ?? '', // Asegura String
            serviceDateTime: item['serviceDateTime'] ?? '',
            description: item['description'] ?? '',
            images: (item['images'] as List<dynamic>?)
                    ?.map((image) => image?.toString() ?? '')
                    .toList() ??
                [],
            location: Map<String, double>.from(
              (item['location'] as Map<String, dynamic>?)?.map((key, value) {
                    return MapEntry(
                        key,
                        (value is int)
                            ? value.toDouble()
                            : (value is double) ? value : 0.0);
                  }) ??
                  {},
            ),
            offeredPrice: _parseOfferedPrice(item['offeredPrice']),
            userId: item['userId'] ?? '',
            workerId: workerId, // Usa el valor mapeado
            status: Status(
              id: statusName,
              name: Status.getNameById(statusName),
            ),
            isFavorite: item['isFavorite'] as bool? ?? false,
            acceptedTerms: item['acceptedTerms'] as bool? ?? false,
            serviceType: ServiceType(
              name: item['serviceType']?.toString() ?? '',
              id: '',
              selectedDate: '',
              selectedTime: '',
            ),
            subcategoryName: item['subcategoryName'] ?? '',
            expertises: _extractExpertises(item), // Usa método auxiliar
            devicesId: '',
            hasOffer: false,
            offers: [],
          );
        }).where((service) => service.status.id == 'in_progress').toList();

        // Cachear solo servicios in_progress
        serviceRequestsList.forEach((request) {
          if (request.status.id == 'in_progress') {
            LocalCacheService.cacheServiceRequest(request);
          }
        });

        print('Servicios in_progress obtenidos: ${serviceRequestsList.length}');
        return serviceRequestsList;

      } else {
        print('Error HTTP ${response.statusCode}: ${response.reasonPhrase}');
        return [];
      }
    }
  } catch (e) {
    print('Error crítico en _fetchServicesByInprogress: $e');
    return [];
  }
}

  List<Expertise> _extractExpertises(Map<String, dynamic> item) {
    final expertisesArray = item['expertises'] as List<dynamic>? ?? [];
    if (expertisesArray.isNotEmpty) {
      final expertiseItem = expertisesArray.first;
      return [
        Expertise(
          id: expertiseItem['id'] ?? '',
          name: expertiseItem['name'] ?? '',
        ),
      ];
    }
    return [];
  }
  

  // Método privado para parsear el precio ofrecido
  double _parseOfferedPrice(dynamic value) {
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Error al convertir el precio ofrecido a double: $e');
        return 0.0;
      }
    } else if (value is num) {
      return value.toDouble();
    }
    return 0.0;
  }
}
