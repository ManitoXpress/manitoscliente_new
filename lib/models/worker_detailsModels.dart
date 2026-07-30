import 'expertiseModels.dart';

class WorkerDetailsModel {
  final String displayName;
  final String email;
  final int? expLevel;
  final List<ExpertiseModel> expertises;
  final String imagePath;
  final String idDocumentImagePath;
  final String phoneNumber;
  final String? verificationStatus;

  WorkerDetailsModel({
    required this.displayName,
    required this.email,
    this.expLevel,
    required this.expertises,
    required this.imagePath,
    required this.idDocumentImagePath,
    required this.phoneNumber,
    this.verificationStatus,
  });

  factory WorkerDetailsModel.fromMap(Map<String, dynamic> map) {
    final rawExpertises = map['expertises'] as List<dynamic>? ?? [];
    return WorkerDetailsModel(
        displayName: map['displayName'] as String? ?? 'Sin nombre',
        email: map['email'] as String? ?? 'Sin correo',
        expLevel: (map['expLevel'] is int) ? map['expLevel'] as int : null,
        expertises: rawExpertises
            .map((e) => ExpertiseModel.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        imagePath: map['imagePath'] as String? ?? '',
        idDocumentImagePath:
        map['idDocumentImagePath'] as String? ?? '',
        phoneNumber: map['phoneNumber'] as String? ?? '',
        verificationStatus: map['verificationStatus'] as String? ?? '',
        );
    }
}