

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../constant/serviceConstants.dart';

import '../models/commentModdels.dart';
import '../models/service_requestModels.dart';
import '../models/worker_detailsModels.dart';
import '../request/ResponseGet.dart';

class ServiceDetailsProvider extends ChangeNotifier {
  final String serviceId;
  final String workerId;           // Worker asignado inicial (puede venir vacío)
  final ApiService2 apiService2;   // Instancia de ApiService

  bool _disposed = false;

  ServiceRequestModel? _service;
  WorkerDetailsModel? _workerDetails;
  bool _hasOffer = false;
  bool _hasInProgressOffer = false; // Nueva bandera
  List<CommentModel> _comments = [];
  String? _errorMessage;
  bool _isLoading = true;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _serviceSub;

  ServiceRequestModel? get service => _service;
  WorkerDetailsModel? get workerDetails => _workerDetails;
  bool get hasOffer => _hasOffer;
  bool get hasInProgressOffer => _hasInProgressOffer;
  List<CommentModel> get comments => List.unmodifiable(_comments);
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  ServiceDetailsProvider({
    required this.serviceId,
    required this.workerId,
    required this.apiService2,
  });

  Future<void> init() async {
    _isLoading = true;
    _notifyIfNeeded();

    // 1) Suscribirse al documento en Firestore
    final docRef = FirebaseFirestore.instance.collection('services').doc(serviceId);
    _serviceSub = docRef.snapshots().listen(
          (docSnap) {
        if (!docSnap.exists) {
          _setError('El servicio no existe.');
          return;
        }
        _parseService(docSnap);
      },
      onError: (e) {
        _setError('Error al escuchar el servicio: $e');
      },
    );

    // 2) Si workerId llegó no vacío, cargar detalles del trabajador
    if (workerId.isNotEmpty) {
      await _loadWorkerDetails();
    } else {
      _workerDetails = null;
    }

    // 3) Calcular si hay ofertas y ofertas en progreso
    await _computeHasOffer();
    await _computeHasInProgressOffer();

    _isLoading = false;
    _notifyIfNeeded();
  }

  void _parseService(DocumentSnapshot<Map<String, dynamic>> docSnap) {
    final nueva = ServiceRequestModel.fromDocument(docSnap);

    // 1) Actualizar lista de comentarios
    _comments = nueva.rawComments
        .map((c) => CommentModel.fromMap(Map<String, dynamic>.from(c)))
        .toList();

    // 2) Asignar el modelo
    _service = nueva;

    // 3) Si antes no había worker, pero ahora en el documento viene uno, recargar detalles
    if (workerId.isEmpty && nueva.workerId.isNotEmpty) {
      _loadWorkerDetails();
    }

    // 4) Recalcular si hay ofertas y ofertas en progreso
    _computeHasOffer();
    _computeHasInProgressOffer();

    _notifyIfNeeded();
  }

  Future<void> _loadWorkerDetails() async {
    final idToLoad = (workerId.isNotEmpty) ? workerId : (_service?.workerId ?? '');
    if (idToLoad.isEmpty) {
      _workerDetails = null;
      _notifyIfNeeded();
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('workers').doc(idToLoad).get();
      if (doc.exists) {
        _workerDetails = WorkerDetailsModel.fromMap(Map<String, dynamic>.from(doc.data()!));
      } else {
        _workerDetails = null;
      }
    } catch (e) {
      _setError('Error al cargar datos del trabajador: $e');
      _workerDetails = null;
    }
    _notifyIfNeeded();
  }

