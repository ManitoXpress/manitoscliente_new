import 'package:flutter/material.dart';

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
  static Future<void> login(BuildContext context, TextEditingController emailController, TextEditingController passwordController) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    SMITrigger? failTrigger;

    try {
      // Coloca aquí tu lógica para el inicio de sesión con correo y contraseña
      // ...

      UserCredential? userCredential;

      if (userCredential != null) {
        // Obtiene el token de ID y lo imprime
        String? token = await _auth.currentUser?.getIdToken(true);
        print("Token de ID: $token");

        // TODO: Enviar el token a tu servidor
        // Puedes usar el paquete `http` en Flutter para hacer una solicitud HTTP a tu servidor.
        // Por ejemplo:
        //
        // final response = await http.post(
        //   Uri.parse('https://tu-servidor.com/verificar-token'),
        //   headers: {
        //     'Content-Type': 'application/json',
        //   },
        //   body: jsonEncode({'token': token}),
        // );
        //
        // Si el servidor responde con un error, puedes manejarlo aquí.

        _navigateToHomePage(context);
      } else {
        failTrigger?.fire();
        _showFailedLoginDialog(context);
      }
    } catch (e) {
      failTrigger?.fire();
      print("Error al iniciar sesión: $e");
      _showFailedLoginDialog(context);
    }
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

  static void _navigateToHomePage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()), // Asegúrate de tener una clase HomePage definida
    );
  }
}