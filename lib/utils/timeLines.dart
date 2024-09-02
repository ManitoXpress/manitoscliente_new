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

  @override
  void initState() {
    super.initState();
    status = widget.initialStatus;
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cancelar Trabajo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Coloque su motivo de cancelación de trabajo:'),
                SizedBox(height: 10),
                TextField(
                  controller: _cancelReasonController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Escriba su motivo aquí',
                  ),
                ),
                SizedBox(height: 10),
                Text('Ejemplos de cancelación de servicio:'),
                ElevatedButton(
                  onPressed: () {
                    _cancelJobWithReason('No puedo continuar con el trabajo');
                  },
                  child: Text('No puedo continuar con el trabajo'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _cancelJobWithReason('Emergencia inesperada');
                  },
                  child: Text('Emergencia inesperada'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _cancelJobWithReason('Otro motivo');
                  },
                  child: Text('Otro motivo'),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _viewProposal() async {
    try {
      final String serviceId = widget.serviceRequest.id;
      final ApiService2 apiService = ApiService2();
      final List<ServiceResponse> offers = await apiService.getOffers(serviceId);

      if (mounted) {
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
    return AlertDialog(
      title: Text('Detalles del Servicio'),
      contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fecha y Hora: ${widget.serviceRequest.serviceDateTime}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Descripción: ${widget.serviceRequest.description}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Container(
              height: 280,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seguimiento del Servicio',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text('Estado: $status'),
                    SizedBox(height: 10),
                    Text(
                      'Precio Ofertado: ${widget.serviceRequest.offeredPrice > 0 ? widget.serviceRequest.offeredPrice.toString() : 'No especificado'}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    if (widget.serviceRequest.offeredPrice > 0)
                      ElevatedButton(
                        onPressed: () {
                          _viewProposal();
                          Navigator.of(context).pop();
                        },
                        child: Text('Mostrar Propuestas'),
                      ),
                    ElevatedButton(
                      onPressed: () {
                        _showCancelDialog(context);
                      },
                      child: Text('Cancelar Trabajo'),
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
        return Color(0xFF84090D);
      default:
        return Colors.grey;
    }
  }
}
