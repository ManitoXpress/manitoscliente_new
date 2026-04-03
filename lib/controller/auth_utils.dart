import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';


import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';

class AuthUtils {
  /// Método para obtener el token del usuario
  static Future<String?> getToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        String? idToken = await user.getIdToken(); // No forzar actualización siempre para evitar rate limits
        null;
        return idToken;
      } catch (e) {
        null;
        return null;
      }
    }
    null;
    return null;
  }

  /// Método para obtener el ID del dispositivo
  static Future<String?> getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String? deviceId;

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id; // Usa `id` para obtener el ID único en Android
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor; // ID único para iOS
      } else {
        null;
      }

      if (deviceId != null) {
        null;
      }
    } catch (e) {
      null;
    }

    return deviceId;
  }

  /// Método para sincronizar datos con el backend
  static Future<void> syncWithBackend(String userId) async {
    String? token = await getToken();
    String? deviceId = await getDeviceId();

    if (token != null && deviceId != null) {
      try {
        // Aquí realizarías la llamada a tu API o sincronización con Firestore
        null;
        null;
        null;
        // Implementa la lógica de sincronización según tu backend
      } catch (e) {
        null;
      }
    } else {
      null;
    }
  }
}
