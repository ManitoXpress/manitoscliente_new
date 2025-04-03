import 'package:cloud_firestore/cloud_firestore.dart';
import '../request/requestExpertise.dart';
import '../request/requestServiceType.dart';
import '../request/requestStatus.dart';
import '../request/requestWoker.dart';

class Offer {
  final String id;
  final String serviceId;
  final String workerId;
  final double offeredPrice;
  final double extraCosts;
  final double totalPrice;
  late Status status;
  final bool hasOffer;
  final String userToken;
  final DateTime createdAt;
  List<Expertise> expertises;
  final String subcategoryName;
  WorkerDetails? workerDetails;
  
  

  Offer({
    required this.id,
    required this.serviceId,
    required this.workerId,
    required this.offeredPrice,
    required this.extraCosts,
    required this.totalPrice,
    required this.status,
    required this.hasOffer,
    required this.userToken,
    required this.createdAt,
    required this.expertises,
    required this.subcategoryName,
    this.workerDetails,
  });

  // Método toMap para convertir la oferta a un mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serviceId': serviceId,
      'workerId': workerId,
      'offeredPrice': offeredPrice,
      'extraCosts': extraCosts,
      'totalPrice': totalPrice,
      'status': status.toMap(),
      'hasOffer': hasOffer,
      'userToken': userToken,
      'createdAt': createdAt.toIso8601String(),  // Usar toIso8601String para formato de fecha
      'expertises': expertises.map((e) => e.toMap()).toList(),
      'subcategoryName': subcategoryName,
      'workerDetails': workerDetails?.toMap(),
    };
  }

  // Método de fábrica para crear una oferta a partir de un mapa
  factory Offer.fromMap(Map<String, dynamic> map) {
    return Offer(
      id: map['id'] ?? '',
      serviceId: map['serviceId'] ?? '',
      workerId: map['workerId'] ?? '',
      offeredPrice: map['offeredPrice']?.toDouble() ?? 0.0,
      extraCosts: map['extraCosts']?.toDouble() ?? 0.0,
      totalPrice: map['totalPrice']?.toDouble() ?? 0.0,
      status: Status(
        id: map['status'] ?? '',
        name: Status.getNameById(map['status'] ?? ''),
      ),
      hasOffer: map['hasOffer'] ?? false,
      userToken: map['userToken'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toString()),
      expertises: map['expertises'] != null
          ? List<Expertise>.from(
              (map['expertises'] as List).map((e) => Expertise.fromMap(e)))
          : [],
      subcategoryName: map['subcategoryName'] ?? '',
      workerDetails: map['workerDetails'] != null
          ? WorkerDetails.fromMap(map['workerDetails'])
          : null,
      
      
      
    );
  }
}
class ServiceRequest {
  String serviceDateTime;
  String devicesId;
  String id;
  String description;
  List<String> images;
  Map<String, double> location;
  double offeredPrice;
  ServiceType serviceType;
  String userId;
  String workerId;
  bool isFavorite;
  String? selectedDate;
  String? selectedTime;
  bool acceptedTerms;
  List<Expertise> expertises;
  late Status status;
  final String subcategoryName;
  bool hasOffer;
  List<Offer> offers;
  WorkerDetails? workerDetails;

  // Constructor principal
  ServiceRequest({
    required this.serviceDateTime,
    required this.id,
    required this.devicesId,
    required this.description,
    required this.images,
    required this.location,
    required this.offeredPrice,
    required this.serviceType,
    required this.userId,
    required this.workerId,
    required this.isFavorite,
    this.selectedDate,
    this.selectedTime,
    required this.acceptedTerms,
    required this.expertises,
    required this.status,
    required this.subcategoryName,
    required this.hasOffer,
    required this.offers,
    this.workerDetails,
  });

  // Factory constructor para instancia vacía
  factory ServiceRequest.empty() {
    return ServiceRequest(
      serviceDateTime: '',
      id: '',
      devicesId: '',
      description: '',
      images: [],
      location: {},
      offeredPrice: 0.0,
      serviceType: ServiceType(
        id: '',
        name: '',
        selectedDate: '',
        selectedTime: '',
      ),
      userId: '',
      workerId: '',
      isFavorite: false,
      acceptedTerms: false,
      expertises: [],
      status: Status(id: '', name: ''),
      subcategoryName: '',
      hasOffer: false,
      offers: [],
      workerDetails: null,
    );
  }

  // Resto de métodos (se mantienen igual)
  @override
  String toString() {
    return 'ServiceRequest{id: $id, description: $description, serviceDateTime: $serviceDateTime, offeredPrice: $offeredPrice}';
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceDateTime': serviceDateTime,
      'id': id,
      'devicesId': devicesId,
      'description': description,
      'status': status.toMap(),
      'images': images,
      'location': location,
      'offeredPrice': offeredPrice,
      'serviceType': serviceType.toMap(),
      'userId': userId,
      'workerId': workerId,
      'isFavorite': isFavorite,
      'selectedDate': selectedDate,
      'selectedTime': selectedTime,
      'acceptedTerms': acceptedTerms,
      'expertises': expertises.map((e) => e.toMap()).toList(),
      'subcategoryName': subcategoryName,
      'hasOffer': hasOffer,
      'offers': offers.map((offer) => offer.toMap()).toList(),
      'workerDetails': workerDetails?.toMap(),
    };
  }

  factory ServiceRequest.fromSnapshot(Map<String, dynamic> map) {
    return ServiceRequest(
      serviceDateTime: map['serviceDateTime'] ?? '',
      id: map['serviceId'] ?? '',
      devicesId: map['devicesId'] ?? '',
      description: map['description'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      location: Map<String, double>.from(map['location'] ?? {}),
      offeredPrice: _parseOfferedPrice(map['offeredPrice']),
      serviceType: ServiceType.fromMap(map['serviceType'] ?? {}),
      userId: map['userId'] ?? '',
      workerId: map['workerId'] ?? '',
      isFavorite: map['isFavorite'] ?? false,
      selectedDate: map['selectedDate'],
      selectedTime: map['selectedTime'],
      acceptedTerms: map['acceptedTerms'] ?? false,
      expertises: map['expertises'] != null
          ? List<Expertise>.from(
              (map['expertises'] as List).map((e) => Expertise.fromMap(e)))
          : [],
      status: Status(
        id: map['status'] ?? '',
        name: Status.getNameById(map['status'] ?? ''),
      ),
      subcategoryName: map['subcategoryName'] ?? '',
      hasOffer: map['hasOffer'] ?? false,
      offers: map['offers'] != null
          ? List<Offer>.from(
              (map['offers'] as List).map((e) => Offer.fromMap(e)))
          : [],
      workerDetails: map['workerDetails'] != null
          ? WorkerDetails.fromMap(map['workerDetails'])
          : null,
    );
  }

  bool isServiceNameEmpty() => description.isEmpty;
  bool isServiceTypeEmpty() => description.isEmpty;

  static double _parseOfferedPrice(dynamic value) {
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

