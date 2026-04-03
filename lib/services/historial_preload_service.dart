import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../provider/providerService.dart';
import '../constant/cacheConstants.dart';

/// 🚀 Servicio de precarga del historial para optimizar la experiencia del usuario
class HistorialPreloadService {
  static final HistorialPreloadService _instance = HistorialPreloadService._internal();
  factory HistorialPreloadService() => _instance;
  HistorialPreloadService._internal();

  bool _isPreloading = false;
  bool _isPreloaded = false;
  String? _preloadedUserId;

  /// Verifica si ya se precargó para este usuario
  bool isPreloadedForUser(String userId) {
    return _isPreloaded && _preloadedUserId == userId;
  }

  /// Inicia la precarga del historial en background
  Future<void> preloadHistorial(BuildContext context, String userId) async {
    if (_isPreloading || isPreloadedForUser(userId)) {
      null;
      return;
    }

    _isPreloading = true;
    _preloadedUserId = userId;

    try {
      null;
      final startTime = DateTime.now();

      // Obtener credenciales de forma asíncrona
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        null;
        return;
      }

      final futures = await Future.wait([
        user.getIdToken(),
        _fetchDeviceId(),
      ]).timeout(const Duration(seconds: 5));

      final token = futures[0] as String?;
      final deviceId = futures[1] as String;

      if (token == null) {
        null;
        return;
      }

      // Obtener el provider del contexto
      final historialProv = Provider.of<HistorialProvider>(context, listen: false);
      
      // Precargar datos de forma asíncrona
      await historialProv.loadAll(
        userId: userId,
        token: token,
        deviceId: deviceId,
      );

      // Configurar actualización automática
      historialProv.startAutoRefresh(
        userId: userId,
        token: token,
        deviceId: deviceId,
      );

      _isPreloaded = true;
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      null;

    } catch (e) {
      null;
      _isPreloaded = false;
      _preloadedUserId = null;
    } finally {
      _isPreloading = false;
    }
  }

  /// Obtiene el device ID de forma optimizada
  Future<String> _fetchDeviceId() async {
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await info.androidInfo;
        return androidInfo.id ?? 'unknown';
      } else if (Platform.isIOS) {
        final iosInfo = await info.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown';
      }
      return 'unsupported';
    } catch (e) {
      null;
      return 'error';
    }
  }

  /// Resetea el estado de precarga
  void reset() {
    _isPreloading = false;
    _isPreloaded = false;
    _preloadedUserId = null;
  }

  /// Verifica si está precargando actualmente
  bool get isPreloading => _isPreloading;

  /// Verifica si ya se precargó
  bool get isPreloaded => _isPreloaded;
}