  Future<void> _computeHasOffer() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('serviceId', isEqualTo: serviceId)
          .where('hasOffer', isEqualTo: true)
          .limit(1)
          .get();
      _hasOffer = querySnapshot.docs.isNotEmpty;
    } catch (e) {
      _setError('Error al comprobar ofertas: $e');
      _hasOffer = false;
    }
    _notifyIfNeeded();
  }

  Future<void> _computeHasInProgressOffer() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('serviceId', isEqualTo: serviceId)
          .where('status', isEqualTo: 'in_progress')
          .limit(1)
          .get();
      _hasInProgressOffer = querySnapshot.docs.isNotEmpty;
    } catch (e) {
      _setError('Error al comprobar ofertas en progreso: $e');
      _hasInProgressOffer = false;
    }
    _notifyIfNeeded();
  }


  Future<void> acceptProposal(String selectedWorkerId) async {
    if (_service == null) {
      _setError('Servicio no cargado.');
      return;
    }

    try {
      // 1) Primero, PATCH al documento de servicio vía API
      await apiService2.updateService(serviceId, {
        'status': 'in_progress',
        'hasOffer': false,
        'workerId': selectedWorkerId,
      });
      null;

      // 2) A continuación, buscamos TODAS las ofertas activas (hasOffer == true)
      //    de este mismo serviceId:
      final snapshotTodas = await FirebaseFirestore.instance
          .collection('offers')
          .where('serviceId', isEqualTo: serviceId)
          .where('hasOffer', isEqualTo: true)
          .get();

      // 3) Recorremos cada documento: si coincide con el worker elegido, lo ponemos "in_progress";
      //    si NO coincide, lo marcamos como "cancelled" (o simplemente hasOffer = false).
      for (final doc in snapshotTodas.docs) {
        final data = doc.data();
        final workerDeEstaOferta = data['workerId'] as String;
        final ref = doc.reference;

        if (workerDeEstaOferta == selectedWorkerId) {
          // 3.a) Esta es la oferta que aceptaste: la ponemos en progreso
          await ref.update({
            'status': ServiceStatus.inProgress,
            'hasOffer': false,
          });
          null;
        } else {
          // 3.b) Esta es cualquier otra oferta que NO elegimos: la cancelamos
          await ref.update({
            'status': ServiceStatus.cancelled,
            'hasOffer': false,
          });
          null;
        }
      }
    } catch (e) {
      _setError('Error al aceptar propuesta: $e');
    }

    // 4) Por último, recalculamos ambas banderas para refrescar la UI:
    await _computeHasOffer();
    await _computeHasInProgressOffer();
  }

  /// 2) Cancelar el servicio y sus ofertas:
  ///    - PATCH /services/{serviceId} vía API REST
  ///    - UPDATE en Firestore de cada oferta de este serviceId (status=cancelled)
  Future<void> cancelService() async {
    if (_service == null) {
      _setError('Servicio no cargado.');
      return;
    }

    try {
      // 2.a) PATCH al servicio vía API REST
      await apiService2.updateService(serviceId, {
        'status': ServiceStatus.cancelled,
        'hasOffer': false,
      });
      null;

      // 2.b) Obtener todas las ofertas vinculadas y cancelarlas en Firestore
      final ofertasSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('serviceId', isEqualTo: serviceId)
          .get();

      for (final doc in ofertasSnapshot.docs) {
        final offerId = doc.id;
        await FirebaseFirestore.instance.collection('offers').doc(offerId).update({
          'status': ServiceStatus.cancelled,
        });
        null;
      }
    } catch (e) {
      _setError('Error al cancelar servicio/ofertas: $e');
    }

    // 2.c) Recalcular si quedan ofertas activas y en progreso
    await _computeHasOffer();
    await _computeHasInProgressOffer();
  }

  Future<void> addComment(String texto) async {
    if (_service == null) {
      _setError('Servicio no cargado.');
      return;
    }

    try {
      // Llamada al backend REST — el servidor valida, determina nombre/rol
      // y escribe en Firestore con arrayUnion. El stream de Firestore detecta
      // el cambio y actualiza la UI en tiempo real automaticamente.
      await apiService2.postServiceComment(
        serviceId,
        {'mensaje': texto},
      );
    } catch (e) {
      _setError('Error al agregar comentario: $e');
    }
    _notifyIfNeeded();
  }

  Future<String?> getWhatsAppUrl() async {
    if (_workerDetails == null || _workerDetails!.phoneNumber.isEmpty) {
      _setError('El trabajador no tiene número de WhatsApp disponible.');
      return null;
    }
    final name = _workerDetails!.displayName;
    final phone = _workerDetails!.phoneNumber;
    final url =
        'https://wa.me/$phone?text=Hola $name, soy el cliente del trabajo desde ManitosXpress.';
    return url;
  }

  void _setError(String mensaje) {
    _errorMessage = mensaje;
    _notifyIfNeeded();
  }

  void _notifyIfNeeded() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _serviceSub?.cancel();
    super.dispose();
    }
}
