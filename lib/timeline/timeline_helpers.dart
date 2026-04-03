import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/service_requestModels.dart';
import '../provider/serviceDetails_providers.dart';
import '../widgets/commentButtonWidget.dart';

class TimelineHelpers {
  static Future<double?> getOfferedPrice(ServiceRequestModel serviceData, String workerId) async {
    double? workerOfferedPrice;
    
    // Debug: Imprimir información para diagnosticar
    null;
    null;
    null;
    null;
    null;
    
    // Intentar obtener el precio desde rawOffers primero
    if (serviceData.rawOffers.isNotEmpty) {
      // Buscar la oferta que coincida con el workerId
      try {
        final anyOffer = serviceData.rawOffers.firstWhere(
          (o) => o['workerId'] == workerId,
        );
        
        null;
        null;
        
        if (anyOffer.isNotEmpty) {
          workerOfferedPrice = (anyOffer['offeredPrice'] as num?)?.toDouble();
          null;
        }
      } catch (e) {
        null;
      }
    }
    
    // Si no se encontró con workerId específico, intentar con la primera oferta disponible
    if (workerOfferedPrice == null && serviceData.rawOffers.isNotEmpty) {
      final firstOffer = serviceData.rawOffers.first;
      workerOfferedPrice = (firstOffer['offeredPrice'] as num?)?.toDouble();
      null;
    }
    
    // Si aún no hay precio, intentar obtenerlo desde la colección offers en Firestore
    if (workerOfferedPrice == null) {
      try {
        null;
        final offersSnapshot = await FirebaseFirestore.instance
            .collection('offers')
            .where('serviceId', isEqualTo: serviceData.id)
            .get();
        
        null;
        
        if (offersSnapshot.docs.isNotEmpty) {
          // Buscar la oferta que coincida con el workerId
          QueryDocumentSnapshot<Map<String, dynamic>>? matchingOffer;
          
          for (final doc in offersSnapshot.docs) {
            final data = doc.data();
            null;
            if (data['workerId'] == workerId) {
              matchingOffer = doc;
              null;
              break;
            }
          }
          
          // Si no se encontró coincidencia, usar la primera
          if (matchingOffer == null) {
            matchingOffer = offersSnapshot.docs.first;
            null;
          }
          
          final offerData = matchingOffer.data();
          workerOfferedPrice = (offerData['offeredPrice'] as num?)?.toDouble();
          null;
          null;
        }
      } catch (e) {
        null;
      }
    }
    
    // Si aún no hay precio, intentar obtenerlo desde el documento del servicio directamente
    if (workerOfferedPrice == null) {
      try {
        null;
        final serviceDoc = await FirebaseFirestore.instance
            .collection('services')
            .doc(serviceData.id)
            .get();
        
        if (serviceDoc.exists) {
          final serviceData = serviceDoc.data();
          workerOfferedPrice = (serviceData?['offeredPrice'] as num?)?.toDouble();
          null;
        }
      } catch (e) {
        null;
      }
    }
    
    // Para servicios en progreso, también buscar en ofertas con status 'in_progress'
    if (workerOfferedPrice == null && serviceData.status == 'in_progress') {
      try {
        null;
        final offersSnapshot = await FirebaseFirestore.instance
            .collection('offers')
            .where('serviceId', isEqualTo: serviceData.id)
            .where('status', isEqualTo: 'in_progress')
            .get();
        
        null;
        
        if (offersSnapshot.docs.isNotEmpty) {
          final offerData = offersSnapshot.docs.first.data();
          workerOfferedPrice = (offerData['offeredPrice'] as num?)?.toDouble();
          null;
        }
      } catch (e) {
        null;
      }
    }
    
    null;
    null;

    return workerOfferedPrice;
  }

  static void showImageDialog(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A819A),
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1A819A),
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error al cargar imagen',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A819A),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(
                      fontFamily: 'Xpress Heavy',
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showCommentsModal(BuildContext context, ServiceDetailsProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return CommentsBottomSheet(provider: provider);
      },
    );
  }
} 