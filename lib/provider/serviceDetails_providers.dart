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

/// Provider que gestiona estado, lecturas y escrituras para un ServiceRequest.
/// - Se suscribe a Firestore para actualizaciones en tiempo real.
/// - Expone datos listos para la UI.
/// - Maneja operaciones: aceptar propuesta, cancelar servicio, agregar comentario.
// lib/providers/service_details_provider.dart
/// Provider que maneja toda la lógica de Firestore para ServiceRequest:
/// - Se suscribe a "services/{serviceId}".
/// - Expone ServiceRequestModel y WorkerDetailsModel.
/// - Maneja aceptar propuesta, cancelar servicio, agregar comentario, etc.
class ServiceDetailsProvider extends ChangeNotifier {
  final String serviceId;
  final String workerId; // Puede ser cadena vacía si aún no hay worker asignado
  bool _disposed = false;

  ServiceRequestModel? _service;
  WorkerDetailsModel? _workerDetails;
  bool _hasOffer = false;
  List<CommentModel> _comments = [];
  String? _errorMessage;
  bool _isLoading = true;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _serviceSub;

  ServiceRequestModel? get service => _service;
  WorkerDetailsModel? get workerDetails => _workerDetails;
  bool get hasOffer => _hasOffer;
  List<CommentModel> get comments => List.unmodifiable(_comments);
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  ServiceDetailsProvider({
    required this.serviceId,
    required this.workerId,
  });

  Future<void> init() async {
    _isLoading = true;
    _notifyIfNeeded();

    // 1) Suscribirse al documento de servicio en tiempo real
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

    // 2) Si workerId no está vacío, cargar detalles del trabajador
    if (workerId.isNotEmpty) {
      await _loadWorkerDetails();
    } else {
      _workerDetails = null;
    }

    // 3) Calcular si hay ofertas inicialmente
    await _computeHasOffer();

    _isLoading = false;
    _notifyIfNeeded();
  }

  void _parseService(DocumentSnapshot<Map<String, dynamic>> docSnap) {
    final nueva = ServiceRequestModel.fromDocument(docSnap);

    // Actualizar comentarios embebidos
    _comments = nueva.rawComments
        .map((c) => CommentModel.fromMap(Map<String, dynamic>.from(c)))
        .toList();

    // Asignar el modelo
    _service = nueva;

    // Si workerId estaba vacío pero en el documento recién llegó un workerId válido, cargar detalles
    if (workerId.isEmpty && nueva.workerId.isNotEmpty) {
      // Carga detalles de trabajador si ahora hay uno asignado
      _loadWorkerDetails();
    }

    // Cada vez que cambia el documento principal, recalcular si hay ofertas
    _computeHasOffer();

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

  Future<void> acceptProposal() async {
    if (_service == null) {
      _setError('Servicio no cargado.');
      return;
    }

    try {
      // 1) Actualizar servicio
      await FirebaseFirestore.instance.collection('services').doc(serviceId).update({
        'status': ServiceStatus.inProgress,
        'hasOffer': false,
        'workerId': workerId,
      });

      // 2) Actualizar oferta específica
      final ofertasSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('serviceId', isEqualTo: serviceId)
          .where('workerId', isEqualTo: workerId)
          .limit(1)
          .get();
      if (ofertasSnapshot.docs.isNotEmpty) {
        final offerDocRef = ofertasSnapshot.docs.first.reference;
        await offerDocRef.update({
          'status': ServiceStatus.inProgress,
          'hasOffer': false,
        });
      } else {
        _setError('No se encontró la oferta del trabajador.');
      }
    } catch (e) {
      _setError('Error al aceptar propuesta: $e');
    }
    await _computeHasOffer();
  }

  Future<void> cancelService() async {
    if (_service == null) {
      _setError('Servicio no cargado.');
      return;
    }

    try {
      // 1) Actualizar estado de servicio
      await FirebaseFirestore.instance.collection('services').doc(serviceId).update({
        'status': ServiceStatus.cancelled,
      });

      // 2) Cancelar todas las ofertas asociadas
      final ofertasSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('serviceId', isEqualTo: serviceId)
          .get();
      for (final doc in ofertasSnapshot.docs) {
        await doc.reference.update({'status': ServiceStatus.cancelled});
      }
    } catch (e) {
      _setError('Error al cancelar servicio/ofertas: $e');
    }
    await _computeHasOffer();
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
        // Verificar si existe en "users/{uid}"
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          rol = 'cliente';
          nombre = userDoc.data()?['displayName'] as String? ?? 'Cliente';
        } else {
          // Verificar en "workers/{uid}"
          final workerDoc = await FirebaseFirestore.instance.collection('workers').doc(currentUser.uid).get();
          if (workerDoc.exists) {
            rol = 'trabajador';
            nombre = workerDoc.data()?['displayName'] as String? ?? 'Trabajador';
          }
        }
      }

      final now = TimeOfDay.now();
      final hora = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final nuevoComentario = CommentModel(
        nombre: nombre,
        mensaje: texto,
        hora: hora,
        rol: rol,
      );

      _comments.add(nuevoComentario);
      final commentsMapList = _comments.map((c) => c.toMap()).toList(growable: false);

      await FirebaseFirestore.instance.collection('services').doc(serviceId).update({
        'comments': commentsMapList,
      });
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
    final url = 'https://wa.me/$phone?text=Hola $name, soy el cliente del trabajo desde ManitosXpress.';
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
