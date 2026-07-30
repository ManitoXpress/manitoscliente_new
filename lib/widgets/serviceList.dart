import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controller/auth_utils.dart';

import '../provider/providerService.dart';
import '../request/ResponseGet.dart';
import '../request/ResponsePost.dart'; // Añadido
import '../request/dataprofile.dart';
import '../request/resquest.dart';
import '../utils/timeLines.dart';
import 'workerInfoCard.dart';

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

class _GlassmorphicServiceCard extends StatefulWidget {
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

  @override
  State<_GlassmorphicServiceCard> createState() => _GlassmorphicServiceCardState();
}

class _GlassmorphicServiceCardState extends State<_GlassmorphicServiceCard> {
  // Alias para acceder a los campos del widget sin repetir widget.x en el build
  ServiceRequest get service => widget.service;
  String get userId => widget.userId;
  UserData get userData => widget.userData;
  ApiService get apiService => widget.apiService;

  void _navigateToDetails(BuildContext context, {String? workerId, bool workerInfoOnly = false}) {
    // Para servicios en progreso, usar siempre service.workerId directamente.
    // Para otros estados, usar el workerId pasado como parámetro (de la oferta).
    final targetWorkerId = workerId ?? 
        (service.workerId.isNotEmpty ? service.workerId : '');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          // ServiceFormWithTimeline crea y gestiona su propio ServiceDetailsProvider
          // internamente en initState — no necesitamos uno externo.
          return ServiceFormWithTimeline(
            serviceId: service.id,
            initialStatus: service.status.id,
            onComplete: (status) => null,
            onStatusChanged: (newStatus) => null,
            userData: userData,
            workerId: targetWorkerId,
            apiService: apiService,
            userId: userId,
            workerInfoOnly: workerInfoOnly,
          );
        },
      ),
    );
  }

  /// Acepta la oferta de un trabajador:
  /// 1. Cambia el servicio a 'in_progress' y asigna el workerId
  /// 2. Marca la oferta aceptada como 'accepted'
  /// 3. Rechaza (status='rejected') todas las demás ofertas del mismo servicio
  Future<void> _acceptOffer(BuildContext context, Offer offer) async {
    // Confirmar antes de ejecutar
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Aceptar oferta'),
        content: Text(
          '¿Aceptar la oferta de Bs. ${offer.offeredPrice.toStringAsFixed(2)}?\n\n'
          'El servicio pasará a "En Progreso" y las demás ofertas serán rechazadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A819A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, aceptar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!context.mounted) return;

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF1A819A))),
    );

    try {
      // 1. Actualizar el servicio: in_progress + workerId del trabajador aceptado
      await apiService.updateService(
        serviceId: service.id,
        data: {
          'status': 'in_progress',
          'workerId': offer.workerId,
          'hasOffer': false,
        },
      );

      // 2. Marcar la oferta aceptada como 'accepted'
      await apiService.updateOffer(
        offerId: offer.id,
        data: {'status': 'accepted'},
      );

      // 3. Rechazar todas las demás ofertas del mismo servicio en paralelo
      final otrasOfertas = service.offers.where((o) => o.id != offer.id).toList();
      if (otrasOfertas.isNotEmpty) {
        await Future.wait(
          otrasOfertas.map((o) => apiService.updateOffer(
            offerId: o.id,
            data: {'status': 'rejected'},
          )),
        );
      }

      // 4. Refrescar el historial del provider para que la UI se actualice
      if (context.mounted) {
        final historialProv = Provider.of<HistorialProvider>(context, listen: false);
        final token = await AuthUtils.getToken();
        final deviceId = await AuthUtils.getDeviceId();
        if (token != null) {
          await historialProv.refresh(
            userId: service.userId,
            token: token,
            deviceId: deviceId ?? '',
          );
        }
      }

      if (context.mounted) {
        Navigator.of(context).pop(); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Oferta aceptada — servicio en progreso'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al aceptar oferta: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
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
    final isInProgress = service.status.id == 'in_progress';
    

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
                _PriceDisplay(
                  service: service,
                  isInProgress: isInProgress,
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
                
                // ── Ofertas recibidas (En espera) ──
                if (service.offers.isNotEmpty && isPending) ...[
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A819A).withOpacity(0.03),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF1A819A).withOpacity(0.12)),
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
                        return _OfferItemCard(
                          offer: offer,
                          onAccept: () => _acceptOffer(context, offer),
                          onViewDetails: () => _navigateToDetails(
                            context,
                            workerId: offer.workerId,
                            workerInfoOnly: true,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                // ── Trabajador asignado (En proceso) ──
                if (isInProgress && service.workerId.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  WorkerInfoExpansionTile(
                    workerId: service.workerId,
                    title: 'Trabajador asignado',
                    initiallyExpanded: true,
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Tarjeta de oferta individual (usada en la lista "Ver ofertas recibidas")
/// Muestra el precio, la info del trabajador expandible y los botones de acción.
// ─────────────────────────────────────────────────────────────────────────────
class _OfferItemCard extends StatefulWidget {
  final Offer offer;
  final VoidCallback onAccept;
  final VoidCallback onViewDetails;

  const _OfferItemCard({
    required this.offer,
    required this.onAccept,
    required this.onViewDetails,
  });

  @override
  State<_OfferItemCard> createState() => _OfferItemCardState();
}

class _OfferItemCardState extends State<_OfferItemCard> {
  bool _showWorkerInfo = false;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1A819A);

    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado: precio de la oferta ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Oferta propuesta',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Bs. ${widget.offer.offeredPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Info del trabajador expandible ──
          if (widget.offer.workerId.isNotEmpty) ...[
            InkWell(
              onTap: () => setState(() => _showWorkerInfo = !_showWorkerInfo),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 16, color: primaryColor),
                    const SizedBox(width: 6),
                    const Text(
                      'Ver info del trabajador',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _showWorkerInfo ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 18, color: primaryColor),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 280),
              crossFadeState: _showWorkerInfo
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: WorkerInfoCard(workerId: widget.offer.workerId),
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],

          const Divider(height: 1, indent: 14, endIndent: 14),

          // ── Botones de acción ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onViewDetails,
                    icon: const Icon(Icons.open_in_new_rounded, size: 14),
                    label: const Text('Ver perfil', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: const BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.onAccept,
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                    label: const Text('Aceptar', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Widget que muestra el precio del servicio.
/// Para servicios in_progress: si no hay precio en memoria, hace una consulta
/// directa a Firestore para asegurarse de mostrar el precio real acordado.
// ─────────────────────────────────────────────────────────────────────────────
class _PriceDisplay extends StatefulWidget {
  final ServiceRequest service;
  final bool isInProgress;

  const _PriceDisplay({required this.service, required this.isInProgress});

  @override
  State<_PriceDisplay> createState() => _PriceDisplayState();
}

class _PriceDisplayState extends State<_PriceDisplay> {
  double? _resolvedPrice;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _resolvePrice();
  }

  Future<void> _resolvePrice() async {
    final svc = widget.service;

    // 1. Precio de la oferta aceptada (fuente más confiable)
    if (svc.offers.isNotEmpty && svc.offers.first.offeredPrice > 0) {
      setState(() => _resolvedPrice = svc.offers.first.offeredPrice);
      return;
    }

    // 2. Precio guardado en el propio servicio
    if (svc.offeredPrice > 0) {
      setState(() => _resolvedPrice = svc.offeredPrice);
      return;
    }

    // 3. Fallback: buscar en Firestore directamente (solo para in_progress)
    if (widget.isInProgress) {
      setState(() => _loading = true);
      try {
        final offersSnap = await FirebaseFirestore.instance
            .collection('offers')
            .where('serviceId', isEqualTo: svc.id)
            .limit(5)
            .get();

        double? found;
        // Priorizar oferta con status 'accepted' o 'in_progress'
        for (final doc in offersSnap.docs) {
          final data = doc.data();
          final price = (data['offeredPrice'] as num?)?.toDouble() ?? 0;
          if (price > 0) {
            found = price;
            break;
          }
        }
        if (mounted) {
          setState(() {
            _resolvedPrice = found;
            _loading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.isInProgress ? 'Precio acordado:' : 'Precio Ofertado base:';
    String priceText;

    if (_loading) {
      priceText = '...';
    } else if (_resolvedPrice != null && _resolvedPrice! > 0) {
      priceText = 'Bs. ${_resolvedPrice!.toStringAsFixed(2)}';
    } else {
      priceText = 'Bs. 0.00';
    }

    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1A819A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: _loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF1A819A),
                  ),
                )
              : Text(
                  priceText,
                  style: const TextStyle(
                    color: Color(0xFF1A819A),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
        ),
      ],
    );
  }
}