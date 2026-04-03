import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../request/ResponseGet.dart';
import '../controller/auth_utils.dart';
import '../request/requestServiceType.dart';

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

  // --- NUEVO: Lista de servicios bloqueados ---
  static const List<String> _blockedServices = [
    // Hogar
    'canaletas',
    'carpintería',
    'modista/costurera',
    'soldador',
    'mudanza',
    'vidriería',
    'wZvEJHJ6Q2eBOEWn3if2',

    // Profesionales
    'arquitectura y diseño',
    'cocina y catering',
    'eventos',
    'técnicos de computadoras y dispositivos electrónicos',
  ];

  // --- NUEVO: Lista de servicios a excluir del área de salud ---
  static const List<String> _excludedHealthServices = [
    'médico general',
    'nutrición clínica',
    'medico-general', // ID del backend
    'nutricion-clinica', // ID del backend
  ];

  // --- NUEVO: Lista de serviceTypes a excluir según la imagen ---
  static const List<String> _excludedServiceTypes = [
    // Belleza y estética
    'corte de cabello para dama',
    'corte de cabello para varones',
    'corte-cabello-dama',
    'corte-cabello-varones',
    'Corte de cabello para dama',
    'Corte de cabello para varón',

    // Albañilería
    'maestro',
    'Maestro',
    'ayudante',
    'Ayudante',
    'Sellado de goteras',
    'sellado de goteras',
    'maestro-albañil',
    'ayudante-albañil',
    'sellado-goteras',

    // Cerrajería
    'deschapado de puertas',
    'Deschapado de puertas',
    'deschapado-puertas',

    // Electricista
    'maestro electricista',
    'ayudante electricista',
    'maestro-electricista',
    'ayudante-electricista',
    'Maestro',
    'Ayudante',

    // Limpieza
    'limpieza de piscina',
    'limpieza-piscina',
    'mimpieza/mantenimiento piscina',
    'limpieza-mantenimiento-piscina',

    // Pintor
    'maestro pintor',
    'ayudante pintor',
    'maestro-pintor',
    'ayudante-pintor',
    'Maestro',
    'Ayudante',

    // Plomería
    'maestro plomero',
    'ayudante plomero',
    'maestro-plomero',
    'ayudante-plomero',
    'Maestro',
    'Ayudante',
    'worker-master',
    'worker-helper',
  ];

  // getters existentes
  List<ServiceResponse> get displayedServices => _displayedServices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ServiceResponse? get selectedService =>
      (_selectedIndex >= 0 && _selectedIndex < _displayedServices.length)
          ? _displayedServices[_selectedIndex]
          : null;
  bool get hasSelection => _selectedIndex != -1;

  /// Verifica si un servicio está bloqueado
  bool isServiceBlocked(ServiceResponse service) {
    final serviceName = service.name.toLowerCase();
    return _blockedServices
        .any((blocked) => serviceName.contains(blocked.toLowerCase()));
  }

  /// Verifica si un servicio debe ser excluido del área de salud
  bool isServiceExcluded(ServiceResponse service) {
    // NO excluir la categoría principal "Area de salud"
    // Solo excluir si es un subservicio específico
    return false; // Temporalmente deshabilitado para probar
  }

  /// Filtra los serviceTypes excluidos de un servicio
  List<ServiceType> filterExcludedServiceTypes(List<ServiceType> serviceTypes) {
    return serviceTypes.where((type) {
      final typeId = type.id.toLowerCase();
      final typeName = type.name.toLowerCase();

      // Verificar contra la lista de servicios de salud excluidos
      bool isHealthExcluded = _excludedHealthServices.any((excluded) =>
          typeId.contains(excluded.toLowerCase()) ||
          typeName.contains(excluded.toLowerCase()));

      // Verificar contra la lista general de serviceTypes excluidos
      bool isGeneralExcluded = _excludedServiceTypes.any((excluded) =>
          typeId.contains(excluded.toLowerCase()) ||
          typeName.contains(excluded.toLowerCase()));

      return !isHealthExcluded && !isGeneralExcluded;
    }).toList();
  }

  /// Obtiene la lista de servicios bloqueados
  List<String> get blockedServices => List.unmodifiable(_blockedServices);

  /// Obtiene la lista de servicios excluidos del área de salud
  List<String> get excludedHealthServices =>
      List.unmodifiable(_excludedHealthServices);

  /// Obtiene la lista de serviceTypes excluidos según la imagen
  List<String> get excludedServiceTypes =>
      List.unmodifiable(_excludedServiceTypes);

  /// Filtra servicios excluidos del área de salud
  List<ServiceResponse> _filterExcludedServices(
      List<ServiceResponse> services) {
    return services.map((service) {
      // Filtrar los serviceTypes excluidos de cada servicio
      final filteredServiceTypes =
          filterExcludedServiceTypes(service.serviceTypes);

      // Crear una copia del servicio con los serviceTypes filtrados
      return ServiceResponse(
        id: service.id,
        name: service.name,
        image: service.image,
        description: service.description,
        serviceTypes: filteredServiceTypes,
        parentId: service.parentId,
        buttonTexts: service.buttonTexts,
        priceRanges: service.priceRanges,
        typeName: service.typeName,
        workerDetails: service.workerDetails,
        workerId: service.workerId,
        userId: service.userId,
        location: service.location,
        offerId: service.offerId,
        images: service.images,
        expertises: service.expertises,
        subcategoryName: service.subcategoryName,
      );
    }).toList();
  }

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
        // Aplicar filtro de servicios excluidos
        _allServices = _filterExcludedServices(_allServices);
      } else {
        // Traer del backend
        final token = await AuthUtils.getToken();
        if (token == null) throw Exception('Token nulo');
        final fetched = await _api.fetchServicesFromBackend2(token, parentId);
        fetched.sort((a, b) => a.name.compareTo(b.name));
        // Aplicar filtro de servicios excluidos
        _allServices = _filterExcludedServices(fetched);

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
      if (kDebugMode) null;
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
        final byType =
            s.serviceTypes.any((t) => t.name.toLowerCase().contains(q));
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
