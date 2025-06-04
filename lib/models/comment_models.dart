// lib/models/comment_model.dart

class CommentModel {
  final String nombre;
  final String mensaje;
  final String hora;
  final String rol;

  CommentModel({
    required this.nombre,
    required this.mensaje,
    required this.hora,
    required this.rol,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      nombre: map['nombre'] as String? ?? 'Anónimo',
      mensaje: map['mensaje'] as String? ?? '',
      hora: map['hora'] as String? ?? '',
      rol: map['rol'] as String? ?? 'desconocido',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'mensaje': mensaje,
      'hora': hora,
      'rol': rol,
    };
  }
}
