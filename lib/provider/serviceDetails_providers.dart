// lib/providers/service_details_provider.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:manitoscliente_new/models/comment_models.dart';
import 'package:manitoscliente_new/models/service_requestModels.dart';
import 'package:manitoscliente_new/models/worker_detailsModels.dart';
import 'package:manitoscliente_new/constants/service_constants.dart';
import 'package:manitoscliente_new/request/ResponseGet.dart';

/// Provider que gestiona estado, lecturas y escrituras para un ServiceRequest.
/// - Se suscribe a Firestore para actualizaciones en tiempo real.
/// - Expone datos listos para la UI.
/// - Maneja operaciones: aceptar propuesta, cancelar servicio, agregar comentario.
// lib/providers/service_details_provider.dart
/// Provider que maneja toda la lógica de Firestore para ServiceRequest:
/// - Se suscribe a "services/{serviceId}".
/// - Expone ServiceRequestModel y WorkerDetailsModel.
/// - Maneja aceptar propuesta, cancelar servicio, agregar comentario, etc.
// service_details_provider.dart


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

  /// 1) Aceptar la propuesta para el [selectedWorkerId]:
  ///    - PATCH /services/{serviceId} vía API REST
  ///    - UPDATE solo en Firestore la oferta que coincida con serviceId + selectedWorkerId
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
    print(
      '✅ Servicio ($serviceId) actualizado a in_progress con workerId=$selectedWorkerId'
    );

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
        print('✅ Oferta (${doc.id}) marcada como in_progress.');
      } else {
        // 3.b) Esta es cualquier otra oferta que NO elegimos: la cancelamos
        await ref.update({
          'status': ServiceStatus.cancelled,
          'hasOffer': false,
        });
        print('— Oferta (${doc.id}) cancelada (no fue elegida).');
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
      print('✅ Servicio ($serviceId) patched a cancelled vía API');

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
        print('✅ Oferta ($offerId) cancelada en Firestore');
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
      // Determinar rol y nombre del usuario actual
      final currentUser = FirebaseAuth.instance.currentUser;
      String rol = 'desconocido';
      String nombre = 'Anónimo';

      if (currentUser != null) {
        // Verificar en “users/{uid}”
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        if (userDoc.exists) {
          rol = 'cliente';
          nombre = userDoc.data()?['displayName'] as String? ?? 'Cliente';
        } else {
          // Verificar en “workers/{uid}”
          final workerDoc = await FirebaseFirestore.instance
              .collection('workers')
              .doc(currentUser.uid)
              .get();
          if (workerDoc.exists) {
            rol = 'trabajador';
            nombre =
                workerDoc.data()?['displayName'] as String? ?? 'Trabajador';
          }
        }
      }

      final now = TimeOfDay.now();
      final hora =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final nuevoComentario = CommentModel(
        nombre: nombre,
        mensaje: texto,
        hora: hora,
        rol: rol,
      );

      _comments.add(nuevoComentario);
      final commentsMapList =
          _comments.map((c) => c.toMap()).toList(growable: false);

      // Actualizar directamente el array “comments” en Firestore
      await FirebaseFirestore.instance
          .collection('services')
          .doc(serviceId)
          .update({'comments': commentsMapList});
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
