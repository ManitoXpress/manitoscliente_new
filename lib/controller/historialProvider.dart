import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:manitoscliente_new/controller/serviceFetcher.dart';
import 'package:manitoscliente_new/request/ResponseGet.dart';
import 'package:manitoscliente_new/request/ResponsePost.dart';
import 'package:manitoscliente_new/request/requestExpertise.dart';
import 'package:manitoscliente_new/request/requestServiceType.dart';
import 'package:manitoscliente_new/request/requestStatus.dart';
import 'package:manitoscliente_new/request/resquest.dart';
import 'package:manitoscliente_new/utils/offerRepository.dart';
import 'package:manitoscliente_new/utils/serviceCancelled.dart';
import 'package:manitoscliente_new/utils/serviceComplete.dart';
import 'package:manitoscliente_new/utils/serviceFetcher.dart';
import 'package:manitoscliente_new/utils/serviceInProgress.dart';

class HistorialProvider extends ChangeNotifier {
  // Repositorios
  final ServiceRepository _repoAvailable;
  final OfferRepository _repoOffer;
  final ServiceRepositoryInProgress _repoInProgress;
  final ServiceRepositoryComplete _repoComplete;
  final ServiceRepositoryCancelled _repoCancelled;

  // Estado
  bool isLoading = false;
  String? errorMessage;
  final Map<String, List<ServiceRequest>> _byStatus = {};

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
    lista.sort((a, b) {
      final aDate = a.createdAt;
      final bDate = b.createdAt;
      return bDate.compareTo(aDate); // Descendente: más reciente primero
    });
    return lista;
  }


  /// Devuelve la lista para cada estado
  List<ServiceRequest> list(String status) => _byStatus[status] ?? [];

  int get availableCount => list('available').length;
  int get offerServiceCount => list('offer').expand((s) => s.offers).length;
  int get inProgressCount => list('in_progress').length;
  int get completedCount => list('completed').length;
  int get cancelledCount => list('cancelled').length;

  /// Carga todo el historial de una vez
  Future<void> loadAll({
    required String userId,
    required String token,
    required String deviceId,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    // 1) Disponibles
    final availableFut = _repoAvailable.fetchServicesByStatus(
        'available', 'status', userId, token, []).catchError((e, _) {
      debugPrint('Error en available: $e');
      return <ServiceRequest>[];
    });

    // 2) Ofertados  (filtrando por workerId)
    final offerFut = _repoOffer
        .fetchOffersForUser(
      'offer', // valor de status
      userId, // workerId
      token,
      ServiceRequest(
        id: '',
        serviceDateTime: '',
        description: '',
        images: [],
        location: {},
        offeredPrice: 0.0,
        serviceType: ServiceType(
          id: '',
          name: '',
          selectedDate: '',
          selectedTime: '',
        ),
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
    )
        .catchError((e, _) {
      debugPrint('Error en offer: $e');
      return <ServiceRequest>[];
    });

    // 3) En progreso → combinamos tres estados
// 3) En progreso → combinamos tres estados SIN tocar el repo
    final estados = [
      'in_progress',
      'pending_confirmation',
      'pending_confirmation2',
    ];

    final inProgressFut = Future.wait(
      estados.map((st) => _repoInProgress
          .fetchServicesByInProgress(
        st, // un status cada vez
        userId,
        'status',
        token,
      )
          .catchError((e, _) {
        debugPrint('Error en $st: $e');
        return <ServiceRequest>[];
      })),
    ).then((listas) {
      // listas es List<List<ServiceRequest>> → lo aplanamos
      return listas.expand((l) => l).toList();
    });

    // 4) Completados
    final completedFut = _repoComplete.fetchServicesByComplete(
      'completed',   // 1) status
      userId,        // 2) userId
      'status',      // 3) column ← este te faltaba
      token,         // 4) token

    )

    .catchError((e, _) {
      debugPrint('Error en completed: $e');
      return <ServiceRequest>[];
    });


    // 5) Cancelados
    final cancelledFut = _repoCancelled.fetchServicesByCancelled(
      'cancelled',   // 1) status
      userId,        // 2) userId
      'status',      // 3) column ← este te faltaba
      token,         // 4) token

    ).catchError((e, _) {
      debugPrint('Error en cancelled: $e');
      return <ServiceRequest>[];
    });

    try {
      final results = await Future.wait<List<ServiceRequest>>([
        availableFut,
        offerFut,
        inProgressFut,
        completedFut,
        cancelledFut,
      ]);

      _byStatus['available'] = _ordenarPorFecha(results[0]);
      _byStatus['offer'] = _ordenarPorFecha(results[1]);
      _byStatus['in_progress'] = _ordenarPorFecha(results[2]);
      _byStatus['completed'] = _ordenarPorFecha(results[3]);
      _byStatus['cancelled'] = _ordenarPorFecha(results[4]);
    } catch (e, st) {
      errorMessage = 'Error cargando historial';
      debugPrint('loadAll fallo inesperado: $st');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Refrescar (llama de nuevo a loadAll)
  Future<void> refresh({
    required String userId,
    required String token,
    required String deviceId,
  }) =>
      loadAll(userId: userId, token: token, deviceId: deviceId);
}