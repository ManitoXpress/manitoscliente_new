import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';

class AuthUtils {
  // Caché en memoria del token para evitar llamadas repetidas a Firebase Auth
  static String? _cachedToken;
  static DateTime? _tokenExpiry;

  /// Obtiene el token del usuario con caché en memoria (55 minutos de validez).
  /// Los tokens de Firebase duran 1 hora, así que 55 min es seguro.
  static Future<String?> getToken() async {
    // Si tenemos un token cacheado y sigue vigente, retornarlo directamente
    if (_cachedToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedToken;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Forzar renovación solo cuando el caché expiró
        final bool forceRefresh = _cachedToken == null;
        _cachedToken = await user.getIdToken(forceRefresh);
        _tokenExpiry = DateTime.now().add(const Duration(minutes: 55));
        return _cachedToken;
      } catch (e) {
        _cachedToken = null;
        _tokenExpiry = null;
        return null;
      }
    }
    return null;
  }

  /// Invalida el caché del token (llamar al cerrar sesión o al detectar 401)
  static void invalidateToken() {
    _cachedToken = null;
    _tokenExpiry = null;
  }

  /// Método para obtener el ID del dispositivo
  static Future<String?> getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String? deviceId;

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor;
      }
    } catch (e) {
      // ignore
    }

    return deviceId;
  }

  /// Método para sincronizar datos con el backend
  static Future<void> syncWithBackend(String userId) async {
    String? token = await getToken();
    String? deviceId = await getDeviceId();

    if (token != null && deviceId != null) {
      try {
        // Implementa la lógica de sincronización según tu backend
      } catch (e) {
        // ignore
      }
    }
  }
}
