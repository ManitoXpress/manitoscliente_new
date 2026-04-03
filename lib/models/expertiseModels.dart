// lib/models/expertise_model.dart

class ExpertiseModel {
  final String id;
  final String name;

  ExpertiseModel({
    required this.id,
    required this.name,
  });

  factory ExpertiseModel.fromMap(Map<String, dynamic> map) {
    return ExpertiseModel(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        );
    }
}