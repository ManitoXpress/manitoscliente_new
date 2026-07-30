import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../main.dart';
import '../controller/baseurl.dart';
import '../request/ResponseGet.dart';
import '../request/ResponsePost.dart';
import '../request/requestExpertise.dart';
import '../request/requestServiceType.dart';
import '../request/requestStatus.dart';
import '../request/resquest.dart';
import 'cacheLocal.dart';

class ServiceRepositoryCancelled {
  final ApiService2 apiService;
  final FirebaseFirestore firestore;
  final String baseUrl = ApiConfiguration.baseUrl;

  ServiceRepositoryCancelled({
    required this.apiService,
    required this.firestore,
  });

  Future<List<ServiceRequest>> fetchServicesByCancelled(
    String status,
    String userId,
    String column,
    String token,
  ) async {
    null;
    // 1. Obtener estados válidos
    final validStatuses = await _getValidStatusesFromFirestore();
    null;

    if (!validStatuses.contains(status)) {
      null;
      throw ArgumentError('Estado no válido: $status');
    }

    // 2. Llamada al fetch principal
    final result = await _fetchServicesByStatus(
      status,
      column,
      userId,
      token,
    );
    null;
    return result;
  }

  Future<List<String>> _getValidStatusesFromFirestore() async {
    // Usar lista estática para evitar escanear toda la colección
    return [
      'available', 'offer', 'in_progress', 'pending_confirmation',
      'pending_confirmation2', 'completed', 'cancelled',
    ];
  }

  Future<List<ServiceRequest>> _fetchServicesByStatus(
    String status,
    String column,
    String userId,
    String token,
  ) async {
    try {
      // 1. Cache local
      final cached = await LocalCacheService.getCachedServiceRequest(userId);
      if (cached != null && cached.status.id == status) {
        null;
        return [cached];
      }

      // 2. Llamada al backend
      await obtenerDeviceId();
      null;
      final response =
          await apiService.getAllServices(token, column, userId, status);
      if (response.statusCode != 200) {
        null;
        return [];
      }

      final servicesData =
          List<Map<String, dynamic>>.from(json.decode(response.body));
      null;

      // 3. Filtrar por status == 'cancelled' y creados por este usuario
      final filteredServices = servicesData.where((item) {
        return (item['status'] as String? ?? '') == 'cancelled' &&
            (item['userId']?.toString() ?? '') == userId;
      }).toList();
      null;

      // 4. Mapear a ServiceRequest
      final serviceRequestsList = filteredServices
          .map((item) => ServiceRequest(
                createdAt: DateTime.now(),
                id: item['id']?.toString() ?? '',
                serviceDateTime: item['serviceDateTime']?.toString() ?? '',
                description: item['description']?.toString() ?? '',
                images: (item['images'] as List<dynamic>? ?? [])
                    .map((e) => e.toString())
                    .toList(),
                location: Map<String, double>.from(
                  (item['location'] as Map<String, dynamic>? ?? {})
                      .map((k, v) => MapEntry(k, (v as num).toDouble())),
                ),
                offeredPrice: _parseOfferedPrice(item['offeredPrice']),
                serviceType: ServiceType(
                  id: item['serviceType']?['id']?.toString() ?? '',
                  name: item['serviceType']?['name']?.toString() ?? '',
                  selectedDate: item['date']?.toString() ?? '',
                  selectedTime: item['time']?.toString() ?? '',
                ),
                userId: item['userId']?.toString() ?? '',
                devicesId: '',
                workerId: '',
                isFavorite: item['isFavorite'] as bool? ?? false,
                acceptedTerms: item['acceptedTerms'] as bool? ?? false,
                expertises: _extractExpertises(item),
                status: Status(
                  id: 'cancelled',
                  name: Status.getNameById('cancelled'),
                ),
                subcategoryName: item['subcategoryName']?.toString() ?? '',
                hasOffer: false,
                offers: [],
                workerDetails: null,
              ))
          .toList();

      // 5. Obtener ofertas para cada servicio (pero incluir todos)
      final futures = serviceRequestsList.map((serviceReq) async {
        try {
          final offerResponses = await apiService.getOffers('workerId', userId,
              'offer', await obtenerDeviceId(), [serviceReq], 'offer');
          final allOffers = offerResponses
              .map((svc) => Offer(
                    id: svc.id,
                    workerId: svc.workerId,
                    offeredPrice: svc.offeredPrice,
                    hasOffer: svc.hasOffer,
                    serviceId: serviceReq.id,
                    extraCosts: 0.0,
                    totalPrice: svc.offeredPrice,
                    status: svc.status,
                    userToken: '',
                    createdAt: DateTime.now(),
                    expertises: svc.expertises,
                    subcategoryName: svc.subcategoryName,
                  ))
              .toList();

          if (allOffers.isNotEmpty) {
            serviceReq.hasOffer = true;
            serviceReq.offers = allOffers;
          }
        } catch (e) {
          null;
        }
      }).toList();
      await Future.wait(futures);

      // 6. Cache y retorno de todos los cancelados
      serviceRequestsList.forEach(LocalCacheService.cacheServiceRequest);
      null;
      return serviceRequestsList;
    } catch (e) {
      null;
      return [];
    }
  }

  List<Expertise> _extractExpertises(Map<String, dynamic> item) {
    final arr = item['expertises'] as List<dynamic>? ?? [];
    return arr
        .map((e) => Expertise(
              id: e['id']?.toString() ?? '',
              name: e['name']?.toString() ?? '',
            ))
        .toList();
  }

  double _parseOfferedPrice(dynamic value) {
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    } else if (value is num) {
      return value.toDouble();
    }
    return 0.0;
  }
}
