import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceRequest {
  String serviceDateTime;
  String id;
  String description;
  List<String> images;
  Map<String, double> location;
  double offeredPrice;
  ServiceType serviceType;
  String userId;
  bool isFavorite;
  String? selectedDate;
  String? selectedTime;
  bool acceptedTerms;
  String expertises;
  late Status status;

  bool isServiceNameEmpty() {
    return description.isEmpty;
  }

  bool isServiceTypeEmpty() {
    return serviceType == null;
  }

  ServiceRequest({
    required this.serviceDateTime,
    required this.id,
    required this.description,
    required this.images,
    required this.location,
    required this.offeredPrice,
    required this.serviceType,
    required this.userId,
    required this.isFavorite,
    this.selectedDate,
    this.selectedTime,
    required this.acceptedTerms,
    required this.expertises,
    required this.status,
  });

  ServiceRequest copyWith({
    String? dateTime,
    String? id,
    String? description,
    List<String>? images,
    Map<String, double>? location,
    double? offeredPrice,
    ServiceType? serviceType,
    Status? status,
    String? userId,
    bool? isFavorite,
    String? selectedDate,
    String? selectedTime,
    bool? acceptedTerms,
    String? expertises,
  }) {
    return ServiceRequest(
      serviceDateTime: dateTime ?? this.serviceDateTime,
      id: id ?? this.id,
      description: description ?? this.description,
      images: images ?? this.images,
      location: location ?? this.location,
      offeredPrice: offeredPrice ?? this.offeredPrice,
      serviceType: serviceType ?? this.serviceType,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      isFavorite: isFavorite ?? this.isFavorite,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      expertises: expertises ?? this.expertises,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceDateTime': serviceDateTime,
      'id': id,
      'description': description,
      'status': status.toMap(),
      'images': images,
      'location': location,
      'offeredPrice': offeredPrice,
      'serviceType': serviceType.toMap(),
      'userId': userId,
      'isFavorite': isFavorite,
      'selectedDate': selectedDate,
      'selectedTime': selectedTime,
      'acceptedTerms': acceptedTerms,
      'expertises': expertises,
    };
  }

  factory ServiceRequest.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return ServiceRequest(
      serviceDateTime: data['serviceDateTime'] ?? '',
      id: data['id'] ?? '',
      description: data['description'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      location: Map<String, double>.from(data['location'] ?? {}),
      offeredPrice: _parseOfferedPrice(data['offeredPrice']),
      serviceType: ServiceType.fromMap(data['serviceType'] ?? {}),
      userId: data['userId'] ?? '',
      isFavorite: data['isFavorite'] ?? false,
      selectedDate: data['selectedDate'],
      selectedTime: data['selectedTime'],
      acceptedTerms: data['acceptedTerms'] ?? false,
      expertises: data['expertises'] ?? '',
      status: Status.fromMap(data['status'] ?? {}),
    );
  }

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

class ServiceType {
  String id;
  String name;
  String selectedDate;
  String selectedTime;

  ServiceType({
    required this.id,
    required this.name,
    required this.selectedDate,
    required this.selectedTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'selectedDate': selectedDate,
      'selectedTime': selectedTime,
    };
  }

  factory ServiceType.fromMap(Map<String, dynamic> map) {
    return ServiceType(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      selectedDate: map['selectedDate'] ?? '',
      selectedTime: map['selectedTime'] ?? '',
    );
  }
}

class Status {
  final String id;
  final String name;

  Status({required this.id, required this.name});

  static final Map<String, String> _nameById = {
    "available": "Disponible",
    "assigned":"Asignado",
    "in_progress":"En curso",
    "completed": "Completado",
    "cancelled": "Cancelado",
  };

  static String getNameById(String id) {
    return _nameById[id] ?? 'Desconocido';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory Status.fromMap(Map<String, dynamic> map) {
    return Status(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
    );
  }
}
