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
        String? idToken = await user.getIdToken(true); // Forzar actualización del token
        print('Token obtenido: $idToken');
        return idToken;
      } catch (e) {
        print('Error al obtener el token: $e');
        return null;
      }
    }
    print('No hay un usuario autenticado.');
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
        print('Plataforma no soportada para obtener el Device ID.');
      }

      if (deviceId != null) {
        print('Device ID obtenido: $deviceId');
      }
    } catch (e) {
      print('Error al obtener el ID del dispositivo: $e');
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
        print('Sincronizando datos con el backend...');
        print('Token: $token');
        print('Device ID: $deviceId');
        // Implementa la lógica de sincronización según tu backend
      } catch (e) {
        print('Error al sincronizar con el backend: $e');
      }
    } else {
      print('No se pudo sincronizar. Token o Device ID nulos.');
    }
  }
}
