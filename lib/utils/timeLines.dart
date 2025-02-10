import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:manitoscliente_new/request/ResponseGet.dart';
import 'package:manitoscliente_new/request/ResponsePost.dart';
import 'package:manitoscliente_new/request/dataprofile.dart';
import 'package:manitoscliente_new/request/requestWoker.dart';
import 'package:manitoscliente_new/request/resquest.dart';
import 'package:manitoscliente_new/Styles/stilo.dart';
import 'package:manitoscliente_new/metodos/serviceActions.dart';
import 'package:manitoscliente_new/metodos/serviceDialog.dart';
import 'package:manitoscliente_new/metodos/serviceFetcher.dart';
import 'package:manitoscliente_new/utils/chats.dart';
import 'package:manitoscliente_new/utils/fullMap.dart';
import 'package:manitoscliente_new/utils/imageComplete.dart';
import 'package:manitoscliente_new/utils/status.dart';
import 'package:timeline_tile/timeline_tile.dart';

import 'cacheLocal.dart';
import 'offers.dart';

import 'offers.dart';
class ServiceFormWithTimeline extends StatefulWidget {
  final ServiceRequest serviceRequest;
  final String initialStatus;
  final ValueChanged<String> onComplete;
  final Function(String) onStatusChanged;
  final UserData userData;
  final String workerId;
  final WorkerDetails? workerDetails;
  final List<Offer> offers;
  final List<String> images;

  const ServiceFormWithTimeline({
    required this.serviceRequest,
    required this.initialStatus,
    required this.onComplete,
    required this.onStatusChanged,
    required this.userData,
    required this.workerId,
    required this.images,
    required this.workerDetails,
    required this.offers, // Parámetro añadido
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
  late LatLng _initialPosition;
  bool _hasOffer = false;
  late Map<String, dynamic> serviceData;
  late List<String> imageFiles;
  WorkerDetails? _workerDetails;

  final Map<String, String> statusNames = {
    "available": "Disponible",
    "offer": "Ofertado",
    "in_progress": "En curso",
    "completed": "Completado",
    "cancelled": "Cancelado",
    "blocked": "Bloqueado",
    "pending_confirmation": "Esperando confirmación",
    "peding_confirmation2": "Esperando confirmación",
  };

  @override
  void initState() {
    super.initState();

    // Inicializar variables
    _currentStatus = widget.initialStatus;
    _initializeControllers();
    _workerDetails = widget.workerDetails;

    // Inicializa serviceData y otras variables
    serviceData = widget.serviceRequest.toMap();
    imageFiles = List<String>.from(serviceData['images'] ?? []);

    // Configurar la posición inicial
    double latitude = serviceData['location']['lat'] ?? 0.0;
    double longitude = serviceData['location']['lng'] ?? 0.0;
    _initialPosition = LatLng(latitude, longitude);

    // Verificar ofertas activas
    if (widget.offers.isNotEmpty) {
      final offer = widget.offers.first;
      _fetchedOfferedPrice = offer.offeredPrice;

      if (_fetchedOfferedPrice != null) {
        _priceController.text = _fetchedOfferedPrice.toString();
      }

      if (offer.hasOffer == true) {
        _hasOffer = true;
      }
    }
    


    // Inicializar el stream
    _initializeServiceStream();
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

    _serviceRequestStream.listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          final newStatus = data['status'] ?? _currentStatus;

          // Verificar si el estado cambió a "pending_confirmation"
          if (newStatus == 'pending_confirmation' && _currentStatus != 'pending_confirmation') {
            setState(() {
              _currentStatus = newStatus; // Actualizar el estado antes de mostrar el diálogo
            });

            // Asegurarse de que el cuadro de diálogo se muestre después de que se haya renderizado la interfaz
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Solo llamar el diálogo si la pantalla está visible
              if (mounted) {
                showConfirmCompletionDialog(context, widget.serviceRequest.id);
              }
            });
          }

          setState(() {
            _currentStatus = newStatus;
            serviceData = data; // Actualizar serviceData
            _hasOffer = data['hasOffer'] ?? false;
          });
        }
      }
    });
  }



  @override
  void dispose() {
    _cancelReasonController.dispose();
    _priceController.dispose();
    super.dispose();
  }


  void _initializeMap() {
    // Verifica si los datos de ubicación están presentes en la solicitud del servicio.
    if (widget.serviceRequest.location != null) {
      double? latitude = widget.serviceRequest.location['lat'];
      double? longitude = widget.serviceRequest.location['lng'];

      // Si los datos son válidos, inicializa la posición; de lo contrario, usa valores predeterminados.
      if (latitude != null && longitude != null) {
        _initialPosition = LatLng(latitude, longitude);
      } else {
        _initialPosition = LatLng(
            0.0, 0.0); // Ubicación predeterminada (ejemplo: coordenadas 0,0)
        print(
            'Ubicación no válida. Usando la posición predeterminada (0.0, 0.0).');
      }
    } else {
      _initialPosition = LatLng(0.0,
          0.0); // Ubicación predeterminada si no se proporciona la ubicación.
      print(
          'No se encontró ubicación en la solicitud de servicio. Usando la posición predeterminada (0.0, 0.0).');
    }
  }

