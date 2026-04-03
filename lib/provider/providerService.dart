import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/serviceConstants.dart';
import '../constant/cacheConstants.dart';
import '../controller/serviceFetcher.dart';
import '../models/expertiseModels.dart';
import '../models/service_requestModels.dart';
import '../request/ResponseGet.dart';
import '../request/ResponsePost.dart';
import '../request/requestExpertise.dart';
import '../request/requestServiceType.dart';
import '../request/requestStatus.dart';
import '../request/resquest.dart';
import '../utils/offerRepository.dart';
import '../utils/serviceCancelled.dart';
import '../utils/serviceComplete.dart';
import '../utils/serviceFetcher.dart';
import '../utils/serviceInProgress.dart';

class HistorialProvider extends ChangeNotifier {
  // Repositorios
  final ServiceRepository _repoAvailable;
  final OfferRepository _repoOffer;
  final ServiceRepositoryInProgress _repoInProgress;
  final ServiceRepositoryComplete _repoComplete;
  final ServiceRepositoryCancelled _repoCancelled;

  // Estado optimizado
  bool isLoading = false;
  bool isRefreshing = false;
  String? errorMessage;
  final Map<String, List<ServiceRequest>> _byStatus = {};
  final Map<String, DateTime> _lastUpdate = {};
  final Map<String, bool> _isLoadingMore = {};
  final Map<String, bool> _hasMore = {};
  
  // Caché inteligente
  Timer? _autoRefreshTimer;
  Timer? _smartRefreshTimer;
  String? _currentUserId;
  bool _isInitialized = false;
  
  // 🚀 OPTIMIZADO: Configuración de caché mejorada desde constantes
  static const int _cacheValidMinutes = CacheConstants.historialCacheValidMinutes;
  static const int _autoRefreshMinutes = CacheConstants.historialAutoRefreshMinutes;
  static const int _smartRefreshSeconds = CacheConstants.historialSmartRefreshSeconds;
  static const int _networkTimeoutSeconds = CacheConstants.networkTimeoutSeconds;
  static const int _maxCacheAgeHours = CacheConstants.maxCacheAgeHours;
  static const int _maxCacheItemsPerStatus = CacheConstants.maxCacheItemsPerStatus;
  static const int _criticalDataCacheMinutes = CacheConstants.criticalDataCacheMinutes;
  static const int _normalDataCacheMinutes = CacheConstants.normalDataCacheMinutes;

  HistorialProvider()
      : _repoAvailable = ServiceRepository(
          apiService: ApiService(),
          firestore: FirebaseFirestore.instance,
        ),
        _repoOffer = OfferRepository(
          apiService2: ApiService2(),
          serviceDataFetcher: ServiceDataFetcher(),
          firestore: FirebaseFirestore.instance,
        ),
        _repoInProgress = ServiceRepositoryInProgress(
          apiService: ApiService2(),
          firestore: FirebaseFirestore.instance,
        ),
        _repoComplete = ServiceRepositoryComplete(
          apiService: ApiService2(),
          firestore: FirebaseFirestore.instance,
        ),
        _repoCancelled = ServiceRepositoryCancelled(
          apiService: ApiService2(),
          firestore: FirebaseFirestore.instance,
        );

  List<ServiceRequest> _ordenarPorFecha(List<ServiceRequest> lista) {
    if (lista.isEmpty) return lista;
    
    final sortedList = List<ServiceRequest>.from(lista);
    sortedList.sort((a, b) {
      final aDate = a.createdAt;
      final bDate = b.createdAt;
      return bDate.compareTo(aDate); // Descendente: más reciente primero
    });
    return sortedList;
  }

  /// Devuelve la lista para cada estado con caché inteligente
  List<ServiceRequest> list(String status) {
    final lista = _byStatus[status] ?? [];
    
    // Si no hay datos y no se ha inicializado, marcar para carga
    if (lista.isEmpty && !_isInitialized && _currentUserId != null) {
      _scheduleSmartRefresh();
    }
    
    return lista;
  }

  int get availableCount => list('available').length;
  int get offerServiceCount => list('offer').expand((s) => s.offers).length;
  int get inProgressCount => list('in_progress').length;
  int get completedCount => list('completed').length;
  int get cancelledCount => list('cancelled').length;

