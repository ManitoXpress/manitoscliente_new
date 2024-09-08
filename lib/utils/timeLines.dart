import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:manitoscliente_new/ServicesResponse/ResponseGet.dart';
import 'package:manitoscliente_new/ServicesResponse/ResponsePost.dart';
import 'package:manitoscliente_new/ServicesResponse/dataprofile.dart';
import 'package:manitoscliente_new/ServicesResponse/resquest.dart';
import 'package:manitoscliente_new/Styles/stilo.dart';
import 'package:manitoscliente_new/utils/fullMap.dart';
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
  final String workerId;
  
  final List<String> images;

  const ServiceFormWithTimeline({
    required this.serviceRequest,
    required this.initialStatus,
    required this.onComplete,
    required this.onStatusChanged,
    required this.userData,
    required this.workerId,
    required this.images,
    
  });

  @override
  _ServiceFormWithTimelineState createState() =>
      _ServiceFormWithTimelineState();
}

class _ServiceFormWithTimelineState extends State<ServiceFormWithTimeline> {
  late TextEditingController _cancelReasonController;
  late TextEditingController _priceController;
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _serviceRequestStream;
  double? _fetchedOfferedPrice;
  late String _currentStatus;
  // Añade una posición predeterminada para el mapa
  late LatLng _initialPosition;

