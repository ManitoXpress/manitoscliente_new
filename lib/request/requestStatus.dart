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

