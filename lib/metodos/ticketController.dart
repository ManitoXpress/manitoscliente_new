import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:math' as math;
class CustomTicketShapePainter extends CustomPainter {
  final String status;

  CustomTicketShapePainter({required this.status});

  @override
  void paint(Canvas canvas, Size size) {
    final double titleHeight = 30.0; // Altura de la línea del título

    final path = Path();

    // Dibuja el fondo del ticket con bordes azules y fondo blanco
    final backgroundPaint = Paint()
      ..color = Colors.white // Fondo blanco
      ..style = PaintingStyle.fill;

    final double borderRadius = 20; // Radio de las esquinas redondeadas

    // Agrega el fondo del ticket con esquinas redondeadas
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

    // Dibuja el área del estado con esquinas redondeadas
    final double statusBoxSize = 50.0; // Tamaño del cuadrado del estado
    final double statusBoxPadding = 20.0; // Espacio entre el cuadrado y el borde del ticket

    final Paint statusBoxPaint = Paint()
      ..color = Colors.yellow // Color de fondo del cuadrado del estado
      ..style = PaintingStyle.fill;

    final double statusBoxRadius = 10; // Radio de las esquinas redondeadas del cuadrado del estado

    // Mover 2 puntos a la izquierda modificando la posición de "left"
    final statusBoxRect = Rect.fromLTWH(
      size.width - statusBoxSize - statusBoxPadding - 12, // Movido 2 puntos a la izquierda
      size.height - statusBoxSize - statusBoxPadding - titleHeight - -10, // Ajusta la posición para estar más abajo dentro del ticket
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

    canvas.drawRRect(statusBoxRRect, statusBoxPaint);

    // Dibuja el texto de Status en el cuadrado
    final TextPainter statusPainter = TextPainter(
      text: TextSpan(
        text: status,
        style: TextStyle(
          color: Colors.black,
          fontFamily: 'Xpress Heavy',
          fontWeight: FontWeight.normal,
          fontStyle: FontStyle.italic,
          fontSize: 10.0, // Tamaño de fuente personalizable
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    statusPainter.layout(minWidth: 0, maxWidth: statusBoxSize);

    final statusOffset = Offset(
      statusBoxRect.left + (statusBoxSize - statusPainter.width) / 2,
      statusBoxRect.top + (statusBoxSize - statusPainter.height) / 2,
    );

    statusPainter.paint(canvas, statusOffset);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