  /// Carga todo el historial con optimizaciones avanzadas
  Future<void> loadAll({
    required String userId,
    required String token,
    required String deviceId,
  }) async {
    if (_currentUserId == userId && _isInitialized) {
      return;
    }

    _currentUserId = userId;
    _isInitialized = false;

    // 1. Cargar desde caché local inmediatamente (más rápido)
    await _loadFromCache(userId);

    // 2. Si no hay datos en caché o están muy viejos, cargar desde servidor
    if (_shouldRefreshFromServer(userId)) {
      await _loadFromServer(userId, token, deviceId);
    }

    // 3. Configurar actualización automática inteligente (menos agresiva)
    _setupSmartRefresh(userId, token, deviceId);
    _setupAutoRefresh(userId, token, deviceId);

    _isInitialized = true;
  }

  /// Carga desde caché local optimizada
  Future<void> _loadFromCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'historial_cache_$userId';
      final tsKey = 'historial_timestamp_$userId';
      final versionKey = 'historial_version_$userId';

      final cachedJson = prefs.getString(cacheKey);
      final ts = prefs.getInt(tsKey) ?? 0;
      final version = prefs.getInt(versionKey) ?? 1;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      // Caché válido por tiempo configurado
      if (cachedJson != null && nowMs - ts < (_cacheValidMinutes * 60 * 1000)) {
        final Map<String, dynamic> decoded = jsonDecode(cachedJson);

        for (final entry in decoded.entries) {
          final status = entry.key;
          final servicesJson = entry.value as List<dynamic>;

          _byStatus[status] = servicesJson
              .map((s) => ServiceRequest.fromSnapshot(s as Map<String, dynamic>))
              .toList();
          _lastUpdate[status] = DateTime.fromMillisecondsSinceEpoch(ts);
          
          // Inicializar estado de paginación
          _isLoadingMore[status] = false;
          _hasMore[status] = false;
        }

        notifyListeners();
      } else {
        // Limpiar caché obsoleto
        await prefs.remove(cacheKey);
        await prefs.remove(tsKey);
      }
    } catch (e) {
      null;
    }
  }

  /// Verifica si debe refrescar desde servidor con lógica mejorada
  bool _shouldRefreshFromServer(String userId) {
    if (_byStatus.isEmpty) {
      return true;
    }

    final now = DateTime.now();
    for (final lastUpdate in _lastUpdate.values) {
      final difference = now.difference(lastUpdate).inMinutes;
      if (difference > _cacheValidMinutes) {
        return true;
      }
    }

    return false;
  }

  /// 🚀 OPTIMIZADO: Carga desde servidor con optimizaciones mejoradas
  Future<void> _loadFromServer(
      String userId, String token, String deviceId) async {
    if (isRefreshing) return;
    isRefreshing = true;
    notifyListeners();

    try {
      // 🚀 OPTIMIZACIÓN: Cargar datos críticos primero (available, in_progress)
      final criticalFutures = [
        _loadAvailableServices(userId, token),
        _loadInProgressServices(userId, token),
      ];
      
      // Cargar datos menos críticos en paralelo
      final normalFutures = [
        _loadOfferServices(userId, token, deviceId),
        _loadCompletedServices(userId, token),
        _loadCancelledServices(userId, token),
      ];

      // Ejecutar cargas críticas primero
      final criticalResults = await Future.wait<List<ServiceRequest>>(criticalFutures)
          .timeout(Duration(seconds: _networkTimeoutSeconds ~/ 2));
      
      // Actualizar UI inmediatamente con datos críticos
      _byStatus['available'] = _ordenarPorFecha(criticalResults[0]);
      _byStatus['in_progress'] = _ordenarPorFecha(criticalResults[1]);
      _updateTimestamps(['available', 'in_progress']);
      notifyListeners(); // 🚀 Notificar UI inmediatamente
      
      // Cargar datos normales en background
      final normalResults = await Future.wait<List<ServiceRequest>>(normalFutures)
          .timeout(Duration(seconds: _networkTimeoutSeconds ~/ 2));
      
      _byStatus['offer'] = _ordenarPorFecha(normalResults[0]);
      _byStatus['completed'] = _ordenarPorFecha(normalResults[1]);
      _byStatus['cancelled'] = _ordenarPorFecha(normalResults[2]);
      _updateTimestamps(['offer', 'completed', 'cancelled']);

      // Guardar en caché con versión
      await _saveToCache(userId);
      errorMessage = null;
      
    } catch (e) {
      errorMessage = 'Error cargando historial: $e';
      null;
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }

  /// 🚀 Helper para actualizar timestamps de forma eficiente
  void _updateTimestamps(List<String> statuses) {
    final now = DateTime.now();
    for (final status in statuses) {
      _lastUpdate[status] = now;
      _isLoadingMore[status] = false;
      _hasMore[status] = false;
    }
  }

  /// Carga servicios disponibles
  Future<List<ServiceRequest>> _loadAvailableServices(
      String userId, String token) async {
    try {
      final result = await _repoAvailable
          .fetchServicesByStatus('available', 'status', userId, token, []);
      return result;
    } catch (e) {
      null;
      return <ServiceRequest>[];
    }
  }

  void iniciarTemporizadorCancelacion(String userId, String token) {
    Timer.periodic(const Duration(seconds: 30), (_) async {
      final servicios = await _loadAvailableServices(userId, token);

      null;
      for (int i = 0; i < servicios.length; i++) {
        final s = servicios[i];
        null;
        null;
      }

      // Convertir ServiceRequest a ServiceRequestModel
      final serviciosModel = servicios
          .map((s) => ServiceRequestModel(
                id: s.id,
                date: s.selectedDate ?? '',
                time: s.selectedTime ?? '',
                status: s.status.id,
                description: s.description,
                location: s.location,
                images: s.images,
                expertises: s.expertises
                    .map((e) => ExpertiseModel(
                          id: e.id,
                          name: e.name,
                        ))
                    .toList(),
                rawOffers: s.offers.map((o) => o.toMap()).toList(),
                rawComments: [], // Campo requerido pero no disponible en ServiceRequest
                userId: s.userId,
                workerId: s.workerId,
              ))
          .toList();

      // Debug: verificar los datos mapeados
      for (int i = 0; i < serviciosModel.length; i++) {
        final sm = serviciosModel[i];
        null;
      }

      await _cancelarServiciosVencidos(serviciosModel);
    });
  }

  /// Carga servicios ofertados
  Future<List<ServiceRequest>> _loadOfferServices(
      String userId, String token, String deviceId) async {
    try {
      final result = await _repoOffer.fetchOffersForUser(
        'offer',
        userId,
        token,
        ServiceRequest(
          id: '',
          serviceDateTime: '',
          description: '',
          images: [],
          location: {},
          offeredPrice: 0.0,
          serviceType:
              ServiceType(id: '', name: '', selectedDate: '', selectedTime: ''),
          userId: userId,
          workerId: '',
          isFavorite: false,
          selectedDate: null,
          selectedTime: null,
          acceptedTerms: false,
          expertises: <Expertise>[],
          status: Status(id: 'offer', name: 'Ofertado'),
          hasOffer: false,
          offers: [],
          devicesId: '',
          subcategoryName: '',
          createdAt: DateTime.now(),
        ),
        deviceId,
      );
      return result;
    } catch (e) {
      null;
      return <ServiceRequest>[];
    }
  }

  /// Carga servicios en progreso
  Future<List<ServiceRequest>> _loadInProgressServices(
      String userId, String token) async {
    try {
      // Solo buscar servicios con estado in_progress para evitar duplicados
      final result = await _repoInProgress.fetchServicesByInProgress(
          'in_progress', userId, 'status', token);
      return result;
    } catch (e) {
      null;
      return <ServiceRequest>[];
    }
  }

  /// Carga servicios completados
  Future<List<ServiceRequest>> _loadCompletedServices(
      String userId, String token) async {
    try {
      final result = await _repoComplete.fetchServicesByComplete(
          'completed', userId, 'status', token);
      return result;
    } catch (e) {
      null;
      return <ServiceRequest>[];
    }
  }

  /// Carga servicios cancelados
  Future<List<ServiceRequest>> _loadCancelledServices(
      String userId, String token) async {
    try {
      return await _repoCancelled.fetchServicesByCancelled(
          'cancelled', userId, 'status', token);
    } catch (e) {
      null;
      return <ServiceRequest>[];
    }
  }

  /// Guarda en caché local
  Future<void> _saveToCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'historial_cache_$userId';
      final tsKey = 'historial_timestamp_$userId';
      final versionKey = 'historial_version_$userId';

      final Map<String, dynamic> cacheData = {};
      for (final entry in _byStatus.entries) {
        cacheData[entry.key] = entry.value.map((s) => s.toMap()).toList();
      }

      await prefs.setString(cacheKey, jsonEncode(cacheData));
      await prefs.setInt(tsKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setInt(versionKey, 1); // Incrementar versión de caché
    } catch (e) {
      null;
    }
  }

  /// Configura actualización automática inteligente
  void _setupSmartRefresh(String userId, String token, String deviceId) {
    _smartRefreshTimer?.cancel();
    _smartRefreshTimer = Timer.periodic(const Duration(seconds: _smartRefreshSeconds), (timer) {
      if (_currentUserId == userId && !isRefreshing) {
        // Solo actualizar si no se está refrescando actualmente
        _loadFromServer(userId, token, deviceId);
      }
    });
  }

  /// Configura actualización automática (método público)
  void startAutoRefresh({
    required String userId,
    required String token,
    required String deviceId,
  }) {
    _setupAutoRefresh(userId, token, deviceId);
  }

  /// Configura actualización automática tradicional
  void _setupAutoRefresh(String userId, String token, String deviceId) {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: _autoRefreshMinutes), (timer) {
      if (_currentUserId == userId && !isRefreshing) {
        // Solo actualizar si no se está refrescando actualmente
        _loadFromServer(userId, token, deviceId);
      }
    });
  }

  /// Programa una actualización inteligente
  void _scheduleSmartRefresh() {
    if (_smartRefreshTimer != null) return;
    
    _smartRefreshTimer = Timer(const Duration(seconds: _smartRefreshSeconds), () {
      if (_currentUserId != null) {
        // Aquí podrías implementar lógica más inteligente
        // Por ejemplo, solo actualizar datos críticos o verificar cambios
      }
    });
  }

  /// Detiene la actualización automática
  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _smartRefreshTimer?.cancel();
  }

  /// Verifica si hay más datos para cargar (para paginación)
  bool hasMore(String status) {
    return _hasMore[status] ?? false;
  }

  /// Verifica si está cargando más datos
  bool isLoadingMore(String status) {
    return _isLoadingMore[status] ?? false;
  }

  /// Carga más datos (para paginación)
  Future<void> loadMore({
    required String status,
    required String userId,
    required String token,
    required String deviceId,
  }) async {
    if (isLoadingMore(status)) {
      return;
    }
    
    _isLoadingMore[status] = true;
    notifyListeners();

    try {
      // Implementar lógica de paginación aquí
      // Por ahora, solo recargamos los datos del estado específico
      List<ServiceRequest> result;
      switch (status) {
        case 'available':
          result = await _loadAvailableServices(userId, token);
          break;
        case 'offer':
          result = await _loadOfferServices(userId, token, deviceId);
          break;
        case 'in_progress':
          result = await _loadInProgressServices(userId, token);
          break;
        case 'completed':
          result = await _loadCompletedServices(userId, token);
          break;
        case 'cancelled':
          result = await _loadCancelledServices(userId, token);
          break;
        default:
          result = [];
      }
      
      _byStatus[status] = _ordenarPorFecha(result);
      _lastUpdate[status] = DateTime.now();
      _isLoadingMore[status] = false;
      _hasMore[status] = false; // No hay más datos para cargar si se cargó todo
      
      // Actualizar caché
      await _saveToCache(userId);
      notifyListeners();
    } catch (e) {
      errorMessage = 'Error cargando más datos: $e';
      null;
      _isLoadingMore[status] = false;
      notifyListeners();
    }
  }

  /// Refrescar manualmente con optimización
  Future<void> refresh({
    required String userId,
    required String token,
    required String deviceId,
  }) async {
    // Si ya se está refrescando, no hacer nada
    if (isRefreshing) {
      return;
    }
    
    // Limpiar caché obsoleto antes de refrescar
    await _clearObsoleteCache(userId);
    
    await _loadFromServer(userId, token, deviceId);
  }

  /// Limpia caché obsoleto
  Future<void> _clearObsoleteCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'historial_cache_$userId';
      final tsKey = 'historial_timestamp_$userId';
      final versionKey = 'historial_version_$userId';
      
      final ts = prefs.getInt(tsKey) ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      
      // Si el caché tiene más de 2 horas, limpiarlo completamente
      if (nowMs - ts > (_maxCacheAgeHours * 60 * 60 * 1000)) {
        await prefs.remove(cacheKey);
        await prefs.remove(tsKey);
        await prefs.remove(versionKey);
      }
    } catch (e) {
      null;
    }
  }

  /// Limpia todos los datos y caché
  void clearAll() {
    _byStatus.clear();
    _lastUpdate.clear();
    _isLoadingMore.clear();
    _hasMore.clear();
    _isInitialized = false;
    errorMessage = null;
    notifyListeners();
  }

  /// Obtiene estadísticas de caché
  Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    final stats = <String, dynamic>{};
    
    for (final entry in _lastUpdate.entries) {
      final status = entry.key;
      final lastUpdate = entry.value;
      final difference = now.difference(lastUpdate).inMinutes;
      final count = _byStatus[status]?.length ?? 0;
      
      stats[status] = {
        'count': count,
        'lastUpdate': lastUpdate.toIso8601String(),
        'minutesAgo': difference,
        'isValid': difference < _cacheValidMinutes,
      };
    }
    
    return stats;
  }

  /// Limpia recursos
  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _smartRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    // Reducir logs excesivos para mejorar rendimiento
    super.notifyListeners();
  }

  /// Devuelve la hora actual en Bolivia (asume que el dispositivo está en UTC-4)
  DateTime _nowBolivia() {
    return DateTime.now();
  }

  Future<void> _cancelarServiciosVencidos(
      List<ServiceRequestModel> servicios) async {
    final ahoraBolivia = _nowBolivia();
    final api = ApiService();

    null;
    null;

    for (final servicio in servicios) {
      // Solo procesar servicios en estado "available" o "offer"
      if (servicio.status != 'available' && servicio.status != 'offer') {
        null;
        continue;
      }

      null;

      DateTime? fechaServicio;

      try {
        if (servicio.date.isNotEmpty && servicio.time.isNotEmpty) {
          // Usar la función _parseFechaHoraBolivia que tiene logs detallados
          fechaServicio = _parseFechaHoraBolivia(servicio.date, servicio.time);
          null;
        } else {
          null;
          continue; // Saltar este servicio si no tiene fecha/hora
        }
      } catch (e) {
        null;
        continue; // Saltar este servicio si hay error
      }

      if (fechaServicio != null && ahoraBolivia.isAfter(fechaServicio)) {
        null;
        try {
          await api.updateService(
            serviceId: servicio.id,
            data: {
              'status': ServiceStatus.cancelled,
              'hasOffer': false,
            },
          );

          final ofertasSnapshot = await FirebaseFirestore.instance
              .collection('offers')
              .where('serviceId', isEqualTo: servicio.id)
              .get();

          for (final doc in ofertasSnapshot.docs) {
            final offerId = doc.id;
            await FirebaseFirestore.instance
                .collection('offers')
                .doc(offerId)
                .update({
              'status': ServiceStatus.cancelled,
            });
          }

          null;
        } catch (e) {
          null;
        }
      } else {
        null;
        null;
      }
    }
  }

  /// Convierte una fecha y hora a DateTime en zona horaria de Bolivia
  DateTime? _parseFechaHoraBolivia(String date, String time) {
    try {
      null;

      // Parsear la fecha
      final fechaBase = DateTime.parse(date);
      null;

      // Parsear la hora
      String timeRaw = time.trim();
      int hour = 0;
      int minute = 0;

      null;

      // Detectar AM/PM con regex más robusto
      final amPmMatch =
          RegExp(r'(AM|PM)', caseSensitive: false).firstMatch(timeRaw);
      if (amPmMatch != null) {
        final isPm = amPmMatch.group(0)!.toUpperCase() == 'PM';
        null;

        // Extraer solo números y dos puntos
        timeRaw = timeRaw.replaceAll(RegExp(r'[^0-9:]'), '');
        null;

        final timeParts = timeRaw.split(':');
        if (timeParts.length >= 2) {
          hour = int.tryParse(timeParts[0]) ?? 0;
          minute = int.tryParse(timeParts[1]) ?? 0;
        } else {
          null;
          return null;
        }

        null;

        // Convertir formato 12h a 24h
        if (isPm && hour < 12) {
          hour += 12;
          null;
        }
        if (!isPm && hour == 12) {
          hour = 0;
          null;
        }

        null;
      } else {
        // Formato 24h
        null;
        final timeParts = timeRaw.split(':');
        if (timeParts.length >= 2) {
          hour = int.tryParse(timeParts[0]) ?? 0;
          minute = int.tryParse(timeParts[1]) ?? 0;
        } else {
          null;
          return null;
        }
        null;
      }

      // Crear DateTime local (Bolivia)
      final fechaBolivia = DateTime(
        fechaBase.year,
        fechaBase.month,
        fechaBase.day,
        hour,
        minute,
      );
      null;
      null;
      return fechaBolivia;
    } catch (e) {
      null;
      return null;
    }
  }
}
