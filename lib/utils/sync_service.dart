import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio global para sincronización de datos
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  Timer? _syncTimer;
  final Map<String, Function> _syncCallbacks = {};
  bool _isInitialized = false;

  /// Inicializa el servicio de sincronización
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Configurar sincronización automática cada 5 minutos
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _performSync();
    });
    
    _isInitialized = true;
    null;
  }

  /// Registra un callback para sincronización
  void registerSyncCallback(String key, Function callback) {
    _syncCallbacks[key] = callback;
    null;
  }

  /// Remueve un callback de sincronización
  void unregisterSyncCallback(String key) {
    _syncCallbacks.remove(key);
    null;
  }

  /// Ejecuta la sincronización
  Future<void> _performSync() async {
    if (_syncCallbacks.isEmpty) return;
    
    null;
    
    try {
      // Ejecutar todos los callbacks en paralelo
      final futures = _syncCallbacks.values.map((callback) async {
        try {
          await callback();
        } catch (e) {
          null;
        }
      });
      
      await Future.wait(futures);
      null;
    } catch (e) {
      null;
    }
  }

  /// Fuerza una sincronización manual
  Future<void> forceSync() async {
    null;
    await _performSync();
  }

  /// Limpia el servicio
  void dispose() {
    _syncTimer?.cancel();
    _syncCallbacks.clear();
    _isInitialized = false;
    null;
  }

  /// Obtiene el estado de sincronización
  bool get isInitialized => _isInitialized;
  int get activeCallbacks => _syncCallbacks.length;
} 