  final Map<String, String> statusNames = {
    "available": "Disponible",
    "offer": "Ofertado",
    "in_progress": "En curso",
    "completed": "Completado",
    "cancelled": "Cancelado",
    "blocked": "Bloqueado",
    "pending_confirmation": "Esperando confirmación",
  };

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeServiceStream();
    _fetchOfferedPrice();
    _initializeMap();
  }

  void _initializeControllers() {
    _cancelReasonController = TextEditingController();
    _priceController = TextEditingController();
  }

  void _initializeServiceStream() {
    _serviceRequestStream = FirebaseFirestore.instance
        .collection('services')
        .doc(widget.serviceRequest.id)
        .snapshots();
  }

  @override
  void dispose() {
    _cancelReasonController.dispose();
    _priceController.dispose();
    super.dispose();
  }
  void _initializeMap() {
  // Si los datos de ubicación están presentes en la solicitud de servicio, los usa; si no, se usa una ubicación predeterminada.
  double latitude = widget.serviceRequest.location['lat'] ?? 0.0;
  double longitude = widget.serviceRequest.location['lng'] ?? 0.0;

  // Inicializa la posición usando los valores de latitud y longitud obtenidos.
  _initialPosition = LatLng(latitude, longitude);
}

  // Confirmación de finalización del trabajo por el cliente
  void _confirmCompletion() async {
    try {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceRequest.id)
          .update({'status': 'completed'});

      widget.onStatusChanged('completed');
      Navigator.of(context).pop();
    } catch (e) {
      print('Error al confirmar la finalización del trabajo: $e');
    }
  }
  // Abre el mapa en pantalla completa
  void _openFullMap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullMapScreen(initialPosition: _initialPosition),
      ),
    );
  }

  // Diálogo de confirmación para la finalización del trabajo
  void _showConfirmCompletionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Finalización'),
          content: Text(
              '¿Estás seguro de que quieres confirmar la finalización de este trabajo?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _confirmCompletion,
              child: Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  // Rechazo de la finalización del trabajo por el cliente
  void _rejectCompletion() async {
    try {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceRequest.id)
          .update({'status': 'in_progress'});

      widget.onStatusChanged('in_progress');
      Navigator.of(context).pop();
    } catch (e) {
      print('Error al rechazar la finalización del trabajo: $e');
    }
  }

  // Diálogo de rechazo para la finalización del trabajo
  void _showRejectCompletionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Rechazar Finalización'),
          content: Text(
              '¿Estás seguro de que quieres rechazar la finalización de este trabajo?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _rejectCompletion,
              child: Text('Rechazar'),
            ),
          ],
        );
      },
    );
  }

  void _acceptProposal() async {
    try {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceRequest.id)
          .update({'status': 'in_progress'});

      widget.onStatusChanged('in_progress');
      Navigator.of(context).pop();
    } catch (e) {
      print('Error al aceptar la propuesta: $e');
    }
  }

  // Diálogo de confirmación para aceptar la propuesta
  void _showAcceptProposalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Aceptar Propuesta'),
          content: Text(
              '¿Estás seguro de que quieres aceptar esta propuesta y comenzar el trabajo?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _acceptProposal,
              child: Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _blockUserParticipation() async {
    try {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceRequest.id)
          .update({
        'blockedUsers': FieldValue.arrayUnion([widget.workerId])
      });

      widget.onStatusChanged('blocked');
      widget.onComplete('blocked');
      Navigator.of(context).pop();
    } catch (e) {
      print('Error al bloquear la participación del usuario: $e');
    }
  }

  Future<void> _updateServiceStatus(String status, String errorMessage) async {
    try {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceRequest.id)
          .update({'status': status});

      widget.onStatusChanged(status);
      Navigator.of(context).pop();
    } catch (e) {
      print('$errorMessage: $e');
    }
  }

  void _showDialog(
    BuildContext context,
    String title,
    String content,
    VoidCallback onConfirm,
    String confirmText,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: onConfirm,
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchOfferedPrice() async {
    try {
      final offeredPrice = await fetchOfferedPrice(widget.serviceRequest.id);
      setState(() {
        _fetchedOfferedPrice = offeredPrice;
        _priceController.text =
            offeredPrice != null ? offeredPrice.toString() : '';
      });
    } catch (e) {
      print('Error al obtener el precio ofertado: $e');
    }
  }

  Future<double?> fetchOfferedPrice(String serviceId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('serviceId', isEqualTo: serviceId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final offerData = querySnapshot.docs.first.data();
        return double.tryParse(offerData['offeredPrice'].toString());
      }
    } catch (e) {
      print('Error al obtener el precio ofertado: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _serviceRequestStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar los datos del servicio'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final serviceData = snapshot.data?.data();
        if (serviceData == null) {
          return Center(child: Text('No se encontraron datos del servicio'));
        }

        _currentStatus = serviceData['status'] ?? 'available';
        List<String> imageFiles = List<String>.from(serviceData['images'] ?? []);
        double latitude = widget.serviceRequest.location['lat'] ?? 0.0;
        double longitude = widget.serviceRequest.location['lng'] ?? 0.0;

        _initialPosition = LatLng(latitude, longitude);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Detalles del Servicio',
              style: MyTextStyles.ButtonTextStyle,
            ),
          ),
          body: Padding(
            padding: EdgeInsets.all(16.0),
            child: Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFF1A819A), width: 2.0),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estado: ${statusNames[_currentStatus] ?? 'Desconocido'}',
                    style: MyTextStyles.formServiceTextStyle,
                  ),
                  SizedBox(height: 16.0),
                  Text.rich(
                    TextSpan(
                      text: 'Descripción: ', // Este texto tendrá su propio estilo
                      style: MyTextStyles.formServiceTextStyle,
                      children: [
                        TextSpan(
                          text: serviceData['description'] ?? '', // Este texto tendrá otro estilo
                          style: MyTextStyles.inputTextStyle, // Aplica un estilo diferente aquí
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.0),
                  Text(
                    'Ubicación:',
                    style: MyTextStyles.formServiceTextStyle,
                  ),
                  GestureDetector(
                    onTap: () => _openFullMap(context),  // Abre el mapa completo
                    child: Container(
                      height: 200,  // Tamaño pequeño del mapa
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.blueAccent),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _initialPosition,
                            zoom: 14.0,
                          ),
                          markers: {
                            Marker(
                              markerId: MarkerId('serviceLocation'),
                              position: _initialPosition,
                            ),
                          },
                          zoomControlsEnabled: false,
                          scrollGesturesEnabled: false,
                          tiltGesturesEnabled: false,
                          rotateGesturesEnabled: false,
                          onTap: (_) => _openFullMap(context),  // Abre el mapa completo
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  
                  
                  Text(
                    'Imágenes:',
                    style: MyTextStyles.formServiceTextStyle,
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: imageFiles.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Image.network(
                            imageFiles[index],
                            height: 80,
                            width: 80,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'Precio Ofertado: ${_fetchedOfferedPrice ?? 'No ofertado'}',
                    style: MyTextStyles.formServiceTextStyle,
                  ),
                  SizedBox(height: 16.0),
                if (_currentStatus == 'offer') ...[
                  ElevatedButton.icon(
                    onPressed: () => _showDialog(
                      context,
                      'Aceptar Propuesta',
                      '¿Estás seguro de que quieres aceptar esta propuesta y comenzar el trabajo?',
                      _acceptProposal,
                      'Aceptar',
                    ),
                    icon: Icon(Icons.energy_savings_leaf, color: Colors.white),
                      label: Text(
                    "Aceptar Propuesta",
                    style: GoogleFonts.karla(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      ),
                    ),
                     style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1A819A),
                    padding:
                        EdgeInsets.symmetric(vertical: 12, horizontal: 25),
                  ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showDialog(
                      context,
                      'Cancelar Trabajo',
                      '¿Estás seguro de que no quieres participar en este trabajo?',
                      _blockUserParticipation,
                      'Confirmar No Participar',
                    ),
                    icon: Icon(Icons.dangerous, color: Colors.white),
                      label: Text(
                    "Cancelar Trabajo",
                    style: GoogleFonts.karla(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                      ),
                       style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1A819A),
                    padding:
                        EdgeInsets.symmetric(vertical: 12, horizontal: 25),
                  ),
                  ),
                ] else if (_currentStatus == 'in_progress' ||
                    _currentStatus == 'available') ...[
                  ElevatedButton.icon(
                    onPressed: () => _showDialog(
                      context,
                      'Cancelar Trabajo',
                      '¿Estás seguro de que no quieres participar en este trabajo?',
                      _blockUserParticipation,
                      'Confirmar No Participar',
                    ),
                    icon: Icon(Icons.dangerous, color: Colors.white),
                      label: Text(
                    "Cancelar Trabajo",
                    style: GoogleFonts.karla(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                      ),
                       style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1A819A),
                    padding:
                        EdgeInsets.symmetric(vertical: 12, horizontal: 25),
                  ),
                  ),
                ] else if (_currentStatus == 'pending_confirmation') ...[
                  ElevatedButton.icon(
                    onPressed: () => _showConfirmCompletionDialog(context),
                    icon: Icon(Icons.architecture, color: Colors.white),
                      label: Text(
                    "Confirmar Finalización",
                    style: GoogleFonts.karla(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                      ),
                       style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1A819A),
                    padding:
                        EdgeInsets.symmetric(vertical: 12, horizontal: 25),
                  ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showRejectCompletionDialog(context),
                    icon: Icon(Icons.dangerous, color: Colors.white),
                      label: Text(
                    "Rechazar Finalización",
                    style: GoogleFonts.karla(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                      ),
                       style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1A819A),
                    padding:
                        EdgeInsets.symmetric(vertical: 12, horizontal: 25),
                  ),
                  ),
                ],
              ],
            ),
          ),
        )
        );
      },
    );
  }

  Future<List<String>> _getImageUrls(List<String> imageNames) async {
    List<String> imageUrls = [];
    final apiService = ApiService2();

    for (String imageName in imageNames) {
      try {
        // Llamada a getImageUrls usando ApiService2
        String imageUrl = await apiService.getImageUrls(
            widget.serviceRequest.userId, imageName);
        if (imageUrl.isNotEmpty) {
          imageUrls.add(imageUrl);
        }
      } catch (e) {
        print('Error al obtener la URL de la imagen $imageName: $e');
      }
    }

    return imageUrls;
  }

}
