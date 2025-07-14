// home_services_provider.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:manitoscliente_new/request/ResponseGet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_utils.dart';

class HomeServicesProvider extends ChangeNotifier {
  final ApiService2 _api = ApiService2();

  List<ServiceResponse> _allServices = [];
  List<ServiceResponse> _displayedServices = [];

  bool _isLoading = false;
  String? _errorMessage;
  int _selectedIndex = -1;
  bool _isSearching = false;
  

  // --- Getters ---
  List<ServiceResponse> get displayedServices => _displayedServices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasSelection => _selectedIndex != -1;
  ServiceResponse? get selectedService =>
      hasSelection ? _displayedServices[_selectedIndex] : null;
  bool get isSearching => _isSearching;

  /// Carga servicios (intenta usar caché <1h, si no llama al backend)
  Future<void> loadServices({required String parentId}) async {
  _isLoading = true;
  notifyListeners();

  final prefs = await SharedPreferences.getInstance();
  final cacheKey   = 'cached_services_$parentId';
  final tsKey      = 'cache_timestamp_$parentId';
  final cachedJson = prefs.getString(cacheKey);
  final ts         = prefs.getInt(tsKey) ?? 0;
  final nowMs      = DateTime.now().millisecondsSinceEpoch;

  if (cachedJson != null && nowMs - ts < 3600000) {
    // < 1 hora: uso de caché específico para parentId
    final decoded = jsonDecode(cachedJson) as List<dynamic>;
    _allServices = decoded
        .map((m) => ServiceResponse.fromJson(m as Map<String, dynamic>))
        .toList();
  } else {
    // Traer del backend con el parentId correcto
    final token = await AuthUtils.getToken();
    if (token == null) throw Exception('Token nulo');
    final fetched = await _api.fetchServicesFromBackend2(token, parentId);
    fetched.sort((a, b) => a.name.compareTo(b.name));
    _allServices = fetched;

    // Guardar en caché SOLO para este parentId
    final serializable =
        _allServices.map((s) => s.toMap()).toList(growable: false);
    await prefs.setString(cacheKey, jsonEncode(serializable));
    await prefs.setInt(tsKey, nowMs);
  }

  _displayedServices = List.from(_allServices);
  _errorMessage      = null;
  _isLoading         = false;
  notifyListeners();
}


  /// Filtra por nombre o tipo
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
}
