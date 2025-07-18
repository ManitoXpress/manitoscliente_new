import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';


import '../constants/service_constants.dart';
import '../models/service_requestModels.dart';
import '../provider/serviceDetails_providers.dart';
import 'timeline_helpers.dart';

class ActionButtonsSection extends StatelessWidget {
  final BuildContext context;
  final ServiceDetailsProvider prov;
  final ServiceRequestModel serviceData;
  final String workerId;
  final double? offeredPrice;
  final int commentCount;
  final Function(String) onStatusChanged;

  const ActionButtonsSection({
    Key? key,
    required this.context,
    required this.prov,
    required this.serviceData,
    required this.workerId,
    required this.offeredPrice,
    required this.commentCount,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A819A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.touch_app_rounded,
                  color: Color(0xFF1A819A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Acciones Disponibles',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A819A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final hasOffer = prov.hasOffer;
    final status = serviceData.status;

    // 1) Si hay oferta pendiente
    if (hasOffer) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await prov.acceptProposal(workerId);

                      if (prov.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(prov.errorMessage!),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else {
                        onStatusChanged(ServiceStatus.inProgress);
                      }
                    },
                    icon: const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 20),
                    label: const Text(
                      "Aceptar",
                      style: TextStyle(
                        fontFamily: 'Xpress Heavy',
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF84090D),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF830A09).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await prov.cancelService();
                      if (prov.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(prov.errorMessage!),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.cancel_rounded,
                        color: Colors.white, size: 20),
                    label: const Text(
                      "Cancelar",
                      style: TextStyle(
                        fontFamily: 'Xpress Heavy',
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF000000),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => TimelineHelpers.showCommentsModal(context, prov),
              icon: const Icon(Icons.chat_bubble_rounded,
                  color: Colors.white, size: 20),
              label: Text(
                'Comentarios ($commentCount)',
                style: const TextStyle(
                  fontFamily: 'Xpress Heavy',
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // 2) Si está en progreso
    else if (status == ServiceStatus.inProgress) {
      return Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF25D366),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final url = await prov.getWhatsAppUrl();
                  if (url != null) {
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No se pudo abrir WhatsApp.'),
                        ),
                      );
                    }
                  } else if (prov.errorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(prov.errorMessage!),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.chat_rounded,
                    color: Colors.white, size: 20),
                label: const Text(
                  "WhatsApp",
                  style: TextStyle(
                    fontFamily: 'Xpress Heavy',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // 3) Disponible sin ofertas
    else if (status == ServiceStatus.available) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF84090D),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () async {
                await prov.cancelService();
                if (prov.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(prov.errorMessage!),
                      backgroundColor: const Color(0xFF84090D),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.cancel_rounded,
                  color: Colors.white, size: 20),
              label: const Text(
                "Cancelar Trabajo",
                style: TextStyle(
                  fontFamily: 'Xpress Heavy',
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF000000),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => TimelineHelpers.showCommentsModal(context, prov),
              icon: const Icon(Icons.chat_bubble_rounded,
                  color: Colors.white, size: 20),
              label: Text(
                'Comentarios ($commentCount)',
                style: const TextStyle(
                  fontFamily: 'Xpress Heavy',
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
