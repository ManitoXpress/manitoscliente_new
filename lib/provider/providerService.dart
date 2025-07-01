import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/serviceFetcher.dart';
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

  // Estado
  bool isLoading = false;
  bool isRefreshing = false;
  String? errorMessage;
  final Map<String, List<ServiceRequest>> _byStatus = {};
  final Map<String, DateTime> _lastUpdate = {};
  Timer? _autoRefreshTimer;
  String? _currentUserId;

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
    print('🔍 Debug - _ordenarPorFecha: ${lista.length} elementos');
    lista.sort((a, b) {
      final aDate = a.createdAt;
      final bDate = b.createdAt;
      return bDate.compareTo(aDate); // Descendente: más reciente primero
    });
    return lista;
  }

  /// Devuelve la lista para cada estado
  List<ServiceRequest> list(String status) {
    final lista = _byStatus[status] ?? [];
    print('🔍 Debug - list($status): ${lista.length} elementos');
    return lista;
  }

  int get availableCount => list('available').length;
  int get offerServiceCount => list('offer').expand((s) => s.offers).length;
  int get inProgressCount {
    final count = list('in_progress').length;
    print('🔍 Debug - inProgressCount: $count');
    print('🔍 Debug - Lista in_progress: ${list('in_progress').map((s) => '${s.id}(${s.status.id})').join(', ')}');
    return count;
  }
  int get completedCount => list('completed').length;
  int get cancelledCount => list('cancelled').length;

  /// Carga todo el historial con optimizaciones
  Future<void> loadAll({
    required String userId,
    required String token,
    required String deviceId,
  }) async {
    print('🔍 Debug - loadAll iniciado para userId: $userId');
    _currentUserId = userId;
    
    // 1. Cargar desde caché local inmediatamente
    print('🔍 Debug - Cargando desde caché...');
    await _loadFromCache(userId);
    
    // 2. Si no hay datos en caché o están muy viejos, cargar desde servidor
    if (_shouldRefreshFromServer(userId)) {
      print('🔍 Debug - Refrescando desde servidor...');
      await _loadFromServer(userId, token, deviceId);
    } else {
      print('🔍 Debug - Usando datos del caché');
    }
    
    // 3. Configurar actualización automática
    _setupAutoRefresh(userId, token, deviceId);
    
    print('🔍 Debug - loadAll completado');
  }

  /// Carga desde caché local
  Future<void> _loadFromCache(String userId) async {
    try {
      print('🔍 Debug - _loadFromCache iniciado para userId: $userId');
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'historial_cache_$userId';
      final tsKey = 'historial_timestamp_$userId';
      
      final cachedJson = prefs.getString(cacheKey);
      final ts = prefs.getInt(tsKey) ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      print('🔍 Debug - Caché encontrado: ${cachedJson != null}');
      print('🔍 Debug - Timestamp caché: $ts');
      print('🔍 Debug - Timestamp actual: $nowMs');
      print('🔍 Debug - Diferencia: ${nowMs - ts} ms');

      // Caché válido por 15 minutos
      if (cachedJson != null && nowMs - ts < 900000) {
        print('🔍 Debug - Usando caché válido');
        final Map<String, dynamic> decoded = jsonDecode(cachedJson);
        
        for (final entry in decoded.entries) {
          final status = entry.key;
          final servicesJson = entry.value as List<dynamic>;
          
          _byStatus[status] = servicesJson
              .map((s) => ServiceRequest.fromSnapshot(s as Map<String, dynamic>))
              .toList();
          _lastUpdate[status] = DateTime.fromMillisecondsSinceEpoch(ts);
          
          print('🔍 Debug - Caché cargado para $status: ${_byStatus[status]?.length ?? 0} elementos');
        }
        
        notifyListeners();
      } else {
        print('🔍 Debug - Caché no válido o no encontrado');
      }
    } catch (e) {
      print('🔍 Debug - Error cargando caché: $e');
      debugPrint('Error cargando caché de historial: $e');
    }
  }

  /// Verifica si debe refrescar desde servidor
  bool _shouldRefreshFromServer(String userId) {
    print('🔍 Debug - _shouldRefreshFromServer evaluando...');
    print('🔍 Debug - _byStatus.isEmpty: ${_byStatus.isEmpty}');
    
    if (_byStatus.isEmpty) {
      print('🔍 Debug - Debe refrescar: _byStatus está vacío');
      return true;
    }
    
    final now = DateTime.now();
    for (final lastUpdate in _lastUpdate.values) {
      final difference = now.difference(lastUpdate).inMinutes;
      print('🔍 Debug - Diferencia desde último update: $difference minutos');
      if (difference > 15) {
        print('🔍 Debug - Debe refrescar: han pasado más de 15 minutos');
        return true;
      }
    }
    
    print('🔍 Debug - No debe refrescar: datos recientes');
    return false;
  }

  /// Carga desde servidor
  Future<void> _loadFromServer(String userId, String token, String deviceId) async {
    if (isRefreshing) return;
    
    isRefreshing = true;
    notifyListeners();

    try {
      // Cargar en paralelo con timeout
      final results = await Future.wait<List<ServiceRequest>>([
        _loadAvailableServices(userId, token),
        _loadOfferServices(userId, token, deviceId),
        _loadInProgressServices(userId, token),
        _loadCompletedServices(userId, token),
        _loadCancelledServices(userId, token),
      ]).timeout(const Duration(seconds: 30));

      _byStatus['available'] = _ordenarPorFecha(results[0]);
      _byStatus['offer'] = _ordenarPorFecha(results[1]);
      _byStatus['in_progress'] = _ordenarPorFecha(results[2]);
      _byStatus['completed'] = _ordenarPorFecha(results[3]);
      _byStatus['cancelled'] = _ordenarPorFecha(results[4]);

      print('🔍 Debug - _loadFromServer - Servicios guardados:');
      print('🔍 Debug - available: ${_byStatus['available']?.length ?? 0}');
      print('🔍 Debug - offer: ${_byStatus['offer']?.length ?? 0}');
      print('🔍 Debug - in_progress: ${_byStatus['in_progress']?.length ?? 0}');
      print('🔍 Debug - completed: ${_byStatus['completed']?.length ?? 0}');
      print('🔍 Debug - cancelled: ${_byStatus['cancelled']?.length ?? 0}');

      // Actualizar timestamps
      final now = DateTime.now();
      for (final status in _byStatus.keys) {
        _lastUpdate[status] = now;
      }

      // Guardar en caché
      await _saveToCache(userId);
      
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Error cargando historial: $e';
      debugPrint('Error cargando desde servidor: $e');
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }

  /// Carga servicios disponibles
  Future<List<ServiceRequest>> _loadAvailableServices(String userId, String token) async {
    try {
      print('🔍 Debug - _loadAvailableServices iniciado para userId: $userId');
      final result = await _repoAvailable.fetchServicesByStatus(
        'available', 'status', userId, token, []);
      print('🔍 Debug - _loadAvailableServices completado: ${result.length} elementos');
      return result;
    } catch (e) {
      print('🔍 Debug - Error en _loadAvailableServices: $e');
      debugPrint('Error en available: $e');
      return <ServiceRequest>[];
    }
  }

  /// Carga servicios ofertados
  Future<List<ServiceRequest>> _loadOfferServices(String userId, String token, String deviceId) async {
    try {
      print('🔍 Debug - _loadOfferServices iniciado para userId: $userId');
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
          serviceType: ServiceType(id: '', name: '', selectedDate: '', selectedTime: ''),
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
      print('🔍 Debug - _loadOfferServices completado: ${result.length} elementos');
      return result;
    } catch (e) {
      print('🔍 Debug - Error en _loadOfferServices: $e');
      debugPrint('Error en offer: $e');
      return <ServiceRequest>[];
    }
  }

  /// Carga servicios en progreso
  Future<List<ServiceRequest>> _loadInProgressServices(String userId, String token) async {
    try {
      print('🔍 Debug - Iniciando carga de servicios en progreso para userId: $userId');
      
      // Solo buscar servicios con estado in_progress para evitar duplicados
      final result = await _repoInProgress.fetchServicesByInProgress('in_progress', userId, 'status', token);
      
      print('🔍 Debug - Total de servicios en progreso encontrados: ${result.length}');
      
      for (int i = 0; i < result.length; i++) {
        final service = result[i];
        print('🔍 Debug - Servicio $i: ID=${service.id}, Status=${service.status.id}, WorkerId=${service.workerId}, Offers=${service.offers.length}');
      }
      
      return result;
    } catch (e) {
      debugPrint('Error en in_progress: $e');
      return <ServiceRequest>[];
    }
  }

  /// Carga servicios completados
  Future<List<ServiceRequest>> _loadCompletedServices(String userId, String token) async {
    try {
      print('🔍 Debug - _loadCompletedServices iniciado para userId: $userId');
      final result = await _repoComplete.fetchServicesByComplete('completed', userId, 'status', token);
      print('🔍 Debug - _loadCompletedServices completado: ${result.length} elementos');
      return result;
    } catch (e) {
      print('🔍 Debug - Error en _loadCompletedServices: $e');
      debugPrint('Error en completed: $e');
      return <ServiceRequest>[];
    }
  }

  /// Carga servicios cancelados
  Future<List<ServiceRequest>> _loadCancelledServices(String userId, String token) async {
    try {
      return await _repoCancelled.fetchServicesByCancelled('cancelled', userId, 'status', token);
    } catch (e) {
      debugPrint('Error en cancelled: $e');
      return <ServiceRequest>[];
    }
  }

  /// Guarda en caché local
  Future<void> _saveToCache(String userId) async {
    try {
      print('🔍 Debug - _saveToCache iniciado para userId: $userId');
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'historial_cache_$userId';
      final tsKey = 'historial_timestamp_$userId';
      
      final Map<String, dynamic> cacheData = {};
      for (final entry in _byStatus.entries) {
        cacheData[entry.key] = entry.value.map((s) => s.toMap()).toList();
        print('🔍 Debug - Guardando en caché para ${entry.key}: ${entry.value.length} elementos');
      }
      
      await prefs.setString(cacheKey, jsonEncode(cacheData));
      await prefs.setInt(tsKey, DateTime.now().millisecondsSinceEpoch);
      print('🔍 Debug - Caché guardado exitosamente');
    } catch (e) {
      print('🔍 Debug - Error guardando caché: $e');
      debugPrint('Error guardando caché de historial: $e');
    }
  }

  /// Configura actualización automática
  void _setupAutoRefresh(String userId, String token, String deviceId) {
    print('🔍 Debug - _setupAutoRefresh configurado para userId: $userId');
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      if (_currentUserId == userId) {
        print('🔍 Debug - Auto refresh ejecutado para userId: $userId');
        _loadFromServer(userId, token, deviceId);
      }
    });
  }

  /// Inicia la actualización automática (método público)
  void startAutoRefresh({
    required String userId,
    required String token,
    required String deviceId,
  }) {
    print('🔍 Debug - startAutoRefresh llamado para userId: $userId');
    _setupAutoRefresh(userId, token, deviceId);
  }

  /// Detiene la actualización automática
  void stopAutoRefresh() {
    print('🔍 Debug - stopAutoRefresh llamado');
    _autoRefreshTimer?.cancel();
  }

  /// Verifica si hay más datos para cargar (para paginación)
  bool hasMore(String status) {
    // Por ahora siempre retorna false ya que no implementamos paginación
    return false;
  }

  /// Verifica si está cargando más datos
  bool isLoadingMore(String status) {
    // Por ahora siempre retorna false ya que no implementamos paginación
    return false;
  }

  /// Carga más datos (para paginación)
  Future<void> loadMore({
    required String status,
    required String userId,
    required String token,
    required String deviceId,
  }) async {
    // Por ahora no hace nada ya que no implementamos paginación
    print('🔍 Debug - loadMore llamado para status: $status (no implementado)');
  }

  /// Refrescar manualmente
  Future<void> refresh({
    required String userId,
    required String token,
    required String deviceId,
  }) async {
    print('🔍 Debug - refresh llamado para userId: $userId');
    await _loadFromServer(userId, token, deviceId);
    print('🔍 Debug - refresh completado');
  }

  /// Limpia recursos
  @override
  void dispose() {
    print('🔍 Debug - dispose llamado');
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    print('🔍 Debug - notifyListeners llamado');
    super.notifyListeners();
  }
}