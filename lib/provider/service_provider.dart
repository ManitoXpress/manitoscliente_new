import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../request/ResponseGet.dart';
import '../controller/auth_utils.dart';

class ProfessionalServicesProvider extends ChangeNotifier {
  final ApiService2 _api = ApiService2();

  List<ServiceResponse> _allServices = [];
  List<ServiceResponse> _displayedServices = [];

  bool _isLoading = false;
  String? _errorMessage;
  int _selectedIndex = -1;

  // --- NUEVO: estado de búsqueda ---
  bool _isSearching = false;
  bool get isSearching => _isSearching;

  // getters existentes
  List<ServiceResponse> get displayedServices => _displayedServices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ServiceResponse? get selectedService =>
      (_selectedIndex >= 0 && _selectedIndex < _displayedServices.length)
          ? _displayedServices[_selectedIndex]
          : null;
  bool get hasSelection => _selectedIndex != -1;

  /// Alterna entre modo búsqueda y modo título en AppBar.
  void toggleSearchMode() {
    _isSearching = !_isSearching;
    if (!_isSearching) {
      // Al cerrar búsqueda, limpiar filtro
      _filterServices('');
    }
    notifyListeners();
  }

  /// Carga la lista de servicios (cache + backend)
  Future<void> loadServices({String parentId = 'wZvEJHJ6Q2eBOEWn3if2'}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cached_services');
      final ts = prefs.getInt('cache_timestamp') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (cachedJson != null && now - ts < 3600000) {
        // < 1h: usar caché
        final List<dynamic> decoded = jsonDecode(cachedJson);
        _allServices = decoded
            .map((m) => ServiceResponse.fromJson(m as Map<String, dynamic>))
            .toList();
      } else {
        // Traer del backend
        final token = await AuthUtils.getToken();
        if (token == null) throw Exception('Token nulo');
        final fetched = await _api.fetchServicesFromBackend2(token, parentId);
        fetched.sort((a, b) => a.name.compareTo(b.name));
        _allServices = fetched;

        // Guardar en caché
        final List<Map<String, dynamic>> serializable =
        _allServices.map((s) => s.toMap()).toList();
        await prefs.setString('cached_services', jsonEncode(serializable));
        await prefs.setInt('cache_timestamp', now);
      }

      _displayedServices = List.from(_allServices);
      _errorMessage = null;
    } catch (e, st) {
      _errorMessage = e.toString();
      if (kDebugMode) debugPrint('❌ loadServices error: $e\n$st');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filtra servicios por nombre o tipo.
  void _filterServices(String query) {
    final q = query.toLowerCase();
    if (q.isEmpty) {
      _displayedServices = List.from(_allServices);
    } else {
      _displayedServices = _allServices.where((s) {
        final byName = s.name.toLowerCase().contains(q);
        final byType = s.serviceTypes
            .any((t) => t.name.toLowerCase().contains(q));
        return byName || byType;
      }).toList();
    }
    _selectedIndex = -1;
    notifyListeners();
  }

  /// Interfaz pública para onChanged del TextField
  void filter(String term) => _filterServices(term);

  /// Limpia filtro
  void clearFilter() => _filterServices('');

  /// Selecciona un servicio en el grid
  void selectIndex(int i) {
    if (i >= 0 && i < _displayedServices.length) {
      _selectedIndex = i;
    } else {
      _selectedIndex = -1;
    }
    notifyListeners();
  }

  /// Limpia selección
  void clearSelection() {
    _selectedIndex = -1;
    notifyListeners();
    }
}