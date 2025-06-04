// lib/models/service_request_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:manitoscliente_new/models/expertise_models.dart';
// lib/models/service_request_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';


class ServiceRequestModel {
  final String id;
  final String status;
  final String date; // e.g. "2025-06-15"
  final String time; // e.g. "14:30"
  final String description;
  final Map<String, dynamic> location; // {'lat': double, 'lng': double}
  final List<String> images;
  final List<ExpertiseModel> expertises;
  final List<Map<String, dynamic>> rawOffers;   // si en el documento hay un array "offers"
  final List<Map<String, dynamic>> rawComments; // campo "comments"
  final String userId;
  final String workerId;
  final String? completionImageUrl;

  ServiceRequestModel({
    required this.id,
    required this.status,
    required this.date,
    required this.time,
    required this.description,
    required this.location,
    required this.images,
    required this.expertises,
    required this.rawOffers,
    required this.rawComments,
    required this.userId,
    required this.workerId,
    this.completionImageUrl,
  });

  factory ServiceRequestModel.fromDocument(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final rawExp = data['expertises'] as List<dynamic>? ?? [];
    final expertises = rawExp
        .map((e) => ExpertiseModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    final locMap = data['location'] as Map<String, dynamic>? ?? {
      'lat': 0.0,
      'lng': 0.0,
    };
    final imgs = (data['images'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList();
    final rawOffers = (data['offers'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final rawComments = (data['comments'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return ServiceRequestModel(
      id: doc.id,
      status: data['status'] as String? ?? '',
      date: data['date'] as String? ?? '',
      time: data['time'] as String? ?? '',
      description: data['description'] as String? ?? '',
      location: {
        'lat': (locMap['lat'] as num?)?.toDouble() ?? 0.0,
        'lng': (locMap['lng'] as num?)?.toDouble() ?? 0.0,
      },
      images: imgs,
      expertises: expertises,
      rawOffers: rawOffers,
      rawComments: rawComments,
      userId: data['userId'] as String? ?? '',
      workerId: data['workerId'] as String? ?? '',
      completionImageUrl: data['completionImageUrl'] as String?,
    );
  }
}