// Abre el mapa en pantalla completa
  void _openFullMap(BuildContext context) {
    if (_initialPosition.latitude == 0.0 && _initialPosition.longitude == 0.0) {
      // Advertencia si la posición no es válida (opcional)
      print('Advertencia: abriendo mapa con posición predeterminada.');
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullMapScreen(initialPosition: _initialPosition),
      ),
    );
  }

  // Función para mostrar el diálogo de confirmación
  void showConfirmCompletionDialog(BuildContext context, String serviceId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ServiceCompletionDialog(
          serviceId: serviceId,
          workerDetails: _workerDetails,
          fetchedOfferedPrice: _fetchedOfferedPrice ?? widget.serviceRequest.offeredPrice, // Aquí pasas el precio ofertado
        );
      },
    ).then((confirmed) {
      if (confirmed == true) {
        // El trabajo ha sido confirmado como completado
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Trabajo confirmado como completado')),
        );
        // Aquí puedes agregar cualquier lógica adicional después de la confirmación
      }
    });
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
      // Actualiza el documento en la colección 'services'
      await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceRequest.id)
          .update({
        'status': 'in_progress',
        'hasOffer': false,
      });

      // Actualiza todos los documentos en la colección 'offers' relacionados con el serviceId
      final batch = FirebaseFirestore.instance.batch();
      final offersQuerySnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('serviceId', isEqualTo: widget.serviceRequest.id)
          .get();

      for (var offerDoc in offersQuerySnapshot.docs) {
        batch.update(offerDoc.reference, {
          'status': 'in_progress',
          'hasOffer': false,
        });
      }

      // Ejecuta el batch para realizar todas las actualizaciones de una vez
      await batch.commit();

      // Llama al callback para notificar el cambio de estado
      widget.onStatusChanged('in_progress');

      // Cierra el diálogo o pantalla actual
      Navigator.of(context).pop();
    } catch (e) {
      // Manejo de errores
      print('Error al aceptar la propuesta: $e');
    }
  }


  void _showDialog(BuildContext context,
      String title,
      String content,
      VoidCallback onConfirm,
      String confirmText,) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: MyTextStyles
                .drawerButtonTextStyle4, // Aplicar el estilo al título
          ),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: onConfirm,
              child: Text(
                confirmText,
                style: MyTextStyles
                    .ButtonTextStyle, // Aplicar un estilo personalizado al botón si es necesario
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                backgroundColor: Color(0xFF1A819A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: BorderSide(
                    color: Color(0xFF1A819A), // Color del borde del botón
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelOffer(String serviceId, String workerId) async {
    try {
      // Actualiza el estado del servicio a 'cancelled' en la colección 'offers'
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.serviceRequest
          .id) // Asumiendo que el ID del servicio está aquí
          .set(
        {'status': 'cancelled'}, // Actualiza el campo 'status'
        SetOptions(merge: true), // No sobrescribe otros campos, solo 'status'
      );

      // Actualiza el estado del servicio a 'available' y el offeredPrice a 0 en la colección 'services'
      await FirebaseFirestore.instance
          .collection('services')
          .doc(serviceId) // El ID del servicio en la colección 'services'
          .set(
        {
          'status': 'available', // Actualiza el campo 'status' a 'available'
          'offeredPrice': 0, // Establece el 'offeredPrice' a 0
        },
        SetOptions(
            merge: true), // No sobrescribe otros campos, solo 'status' y 'offeredPrice'
      );

      // Mostrar un mensaje o snackbar para confirmar la cancelación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'El servicio ha sido cancelado y está disponible nuevamente.'),
        ),
      );

      // Regresar a la pantalla anterior o hacer alguna otra acción
      Navigator.of(context).pop();
    } catch (e) {
      print('Error al cancelar el servicio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cancelar el servicio. Inténtalo de nuevo.'),
        ),
      );
    }
  }


  Future<void> _cancelService() async {
    try {
      // Actualiza el estado del servicio a 'cancelled'
      await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceRequest.id)
          .update({'status': 'cancelled'});

      // Mostrar un mensaje o snackbar para confirmar la cancelación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El servicio ha sido cancelado.'),
        ),
      );

      // Regresar a la pantalla anterior o hacer alguna otra acción
      Navigator.of(context).pop();
    } catch (e) {
      print('Error al cancelar el servicio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cancelar el servicio. Inténtalo de nuevo.'),
        ),
      );
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

        // Asignar datos del servicio
        // Extraer datos relevantes del servicio
        final String newStatus = serviceData['status'] ?? 'available';

        // Detectar cambio a pending_confirmation y mostrar cuadro de diálogo
        if (newStatus == 'pending_confirmation' && _currentStatus != 'pending_confirmation') {
          setState(() {
            _currentStatus = newStatus;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showConfirmCompletionDialog(context, widget.serviceRequest.id);
          });
        }

        // Actualizar el estado actual
        _currentStatus = newStatus;
        _initialPosition = LatLng(
  (serviceData['location']?['lat'] as num?)?.toDouble() ?? 0.0,
  (serviceData['location']?['lng'] as num?)?.toDouble() ?? 0.0,
);


        final List<String> images = List<String>.from(serviceData['images'] ?? []);
        final String description = serviceData['description'] ?? 'Sin descripción';
        final String categoryName = serviceData['categoryId'] ?? 'Sin categoría';
        final String expertiseName = serviceData['expertiseName'] ?? 'Sin subcategoría';
        final double? offeredPrice = (serviceData['offeredPrice'] as num?)?.toDouble();

        final WorkerDetails? workerDetails = widget.workerDetails;
        final List<Map<String, dynamic>> expertises = List<Map<String, dynamic>>.from(serviceData['expertises'] ?? []);

        return Scaffold(
          appBar: AppBar(
            iconTheme: IconThemeData(color: Colors.white),
            title: Text(
              'Detalles del Servicio',
              style: MyTextStyles.ButtonTextStyle,
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF1A819A), width: 2.0),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado: ${statusNames[_currentStatus] ?? 'Desconocido'}',
                      style: MyTextStyles.formServiceTextStyle,
                    ),
                    const SizedBox(height: 16.0),
                    _buildRichText('Descripción:', description),
                    _buildRichText('Especialidad:', expertiseName),
                    _buildRichText('Precio ofertado:', offeredPrice?.toString() ?? 'No ofertado'),
                    const SizedBox(height: 16.0),
                    // Mostrar imágenes
                    if (images.isNotEmpty)
                      Column(
                        children: images.map((url) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: CachedNetworkImage(
                              imageUrl: url,
                              height: 150.0,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => CircularProgressIndicator(),
                              errorWidget: (context, url, error) => Icon(Icons.error),
                            ),
                          );
                        }).toList(),
                      ),

                    // Mostrar habilidades
                    if (expertises.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: expertises.map((expertise) {
                          return Text(
                            'Tipo de servicio: ${expertise['name'] ?? 'Sin nombre'}',
                            style: MyTextStyles.formServiceTextStyle,
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 16.0),

                    // Mostrar detalles del trabajador si están disponibles o si el estado es 'in_progress'
                    if (workerDetails != null || _currentStatus == 'in_progress')
                      _buildWorkerDetails(workerDetails!,serviceData),

                    _buildActionButtons(context),
                    // Mostrar el botón "Hacer el pago" solo si el estado es 'pending_confirmation'
                    if (_currentStatus == 'pending_confirmation')
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: ElevatedButton(
                          onPressed: () {
                            showConfirmCompletionDialog(context, widget.serviceRequest.id);
                          },
                          child: Text(
                            'Hacer el pago',
                            style: GoogleFonts.karla(
                              color: Color(0xFF1A819A),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              side: BorderSide(
                                color: Color(0xFF1A819A),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkerDetails(WorkerDetails worker, Map<String, dynamic>? serviceData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Trabajador',
          style: MyTextStyles.formServiceTextStyle.copyWith(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: CachedNetworkImage(
                imageUrl: worker.imagePath,
                height: 150.0,
                width: 150.0,
                fit: BoxFit.cover,
                placeholder: (context, url) => CircularProgressIndicator(),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
            ),
            const SizedBox(width: 16.0),
            Flexible(
              child: CachedNetworkImage(
                imageUrl: worker.idDocumentImagePath,
                height: 150.0,
                width: 150.0,
                fit: BoxFit.cover,
                placeholder: (context, url) => CircularProgressIndicator(),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
            ),
          ],
        ),
        const SizedBox(height: 26.0),
        _buildRichText('Nombre:', worker.displayName ?? 'No disponible'),
        _buildRichText('Correo:', worker.email ?? 'No disponible'),
        _buildRichText('Teléfono:', worker.phoneNumber ?? 'No disponible'),
        _buildRichText('Nivel de Experiencia:', worker.expLevel?.toString() ?? 'No disponible'),
        _buildRichText(
          'Especialidad:',
          worker.expertises?.map((e) => e.name).join(', ') ?? 'No disponible',
        ),
        const SizedBox(height: 26.0),
        _buildRichText('Precio ofertado:', '${serviceData?['offeredPrice'] ?? 'No ofertado'}'),
      ],
    );
  }

  Widget _buildRichText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text.rich(
        TextSpan(
          text: '$label ',
          style: MyTextStyles.drawerButtonTextStyle,
          children: [
            TextSpan(
              text: value,
              style: MyTextStyles.drawerButtonTextStyle5,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }



// Widget para los botones de acción según el estado
  Widget _buildActionButtons(BuildContext context) {
    if (_hasOffer) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: () => _acceptProposal(),
            icon: Icon(Icons.architecture, color: const Color(0xFF1A819A)),
            label: Text(
              "Aceptar Propuesta",
              style: GoogleFonts.karla(
                color: const Color(0xFF1A819A),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
                side: BorderSide(color: const Color(0xFF1A819A)),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () =>
                _cancelOffer(widget.serviceRequest.id, widget.workerId),
            icon: Icon(Icons.dangerous, color: const Color(0xFF1A819A)),
            label: Text(
              "Cancelar Propuesta",
              style: GoogleFonts.karla(
                color: const Color(0xFF1A819A),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
                side: BorderSide(color: const Color(0xFF1A819A)),
              ),
            ),
          ),
        ],
      );
    } else if (_currentStatus == 'in_progress') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: _cancelService,
            icon: Icon(Icons.dangerous, color: Colors.white),
            label: Text(
              "Cancelar Trabajo",
              style: GoogleFonts.karla(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _openChat(widget.workerId, widget.serviceRequest.userId),
            icon: Icon(Icons.chat, color: Colors.white),
            label: Text(
              "Chat",
              style: GoogleFonts.karla(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
        ],
      );
    }
    else if (_currentStatus == 'available') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: _cancelService,
            icon: Icon(Icons.dangerous, color: Colors.white),
            label: Text(
              "Cancelar Trabajo",
              style: GoogleFonts.karla(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            ),
          ),
        ],
      );
    }
    return SizedBox.shrink();
  }
  void _openChat(String workerId, String userId) async {
    final chatId = _generateChatId(workerId, userId);

    // Referencia al documento del chat
    final chatDoc = FirebaseFirestore.instance.collection('chats').doc(chatId);

    // Verifica si el chat ya existe
    final chatSnapshot = await chatDoc.get();

    if (!chatSnapshot.exists) {
      // Si el chat no existe, lo crea con información inicial
      await chatDoc.set({
        'chatId': chatId,
        'participants': [userId, workerId],
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    // Navegar a la pantalla de chat (debes implementar esta pantalla)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: chatId,
          userId: userId,
          workerId: workerId,
        ),
      ),
    );
  }

  String _generateChatId(String workerId, String userId) {
    // Generar un ID único basado en los IDs de los participantes
    return workerId.hashCode <= userId.hashCode
        ? '$workerId\_$userId'
        : '$userId\_$workerId';
  }
}