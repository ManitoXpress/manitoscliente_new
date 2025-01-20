import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ServicesResponse/resquest.dart';

class LocalCacheService {
  static Future<void> cacheServiceRequest(ServiceRequest serviceRequest) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String serviceRequestKey = 'service_request_${serviceRequest.id}';
      final String serviceRequestJson = jsonEncode(serviceRequest.toMap());
      await prefs.setString(serviceRequestKey, serviceRequestJson);
    } catch (e) {
      print('Error al cachear el servicio: $e');
    }
  }

  static Future<ServiceRequest?> getCachedServiceRequest(String serviceRequestId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String serviceRequestKey = 'service_request_$serviceRequestId';
      final String? serviceRequestJson = prefs.getString(serviceRequestKey);
      if (serviceRequestJson != null) {
        final Map<String, dynamic> serviceRequestMap = jsonDecode(serviceRequestJson);
        return ServiceRequest.fromSnapshot(serviceRequestMap);

      }
    } catch (e) {
      print('Error al obtener el servicio del caché: $e');
    }
    return null;
  }
}
