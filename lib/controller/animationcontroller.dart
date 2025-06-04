import 'package:flutter/material.dart';
import 'package:manitoscliente_new/request/dataprofile.dart';

import 'package:rive/rive.dart';
import 'package:firebase_auth/firebase_auth.dart';


import '../home.dart';
class EstrellaController {
  static void handsOnTheEyes(SMIBool? isHandsUp) {
    isHandsUp?.change(true);
  }

  static void lookOnTheTextField(SMIBool? isHandsUp, SMIBool? isChecking, SMINumber? numLook) {
    isHandsUp?.change(false);
    isChecking?.change(false);
    numLook?.change(0); // Ajusta este valor según cómo quieras que Teddy mire al campo de texto.
  }

  static void moveEyeBalls(SMINumber? numLook, String val) {
    numLook?.change(val.length.toDouble());
  }
  static void lookAtTapPosition(SMIBool? isHandsUp, SMIBool? isChecking, SMINumber? numLook, TextEditingController? textEditingController) {
    isHandsUp?.change(false);
    isChecking?.change(true);

    // Obten la posición actual del cursor en el campo de texto
    final cursorPosition = textEditingController?.selection.base.offset ?? 0;

    // Calcula la posición relativa en la que Teddy debe mirar
    // Por ejemplo, puedes dividir el ancho del campo de texto en zonas iguales y mirar a la zona correspondiente al toque.
    const totalZones = 4; // Divide el campo de texto en 4 zonas iguales
    final zoneWidth = textEditingController!.text.length / totalZones;
    final targetZone = (cursorPosition / zoneWidth).ceil();

    // Ajusta numLook para que Teddy mire a la zona correcta
    numLook?.change(targetZone.toDouble());
  }
  

  static void _showFailedLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Inicio de sesión fallido"),
          content: const Text("Email o contraseña incorrectos. Inténtalo de nuevo."),
          actions: [
            TextButton(
              child: const Text("Aceptar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Ahora acepta userData y onTabTapped
  static void _navigateToHomePage(
      BuildContext context,
      UserData userData,
      VoidCallback onTabTapped,
      ) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          initialPageIndex: 0,userData: userData!

        ),
      ),
    );
  }
}