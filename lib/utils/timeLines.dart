import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:manitoscliente_new/ServicesResponse/ResponseGet.dart';
import 'package:manitoscliente_new/ServicesResponse/ResponsePost.dart';
import 'package:manitoscliente_new/ServicesResponse/dataprofile.dart';
import 'package:manitoscliente_new/ServicesResponse/resquest.dart';
import 'package:manitoscliente_new/utils/status.dart';
import 'package:timeline_tile/timeline_tile.dart';

import 'cacheLocal.dart';
import 'offers.dart';
class ServiceFormWithTimeline extends StatefulWidget {
  final ServiceRequest serviceRequest;
  final String initialStatus;
  final ValueChanged<String> onComplete;
  final Function(String) onStatusChanged;
  final UserData userData;

  const ServiceFormWithTimeline({
    required this.serviceRequest,
    required this.initialStatus,
    required this.onComplete,
    required this.onStatusChanged,
    required this.userData,
  });

  @override
  _ServiceFormWithTimelineState createState() =>
      _ServiceFormWithTimelineState();
}

class _ServiceFormWithTimelineState extends State<ServiceFormWithTimeline> {
  late String status;
  final TextEditingController _cancelReasonController = TextEditingController();
  List<ServiceResponse> offers = [];

  @override
  void initState() {
    super.initState();
    status = widget.initialStatus;

    // Cargar ofertas si es necesario
    if (widget.serviceRequest.offeredPrice > 0) {
      _fetchOffers(); // Nueva función para obtener ofertas
    }
  }

  void _fetchOffers() async {
    try {
      final String serviceId = widget.serviceRequest.id;
      final ApiService2 apiService = ApiService2();
      final List<ServiceResponse> fetchedOffers = await apiService.getOffers(serviceId);

      setState(() {
        offers = fetchedOffers; // Actualizar las ofertas
      });
    } catch (e) {
      print('Error al obtener las ofertas: $e');
    }
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancelar Servicio'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Coloque su motivo de cancelación de trabajo:'),
                const SizedBox(height: 10),
                TextField(
                  controller: _cancelReasonController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Escriba su motivo aquí',
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Ejemplos de cancelación de servicio:'),
                ElevatedButton(
                  onPressed: () {
                    _cancelJobWithReason('No puedo continuar con el trabajo');
                  },
                  child: const Text('No puedo continuar con el trabajo'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _cancelJobWithReason('Emergencia inesperada');
                  },
                  child: const Text('Emergencia inesperada'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _cancelJobWithReason('Otro motivo');
                  },
                  child: const Text('Otro motivo'),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _viewProposal() async {
    try {
      if (offers.isNotEmpty) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return OfferDialog(offers: offers);
          },
        );
      }
    } catch (e) {
      print('Error al obtener las ofertas: $e');
    }
  }

  void _cancelJobWithReason(String reason) async {
    try {
      print('Trabajo cancelado por la razón: $reason');
      final Status cancelledStatus = Status(id: 'cancelled', name: 'Cancelado');
      setState(() {
        status = cancelledStatus.name;
      });

      await ApiService().updateServiceStatus(
        widget.serviceRequest,
        cancelledStatus.id,
        widget.userData.getToken!,
      );

      widget.onComplete(cancelledStatus.id);
      Navigator.of(context).pop();
    } catch (e) {
      print('Error al cancelar el trabajo: $e');
    }
  }

@override
Widget build(BuildContext context) {
  print('Precio ofertado: ${widget.serviceRequest.offeredPrice}');
  
  return AlertDialog(
    title: const Text('Detalles del Servicio'),
    contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
    content: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fecha y Hora: ${widget.serviceRequest.serviceDateTime}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            'Descripción: ${widget.serviceRequest.description}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            height: 280,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seguimiento del Servicio',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text('Estado: ${widget.serviceRequest.status.name}'),
                  const SizedBox(height: 10),
                  Text(
                    'Precio Ofertado: ${widget.serviceRequest.offeredPrice > 0 ? "\$${widget.serviceRequest.offeredPrice.toStringAsFixed(2)}" : 'No hay precio ofertado aún.'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (offers.isNotEmpty)
                    ElevatedButton(
                      onPressed: _viewProposal,
                      child: const Text('Mostrar Propuestas'),
                    ),
                  ElevatedButton(
                    onPressed: () {
                      _showCancelDialog(context);
                    },
                    child: const Text('Cancelar Trabajo'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}



  Color _getTextColorByStatus(String statusId) {
    final status = StatusUtils.getStatusById(statusId);
    switch (status.id) {
      case "available":
        return Colors.green;
      case "assigned":
        return Colors.orange;
      case "in_progress":
        return Colors.black;
      case "completed":
        return Colors.blue;
      case "cancelled":
        return const Color(0xFF84090D);
      default:
        return Colors.grey;
    }
  }
}
