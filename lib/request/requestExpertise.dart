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
