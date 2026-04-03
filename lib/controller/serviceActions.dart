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
      null;
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
      null;
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
      null;
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
      null;
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
      null;
    }
  }
}