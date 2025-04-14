import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:carousel_slider/carousel_slider.dart';

import '../Styles/stilo.dart';
import '../request/ResponseGet.dart';
import '../request/dataprofile.dart';
import '../request/requestWoker.dart';
import '../request/resquest.dart';
import '../widgets/imagePreview.dart';
import 'chats.dart';
import 'fullMap.dart';
import 'imageComplete.dart';

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
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;
  double? _fetchedOfferedPrice;
  late String _currentStatus;
  late LatLng _initialPosition;
  bool _hasOffer = false;
  late Map<String, dynamic> serviceData;
  late List<String> imageFiles;
  WorkerDetails? _workerDetails;
  double? _workerOfferedPrice;
  final ApiService2 apiService = ApiService2();
  final Map<String, String> statusNames = {
    "available": "Disponible",
    "offer": "Ofertado",
    "in_progress": "En curso",
    "completed": "Completado",
    "cancelled": "Cancelado",
    "blocked": "Bloqueado",
    "pending_confirmation": "Esperando confirmación",
    "pending_confirmation2": "Esperando confirmación",
  };

  @override
  void initState() {
    super.initState();

    // Inicializar variables
    _currentStatus = widget.initialStatus;
    _initializeControllers();
    _workerDetails = widget.workerDetails;

    // Inicializar serviceData y otras variables
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
      _hasOffer = offer.hasOffer;
    }

    // Inicializar el stream
    _initializeServiceStream();
    _fetchWorkerOffer();
  }

  void _initializeControllers() {
    _cancelReasonController = TextEditingController();
    _priceController = TextEditingController();
  }

  Future<void> _fetchWorkerOffer() async {
    try {
      final offerSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('serviceId', isEqualTo: widget.serviceRequest.id)
          .where('workerId', isEqualTo: widget.workerId)
          .get();

      if (offerSnapshot.docs.isNotEmpty) {
        setState(() {
          _workerOfferedPrice =
              offerSnapshot.docs.first.data()['offeredPrice']?.toDouble();
        });
      } else {
        setState(() {
          _workerOfferedPrice = null;
        });
      }
    } catch (e) {
      print('Error al obtener la oferta del trabajador: $e');
      setState(() {
        _workerOfferedPrice = null;
      });
    }
  }

  Future<bool> _checkHasOffers(String serviceId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('offers')
        .where('serviceId', isEqualTo: serviceId)
        .where('hasOffer',
            isEqualTo: true) // Filtramos solo las que tienen ofertas
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  void _initializeServiceStream() {
    _serviceRequestStream = FirebaseFirestore.instance
        .collection('services')
        .doc(widget.serviceRequest.id)
        .snapshots();

    _subscription = _serviceRequestStream.listen((snapshot) async {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          final newStatus = data['status'] ?? _currentStatus;
          bool hasOffer = await _checkHasOffers(widget.serviceRequest.id);

          if (newStatus == 'pending_confirmation' &&
              _currentStatus != 'pending_confirmation') {
            setState(() {
              _currentStatus = newStatus;
            });

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                showConfirmCompletionDialog(context, widget.serviceRequest.id);
              }
            });
          }

          setState(() {
            _currentStatus = newStatus;
            serviceData = data;
            _hasOffer = hasOffer;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _cancelReasonController.dispose();
    _priceController.dispose();
    _subscription?.cancel(); // Cancelar la suscripción al stream
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
          fetchedOfferedPrice: _fetchedOfferedPrice ??
              widget
                  .serviceRequest.offeredPrice, // Aquí pasas el precio ofertado
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

  void _acceptProposal(String selectedWorkerId) async {
    try {
      // Actualiza el documento en la colección 'services'
      await apiService.updateService(widget.serviceRequest.id, {
        'status': 'in_progress',
        'hasOffer': false,
        'workerId': selectedWorkerId,
      });

      // Actualiza solo la oferta del trabajador seleccionado en la colección 'offers'
      final offersQuerySnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('serviceId', isEqualTo: widget.serviceRequest.id)
          .where('workerId', isEqualTo: selectedWorkerId)
          .get();

      if (offersQuerySnapshot.docs.isNotEmpty) {
        final offerDoc = offersQuerySnapshot.docs.first;
        await offerDoc.reference.update({
          'status': 'in_progress',
          'hasOffer': false,
        });
      } else {
        print('No se encontró la oferta del trabajador seleccionado.');
      }

      // Llama al callback para notificar el cambio de estado
      widget.onStatusChanged('in_progress');

      // Cierra el diálogo o pantalla actual
      Navigator.of(context).pop();
    } catch (e) {
      // Manejo de errores
      print('Error al aceptar la propuesta: $e');
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
          .doc(widget
              .serviceRequest.id) // Asumiendo que el ID del servicio está aquí
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
            merge:
                true), // No sobrescribe otros campos, solo 'status' y 'offeredPrice'
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
        final String newStatus = serviceData['status'] ?? 'available';

        // Detectar cambio a pending_confirmation y mostrar cuadro de diálogo
        if (newStatus == 'pending_confirmation' &&
            _currentStatus != 'pending_confirmation') {
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

        final List<String> images =
            List<String>.from(serviceData['images'] ?? []);
        final String description =
            serviceData['description'] ?? 'Sin descripción';
        final String categoryName =
            serviceData['categoryId'] ?? 'Sin categoría';
        final String expertiseName =
            serviceData['expertiseName'] ?? 'Sin subcategoría';

        // Usar _fetchedOfferedPrice obtenido de ApiService
        final double? offeredPrice = _workerOfferedPrice;
        print('Precio Ofertado Obtenido: $offeredPrice'); // Depuración

        final WorkerDetails? workerDetails = widget.workerDetails;
        final List<Map<String, dynamic>> expertises =
            List<Map<String, dynamic>>.from(serviceData['expertises'] ?? []);

        return Scaffold(
          appBar: AppBar(
            iconTheme: IconThemeData(color: Colors.white),
            title: Text(
              'Detalles del Servicio',
              style: MyTextStyles.buttonTextStyle,
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: const Color(0xFF1A819A), width: 2.0),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado: ${statusNames[_currentStatus] ?? 'Desconocido'}',
                      style: MyTextStyles.inputTextStyle6,
                    ),
                    const SizedBox(height: 16.0),
                    _buildRichText('Descripción:', description),
                    const SizedBox(height: 16.0),
                    _buildRichText(
                        'Precio Ofertado:',
                        _workerOfferedPrice != null
                            ? '\$${_workerOfferedPrice!.toStringAsFixed(2)}'
                            : 'No ofertado'),
                    const SizedBox(height: 16.0),

                    // Mostrar imágenes en un carrusel
                    if (images.isNotEmpty)
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 200.0,
                          enlargeCenterPage: true,
                          autoPlay: true,
                          aspectRatio: 16 / 9,
                          autoPlayCurve: Curves.fastOutSlowIn,
                          enableInfiniteScroll: true,
                          autoPlayAnimationDuration:
                              Duration(milliseconds: 500),
                          viewportFraction: 0.5,
                        ),
                        items: images.map((url) {
                          return Builder(
                            builder: (BuildContext context) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ImageViewer(imageUrl: url),
                                    ),
                                  );
                                },
                                child: Hero(
                                  tag: url,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12.0),
                                    child: CachedNetworkImage(
                                      imageUrl: url,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          CircularProgressIndicator(),
                                      errorWidget: (context, url, error) =>
                                          Icon(Icons.error),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 16.0),
                    // Mostrar habilidades
                    if (expertises.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: expertises.map((expertise) {
                          return Text(
                            'Tipo de servicio: ${expertise['name'] ?? 'Sin nombre'}',
                            style: MyTextStyles.inputTextStyle6,
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 16.0),

                    // Mostrar detalles del trabajador con un botón de expansión
                    if (workerDetails != null ||
                        _currentStatus == 'in_progress')
                      ExpansionTile(
                        title: Text(
                          'Ver detalles del trabajador',
                          style: MyTextStyles.inputTextStyle6,
                        ),
                        children: [
                          _buildWorkerDetails(workerDetails!, serviceData),
                        ],
                      ),

                    _buildActionButtons(context, widget.workerId),
                    // Mostrar el botón "Hacer el pago" solo si el estado es 'pending_confirmation'
                    if (_currentStatus == 'pending_confirmation')
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: ElevatedButton(
                          onPressed: () {
                            showConfirmCompletionDialog(
                                context, widget.serviceRequest.id);
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
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
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

  Widget _buildWorkerDetails(
      WorkerDetails worker, Map<String, dynamic>? serviceData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trabajador',
          style: MyTextStyles.inputTextStyle4,
        ),
        const SizedBox(height: 16.0),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedNetworkImage(
              imageUrl: worker.imagePath,
              height: 150.0,
              width: 150.0,
              fit: BoxFit.cover,
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) => Icon(Icons.error),
            ),
            const SizedBox(width: 16.0),
            CachedNetworkImage(
              imageUrl: worker.idDocumentImagePath,
              height: 150.0,
              width: 150.0,
              fit: BoxFit.cover,
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) => Icon(Icons.error),
            ),
          ],
        ),
        const SizedBox(height: 24.0),
        _buildRichText('Nombre:', worker.displayName ?? 'No disponible'),
        const SizedBox(height: 8.0),
        _buildRichText('Correo:', worker.email ?? 'No disponible'),
        const SizedBox(height: 8.0),
        _buildRichText('Nivel de Experiencia:',
            worker.expLevel?.toString() ?? 'No disponible'),
        const SizedBox(height: 8.0),
        _buildRichText(
          'Especialidad:',
          worker.expertises?.map((e) => e.name).join(', ') ?? 'No disponible',
        ),
      ],
    );
  }

  Widget _buildRichText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text.rich(
        TextSpan(
          text: '$label ',
          style: MyTextStyles.inputTextStyle6,
          children: [
            TextSpan(
              text: value,
              style: MyTextStyles.inputTextStyle1,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

// Widget para los botones de acción según el estado
  Widget _buildActionButtons(BuildContext context, String selectedWorkerId) {
    debugPrint("Valor de _hasOffer: $_hasOffer"); // Depuración

    if (_hasOffer == true) {
      // Comparación explícita
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: () => _acceptProposal(selectedWorkerId),
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
    }

    if (_currentStatus == 'in_progress') {
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
              backgroundColor: const Color(0xFF830A09),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final userId = FirebaseAuth.instance.currentUser?.uid;

              print("Botón de Chat presionado");
              print("workerId: ${widget.workerId}");
              print("userId (actual): $userId");

              if (userId == null) {
                print("Error: userId es null, usuario no autenticado");
                return;
              }

              _openChat(widget.workerId, userId);
            },
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
              backgroundColor: const Color(0xFF1A819A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          )
        ],
      );
    }

    if (_currentStatus == 'available') {
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
              backgroundColor: const Color(0xFF830A09),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            ),
          ),
        ],
      );
    }

    return SizedBox.shrink();
  }

  void _openChat(String workerId, String userId) async {
  print("Abriendo chat...");
  final chatId = _generateChatId(workerId, userId);
  print("Chat ID generado: $chatId");

  final chatDoc = FirebaseFirestore.instance.collection('chats').doc(chatId);

  final chatSnapshot = await chatDoc.get();
  print("Existe chat? ${chatSnapshot.exists}");

  if (!chatSnapshot.exists) {
    print("Creando nuevo documento de chat...");
    await chatDoc.set({
      'chatId': chatId,
      'participants': [userId, workerId],
      'timestamp': FieldValue.serverTimestamp(),
    });
    print("Chat creado exitosamente");
  } else {
    print("El chat ya existe");
  }

  // Navegar a la pantalla de chat
  print("Navegando a la pantalla de chat");
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChatScreen(
        chatId: chatId,
        userId: userId,
        workerId: workerId,
        isUser: true, // Add the required 'isUser' parameter
      ),
    ),
  );
}


  String _generateChatId(String workerId, String userId) {
    // Generar un ID único basado en los IDs de los participantes
    return workerId.hashCode <= userId.hashCode
        ? '$workerId\_$userId'
        : '$userId\_$workerId';
  }
}