import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'dart:math' as math;

import '../request/requestStatus.dart';

class CustomTicketShapePainter extends CustomPainter { 
  final Status status; // Suponemos que status es un objeto de tipo `Status` que tiene un campo `id`

  CustomTicketShapePainter({required this.status});

  // Método para obtener el color según el id del estado
  Color _getStatusColor(String id) {
    null; // Muestra el id con comillas para depurar
    switch (id.trim().toLowerCase()) { // Usamos el id en lugar del status completo
      case 'available':
        return Colors.green;
      case 'offer':
        return Colors.yellow;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.black;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey; // Si no coincide con ningún id conocido
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double titleHeight = 28.0; // Altura de la línea del título

    final path = Path();

    // Añadir sombra para efecto 3D
    canvas.drawShadow(path, Colors.black.withOpacity(0.8), 2.0, true);

    // Dibuja el fondo del ticket con un degradado
    final Rect rect = Rect.fromLTWH(0, titleHeight, size.width, size.height - titleHeight);
    final Gradient gradient = LinearGradient(
      colors: [Colors.white, Colors.grey.shade300], // Degradado de blanco a gris claro
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    
    final Paint backgroundPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    final double borderRadius = 20; // Radio de las esquinas redondeadas

    // Agrega el fondo del ticket con esquinas redondeadas
    path.addRRect(
      RRect.fromRectAndCorners(
        rect,
        topLeft: Radius.circular(borderRadius),
        topRight: Radius.circular(borderRadius),
        bottomLeft: Radius.circular(borderRadius),
        bottomRight: Radius.circular(borderRadius),
      ),
    );

    // Dibuja el fondo con el degradado
    canvas.drawPath(path, backgroundPaint);

    // Dibuja los bordes azules del ticket
    final borderPaint = Paint()
      ..color = Color(0xFF32AFCC) // Color del borde azul
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0; // Grosor del borde

    canvas.drawPath(path, borderPaint);

    // Dibuja el área del estado con esquinas redondeadas
    final double statusBoxSize = 40.0; // Tamaño del cuadrado del estado
    final double statusBoxPadding = 45.0; // Espacio entre el cuadrado y el borde del ticket

    final Paint statusBoxPaint = Paint()
      ..color = _getStatusColor(status.id) // Color según el id del estado
      ..style = PaintingStyle.fill;

    final double statusBoxRadius = 10; // Radio de las esquinas redondeadas del cuadrado del estado

    // Mover 2 puntos a la izquierda modificando la posición de "left"
    final statusBoxRect = Rect.fromLTWH(
      size.width - statusBoxSize - statusBoxPadding + 27, // Mueve 2 puntos a la izquierda
      size.height - statusBoxPadding - titleHeight - 90, // Ajusta para estar justo debajo de la imagen
      statusBoxSize,
      statusBoxSize,
    );

    final RRect statusBoxRRect = RRect.fromRectAndCorners(
      statusBoxRect,
      topLeft: Radius.circular(statusBoxRadius),
      topRight: Radius.circular(statusBoxRadius),
      bottomLeft: Radius.circular(statusBoxRadius),
      bottomRight: Radius.circular(statusBoxRadius),
    );

    // Dibuja el cuadro de estado de color
    canvas.drawRRect(statusBoxRRect, statusBoxPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
