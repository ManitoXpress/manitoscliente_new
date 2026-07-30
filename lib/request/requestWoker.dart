
import 'package:manitoscliente_new/request/requestExpertise.dart';
import 'package:manitoscliente_new/request/requestLocation.dart';
class WorkerDetails {
  final String id;
  final List<String> certificateImagePaths;   // ← Ahora es lista
  final String idDocumentImagePath;
  final String imagePath;
  final String phoneNumber;
  final String displayName;
  final String email;
  final List<String> expLevel;
  final List<Expertise> expertises;
  final String criminalRecordImagePath;
  final String fcmToken;
  final Location location;
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

  factory WorkerDetails.fromMap(Map<String, dynamic> map) {
    return WorkerDetails(
      id: map['id'] ?? '',
      // Si viene como lista o como string CSV, atacamos ambos casos:
      certificateImagePaths: map['certificateImagePaths'] is List
          ? List<String>.from(map['certificateImagePaths'])
          : (map['certificateImagePaths'] is String
      // opcionalmente parsea CSV antiguo
          ? (map['certificateImagePaths'] as String)
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList()
          : <String>[]),
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
          ? Location.fromMap(Map<String, dynamic>.from(map['location']))
          : Location(lat: 0.0, lng: 0.0),
      verificationStatus: map['verificationStatus'] ?? '',
      idCardNumber: map['idCardNumber'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'certificateImagePaths': certificateImagePaths,  // ← Lista directamente
      'idDocumentImagePath': idDocumentImagePath,
      'imagePath': imagePath,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'email': email,
      'expLevel': expLevel,
      'expertises': expertises.map((e) => e.toMap()).toList(),
      'criminalRecordImagePath': criminalRecordImagePath,
      'fcmToken': fcmToken,
      'location': location.toMap(),
      'verificationStatus': verificationStatus,
      'idCardNumber': idCardNumber,
    };
  }
}
