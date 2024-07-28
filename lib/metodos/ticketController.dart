import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:math' as math;
class CustomTicketShapePainter extends CustomPainter {
  final String status;

  CustomTicketShapePainter({required this.status});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();

    // Dibuja la línea horizontal para el título
    final double titleHeight = 30.0; // Altura de la línea del título
    final Paint titlePaint = Paint()
      ..color = Color(0xFF32AFCC) // Color del título
      ..style = PaintingStyle.fill;

    // Dibuja la línea horizontal para el título
    final titleRect = Rect.fromLTWH(0, 0, size.width, titleHeight);
    canvas.drawRect(titleRect, titlePaint);

    // Dibuja el fondo del ticket con bordes azules y fondo blanco
    final backgroundPaint = Paint()
      ..color = Colors.white // Fondo blanco
      ..style = PaintingStyle.fill;

    final double borderRadius = 0; // Radio de las esquinas redondeadas

    // Agrega el fondo del ticket con bordes azules y esquinas redondeadas
    path.addRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, titleHeight, size.width, size.height - titleHeight), // Ajusta la altura para excluir la línea del título
        topLeft: Radius.circular(borderRadius),
        topRight: Radius.circular(borderRadius),
        bottomLeft: Radius.circular(borderRadius),
        bottomRight: Radius.circular(borderRadius),
      ),
    );

    // Dibuja el fondo blanco del ticket
    canvas.drawPath(path, backgroundPaint);

    // Dibuja los bordes azules del ticket
    final borderPaint = Paint()
      ..color = Color(0xFF32AFCC) // Color del borde azul
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0; // Grosor del borde

    canvas.drawPath(path, borderPaint);

    // Dibuja el texto de Status
    final TextPainter statusPainter = TextPainter(
      text: TextSpan(
        text: 'Status: $status',
        style: TextStyle(
          color: Colors.black,
          fontFamily: 'Xpress Heavy',
          fontWeight: FontWeight.normal,
          fontStyle: FontStyle.italic,
          fontSize: 16.0, // Tamaño de fuente personalizable
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    statusPainter.layout(minWidth: 0, maxWidth: size.width);

    final statusOffset = Offset(10, 5); // Ajusta la posición del texto
    statusPainter.paint(canvas, statusOffset);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
