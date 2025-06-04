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
    debugPrint('▶️ fetchServicesByComplete iniciado con status=$status, userId=$userId');
    // 1. Obtener estados válidos
    List<String> validStatuses = await _getValidStatusesFromFirestore();
    debugPrint('   > estados válidos desde Firestore: $validStatuses');

    if (!validStatuses.contains(status)) {
      debugPrint('   ⚠️ Estado no válido: $status');
      throw ArgumentError('Estado no válido: $status');
    }

    // 2. Llamar al fetch principal
    final result = await _fetchServicesByStatus(
      status,
      column,
      userId,
      token,
    );
    debugPrint('◀️ fetchServicesByComplete devuelve ${result.length} servicios completos');
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
      debugPrint('   • _getValidStatusesFromFirestore encontró: $statusSet');
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
      if (cached != null &&
          (cached.status.id == 'in_progress' ||
              cached.status.id == 'pending_confirmation' ||
              cached.status.id == 'pending_confirmation2')) {
        debugPrint('   • Retornando cache para in_progress/pending: ${cached.id}');
        return [cached];
      }

      // 2. Llamada al backend
      final deviceId = await obtenerDeviceId();
      debugPrint('   • Llamando getAllServices con status=$status, column=$column');
      final response = await apiService.getAllServices(token, column, userId, status);

      if (response.statusCode != 200) {
        debugPrint('   ❌ getAllServices statusCode=${response.statusCode}');
        return [];
      }

      final List<Map<String, dynamic>> servicesData =
      List<Map<String, dynamic>>.from(json.decode(response.body));
      debugPrint('   • getAllServices devolvió ${servicesData.length} items');

      // 3. Filtrar por status == 'completed'
      // 3. Filtrar por status == 'completed' y services creados por este userId
      final filteredServices = servicesData.where((item) {
        final statusVal = (item['status'] as String?) ?? '';
        final ownerId   = item['userId']?.toString() ?? '';
        return statusVal == 'cancelled' && ownerId == userId;
      }).toList();
      debugPrint('   • filteredServices (completados de $userId) = ${filteredServices.length}');

      // 4. Mapear a ServiceRequest
      final serviceRequestsList = filteredServices.map((item) {
        return ServiceRequest(
          createdAt: DateTime.now(),
          id: item['id']?.toString() ?? '',
          serviceDateTime: item['serviceDateTime']?.toString() ?? '',
          description: item['description']?.toString() ?? '',
          images: (item['images'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
          location: Map<String, double>.from(
            (item['location'] as Map<String, dynamic>? ?? {})
                .map((k, v) => MapEntry(k, (v as num).toDouble())),
          ),
          offeredPrice: _parseOfferedPrice(item['offeredPrice']),
          serviceType: ServiceType(
            id: item['serviceType']?['id']?.toString() ?? '',
            name: item['serviceType']?['name']?.toString() ?? '',
            selectedDate: item['serviceType']?['selectedDate']?.toString() ?? '',
            selectedTime: item['serviceType']?['selectedTime']?.toString() ?? '',
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
        );
      }).toList();
      debugPrint('   • serviceRequestsList.length = ${serviceRequestsList.length}');

      // 5. Obtener ofertas para cada servicio
      // 5. Obtener ofertas para cada servicio y poblar validServices
      // 5. Obtener ofertas para cada servicio y poblar validServices
      final validServices = <ServiceRequest>[];
      final futures = serviceRequestsList.map((serviceReq) async {
        debugPrint('   • solicitando ofertas para servicio ${serviceReq.id}');
        try {
          final offerResponses = await apiService.getOffers(
            'workerId',
            userId,
            'offer',
            await obtenerDeviceId(),
            [serviceReq],
            'offer',
          );
          debugPrint('     – getOffers devolvió ${offerResponses.length} items');

          // Mapeamos *todas* las respuestas a Offer, sin filtrar por workerId
          final allOffers = offerResponses.map((svc) => Offer(
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
          )).toList();
          debugPrint('     – allOffers.length = ${allOffers.length}');

          if (allOffers.isNotEmpty) {
            serviceReq.hasOffer = true;
            serviceReq.offers = allOffers;
            validServices.add(serviceReq);
          }
        } catch (e) {
          debugPrint('     ❌ Error getOffers para ${serviceReq.id}: $e');
        }
      }).toList();

      await Future.wait(futures);
      debugPrint('   • validServices.length = ${validServices.length}');


      // Cache y retorno
      validServices.forEach(LocalCacheService.cacheServiceRequest);
      return validServices;
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
      try {
        return double.parse(value);
      } catch (_) {
        return 0.0;
      }
    } else if (value is num) {
      return value.toDouble();
    }
    return 0.0;
  }
}