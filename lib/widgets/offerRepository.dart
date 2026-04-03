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
import '../utils/cacheLocal.dart';

class OfferRepository {
  final ApiService2 apiService2;
  final ServiceDataFetcher serviceDataFetcher;
  final FirebaseFirestore firestore;

  OfferRepository({
    required this.apiService2,
    required this.serviceDataFetcher,
    required this.firestore,
  });

  Future<List<ServiceRequest>> fetchServicesByStatus(
    String status,
    String userId,
    String column,
    String token,
    List<Offer> offers,
    String deviceId,
  ) async {
    // Obtener la lista de estados válidos desde Firestore
    List<String> validStatuses = await _getValidStatusesFromFirestore();

    // Validar el estado proporcionado
    if (!validStatuses.contains(status)) {
      throw ArgumentError('Estado no válido: $status');
    }

    // Construir un servicio de ejemplo para pasar a fetchOffersForUser
    // Esto puede variar según tu lógica, aquí asumimos que hay un ServiceRequest inicial
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
      offers: [], subcategoryName: '', createdAt: DateTime.now(),
    );

    // Retornar los servicios con sus ofertas
    return await fetchOffersForUser(status, column, userId, token, service,
        deviceId // Reemplaza esto con el deviceId real si lo tienes
        );
  }

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

  Future<List<ServiceRequest>> fetchOffersForUser(
    String type,
    String column,
    String userId,
    String token,
    ServiceRequest service,
    String deviceId,
  ) async {
    try {
      // Verificar caché
      final cachedRequest =
          await LocalCacheService.getCachedServiceRequest(userId);
      if (cachedRequest != null) {
        null;
        return [cachedRequest];
      } else {
        null;

        final response = await apiService2.getAllServices(
          token,
          column,
          userId,
          type,


        );
        null;
        null;
        null;
        null;
        null;

        if (response.statusCode == 200) {
          final List<Map<String, dynamic>> servicesData =
              List<Map<String, dynamic>>.from(
            json.decode(response.body),
          );

          if (servicesData.isNotEmpty) {
            try {
              // Mapeamos los datos para crear una lista de ServiceRequest
              final List<ServiceRequest> serviceRequestsList =
                  servicesData.map((item) {
                final statusName = item['status'] as String? ?? 'offer';
                final statusObject = Status(
                  id: statusName,
                  name: Status.getNameById(statusName),
                );

                return ServiceRequest(
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
                          return MapEntry(
                              key, (value is int) ? value.toDouble() : value);
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
                    selectedDate: '',
                    selectedTime: '',
                  ),
             
                  devicesId: '',
                  hasOffer: false,
                  offers: [], subcategoryName: '', createdAt: DateTime.now(),// Lista vacía inicialmente
                );
              }).toList();

              // Cacheamos las solicitudes de servicio
              serviceRequestsList.forEach((request) {
                LocalCacheService.cacheServiceRequest(request);
              });

              // Ahora obtenemos las ofertas de forma asincrónica
              List<Future> requests =
                  serviceRequestsList.map((serviceRequest) async {
                null;
                try {
                  final offerResponses = await ApiService2().getOffers(
                    "userId",    // Columna a filtrar
                    userId,      // Valor del usuario
                    "offer",    // Tipo de filtro
                    deviceId,
                    [serviceRequest],
                    "offer", // Filtrar solo ofertas en estado offer
                  );
                  

                  // Mapear las ofertas
                  // Corregir el mapeo de ofertas
                  List<Offer> offers = offerResponses.map((serviceOffer) {
                    // 1. Acceder directamente a las propiedades del objeto ServiceRequest
                    final statusName = serviceOffer.status.id; // <--- Cambio clave aquí
                    final statusObject = Status(
                        id: statusName,
                        name: Status.getNameById(statusName),
                      ); // Usar el status existente
                    
                    // 2. Obtener precios desde el objeto real
                    final offeredPrice = serviceOffer.offeredPrice;

                    return Offer(
                      id: serviceOffer.id,
                      workerId: serviceOffer.workerId,
                      offeredPrice: offeredPrice,
                      hasOffer: serviceOffer.hasOffer,
                      serviceId: serviceRequest.id,
                      extraCosts:0.0, // Si existe en ServiceRequest
                      totalPrice: serviceOffer.offeredPrice, // Ajustar según lógica real
                      status: statusObject, // Usar el status del servicio
                      userToken: '',
                      createdAt: DateTime.now(),
                      expertises: serviceOffer.expertises, subcategoryName: '',
                
                    );
                  }).toList();

                  // Asignar las ofertas al servicio correspondiente
                  serviceRequest.offers = offers;

                  // Imprimir la cantidad de ofertas obtenidas
                  null;
                } catch (e) {
                  null;
                }
              }).toList();

              // Esperar a que todas las solicitudes de ofertas terminen
              await Future.wait(requests);

              // Retornar la lista de solicitudes de servicio con sus ofertas
              return serviceRequestsList;
            } catch (e) {
              null;
              return [];
            }
          } else {
            null;
            return [];
          }
        } else {
          null;
          return [];
        }
      }
    } catch (e) {
      null;
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
