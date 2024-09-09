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
  String workerId;
  bool isFavorite;
  String? selectedDate;
  String? selectedTime;
  bool acceptedTerms;
  List<Expertises> expertises; // Cambiado a una lista de Expertises
  late Status status;
  final String subcategoryName;

  bool isServiceNameEmpty() {
    return (description == null || description.isEmpty);
  }

  bool isServiceTypeEmpty() {
    return (serviceType == null);
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
    required this.workerId,
    required this.isFavorite,
    this.selectedDate,
    this.selectedTime,
    required this.acceptedTerms,
    required this.expertises, // Cambiado para recibir una lista de Expertises
    required this.status,
    required this.subcategoryName,
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
    List<Expertises>? expertises,
    String? subcategoryName, // Cambiado a una lista de Expertises
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
      workerId: workerId ?? this.workerId,
      isFavorite: isFavorite ?? this.isFavorite,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      expertises: expertises ?? this.expertises,
      subcategoryName: subcategoryName ??
          this.subcategoryName, // Cambiado a una lista de Expertises
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceDateTime': serviceDateTime,
      'id': id,
      'description': description,
      'status': status.toMap(), // Utiliza toMap en lugar de toJson
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
      'subcategoryName':
          subcategoryName, // Convierte la lista de Expertises a Map
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
      workerId: data['workerId'] ?? '',
      isFavorite: data['isFavorite'] ?? false,
      selectedDate: data['selectedDate'],
      selectedTime: data['selectedTime'],
      acceptedTerms: data['acceptedTerms'] ?? false,
      expertises: data['expertises'] != null
          ? List<Expertises>.from(
              (data['expertises'] as List).map((e) => Expertises.fromMap(e)))
          : [], // Garantiza que expertises sea siempre una lista válida
      status: Status(
        id: data['status'] ?? '',
        name: Status.getNameById(data['status'] ?? ''),
      ),
      subcategoryName: data['subcategoryName'] ?? '',
    );
  }

  // Función para convertir el precio ofrecido a un número decimal
  static double _parseOfferedPrice(dynamic value) {
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Error al convertir el precio ofrecido a double: $e');
        return 0.0; // Devuelve un valor predeterminado en caso de error
      }
    } else if (value is num) {
      return value.toDouble();
    }
    return 0.0; // Devuelve un valor predeterminado si el valor no es String ni num
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
}
class WorkerDetails {
  final List<String> certificateImagePaths;
  final String criminalRecordImagePath;
  final String displayName;
  final String email;
  final List<String> expLevel;
  final List<Expertise> expertises;

  WorkerDetails({
    required this.certificateImagePaths,
    required this.criminalRecordImagePath,
    required this.displayName,
    required this.email,
    required this.expLevel,
    required this.expertises,
  });

  factory WorkerDetails.fromMap(Map<String, dynamic> data) {
    return WorkerDetails(
      certificateImagePaths: List<String>.from(data['certificateImagePaths'] ?? []),
      criminalRecordImagePath: data['criminalRecordImagePath'] ?? '',
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      expLevel: List<String>.from(data['expLevel'] ?? []),
      expertises: (data['expertises'] as List<dynamic>?)
              ?.map((item) => Expertise.fromMap(item))
              .toList() ?? [],
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



