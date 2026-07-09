import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Styles/stilo.dart';
import '../controller/serviceFetcher.dart';
import '../provider/serviceDetails_providers.dart';
import '../request/ResponseGet.dart';
import '../request/ResponsePost.dart'; // Añadido
import '../request/dataprofile.dart';
import '../request/resquest.dart';
import '../utils/timeLines.dart';

class ServiceListBuilder {
  static Widget buildGlassmorphicList(
    List<ServiceRequest> services,
    double screenWidth,
    double screenHeight,
    String userId,
    UserData userData,
    ApiService apiService,
  ) {
    if (services.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return _GlassmorphicServiceCard(
            service: service,
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            userId: userId,
            userData: userData,
            apiService: apiService,
          );
        },
      ),
    );
  }
}

class _GlassmorphicServiceCard extends StatelessWidget {
  final ServiceRequest service;
  final double screenWidth;
  final double screenHeight;
  final String userId;
  final UserData userData;
  final ApiService apiService;

  const _GlassmorphicServiceCard({
    required this.service,
    required this.screenWidth,
    required this.screenHeight,
    required this.userId,
    required this.userData,
    required this.apiService,
  });

  void _navigateToDetails(BuildContext context, {String? workerId, bool workerInfoOnly = false}) {
    // Para servicios disponibles, no hay worker final. Usamos service.workerId o un fallback.
    final targetWorkerId = workerId ?? (service.workerId.isNotEmpty ? service.workerId : 'unknown_worker');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return ChangeNotifierProvider<ServiceDetailsProvider>(
            create: (_) {
              final prov = ServiceDetailsProvider(
                serviceId: service.id,
                workerId: targetWorkerId,
                apiService2: ApiService2(),
              );
              prov.init();
              return prov;
            },
            child: ServiceFormWithTimeline(
              serviceId: service.id,
              initialStatus: service.status.id,
              onComplete: (status) => null,
              onStatusChanged: (newStatus) => null,
              userData: userData,
              workerId: targetWorkerId,
              apiService: apiService,
              userId: userId,
              workerInfoOnly: workerInfoOnly,
            ),
          );
        },
      ),
    );
  }

  void _cancelService(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar solicitud'),
        content: const Text('¿Estás seguro de que deseas cancelar esta solicitud?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await apiService.updateService(
          serviceId: service.id,
          data: {'status': 'cancelled', 'hasOffer': false},
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Servicio cancelado exitosamente'), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cancelar el servicio'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = service.status.id == 'available' || service.status.id == 'offer';
    
    // Obtener precio si hay
    String priceText = 'Bs. 0.00';
    if (service.offeredPrice > 0) {
      priceText = 'Bs. ${service.offeredPrice.toStringAsFixed(2)}';
    } else if (service.offers.isNotEmpty) {
      priceText = 'Bs. ${service.offers.first.offeredPrice.toStringAsFixed(2)}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
          BoxShadow(
            color: const Color(0xFF1A819A).withOpacity(0.02),
            offset: const Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera: Etiqueta de estado y logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Categoría:',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            service.subcategoryName.isNotEmpty ? service.subcategoryName : 'Servicio general',
                            style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Servicio:',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            service.expertises.map((e) => e.name).join(', ').isNotEmpty 
                              ? service.expertises.map((e) => e.name).join(', ') 
                              : 'Por definir',
                            style: const TextStyle(color: Colors.black87, fontSize: 14, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/animations/manito.png', 
                          height: 30,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.handyman, color: Colors.green[700]),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                
                // Precio Base
                Row(
                  children: [
                    Text(
                      'Precio Ofertado base:',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A819A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        priceText,
                        style: const TextStyle(color: Color(0xFF1A819A), fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Botones principales
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _navigateToDetails(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1A819A),
                          side: const BorderSide(color: Color(0xFF1A819A)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Ver detalles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                    if (isPending) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _cancelService(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Cancelar solicitud', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
                        ),
                      ),
                    ],
                  ],
                ),
                
                // Offers list expansion (Solo visible si hay ofertas y está en espera)
                if (service.offers.isNotEmpty && isPending) ...[
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.1)),
                    ),
                    child: ExpansionTile(
                      shape: const Border(),
                      title: Text(
                        'Ver ofertas recibidas (${service.offers.length})',
                        style: const TextStyle(
                          color: Color(0xFF1A819A), 
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      iconColor: const Color(0xFF1A819A),
                      collapsedIconColor: const Color(0xFF1A819A),
                      children: service.offers.map((offer) {
                        return Container(
                          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Oferta propuesta',
                                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]),
                                  ),
                                  Text(
                                    'Bs. ${offer.offeredPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _navigateToDetails(context, workerId: offer.workerId, workerInfoOnly: true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(0xFF1A819A),
                                        elevation: 0,
                                        side: BorderSide(color: Colors.grey[300]!),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('Info trabajador', style: TextStyle(fontSize: 12)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _navigateToDetails(context, workerId: offer.workerId),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1A819A),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('Aceptar oferta', style: TextStyle(fontSize: 12)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}