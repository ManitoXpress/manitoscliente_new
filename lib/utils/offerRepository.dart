import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../controller/serviceFetcher.dart';
import '../request/ResponseGet.dart';
import '../request/requestExpertise.dart';
import '../request/requestServiceType.dart';
import '../request/requestStatus.dart';
import '../request/resquest.dart';
import 'cacheLocal.dart';

class OfferRepository {
  final ApiService2 apiService2;
  final ServiceDataFetcher serviceDataFetcher;
  final FirebaseFirestore firestore;

  OfferRepository({
    required this.apiService2,
    required this.serviceDataFetcher,
    required this.firestore,
  });

  /// Método público que filtra los servicios por estado y usuario autenticado.
  Future<List<ServiceRequest>> fetchServicesByStatus(
    String status,
    String userId,
    String token,
    List<Offer> offers,
    String deviceId,
  ) async {
    // Se obtienen los estados válidos desde Firestore (globales o configurados)
    List<String> validStatuses = await _getValidStatusesFromFirestore();

    // Validar que el estado proporcionado sea correcto.
    if (!validStatuses.contains(status)) {
      throw ArgumentError('Estado no válido: $status');
    }

    // Se crea un ServiceRequest "dummy" para pasarlo a la función interna.
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
      devicesId: '',
      hasOffer: false,
      offers: [],
      subcategoryName: '',
      createdAt: DateTime.now(),
    );

    // Se invoca la función que obtiene los servicios y sus ofertas filtrando por userId.
    return await fetchOffersForUser(status, userId, token, service, deviceId);
  }

  /// Retorna la lista de estados válidos (hardcodeada para evitar lectura completa de Firestore).
  Future<List<String>> _getValidStatusesFromFirestore() async {
    return const ['available', 'offer', 'in_progress', 'completed', 'cancelled'];
  }

  /// Método que obtiene los servicios y, para cada uno, sus ofertas filtradas por el userId.
  Future<List<ServiceRequest>> fetchOffersForUser(
    String type,
    String userId,
    String token,
    ServiceRequest service,
    String deviceId,
  ) async {
    try {
      // No leer de caché local aquí: puede devolver el servicio sin las ofertas adjuntas.
      // Siempre buscamos en la API para garantizar que las ofertas estén actualizadas.

      // Llamada a la API usando "userId" como columna de filtro.
      final response = await apiService2.getAllServices(
        token,
        "userId",
        userId,
        type,
      );

      debugPrint('🔍 [OfferRepo] Buscando servicios tipo=$type para userId=$userId');
      debugPrint('🔍 [OfferRepo] HTTP status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final List<Map<String, dynamic>> servicesData =
              List<Map<String, dynamic>>.from(json.decode(response.body));

          if (servicesData.isNotEmpty) {
            debugPrint('🔍 [OfferRepo] Total documentos en respuesta: ${servicesData.length}');
            try {
              // Mapeo de la respuesta para crear una lista de ServiceRequest.
              // Se filtran aquellos que tengan status 'available' y userId igual al autenticado.
              final List<ServiceRequest> serviceRequestsList = servicesData
                  .map((item) {
                    final statusName = item['status'] as String? ?? 'offer';
                    final statusObject = Status(
                      id: statusName,
                      name: Status.getNameById(statusName),
                    );

                    return ServiceRequest(
                      createdAt: DateTime.now(),
                      expertises: _extractExpertises(item),
                      id: item['id'] ?? '',
                      serviceDateTime: item['serviceDateTime'] ?? '',
                      description: item['description'] ?? '',
                      images: (item['images'] as List<dynamic>?)
                              ?.map((image) => image as String? ?? '')
                              .toList() ??
                          [],
                      location: Map<String, double>.from(
                        (item['location'] as Map<String, dynamic>?)
                                ?.map((key, value) {
                              return MapEntry(key,
                                  (value is int) ? value.toDouble() : value);
                            }) ??
                            {},
                      ),
                      offeredPrice: _parseOfferedPrice(item['offeredPrice']),
                      userId: item['userId'] ?? '',
                      workerId: item['workerId'] ?? '',
                      status: statusObject,
                      isFavorite: item['isFavorite'] as bool? ?? false,
                      acceptedTerms: item['acceptedTerms'] as bool? ?? false,
                      serviceType: ServiceType(
                        name: item['serviceType'] ?? '',
                        id: '',
                        selectedDate: item['date'] ?? '',
                        selectedTime: item['time'] ?? '',
                      ),
                      devicesId: '',
                      hasOffer: false,
                      offers: [],
                      subcategoryName: item['subcategoryName'] ?? '',
                    );
                  })
                  .where((service) =>
                      service.status.id == 'available' &&
                      service.userId == userId)
                  .toList();

              debugPrint('✅ [OfferRepo] Servicios filtrados como offer: ${serviceRequestsList.length}');

              // Cacheamos las solicitudes de servicio para este usuario.
              for (var request in serviceRequestsList) {
                LocalCacheService.cacheServiceRequest(request);
              }

              // Para cada servicio, se solicitan las ofertas correspondientes filtradas por userId.
              List<Future> offerRequests =
                  serviceRequestsList.map((serviceRequest) async {
                null;
                try {
                  debugPrint('📡 [OfferRepo] Pidiendo ofertas para serviceId=${serviceRequest.id}');
                  final offerResponses = await ApiService2().getOffers(
                    "userId", // Filtrar por la columna "userId"
                    userId, // Valor del usuario autenticado
                    "offer", // Tipo de filtro (ajusta según tu lógica)
                    deviceId,
                    [serviceRequest],
                    "offer", // Filtrar solo ofertas en estado offer
                  );

                  // Mapeo de las ofertas recibidas.
                  List<Offer> offers = offerResponses.map((serviceOffer) {
                    final statusName = serviceOffer.status.id;
                    final statusObject = Status(
                      id: statusName,
                      name: Status.getNameById(statusName),
                    );

                    return Offer(
                      id: serviceOffer.id,
                      workerId: serviceOffer.workerId,
                      offeredPrice: serviceOffer.offeredPrice,
                      hasOffer: serviceOffer.hasOffer,
                      serviceId: serviceRequest.id,
                      extraCosts: 0.0,
                      totalPrice: serviceOffer.offeredPrice,
                      status: statusObject,
                      userToken: '',
                      createdAt: DateTime.now(),
                      expertises: serviceOffer.expertises,
                      subcategoryName: serviceOffer.subcategoryName,
                    );
                  }).toList();

                  // Se asignan las ofertas al servicio correspondiente.
                  serviceRequest.offers = offers;
                  debugPrint('✅ [OfferRepo] Ofertas asignadas al servicio ${serviceRequest.id}: ${offers.length} oferta(s)');
                } catch (e) {
                  debugPrint('❌ [OfferRepo] Error al obtener ofertas para ${serviceRequest.id}: $e');
                }
              }).toList();

              // Se espera a que todas las solicitudes de ofertas finalicen.
              await Future.wait(offerRequests);

              return serviceRequestsList;
            } catch (e) {
              return [];
            }
          } else {
            return [];
          }
        } else {
          return [];
        }
    } catch (e) {
      return [];
    }
  }

  /// Extrae la lista de expertises a partir del mapa recibido.
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

  /// Parsea el valor del precio ofrecido a double.
  double _parseOfferedPrice(dynamic value) {
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        null;
      }
    } else if (value is num) {
      return value.toDouble();
    }
    return 0.0;
  }
}
