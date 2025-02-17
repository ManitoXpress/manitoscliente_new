import 'package:manitoscliente_new/request/requestExpertise.dart';
import 'package:manitoscliente_new/request/requestLocation.dart';

class WorkerDetails {
  final String id;
  final String certificateImagePaths;
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
      certificateImagePaths: map['certificateImagePaths'] ?? [],
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

