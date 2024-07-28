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
          content: Column(
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

      // Obtener una instancia de ApiService2
      final ApiService2 apiService = ApiService2();

      // Llamar al método _getOffers
      final List<ServiceResponse> offers =
          await apiService.getOffers(serviceId);

      // Verificar si el widget aún está montado antes de mostrar el cuadro de diálogo
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return OfferDialog(
                offers:
                    offers); // Pasar la lista de ofertas al cuadro de diálogo
          },
        );
      }

      // Aquí puedes hacer lo que necesites con la lista de ofertas
      // Por ejemplo, mostrarlas en un diálogo o procesarlas de alguna otra manera
    } catch (e) {
      print('Error al obtener las ofertas: $e');
    }
  }

  void _cancelJobWithReason(String reason) async {
    try {
      print('Trabajo cancelado por la razón: $reason');

      // Obtén el objeto Status correspondiente al estado 'Cancelado'
      final Status cancelledStatus = Status(id: 'cancelled', name: 'Cancelado');

      // Cambia el estado local a 'Cancelado'
      setState(() {
        status = cancelledStatus
            .name; // Usa el nombre del estado en lugar del objeto Status
      });

      // Actualiza el estado en el backend
      await ApiService().updateServiceStatus(
        widget.serviceRequest,
        cancelledStatus.id, // Envía el id del estado
        widget.userData.getToken!,
      );

      // Llama al callback onComplete con el nuevo estado
      widget.onComplete(cancelledStatus.id); // Envía el id del estado
      Navigator.of(context).pop();
    } catch (e) {
      print('Error al cancelar el trabajo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Detalles del Servicio'),
      contentPadding: EdgeInsets.symmetric(
          vertical: 20, horizontal: 40), // Ajuste del padding
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
              child: TimelineTile(
                axis: TimelineAxis.vertical,
                alignment: TimelineAlign.start,
                indicatorStyle: IndicatorStyle(
                  width: 40,
                  color: _getTextColorByStatus(widget.serviceRequest.status.id),
                ),
                endChild: Column(
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
                          _viewProposal(); // Llama a la función al presionar el botón
                          Navigator.of(context)
                              .pop(); // Cierra el cuadro de diálogo después de aceptar la propuesta
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
        return Colors.green; // Color del texto para "Disponible"
      case "assigned":
        return Colors.orange; // Color del texto para "Asignado"
      case "in_progress":
        return Colors.black; // Color del texto para "En curso"
      case "completed":
        return Colors.blue; // Color del texto para "Completado"
      case "cancelled":
        return Color(0xFF84090D); // Color del texto para "Cancelado"
      default:
        return Colors.grey; // Color del texto para cualquier otro estado
    }
  }
}
