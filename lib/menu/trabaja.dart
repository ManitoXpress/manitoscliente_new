import 'package:flutter/material.dart';

class TrabajeConNosotrosScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trabaje con Nosotros',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Xpress',
          ),
        ),
      ),
      body: Center(
        child: Text(
          "Muy Pronto Trabajarás con Nosotros!",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFFFFF),
            fontFamily: 'Xpress',
            fontSize: 24, // Tamaño de fuente ajustado
          ),
        ),
      ),
      backgroundColor: const Color(0xFF6AB8D6), // Cambia el color de fondo
    );
  }
}
