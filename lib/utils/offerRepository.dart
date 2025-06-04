import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      serviceType: ServiceType(name: '', id: '', selectedDate: '', selectedTime: ''),
      devicesId: '',
      hasOffer: false,
      offers: [],
      subcategoryName: '', createdAt: DateTime.now(),
    );

    // Se invoca la función que obtiene los servicios y sus ofertas filtrando por userId.
    return await fetchOffersForUser(status, userId, token, service, deviceId);
  }

  /// Obtiene la lista de estados válidos desde la colección "offers" en Firestore.
  Future<List<String>> _getValidStatusesFromFirestore() async {
    try {
      QuerySnapshot querySnapshot = await firestore.collection('offers').get();
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

  /// Método que obtiene los servicios y, para cada uno, sus ofertas filtradas por el userId.
  Future<List<ServiceRequest>> fetchOffersForUser(
  String type,
  String userId,
  String token,
  ServiceRequest service,
  String deviceId,
) async {
  try {
    // Verificar si hay datos en caché para este usuario.
    final cachedRequest = await LocalCacheService.getCachedServiceRequest(userId);
    if (cachedRequest != null) {
      print('Datos del caché encontrados.');
      return [cachedRequest];
    } else {
      print('Enviando solicitud a getAllServices para el servicio ID: ${service.id}');

      // Llamada a la API usando "userId" como columna de filtro.
      final response = await apiService2.getAllServices(
        token,
        "userId", // Columna de filtro fija
        userId,   // Valor del usuario autenticado
        type,
        
      );

      print('token=$token');
      print('Filtrando por userId: $userId');
      print('type=$type');
      print('deviceId=$deviceId');

      if (response.statusCode == 200) {
        final List<Map<String, dynamic>> servicesData =
            List<Map<String, dynamic>>.from(json.decode(response.body));

        if (servicesData.isNotEmpty) {
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
                      (item['location'] as Map<String, dynamic>?)?.map((key, value) {
                        return MapEntry(key, (value is int) ? value.toDouble() : value);
                      }) ?? {},
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
                      selectedDate: '',
                      selectedTime: '',
                    ),
                    devicesId: '',
                    hasOffer: false,
                    offers: [],
                    subcategoryName: item['subcategoryName'] ?? '',
                  );
                })
                .where((service) =>
                    service.status.id == 'available' && service.userId == userId)
                .toList();

            // Cacheamos las solicitudes de servicio para este usuario.
            for (var request in serviceRequestsList) {
              LocalCacheService.cacheServiceRequest(request);
            }

            // Para cada servicio, se solicitan las ofertas correspondientes filtradas por userId.
            List<Future> offerRequests = serviceRequestsList.map((serviceRequest) async {
              print('Solicitando ofertas para el servicio ID: ${serviceRequest.id}');
              try {
                final offerResponses = await ApiService2().getOffers(
                  "userId",   // Filtrar por la columna "userId"
                  userId,     // Valor del usuario autenticado
                  "offer",    // Tipo de filtro (ajusta según tu lógica)
                  deviceId,
                  [serviceRequest],
                  "offer",
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
                print('Ofertas obtenidas para el servicio ${serviceRequest.id}: ${offers.length}');
              } catch (e) {
                print('Error al obtener ofertas para el servicio ${serviceRequest.id}: $e');
              }
            }).toList();

            // Se espera a que todas las solicitudes de ofertas finalicen.
            await Future.wait(offerRequests);

            return serviceRequestsList;
          } catch (e) {
            print('Error al procesar los datos del servicio: $e');
            return [];
          }
        } else {
          print('No se encontraron servicios disponibles.');
          return [];
        }
      } else {
        print('Error en la solicitud HTTP: ${response.statusCode}');
        return [];
      }
    }
  } catch (e) {
    print('Error en la solicitud: $e');
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
        print('Error al convertir el precio ofrecido a double: $e');
      }
    } else if (value is num) {
      return value.toDouble();
    }
    return 0.0;
  }
}
