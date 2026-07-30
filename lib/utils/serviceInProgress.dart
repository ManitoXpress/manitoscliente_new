import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '../controller/baseurl.dart';
import '../request/ResponseGet.dart';
import '../request/requestExpertise.dart';
import '../request/requestServiceType.dart';
import '../request/requestStatus.dart';
import '../request/resquest.dart';
import 'cacheLocal.dart';

class ServiceRepositoryInProgress {
  final ApiService2 apiService;
  final FirebaseFirestore firestore;
  final String baseUrl = ApiConfiguration.baseUrl;

  ServiceRepositoryInProgress(
      {required this.apiService, required this.firestore});

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
    // Usar lista estática para evitar escanear toda la colección
    return [
      'available', 'offer', 'in_progress', 'pending_confirmation',
      'pending_confirmation2', 'completed', 'cancelled',
    ];
  }

  Future<List<ServiceRequest>> _fetchServicesByInProgress(
    String status,
    String column,
    String userId,
    String token,
  ) async {
    try {
      // No usar caché local para in_progress — siempre traer datos frescos del servidor

      final deviceId = await obtenerDeviceId();
      final response = await apiService.getAllServices(
        token,
        column,
        userId,
        status,
      );

      if (response.statusCode != 200) {
        null;
        return [];
      }

      final List<Map<String, dynamic>> servicesData =
          List<Map<String, dynamic>>.from(json.decode(response.body));

      // Filtrar servicios con estado in_progress o pending_confirmation y que pertenezcan al usuario autenticado
      final filteredServices = servicesData.where((item) {
        final itemStatus = item['status'] as String? ?? '';
        return (itemStatus == 'in_progress' ||
                itemStatus == 'pending_confirmation') &&
            (item['userId']?.toString() ?? '') == userId;
      }).toList();

      List<ServiceRequest> serviceRequestsList = filteredServices.map((item) {
        final statusName = (item['status'] as String?) ?? 'in_progress';
        final statusObject = Status(
          id: statusName,
          name: Status.getNameById(statusName),
        );

        return ServiceRequest(
          id: item['id']?.toString() ?? '',
          serviceDateTime: item['serviceDateTime']?.toString() ?? '',
          description: item['description']?.toString() ?? '',
          expertises: _extractExpertises(item),
          images: (item['images'] as List<dynamic>?)
                  ?.map((e) => e?.toString() ?? '')
                  .toList() ??
              [],
          location: Map<String, double>.from(
            (item['location'] as Map<String, dynamic>?)?.map(
                  (key, value) => MapEntry(key, (value as num).toDouble()),
                ) ??
                {},
          ),
          offeredPrice: _parseOfferedPrice(item['offeredPrice']),
          userId: item['userId']?.toString() ?? '',
          workerId: '',
          status: statusObject,
          isFavorite: item['isFavorite'] as bool? ?? false,
          acceptedTerms: item['acceptedTerms'] as bool? ?? false,
          serviceType: ServiceType(
            name: item['serviceType']?['name']?.toString() ?? '',
            id: item['serviceType']?['id']?.toString() ?? '',
            selectedDate: item['date']?.toString() ?? '',
            selectedTime: item['time']?.toString() ?? '',
          ),
          devicesId: item['devicesId']?.toString() ?? '',
          hasOffer: false,
          offers: [],
          subcategoryName: item['subcategoryName']?.toString() ?? '',
          createdAt: DateTime.now(),
        );
      }).toList();

      List<ServiceRequest> validServices = [];

      // Para cada servicio, obtener las ofertas correspondientes y mapearlas a objetos Offer
      for (var service in serviceRequestsList) {
        // Buscar ofertas sin filtro de status para encontrar tanto
        // las que quedaron en 'accepted' como las que están en 'in_progress'
        final List<ServiceRequest> offersResponse = await apiService.getOffers(
          "userId",   // Columna por la que filtrar
          userId,     // Valor del usuario autenticado
          "in_progress", // Tipo de filtro del servicio
          deviceId,
          [service],
          "",         // Sin filtro de status en la oferta → trae 'accepted' e 'in_progress'
        );

        // Mapear cada objeto ServiceRequest a un objeto Offer
        final List<Offer> offers = offersResponse.map((serviceOffer) {
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
            serviceId: service.id,
            extraCosts: 0.0,
            totalPrice: serviceOffer.offeredPrice,
            status: statusObject,
            userToken: '',
            createdAt: DateTime.now(),
            expertises: serviceOffer.expertises,
            subcategoryName: '',
          );
        }).toList();

        if (offers.isNotEmpty) {
          service.workerId = offers.first.workerId;
          service.hasOffer = true;
          service.offers = offers;
          // Actualizar el precio mostrado con el de la oferta aceptada
          // (el offeredPrice del servicio puede ser el precio base original del cliente)
          if (service.offeredPrice <= 0) {
            service.offeredPrice = offers.first.offeredPrice;
          }
        }
        validServices.add(service);
      }

      validServices.forEach(LocalCacheService.cacheServiceRequest);
      // Devolver todos los servicios in_progress, con o sin workerId
      return validServices;
    } catch (e) {
      null;
      return [];
    }
  }

  List<Expertise> _extractExpertises(Map<String, dynamic> item) {
    final expertisesArray = item['expertises'] as List<dynamic>? ?? [];
    if (expertisesArray.isNotEmpty) {
      return expertisesArray.map((exp) {
        return Expertise(
          id: exp['id'] ?? '',
          name: exp['name'] ?? '',
        );
      }).toList();
    }
    return [];
  }

  double _parseOfferedPrice(dynamic value) {
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        null;
        return 0.0;
      }
    } else if (value is num) {
      return value.toDouble();
    }
    return 0.0;
  }
}
