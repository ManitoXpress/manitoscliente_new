import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:manitoscliente_new/provider/serviceFormProvider.dart';
import 'package:manitoscliente_new/request/ResponsePost.dart';
import 'package:manitoscliente_new/utils/chats.dart';
import 'package:manitoscliente_new/utils/fullMap.dart';
import 'package:manitoscliente_new/utils/imageComplete.dart';
import 'package:manitoscliente_new/widgets/completeDialog.dart';
import 'package:manitoscliente_new/widgets/imagePreview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Styles/stilo.dart';
import '../request/ResponseGet.dart';
import '../request/dataprofile.dart';
import '../request/requestWoker.dart';
import '../request/resquest.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  final ApiService apiService;
  final String userId;

  const ServiceFormWithTimeline({
    required this.serviceRequest,
    required this.initialStatus,
    required this.onComplete,
    required this.onStatusChanged,
    required this.userData,
    required this.workerId,
    required this.images,
    required this.workerDetails,
    required this.apiService,
    required this.offers,
    required this.userId, // Parámetro añadido
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
  String? _offerStatus;
  String? _previousStatus;
  bool _completionDialogShown = false;
  String? phoneNumber;
  String? displayName;

  List<Map<String, String>> comentarios = [];

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
    if (widget.serviceRequest.offers.isNotEmpty) {
      final offer = widget.serviceRequest.offers.first;
      _hasOffer = true;
      _offerStatus = offer.status.id; // Ej: "pending", "cancelled", etc.
      _fetchedOfferedPrice = offer.offeredPrice;
      if (_fetchedOfferedPrice != null) {
        _priceController.text = _fetchedOfferedPrice.toString();
      }
    }

    // Inicializar el stream
    _previousStatus = null; // <-- sin valor al arrancar
    _initializeServiceStream();
    _fetchWorkerOffer();
    _loadServiceComments();
    _fetchUserInfo();
  }

  Future<void> _loadServiceComments() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceRequest.id)
          .get();

      final data = doc.data();
      if (data == null || data['comments'] == null) {
        comentarios = [];
      } else {
        final raw = data['comments'] as List<dynamic>;
        comentarios = raw.map((c) => Map<String, String>.from(c)).toList();
      }

      setState(() {});
    } catch (e) {
      print('Error cargando comentarios desde Firestore: $e');
    }
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
      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      final newStatus = data['status'] as String? ?? 'available';

      final String? proofUrl = serviceData['completionImageUrl'] as String?;

      // 1) Detectar transición limpia a "completed"
      if (newStatus == 'completed' && _previousStatus != 'completed') {
        // Solo mostramos una vez
        if (!_completionDialogShown) {
          _completionDialogShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            showDialog(
              context: context,
              builder: (_) => PaymentDetailsDialog(
                offeredPrice: _workerOfferedPrice ??
                    0.0, // Provee un valor por defecto si es null
                completionImageUrl: proofUrl,
              ),
            );
          });
        }
      }

      // 2) Actualizar estados para la próxima iteración
      () async {
        final hasOffer = await _checkHasOffers(widget.serviceRequest.id);

        if (!mounted) return;

        setState(() {
          _previousStatus = newStatus;
          _currentStatus = newStatus;
          serviceData = data;
          _hasOffer = hasOffer;
        });
      }();
    });
  }

  @override
  void dispose() {
    _cancelReasonController.dispose();
    _priceController.dispose();
    _subscription?.cancel(); // Cancelar la suscripción al stream
    super.dispose();
  }

  void _mostrarComentarios(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final _comentarioController = TextEditingController();
    final api = ApiService2();
    final sr = widget.serviceRequest;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: FutureBuilder<Map<String, dynamic>>(
            future: api.fetchSingleService(
              'userId',
              sr.userId,
              'status',
              sr.devicesId,
              sr.id,
            ),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Text(
                    'Error cargando comentarios:\n${snap.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }
              if (!snap.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final serviceJson = snap.data!;
              final List<Map<String, String>> comentarios =
                  (serviceJson['comments'] as List<dynamic>? ?? [])
                      .map((e) => Map<String, String>.from(e as Map))
                      .toList();

              return DraggableScrollableSheet(
                expand: false,
                builder: (context, scrollController) {
                  return StatefulBuilder(
                    builder: (context, setModalState) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        child: Column(
                          children: [
                            Text(
                              'Comentarios (${comentarios.length})',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Divider(),
                            Expanded(
                              child: ListView.builder(
                                controller: scrollController,
                                itemCount: comentarios.length,
                                itemBuilder: (ctx, i) {
                                  final c = comentarios[i];
                                  final isClient = c['rol'] == 'cliente';
                                  final alignment = isClient
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start;
                                  final color = isClient
                                      ? const Color(0xFF1A819A)
                                      : const Color(0xFF841813);
                                  final textAlign = isClient
                                      ? TextAlign.end
                                      : TextAlign.start;
                                  final nombre =
                                      isClient ? 'Cliente' : 'Trabajador';

                                  return ListTile(
                                    title: Row(
                                      mainAxisAlignment: alignment,
                                      children: [
                                        Text(
                                          nombre,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: color,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          c['hora'] ?? '',
                                          style: TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      c['mensaje'] ?? '',
                                      textAlign: textAlign,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _comentarioController,
                                    decoration: InputDecoration(
                                      hintText: 'Escribe un comentario...',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.send),
                                  onPressed: () async {
                                    final text =
                                        _comentarioController.text.trim();
                                    if (text.isEmpty) return;

                                    final currentUid = user?.uid;
                                    String rol = 'desconocido';

                                    // Determinar rol revisando colecciones Firestore
                                    if (currentUid != null) {
                                      final userDoc = await FirebaseFirestore
                                          .instance
                                          .collection('users')
                                          .doc(currentUid)
                                          .get();
                                      if (userDoc.exists) {
                                        rol = 'cliente';
                                      } else {
                                        final workerDoc =
                                            await FirebaseFirestore.instance
                                                .collection('workers')
                                                .doc(currentUid)
                                                .get();
                                        if (workerDoc.exists) {
                                          rol = 'trabajador';
                                        }
                                      }
                                    }

                                    // Nombre fijo según rol
                                    final nombre = (rol == 'cliente')
                                        ? 'Cliente'
                                        : (rol == 'trabajador')
                                            ? 'Trabajador'
                                            : 'Anónimo';

                                    final now = TimeOfDay.now();
                                    final hora =
                                        '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

                                    final nuevo = {
                                      'nombre': nombre,
                                      'mensaje': text,
                                      'hora': hora,
                                      'rol': rol,
                                    };

                                    try {
                                      comentarios.add(nuevo);
                                      await api.patchServiceComments(
                                          sr.id, comentarios);
                                      setModalState(() {});
                                    } catch (e) {
                                      print('Error enviando comentario: $e');
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'No se pudo enviar el comentario'),
                                        ),
                                      );
                                    }

                                    _comentarioController.clear();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
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

  Future<void> _fetchUserInfo() async {
    try {
      final workerDoc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(widget.workerId)
          .get();
      if (workerDoc.exists) {
        setState(() {
          displayName = workerDoc['displayName'];
          phoneNumber = workerDoc['phoneNumber'];
        });
      }
    } catch (e) {
      print('Error al obtener datos del trabajador: $e');
    }
  }

  Future<void> _cancelService() async {
    final api = ApiService();
    try {
      // 1. Obtener token de autenticación
      final token = await api.getAuthToken();
      if (token == null) {
        throw Exception('No se pudo obtener el token de autenticación.');
      }

      // 2. Actualizar el estado del servicio en el backend
      await api.updateServiceStatus(
        widget.serviceRequest, // tu objeto ServiceRequest
        'cancelled', // nuevo estado
        token,
      );

      // 3. Iterar y actualizar el estado de cada oferta asociada
      for (final offer in widget.serviceRequest.offers) {
        await api.updateOfferStatus(
          offerId: offer.id,
          newStatus: 'cancelled',
        );
      }

      // 4. Feedback al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('El servicio y todas sus ofertas han sido cancelados.')),
      );

      // 5. Volver a la pantalla anterior
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error al cancelar servicio/ofertas: $e');
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
          return Center(
            child: Text('Error al cargar los datos del servicio'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final serviceData = snapshot.data?.data();
        if (serviceData == null) {
          return Center(child: Text('No se encontraron datos del servicio'));
        }

        // Actualizar estado y posición
        _currentStatus = serviceData['status'] as String? ?? 'available';
        _initialPosition = LatLng(
          (serviceData['location']?['lat'] as num?)?.toDouble() ?? 0.0,
          (serviceData['location']?['lng'] as num?)?.toDouble() ?? 0.0,
        );

        // Datos varios
        final List<String> images =
            List<String>.from(serviceData['images'] ?? []);
        final String description =
            serviceData['description'] as String? ?? 'Sin descripción';
        final String dateOnly =
            serviceData['date'] as String? ?? '—'; // e.g. "2025-06-15"
        final String timeOnly = serviceData['time'] as String? ?? '—';
        final double? offeredPrice = _workerOfferedPrice;
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
                  border: Border.all(
                    color: const Color(0xFF1A819A),
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado: ${statusNames[_currentStatus] ?? 'Desconocido'}',
                      style: MyTextStyles.inputTextStyle6,
                    ),
                    Text('Fecha: $dateOnly',
                        style: MyTextStyles.inputTextStyle1),
                    Text('Hora: $timeOnly',
                        style: MyTextStyles.inputTextStyle1),
                    const SizedBox(height: 5.0),
                    _buildRichText('Descripción:', description),
                    const SizedBox(height: 10.0),
                    _buildRichText(
                      'Precio Ofertado:',
                      offeredPrice != null
                          ? 'Bs ${offeredPrice.toStringAsFixed(2)}'
                          : 'No ofertado',
                    ),
                    const SizedBox(height: 16.0),

                    // Carrusel de imágenes
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
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ImageViewer(imageUrl: url),
                                  ),
                                ),
                                child: Hero(
                                  tag: url,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12.0),
                                    child: CachedNetworkImage(
                                      imageUrl: url,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) =>
                                          CircularProgressIndicator(),
                                      errorWidget: (_, __, ___) =>
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

                    // Habilidades/subcategorías
                    if (expertises.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: expertises.map((e) {
                          return Text(
                            'Tipo de servicio: ${e['name'] ?? 'Sin nombre'}',
                            style: MyTextStyles.inputTextStyle6,
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 16.0),

                    // Detalles del trabajador
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

                    // Botones de acción según estado (incluye el diálogo de pago al pulsar)
                    _buildActionButtons(context, widget.workerId),
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
    debugPrint(
        "hasOffer=$_hasOffer, offerStatus=$_offerStatus, serviceStatus=$_currentStatus");

    // 1) Si hay oferta y está en estado "pending" (o el que corresponda), mostramos solo los botones de propuesta
    if (_hasOffer) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _mostrarComentarios(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: EdgeInsets.symmetric(
                vertical: 25, // Altura fija del padding
                horizontal: MediaQuery.of(context).size.width *
                    0.2, // Padding dinámico basado en el ancho de la pantalla
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.comment, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Comentarios (${comentarios.length})',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    // 2) Si el servicio está en progreso
    else if (_currentStatus == 'in_progress') {
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
              print("workerId: ${widget.userId}");
              print("userId (actual): $userId");

              if (userId == null) {
                print("Error: userId es null, usuario no autenticado");
                return;
              }

              _openWhatsApp(userId);
            },
            icon: Icon(Icons.chat, color: Colors.white),
            label: Text(
              "WhatsApp",
              style: GoogleFonts.karla(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
        ],
      );
    }
    // 3) Servicio disponible sin ofertas pendientes
    else if (_currentStatus == 'available') {
      return Column(
        children: [
          Row(
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _mostrarComentarios(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: EdgeInsets.symmetric(
                vertical: 25, // Altura fija del padding
                horizontal: MediaQuery.of(context).size.width *
                    0.2, // Padding dinámico basado en el ancho de la pantalla
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.comment, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Comentarios (${comentarios.length})',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Ningún otro caso
    return SizedBox.shrink();
  }

  void _openWhatsApp(userId) async {
    if (phoneNumber == null) return;

    final whatsappUrl = Uri.parse(
        "https://wa.me/$phoneNumber?text=Hola $displayName, soy el cliente del trabajo desde ManitosXpress.");
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir WhatsApp.')),
      );
    }
  }
}