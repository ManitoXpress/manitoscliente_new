import 'package:flutter/material.dart';

import 'package:rive/rive.dart';
import 'package:firebase_auth/firebase_auth.dart';


import '../home.dart';
import '../home.dart';
import '../request/dataprofile.dart';

class EstrellaController {
  static void handsOnTheEyes(SMIBool? isHandsUp) {
    isHandsUp?.change(true);
  }

  static void lookOnTheTextField(SMIBool? isHandsUp, SMIBool? isChecking, SMINumber? numLook) {
    isHandsUp?.change(false);
    isChecking?.change(false);
    numLook?.change(0);
  }

  static void moveEyeBalls(SMINumber? numLook, String val) {
    numLook?.change(val.length.toDouble());
  }

  static void lookAtTapPosition(
      SMIBool? isHandsUp,
      SMIBool? isChecking,
      SMINumber? numLook,
      TextEditingController? textEditingController,
      ) {
    isHandsUp?.change(false);
    isChecking?.change(true);

    final cursorPosition = textEditingController?.selection.base.offset ?? 0;
    const totalZones = 4;
    final zoneWidth = (textEditingController!.text.length / totalZones);
    final targetZone = (cursorPosition / zoneWidth).ceil();
    numLook?.change(targetZone.toDouble());
  }

  /// Ahora recibe userData y onTabTapped
  static Future<void> login(
      BuildContext context,
      TextEditingController emailController,
      TextEditingController passwordController,
      UserData userData,
      VoidCallback onTabTapped,
      ) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    SMITrigger? failTrigger;

    try {
      // Lógica de autenticación...
      UserCredential? userCredential;

      if (userCredential != null) {
        String? token = await _auth.currentUser?.getIdToken(true);
        null;
        _navigateToHomePage(context, userData, onTabTapped);
      } else {
        failTrigger?.fire();
        _showFailedLoginDialog(context);
      }
    } catch (e) {
      failTrigger?.fire();
      null;
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
              onPressed: () => Navigator.of(context).pop(),
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
