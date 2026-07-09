class CommentModel {
  final String userId;
  final String nombre;
  final String mensaje;
  final String hora;
  final String fecha;      // "2025-05-12"
  final String timestamp;  // ISO 8601, para ordenar
  final String rol;

  CommentModel({
    required this.userId,
    required this.nombre,
    required this.mensaje,
    required this.hora,
    required this.fecha,
    required this.timestamp,
    required this.rol,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      userId:    map['userId']    as String? ?? '',
      nombre:    map['nombre']    as String? ?? 'Anónimo',
      mensaje:   map['mensaje']   as String? ?? '',
      hora:      map['hora']      as String? ?? '',
      fecha:     map['fecha']     as String? ?? '',
      timestamp: map['timestamp'] as String? ?? '',
      rol:       map['rol']       as String? ?? 'desconocido',
    );
  }

  Map<String, dynamic> toMap() => {
    'userId':    userId,
    'nombre':    nombre,
    'mensaje':   mensaje,
    'hora':      hora,
    'fecha':     fecha,
    'timestamp': timestamp,
    'rol':       rol,
  };
}