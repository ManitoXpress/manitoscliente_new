// ---------- service_form_controller.dart ----------
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:manitoscliente_new/request/ResponsePost.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';


class ServiceFormController extends ChangeNotifier {
  final String serviceId;
  final String workerId;
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;

  // Estado interno
  String _currentStatus;
  bool _hasOffer = false;
  double? _workerOfferedPrice;

  // Getters públicos
  String get currentStatus   => _currentStatus;
  bool   get hasOffer        => _hasOffer;
  double? get workerOfferedPrice => _workerOfferedPrice;

  ServiceFormController({
    required this.serviceId,
    required this.workerId,
    FirebaseFirestore? firestore,
    FirebaseMessaging? messaging,
    String initialStatus = 'available',
  })  : _firestore     = firestore  ?? FirebaseFirestore.instance,
        _messaging     = messaging  ?? FirebaseMessaging.instance,
        _currentStatus = initialStatus;

  /// Inicia el stream y carga datos iniciales
  void init() {
    _subscription = _firestore
        .collection('services')
        .doc(serviceId)
        .snapshots()
        .listen(_onServiceUpdated);

    _fetchWorkerOffer();
    updateFcmToken();
  }

  Future<void> _onServiceUpdated(DocumentSnapshot<Map<String, dynamic>> snap) async {
    if (!snap.exists) return;
    final data = snap.data()!;
    final newStatus = data['status'] as String? ?? _currentStatus;
    if (newStatus != _currentStatus) {
      _currentStatus = newStatus;
      notifyListeners();
    }

    final has = await _checkHasOffers();
    if (has != _hasOffer) {
      _hasOffer = has;
      notifyListeners();
    }
  }

  Future<void> _fetchWorkerOffer() async {
    final query = await _firestore
      .collection('offers')
      .where('serviceId', isEqualTo: serviceId)
      .where('workerId', isEqualTo: workerId)
      .limit(1)
      .get();

    if (query.docs.isNotEmpty) {
      final val = query.docs.first.data()['offeredPrice'];
      final price = (val is num) ? val.toDouble() : null;
      if (price != _workerOfferedPrice) {
        _workerOfferedPrice = price;
        notifyListeners();
      }
    }
  }

  Future<bool> _checkHasOffers() async {
    final query = await _firestore
      .collection('offers')
      .where('serviceId', isEqualTo: serviceId)
      .where('hasOffer', isEqualTo: true)
      .limit(1)
      .get();
    return query.docs.isNotEmpty;
  }

  /// Actualiza el token FCM en el backend sólo si cambió
  Future<void> updateFcmToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('fcm_token');
    if (token != saved) {
      try {
        final auth = await user.getIdToken();
        await ApiService().updateFcmToken(user.uid, auth!, token);
        await prefs.setString('fcm_token', token);
      } catch (_) {
        // podrías loguear el error
      }
    }
  }

  /// Acepta la propuesta del worker
  Future<void> acceptProposal() async {
    // Actualiza servicio
    await _firestore.collection('services').doc(serviceId).update({
      'status': 'in_progress',
      'hasOffer': false,
      'workerId': workerId,
    });
    // Actualiza oferta específica
    final offers = await _firestore
      .collection('offers')
      .where('serviceId', isEqualTo: serviceId)
      .where('workerId', isEqualTo: workerId)
      .limit(1)
      .get();
    if (offers.docs.isNotEmpty) {
      await offers.docs.first.reference.update({
        'status': 'in_progress',
        'hasOffer': false,
      });
    }
  }

  /// Cancela la oferta sin afectar otros campos
  Future<void> cancelOffer() async {
    await _firestore.collection('offers').doc(serviceId).set(
      {'status': 'cancelled'},
      SetOptions(merge: true),
    );
    await _firestore.collection('services').doc(serviceId).set(
      {'status': 'available', 'offeredPrice': 0},
      SetOptions(merge: true),
    );
  }

  /// Cancela el servicio por completo
  Future<void> cancelService() async {
    await _firestore
      .collection('services')
      .doc(serviceId)
      .update({'status': 'cancelled'});
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
