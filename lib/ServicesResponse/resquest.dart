import 'package:cloud_firestore/cloud_firestore.dart';

class Offer {
  final String offerId;
  final bool hasOffer;
  final String serviceId; // Nuevo campo
  final String workerId;
  final double offeredPrice;
  final DateTime createdAt;
  final double extraCosts;
  final String status;
  final double totalPrice;

  Offer({
    required this.offerId,
    required this.serviceId, // Nuevo campo requerido
    required this.workerId,
    required this.offeredPrice,
    required this.createdAt,
    required this.hasOffer,
    this.extraCosts = 0.0,
    this.status = '',
    this.totalPrice = 0.0,
  });

  /// Convierte la oferta a un mapa (útil para guardar en Firestore)
  Map<String, dynamic> toMap() {
    return {
      'offerId': offerId,
      'serviceId': serviceId, // Incluir el campo en el mapeo
      'workerId': workerId,
      'offeredPrice': offeredPrice,
      'createdAt': createdAt.toIso8601String(),
      'extraCosts': extraCosts,
      'status': status,
      'totalPrice': totalPrice,
    };
  }

  /// Crea una instancia de Offer desde un mapa (útil para leer de Firestore)
  factory Offer.fromMap(Map<String, dynamic> map) {
    return Offer(
      offerId: map['offerId'] ?? '',
      hasOffer: map['hasOffer'] ?? '',
      serviceId: map['serviceId'] ?? '', // Mapeo del nuevo campo
      workerId: map['workerId'] ?? '',
      offeredPrice: map['offeredPrice'] ?? 0.0,
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      extraCosts: map['extraCosts'] ?? 0.0,
      status: map['status'] ?? '',
      totalPrice: map['totalPrice'] ?? 0.0,
    );
  }

  /// Personaliza la salida al imprimir una instancia de Offer
  @override
  String toString() {
    return 'Offer(offerId: $offerId, serviceId: $serviceId, workerId: $workerId, offeredPrice: $offeredPrice, createdAt: $createdAt, extraCosts: $extraCosts, status: $status, totalPrice: $totalPrice)';
  }
}

class ServiceRequest {
  String serviceDateTime;
  String devicesId;
  String id;
  String description;
  List<String> images;
  Map<String, double> location;
  double offeredPrice = 0.0;
  ServiceType serviceType;
  String userId;
  String workerId;
  bool isFavorite;
  String? selectedDate;
  String? selectedTime;
  bool acceptedTerms;
  List<Expertises> expertises;
  late Status status;
  final String subcategoryName;
  bool hasOffer;
  List<Offer>
      offers; // Cambié 'offer' a 'offers' para manejar múltiples ofertas
  WorkerDetails? workerDetails;
  bool isServiceNameEmpty() {
    return (description == null || description.isEmpty);
  }

  bool isServiceTypeEmpty() {
    return (serviceType == null);
  }

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
    required this.offers, // Inicialización de ofertas
  });

  ServiceRequest copyWith({
    String? dateTime,
    String? id,
    String? devicesId,
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
    List<Expertises>? expertises,
    String? subcategoryName,
    bool? hasOffer,
    List<Offer>? offers, // Cambié 'offer' a 'offers' también en copyWith
  }) {
    return ServiceRequest(
      serviceDateTime: dateTime ?? this.serviceDateTime,
      id: id ?? this.id,
      devicesId: devicesId ?? this.devicesId,
      description: description ?? this.description,
      images: images ?? this.images,
      location: location ?? this.location,
      offeredPrice: offeredPrice ?? this.offeredPrice,
      serviceType: serviceType ?? this.serviceType,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      workerId: workerId ?? this.workerId,
      isFavorite: isFavorite ?? this.isFavorite,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      expertises: expertises ?? this.expertises,
      subcategoryName: subcategoryName ?? this.subcategoryName,
      hasOffer: hasOffer ?? this.hasOffer,
      offers: offers ??
          this.offers, // Cambié 'offer' a 'offers' también en copyWith
    );
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
      'offers': offers.map((offer) => offer.toMap()).toList(), // Ahora 'offers'
    };
  }

  factory ServiceRequest.fromSnapshot(Map<String, dynamic> map) {
    return ServiceRequest(
      serviceDateTime: map['serviceDateTime'] ?? '',
      id: map['id'] ?? '',
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
    ? List<Expertises>.from(
        (map['expertises'] as List).map((e) => Expertises.fromMap(e)))
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
          : [], // Mapeo de 'offers' correctamente
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

class Expertises {
  String id;
  String name;

  Expertises({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory Expertises.fromMap(Map<String, dynamic> map) {
    return Expertises(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
    );
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

  // Mapa inverso para buscar el nombre por ID
  static final Map<String, String> _nameById = {
    "available": "Disponible",
    "offer": "Ofertado",
    "in_progress": "En curso",
    "completed": "Completado",
    "cancelled": "Cancelado",
    // Agrega más asignaciones de ID a nombre según sea necesario
  };

  // Método estático para obtener el nombre por ID
  static String getNameById(String id) {
    return _nameById[id] ?? 'Desconocido';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  // Método de fábrica para crear una instancia de Status desde un mapa
  factory Status.fromMap(Map<String, dynamic> map) {
    return Status(
      id: map['id'] ?? '',
      name: getNameById(map['id'] ?? ''),
    );
  }
}

class WorkerDetails {
  final String id;
  final List<String> certificateImagePaths;
  final String idDocumentImagePath;
  final String imagePath;
  final String phoneNumber;
  final String displayName;
  final String email;
  final List<String> expLevel;
  final List<Expertise> expertises;

  WorkerDetails({
    required this.id,
    required this.certificateImagePaths,
    required this.idDocumentImagePath,
    required this.imagePath,
    required this.phoneNumber,
    required this.displayName,
    required this.email,
    required this.expLevel,
    required this.expertises,
  });

  // Método de fábrica para convertir Map<String, dynamic> a WorkerDetails
  factory WorkerDetails.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return WorkerDetails(
        id: '',
        certificateImagePaths: [],
        idDocumentImagePath: '',
        imagePath: '',
        phoneNumber: '',
        displayName: '',
        email: '',
        expLevel: [],
        expertises: [],
      );
    }

    return WorkerDetails(
      id: map['id'] ?? '',
      // Asegúrate de tener 'id' en el mapa
      certificateImagePaths:
          List<String>.from(map['certificateImagePaths'] ?? []),
      idDocumentImagePath: map['idDocumentImagePath'] ?? '',
      imagePath: map['imagePath'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      expLevel: List<String>.from(map['expLevel'] ?? []),
      expertises: (map['expertises'] as List<dynamic>?)
              ?.map((item) => Expertise.fromMap(item))
              .toList() ??
          [],
    );
  }
}

class Expertise {
  final String id;
  final String name;

  Expertise({required this.id, required this.name});

  factory Expertise.fromMap(Map<String, dynamic> data) {
    return Expertise(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
    );
  }
}

class category {
  final String id;
  final String name;

  category({required this.id, required this.name});
  factory category.fromMap(Map<String, dynamic> data) {
    return category(id: data['id'], name: data['name']);
  }
}
