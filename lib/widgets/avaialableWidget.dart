import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AvailableActionsWidget extends StatelessWidget {
  final VoidCallback onCancel;

  const AvailableActionsWidget({
    Key? key,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: onCancel,
          icon: Icon(Icons.dangerous, color: Colors.white),
          label: Text(
            "Cancelar Trabajo",
            style: GoogleFonts.karla(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF830A09),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          ),
        ),
      ],
    );
  }
}
