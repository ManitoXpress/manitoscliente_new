import 'package:cloud_firestore/cloud_firestore.dart';
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
  double offeredPrice = 0.0;
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

  // Sobrescribir el método toString para mejorar la salida en consola
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
      id: map['serviceId'] ?? '', // Se asegura de usar el ID del servicio correcto
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



  // Método para verificar si el nombre del servicio está vacío
  bool isServiceNameEmpty() {
    return description.isEmpty;
  }

  bool isServiceTypeEmpty() {
    return description.isEmpty;
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
  final String criminalRecordImagePath;
  final String fcmToken;
  final Location location; // Cambiado a un objeto Location
  final String verificationStatus;
  final String idCardNumber;

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
    required this.criminalRecordImagePath,
    required this.fcmToken,
    required this.location,
    required this.verificationStatus,
    required this.idCardNumber,
  });

  // Constructor fromMap
  factory WorkerDetails.fromMap(Map<String, dynamic> map) {
    return WorkerDetails(
      id: map['id'] ?? '',
      certificateImagePaths: List<String>.from(map['certificateImagePaths'] ?? []),
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
      criminalRecordImagePath: map['criminalRecordImagePath'] ?? '',
      fcmToken: map['fcmToken'] ?? '',
      location: map['location'] != null
          ? Location.fromMap(map['location']) // Mapeo del objeto Location
          : Location(lat: 0.0, lng: 0.0), // Valor por defecto
      verificationStatus: map['verificationStatus'] ?? '',
      idCardNumber: map['idCardNumber'] ?? '',
    );
  }

  // Método toMap
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'certificateImagePaths': certificateImagePaths,
      'idDocumentImagePath': idDocumentImagePath,
      'imagePath': imagePath,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'email': email,
      'expLevel': expLevel,
      'expertises': expertises.map((e) => e.toMap()).toList(),
      'criminalRecordImagePath': criminalRecordImagePath,
      'fcmToken': fcmToken,
      'location': location.toMap(), // Convertir objeto Location a mapa
      'verificationStatus': verificationStatus,
      'idCardNumber': idCardNumber,
    };
  }
}

// Clase Location
class Location {
  final double lat;
  final double lng;

  Location({
    required this.lat,
    required this.lng,
  });

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      lat: (map['lat'] ?? 0.0).toDouble(),
      lng: (map['lng'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
    };
  }
}

// Clase Expertise
class Expertise {
  final String name;
  final String id;

  Expertise({
    required this.name,
    required this.id,
  });

  factory Expertise.fromMap(Map<String, dynamic> map) {
    return Expertise(
      name: map['name'] ?? '',
      id: map['id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'id': id,
    };
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
