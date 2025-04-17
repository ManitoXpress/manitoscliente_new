import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceActions {
  Future<void> confirmCompletion(String serviceId, Function(String) onStatusChanged) async {
    try {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(serviceId)
          .update({'status': 'completed'});

      onStatusChanged('completed');
    } catch (e) {
      print('Error al confirmar la finalización del trabajo: $e');
    }
  }

  Future<void> rejectCompletion(String serviceId, Function(String) onStatusChanged) async {
    try {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(serviceId)
          .update({'status': 'in_progress'});

      onStatusChanged('in_progress');
    } catch (e) {
      print('Error al rechazar la finalización del trabajo: $e');
    }
  }

  Future<void> acceptProposal(String serviceId, Function(String) onStatusChanged) async {
    try {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(serviceId)
          .update({'status': 'in_progress'});

      onStatusChanged('in_progress');
    } catch (e) {
      print('Error al aceptar la propuesta: $e');
    }
  }

  Future<void> blockUserParticipation(String serviceId, String workerId, Function(String) onStatusChanged, VoidCallback onComplete) async {
    try {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(serviceId)
          .update({
        'blockedUsers': FieldValue.arrayUnion([workerId])
      });

      onStatusChanged('blocked');
      onComplete();
    } catch (e) {
      print('Error al bloquear la participación del usuario: $e');
    }
  }

  Future<void> updateServiceStatus(String serviceId, String status, Function(String) onStatusChanged, String errorMessage) async {
    try {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(serviceId)
          .update({'status': status});

      onStatusChanged(status);
    } catch (e) {
      print('$errorMessage: $e');
    }
  }
}