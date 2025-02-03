import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:manitoscliente_new/ServicesResponse/ResponseGet.dart';
import 'package:manitoscliente_new/ServicesResponse/ResponsePost.dart';
import 'package:manitoscliente_new/ServicesResponse/resquest.dart';
import 'package:manitoscliente_new/main.dart';
import 'package:manitoscliente_new/metodos/baseurl.dart';
import 'package:manitoscliente_new/utils/cacheLocal.dart';

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';


import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';


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
  ) async {
    List<String> validStatuses = await _getValidStatusesFromFirestore();

    if (!validStatuses.contains(status)) {
      throw ArgumentError('Estado no válido: $status');
    }

    return await _fetchServicesByInProgress(status, column, userId, token);
  }

  Future<List<String>> _getValidStatusesFromFirestore() async {
    try {
      QuerySnapshot querySnapshot = await firestore.collection('services').get();
      Set<String> statusSet = {};

      for (var doc in querySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('status')) {
          statusSet.add(data['status'] as String);
        }
      }

      return statusSet.toList();
    } catch (e) {
      throw Exception('Error al obtener estados desde Firestore: $e');
    }
  }

  Future<List<ServiceRequest>> _fetchServicesByInProgress(
    String status,
    String column,
    String userId,
    String token,
  ) async {
    try {
      final cachedRequest = await LocalCacheService.getCachedServiceRequest(userId);
      if (cachedRequest != null && cachedRequest.status.id == status) {
        return [cachedRequest];
      }

      final deviceId = await obtenerDeviceId();
      final response = await apiService.getAllServices(token, column, userId, status, deviceId);

      if (response.statusCode != 200) {
        return [];
      }

      final List<Map<String, dynamic>> servicesData = List<Map<String, dynamic>>.from(json.decode(response.body));

        // Filtrar solo los que tienen status "in_progress"
        final filteredServices = servicesData.where((item) => item['status'] == 'in_progress').toList();

        List<ServiceRequest> serviceRequestsList = filteredServices.map((item) {
          final statusName = item['status'] as String? ?? 'in_progress';
          final statusObject = Status(
            id: statusName,
            name: Status.getNameById(statusName),
          );

          return ServiceRequest(
            id: item['id']?.toString() ?? '',
            serviceDateTime: item['serviceDateTime']?.toString() ?? '',
            description: item['description']?.toString() ?? '',
            expertises: _extractExpertises(item),
            images: (item['images'] as List<dynamic>?)?.map((e) => e?.toString() ?? '').toList() ?? [],
            location: Map<String, double>.from((item['location'] as Map<String, dynamic>?)?.map((key, value) => MapEntry(key, (value as num).toDouble())) ?? {}),
            offeredPrice: _parseOfferedPrice(item['offeredPrice']),
            userId: item['userId']?.toString() ?? '',
            workerId: '',
            status: statusObject,
            isFavorite: item['isFavorite'] as bool? ?? false,
            acceptedTerms: item['acceptedTerms'] as bool? ?? false,
            serviceType: ServiceType(
              name: item['serviceType']?['name']?.toString() ?? '',
              id: item['serviceType']?['id']?.toString() ?? '',
              selectedDate: item['serviceType']?['selectedDate']?.toString() ?? '',
              selectedTime: item['serviceType']?['selectedTime']?.toString() ?? '',
            ),
            subcategoryName: item['subcategoryName']?.toString() ?? '',
            devicesId: item['devicesId']?.toString() ?? '',
            hasOffer: false,
            offers: [],
          );
        }).toList();


      List<ServiceRequest> validServices = [];
      for (var service in serviceRequestsList) {
        final List<ServiceRequest> offers = await apiService.getOffers('in_progress',deviceId,'in_progress',deviceId,serviceRequestsList,status);
        if (offers.isNotEmpty) {
          service.workerId = offers.first.workerId;
          service.hasOffer = true;
          service.offers = service.offers;
        }
        validServices.add(service);
      }

      validServices.forEach(LocalCacheService.cacheServiceRequest);
      return validServices.where((s) => s.workerId.isNotEmpty).toList();
    } catch (e) {
      print('Error crítico en _fetchServicesByInProgress: ${e.toString()}');
      return [];
    }
  }

  List<Expertise> _extractExpertises(Map<String, dynamic> item) {
    final expertisesArray = item['expertises'] as List<dynamic>? ?? [];
    if (expertisesArray.isNotEmpty) {
      return expertisesArray.map((exp) => Expertise(
        id: exp['id'] ?? '',
        name: exp['name'] ?? '',
      )).toList();
    }
    return [];
  }

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
