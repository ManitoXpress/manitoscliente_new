import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
    debugPrint(
        '▶️ fetchServicesByCancelled iniciado con status=$status, userId=$userId');
    // 1. Obtener estados válidos
    final validStatuses = await _getValidStatusesFromFirestore();
    debugPrint('   > estados válidos desde Firestore: $validStatuses');

    if (!validStatuses.contains(status)) {
      debugPrint('   ⚠️ Estado no válido: $status');
      throw ArgumentError('Estado no válido: $status');
    }

    // 2. Llamada al fetch principal
    final result = await _fetchServicesByStatus(
      status,
      column,
      userId,
      token,
    );
    debugPrint(
        '◀️ fetchServicesByCancelled devuelve ${result.length} servicios cancelados');
    return result;
  }

  Future<List<String>> _getValidStatusesFromFirestore() async {
    try {
      final snapshot = await firestore.collection('services').get();
      final statusSet = <String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('status')) {
          statusSet.add(data['status'] as String);
        }
      }
      if (statusSet.isEmpty) {
        throw Exception('No se encontraron estados válidos en Firestore.');
      }
      return statusSet.toList();
    } catch (e) {
      debugPrint('   ❌ Error al obtener estados desde Firestore: $e');
      rethrow;
    }
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
        debugPrint('   • Retornando cache para $status: ${cached.id}');
        return [cached];
      }

      // 2. Llamada al backend
      await obtenerDeviceId();
      debugPrint(
          '   • Llamando getAllServices con status=$status, column=$column');
      final response =
          await apiService.getAllServices(token, column, userId, status);
      if (response.statusCode != 200) {
        debugPrint('   ❌ getAllServices statusCode=${response.statusCode}');
        return [];
      }

      final servicesData =
          List<Map<String, dynamic>>.from(json.decode(response.body));
      debugPrint('   • getAllServices devolvió ${servicesData.length} items');

      // 3. Filtrar por status == 'cancelled' y creados por este usuario
      final filteredServices = servicesData.where((item) {
        return (item['status'] as String? ?? '') == 'cancelled' &&
            (item['userId']?.toString() ?? '') == userId;
      }).toList();
      debugPrint(
          '   • filteredServices (cancelados de $userId) = ${filteredServices.length}');

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
          debugPrint('     ❌ Error getOffers para ${serviceReq.id}: $e');
        }
      }).toList();
      await Future.wait(futures);

      // 6. Cache y retorno de todos los cancelados
      serviceRequestsList.forEach(LocalCacheService.cacheServiceRequest);
      debugPrint(
          '   • Total cancelados retornados = ${serviceRequestsList.length}');
      return serviceRequestsList;
    } catch (e) {
      debugPrint('❌ Error crítico en _fetchServicesByStatus: $e');
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
