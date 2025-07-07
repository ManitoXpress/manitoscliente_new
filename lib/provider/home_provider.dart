import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../request/ResponseGet.dart';
import '../controller/auth_utils.dart';


class HomeServicesProvider extends ChangeNotifier {
  final ApiService2 _api = ApiService2();
  Timer? _refreshTimer;
  Timer? _cacheTimer;

  List<ServiceResponse> _allServices = [];
  List<ServiceResponse> _displayedServices = [];
  Map<String, List<ServiceResponse>> _cacheByParentId = {};

  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  int _selectedIndex = -1;
  bool _isSearching = false;
  String? _currentParentId;

  // --- NUEVO: Lista de servicios bloqueados ---
  static const List<String> _blockedServices = [
    // Hogar
    'canaletas',
    'carpintería',
    'mudanza',
    'vidriero',
    // Profesionales
    'arquitectura y diseño',
    'cocina y catering',
  ];

  // --- Getters ---
  List<ServiceResponse> get displayedServices => _displayedServices;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  bool get hasSelection => _selectedIndex != -1;
  ServiceResponse? get selectedService =>
      hasSelection ? _displayedServices[_selectedIndex] : null;
  bool get isSearching => _isSearching;

  /// Verifica si un servicio está bloqueado
  bool isServiceBlocked(ServiceResponse service) {
    final serviceName = service.name.toLowerCase();
    return _blockedServices.any((blocked) => 
        serviceName.contains(blocked.toLowerCase()));
  }

  /// Obtiene la lista de servicios bloqueados
  List<String> get blockedServices => List.unmodifiable(_blockedServices);

  /// Carga servicios optimizada con múltiples estrategias
  Future<void> loadServices({required String parentId}) async {
    _currentParentId = parentId;
    
    // 1. Mostrar datos del caché inmediatamente si están disponibles
    if (_cacheByParentId.containsKey(parentId)) {
      _allServices = _cacheByParentId[parentId]!;
      _displayedServices = List.from(_allServices);
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    }

    // 2. Cargar desde caché local si existe
    await _loadFromLocalCache(parentId);
    
    // 3. Actualizar desde el servidor en background
    _refreshFromServer(parentId);
    
    // 4. Configurar actualización automática
    _setupAutoRefresh(parentId);
  }

  /// Carga desde caché local
  Future<void> _loadFromLocalCache(String parentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'cached_services_$parentId';
      final tsKey = 'cache_timestamp_$parentId';
      final cachedJson = prefs.getString(cacheKey);
      final ts = prefs.getInt(tsKey) ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      // Caché válido por 30 minutos (reducido de 1 hora)
      if (cachedJson != null && nowMs - ts < 1800000) {
        final decoded = jsonDecode(cachedJson) as List<dynamic>;
        _allServices = decoded
            .map((m) => ServiceResponse.fromJson(m as Map<String, dynamic>))
            .toList();
        _displayedServices = List.from(_allServices);
        _cacheByParentId[parentId] = _allServices;
        _errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print('Error cargando caché local: $e');
    }
  }

  /// Actualiza desde el servidor en background
  Future<void> _refreshFromServer(String parentId) async {
    if (_isRefreshing) return;
    
    _isRefreshing = true;
    notifyListeners();

    try {
      final token = await AuthUtils.getToken();
      if (token == null) throw Exception('Token nulo');
      
      final fetched = await _api.fetchServicesFromBackend2(token, parentId);
      fetched.sort((a, b) => a.name.compareTo(b.name));
      
      // Actualizar solo si hay cambios
      if (_hasChanges(_allServices, fetched)) {
        _allServices = fetched;
        _displayedServices = List.from(_allServices);
        _cacheByParentId[parentId] = _allServices;
        
        // Guardar en caché local
        await _saveToLocalCache(parentId);
      }
      
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) print('Error refrescando desde servidor: $e');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Guarda en caché local
  Future<void> _saveToLocalCache(String parentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'cached_services_$parentId';
      final tsKey = 'cache_timestamp_$parentId';
      
      final serializable = _allServices.map((s) => s.toMap()).toList(growable: false);
      await prefs.setString(cacheKey, jsonEncode(serializable));
      await prefs.setInt(tsKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      if (kDebugMode) print('Error guardando caché local: $e');
    }
  }

  /// Verifica si hay cambios en los datos
  bool _hasChanges(List<ServiceResponse> old, List<ServiceResponse> newData) {
    if (old.length != newData.length) return true;
    
    for (int i = 0; i < old.length; i++) {
      if (old[i].id != newData[i].id || old[i].name != newData[i].name) {
        return true;
      }
    }
    return false;
  }

  /// Configura actualización automática
  void _setupAutoRefresh(String parentId) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_currentParentId == parentId) {
        _refreshFromServer(parentId);
      }
    });
  }

  /// Refresca manualmente
  Future<void> refresh() async {
    if (_currentParentId != null) {
      await _refreshFromServer(_currentParentId!);
    }
  }

  /// Filtra por nombre o tipo (optimizado)
  void filter(String q) {
    final query = q.toLowerCase();
    if (query.isEmpty) {
      _displayedServices = List.from(_allServices);
    } else {
      _displayedServices = _allServices.where((s) {
        final byName = s.name.toLowerCase().contains(query);
        final byType = s.serviceTypes
            .any((t) => t.name.toLowerCase().contains(query));
        return byName || byType;
      }).toList();
    }
    _selectedIndex = -1;
    notifyListeners();
  }

  void clearFilter() => filter('');

  void selectIndex(int i) {
    _selectedIndex = (i >= 0 && i < _displayedServices.length) ? i : -1;
    notifyListeners();
  }

  void clearSelection() {
    _selectedIndex = -1;
    notifyListeners();
  }

  void toggleSearchMode() {
    _isSearching = !_isSearching;
    if (!_isSearching) clearFilter();
    notifyListeners();
  }

  /// Limpia recursos al destruir
  @override
  void dispose() {
    _refreshTimer?.cancel();
    _cacheTimer?.cancel();
    super.dispose();
  }
} 