import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:manitoscliente_new/ServicesResponse/ResponseGet.dart';
import 'package:manitoscliente_new/ServicesResponse/ResponsePost.dart';
import 'package:manitoscliente_new/ServicesResponse/dataprofile.dart';

import 'package:manitoscliente_new/ServicesResponse/resquest.dart';
import 'package:manitoscliente_new/Styles/stilo.dart';
import 'package:manitoscliente_new/chatscreen.dart';
import 'package:manitoscliente_new/main.dart';
import 'package:manitoscliente_new/metodos/RegisController.dart';
import 'package:manitoscliente_new/metodos/baseurl.dart';
import 'package:manitoscliente_new/metodos/serviceFetcher.dart';

import 'package:manitoscliente_new/metodos/ticketController.dart';
import 'package:manitoscliente_new/utils/cacheLocal.dart';
import 'package:manitoscliente_new/utils/notification.dart';
import 'package:manitoscliente_new/utils/serviceFetcher.dart';
import 'package:manitoscliente_new/utils/status.dart';

import 'package:manitoscliente_new/utils/timeLines.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:manitoscliente_new/widgets/offerRepository.dart';

class Historial extends StatefulWidget {
  final VoidCallback? onTabTapped;

  const Historial({Key? key, this.onTabTapped}) : super(key: key);

  @override
  _HistorialState createState() => _HistorialState();
}

class _HistorialState extends State<Historial>
    with SingleTickerProviderStateMixin {
  List<ServiceRequest> serviceRequests = [];
  List<Status> statuses = [];
  late final UserData userData;
  int unreadMessagesCount = 0;
  int offerServiceCount = 0;
  StreamSubscription? _foregroundServiceListener;

  late final RegistrationData registrationData;
  late TabController _tabController;
  final ApiService apiService = ApiService();
  late NotificationService notificationService;
  late final ServiceDataFetcher serviceDataFetcher;
  late OfferRepository _offerRepository;

  Timer? _notificationTimer;
  bool isLoading = false;
  int notificationCount = 0;
  String workerId = '';
  String userId = '';
  String authToken = '';

  String deviceId = '';
  late ServiceRequest? serviceRequest;
  String value = '';

  final ServiceRepository _serviceRepository = ServiceRepository(
    apiService: ApiService(),
    firestore: FirebaseFirestore.instance,
  );

  NotificationService _notificationService = NotificationService();
  int inProgressServiceCount = 0;

  int globalServiceCount = 0;
  int availableServiceCount = 0;

  int completedServiceCount = 0;
  int cancelledServiceCount = 0;

  @override
  void initState() {
    super.initState();
    serviceRequest = ServiceRequest(
      serviceDateTime: '',
      id: '',
      devicesId: '',
      description: '',
      images: [],
      location: {},
      offeredPrice: 0.0,
      serviceType:
          ServiceType(id: '', name: '', selectedDate: '', selectedTime: ''),
      userId: '',
      workerId: '',
      isFavorite: false,
      selectedDate: null,
      selectedTime: null,
      acceptedTerms: false,
      expertises: [],
      status: Status(id: '', name: ''),
      subcategoryName: '',
      hasOffer: false,
      offers: [],
      workerDetails: WorkerDetails(
        id: '',
        phoneNumber: '',
        certificateImagePaths: [],
        idDocumentImagePath: '',
        imagePath: '',
        displayName: '',
        email: '',
        expLevel: [],
        expertises: [],
        criminalRecordImagePath: '',
        fcmToken: '',
        location: '',
        verificationStatus: '',
        idCardNumber: '',
      ),
    );
    registrationData = RegistrationData(
      userId: '',
      displayName: '',
      phoneNumber: '',
      paymentType: '',
      selectedCountryCode: '',
      location: {},
      email: '',
      devicesId: '',
      fcmToken: '',
    );

    userData = UserData(
      displayName: '',
      email: '',
      phoneNumber: '',
      userId: '',
      location: {},
      paymentType: '',
      selectedCountryCode: '',
      registrationData: registrationData,
      getToken: '',
    );

    // Configurar el controlador de pestañas
    _tabController = TabController(length: 5, vsync: this);

    // Obtener datos y verificar ofertas
    fetchDataForUserId().then((_) {
      _checkForOffers();
    });
    fetchDataForUserId();

    // Calcular mensajes no leídos
    calculateUnreadMessagesCount();
    _refreshHistorial();
    _fetchServiceIdForUser();
    _offerRepository = OfferRepository(
    apiService2: ApiService2(),
    serviceDataFetcher: ServiceDataFetcher(),
    firestore: FirebaseFirestore.instance,
  );

    // Inicializar servicio de notificaciones

    // Activar listener de notificaciones en primer plano
  }
Future<void> _refreshHistorial() async {
  setState(() {
    availableServiceCount = 0;
    offerServiceCount = 0;
    inProgressServiceCount = 0;
    completedServiceCount = 0;
    cancelledServiceCount = 0;
  });

  serviceRequest ??= ServiceRequest(
    serviceDateTime: '',
    id: '',
    devicesId: '',
    description: '',
    images: [],
    location: {},
    offeredPrice: 0.0,
    serviceType: ServiceType(id: '', name: '', selectedDate: '', selectedTime: ''),
    userId: '',
    workerId: '',
    isFavorite: false,
    selectedDate: null,
    selectedTime: null,
    acceptedTerms: false,
    expertises: [],
    status: Status(id: '', name: ''),
    subcategoryName: '',
    hasOffer: false,
    offers: [],
    workerDetails: WorkerDetails(
      id: '',
      phoneNumber: '',
      certificateImagePaths: [],
      idDocumentImagePath: '',
      imagePath: '',
      displayName: '',
      email: '',
      expLevel: [],
      expertises: [],
      criminalRecordImagePath: '',
      fcmToken: '',
      location: '',
      verificationStatus: '',
      idCardNumber: '',
    ),
  );

  try {

  
  } catch (e) {
    print("Error al obtener los servicios: $e");
  }
}


  Future<void> _fetchServiceIdForUser() async {
    try {
      final apiService2 = ApiService2();
      final services = await apiService2.fetchServicesByUserId(userData.userId);
      if (services.isNotEmpty) {
        setState(() {
          serviceRequest!.id = services.first
              .id; // Asumiendo que el primer servicio tiene el serviceId que necesitamos
        });
      }
    } catch (e) {
      print('Error al obtener el serviceId: $e');
    }
  }

  Future<void> _checkForOffers() async {
    // Espera a que se carguen los datos
    await Future.delayed(Duration(seconds: 2));

    final hasOffers =
        serviceRequests.any((request) => request.status.id == 'offer');

    if (hasOffers) {
      // Cambia a la pestaña de 'Ofertados' si hay servicios en oferta
      _tabController.animateTo(1);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _foregroundServiceListener?.cancel();
    super.dispose();
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
        final offeredPrice = offerData['offeredPrice'];

        if (offeredPrice is String) {
          return double.tryParse(offeredPrice);
        } else if (offeredPrice is double) {
          return offeredPrice;
        }
      }
    } catch (e) {
      print('Error al obtener el precio ofertado: $e');
    }
    return null;
  }

  Future<void> fetchDataForUserId() async {
    try {
      // Obtener el usuario actual y su userId
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        print('Usuario no autenticado');
        throw Exception('Usuario no autenticado.');
      }

      final userId = user.uid;
      final token =
          await user.getIdToken(); // Obtener el token del usuario autenticado

      // Validar el token
      if (token == null || token.isEmpty) {
        throw Exception('El token no puede estar vacío.');
      }

      // Verificar si los datos ya están en el caché
      final cachedRequest =
          await LocalCacheService.getCachedServiceRequest(userId);
      if (cachedRequest != null) {
        print('Datos del caché encontrados. Mostrando datos del caché...');
        setState(() {
          serviceRequests = [cachedRequest];
          statuses = [cachedRequest.status];
        });
        return;
      }

      // Obtener el deviceId
      final deviceId = await obtenerDeviceId();

      // Guardar el deviceId en Firestore si no está presente
      await saveDeviceIdToFirestore(userId, deviceId);

      // Datos para la solicitud
      final column = "userId";
      final value = userId;
      final type = "";

      // Realizar la solicitud al backend
      final serviceResponse = await ApiService2().getByUserId(
        userId: userId,
        authToken: token,
        column: column,
        value: value,
        type: type,
        deviceId: deviceId,
      );

      if (serviceResponse.statusCode == 200) {
        try {
          // Decodificar la respuesta JSON
          final List<dynamic> jsonDataList = json.decode(serviceResponse.body);

          print(
              "Datos obtenidos del backend: $jsonDataList"); // Log para ver los datos

          // Filtrar y mapear los datos a objetos ServiceRequest
          List<ServiceRequest> serviceRequestsList = jsonDataList
              .map((item) {
                // Verificar el userId
                final serviceUserId = item['userId']?.toString();
                print(
                    "Comparando userId: $serviceUserId con el userId del usuario: $userId"); // Log para verificar los IDs

                // Si los userId no coinciden, retorna null
                if (serviceUserId != userId) {
                  return null;
                }

                final statusName = item['status'] as String? ?? 'unknown';
                final status = Status(
                    id: statusName, name: Status.getNameById(statusName));

                final expertisesArray =
                    item['expertises'] as List<dynamic>? ?? [];
                final expertiseItem =
                    expertisesArray.isNotEmpty ? expertisesArray.first : {};

                return ServiceRequest(
                  expertises: [
                    Expertise(
                      id: expertiseItem['id'] ?? '',
                      name: expertiseItem['name'] ?? '',
                    )
                  ],
                  id: item['id'] ?? '',
                  serviceDateTime: item['serviceDateTime'] ?? '',
                  description: item['description'] ?? '',
                  images: (item['images'] as List<dynamic>?)
                          ?.map((image) => image as String? ?? '')
                          .toList() ??
                      [],
                  location: Map<String, double>.from(
                    (item['location'] as Map<String, dynamic>?)
                            ?.map((key, value) {
                          return MapEntry(
                              key, (value is int) ? value.toDouble() : value);
                        }) ??
                        {},
                  ),
                  offeredPrice: _parseOfferedPrice(item['offeredPrice']),
                  userId: item['userId'] ?? '',
                  workerId: item['workerId'] ?? '',
                  status: status,
                  isFavorite: item['isFavorite'] as bool? ?? false,
                  acceptedTerms: item['acceptedTerms'] as bool? ?? false,
                  serviceType: ServiceType(
                    name: item['serviceType'] ?? '',
                    id: '',
                    selectedDate: '',
                    selectedTime: '',
                  ),
                  subcategoryName: item['subcategoryName'] ?? '',
                  devicesId: item['devicesId'] ?? '',
                  hasOffer: false,
                  offers: [],
                );
              })
              .where((item) => item != null) // Filtra los valores nulos
              .cast<ServiceRequest>() // Convierte a List<ServiceRequest>
              .toList();

          print(
              "Servicios filtrados: $serviceRequestsList"); // Log para verificar los servicios filtrados

          // Actualizar el estado y almacenar en caché
          setState(() {
            serviceRequests = serviceRequestsList;
            statuses = serviceRequestsList
                .map((request) => request.status) // Accede de forma segura
                .toList();
          });

          // Cachear los servicios para futuros accesos
          for (var request in serviceRequests) {
            LocalCacheService.cacheServiceRequest(request);
          }

          print(
              'Servicios cargados con éxito. Total de servicios obtenidos del backend: ${serviceRequests.length}');
        } catch (e) {
          print('Error al decodificar la respuesta JSON: $e');
        }
      } else {
        print(
            'Error al obtener datos del backend. Código de estado: ${serviceResponse.statusCode}');
      }
    } catch (e) {
      print('Error en la solicitud HTTP: $e');
    }
  }

  Future<void> saveDeviceIdToFirestore(String userId, String deviceId) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Verificar si el dispositivo ya está registrado
      final deviceDoc =
          await firestore.collection('devices').doc(deviceId).get();

      if (!deviceDoc.exists) {
        await firestore.collection('devices').doc(deviceId).set({
          'userId': userId,
          'deviceId': deviceId,
          'fcmToken': await FirebaseMessaging.instance.getToken(),
        });
        print('Device ID guardado correctamente en Firestore.');
      }
    } catch (e) {
      print('Error al guardar el Device ID en Firestore: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchOffers() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    // Primero, obtener los IDs de los servicios del usuario actual
    final servicesSnapshot = await FirebaseFirestore.instance
        .collection('services')
        .where('userId', isEqualTo: userId)
        .get();

    final serviceIds = servicesSnapshot.docs.map((doc) => doc.id).toList();

    if (serviceIds.isEmpty) {
      return []; // Si no hay servicios, no hay ofertas
    }

    // Luego, buscar las ofertas relacionadas con estos servicios
    final offersSnapshot = await FirebaseFirestore.instance
        .collection('offers')
        .where('serviceId', whereIn: serviceIds)
        .get();

    return offersSnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Obtener el userId de Firebase Auth
    final userId = FirebaseAuth.instance.currentUser?.uid;

    // Asegúrate de que userId no sea nulo
    if (userId == null) {
      return Scaffold(
        body: Center(
          child: Text('Usuario no autenticado.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelPadding: EdgeInsets.symmetric(horizontal: 8.0),
              labelStyle: MyTextStyles.tabTextStyle,
              unselectedLabelStyle: MyTextStyles.unselectedTabTextStyle,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(width: 3.0, color: Color(0xFF84090D)),
                insets: EdgeInsets.symmetric(horizontal: 20.0),
              ),
              tabs: [
                Tab(
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Icon(Icons.task_alt, color: Colors.black),
                  ),
                  text: 'Disponibles ($availableServiceCount)',
                ),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Icon(Icons.local_offer, color: Colors.black),
                          ),
                          if (offerServiceCount > 0)
                            Positioned(
                              top: -10,
                              right: -10,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Text(
                                  offerServiceCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4.0),
                      Text(
                        'Ofertados',
                        style: TextStyle(fontSize: 12.0),
                      ),
                    ],
                  ),
                ),
                Tab(
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Icon(Icons.assignment_ind, color: Colors.black),
                  ),
                  text: 'Asignados ($inProgressServiceCount)',
                ),
                Tab(
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Icon(Icons.check_circle, color: Colors.black),
                  ),
                  text: 'Completados ($completedServiceCount)',
                ),
                Tab(
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Icon(Icons.cancel, color: Colors.black),
                  ),
                  text: 'Cancelados ($cancelledServiceCount)',
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Text(
                  'Historial',
                  style: MyTextStyles.buttonTextStyle3,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF1A819A)),
                  onPressed: _refreshHistorial,
                ),
              ],
            ),
          ),
          const SizedBox(height: 1.0),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildServiceListByStatus(
                    'available', screenWidth, screenHeight, userId, authToken),
                _buildServiceListByStatus(
                    'offer', screenWidth, screenHeight, userId, authToken),
                _buildServiceListByStatus('in_progress,pending_confirmation',
                    screenWidth, screenHeight, userId, authToken),
                _buildServiceListByStatus(
                    'completed', screenWidth, screenHeight, userId, authToken),
                _buildServiceListByStatus(
                    'cancelled', screenWidth, screenHeight, userId, authToken),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildServiceListByStatus(
  String statusIds,
  double screenWidth,
  double screenHeight,
  String userId,
  String token,
) {
  Future<List<ServiceRequest>>? future;

  final offerRepository = OfferRepository(
    apiService2: ApiService2(),
    serviceDataFetcher: ServiceDataFetcher(),
    firestore: FirebaseFirestore.instance,
  );

  switch (statusIds) {
    case 'offer':
      future = offerRepository.fetchOffersForUser(
        statusIds,
        userId,
        token,
        ServiceRequest(
          id: '',
          serviceDateTime: '',
          devicesId: '',
          description: '',
          images: [],
          location: {},
          offeredPrice: 0.0,
          serviceType: ServiceType(id: '', name: '', selectedDate: '', selectedTime: ''),
          userId: '',
          workerId: '',
          isFavorite: false,
          acceptedTerms: false,
          expertises: [],
          status: Status(id: '', name: ''),
          subcategoryName: '',
          hasOffer: false,
          offers: [],
        ),
        userId,
      );
      break;

    case 'available':
    case 'in_progress':
      future = _serviceRepository.fetchServicesByStatus(
        statusIds,
        'status',
        userId,
        token,
        [],
      );
      break;

    default:
      return Center(child: Text("Estado no válido."));
  }

  return FutureBuilder<List<ServiceRequest>>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Center(child: Text("Error al cargar servicios."));
      }

      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return Center(child: Text("No hay servicios disponibles para este estado."));
      }

      final services = snapshot.data!;

      if (statusIds == 'offer') {
        final offers = services.expand((service) => service.offers).toList();
        return _buildOfferList(offers, screenWidth, screenHeight, userId);
      } else {
        return _buildServiceList(services, screenWidth, screenHeight, userId);
      }
    },
  );
}

Widget _buildOfferList(List<Offer> offers, double screenWidth,
    double screenHeight, String userId) {
  final serviceDataFetcher = ServiceDataFetcher();
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
    child: ListView.builder(
      itemCount: offers.length,
      itemBuilder: (context, index) {
        final offer = offers[index];
        print('Construyendo tarjeta para oferta: ${offer.id}');

        return GestureDetector(
          onTap: () async {
          try {
            print('Cargando detalles del trabajador para oferta: ${offer.id}');
            final workerDetails = await serviceDataFetcher.fetchWorkerDetails(offer.workerId);

            if (workerDetails == null) {
              print('Detalles del trabajador no encontrados.');
              return;
            }

            print('Detalles del trabajador cargados: ${workerDetails.displayName}');

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceFormWithTimeline(
                  serviceRequest: ServiceRequest(
                    id: offer.serviceId,
                    serviceDateTime: '',
                    devicesId: '',
                    description: '',
                    images: [],
                    location: {}, // Asegúrate de usar un mapa compatible
                    offeredPrice: offer.offeredPrice,
                    serviceType: ServiceType(id: '', name: '', selectedDate: '', selectedTime: ''),
                    workerId: offer.workerId,
                    isFavorite: false,
                    acceptedTerms: false,
                    expertises: offer.expertises,
                    status: Status(id: '', name: ''),
                    subcategoryName: offer.subcategoryName,
                    hasOffer: false,
                    offers: [],
                    workerDetails: workerDetails, // Asegúrate de que esto sea compatible
                    userId: '',
                  ),
                  initialStatus: offer.status.id,
                  onComplete: (status) {
                    print('Estado completado: $status');
                  },
                  onStatusChanged: (newStatus) {
                    print('Estado cambiado a: $newStatus');
                  },
                  userData: userData,
                  workerId: offer.workerId,
                  workerDetails: workerDetails,
                  offers: [],
                  images: [],
                ),
              ),
            );
          } catch (e) {
            print('Error al cargar los detalles del trabajador: $e');
          }
        },

          child: Container(
            margin: EdgeInsets.only(bottom: screenHeight * 0.02),
            width: screenWidth,
            height: screenHeight * 0.24,
            child: CustomPaint(
              size: Size(screenWidth, screenHeight * 0.35),
              painter: CustomTicketShapePainter(status: Status(id: '', name: '')),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            SizedBox(height: 30),
                            Text('Categoría:',
                                style: MyTextStyles.drawerButtonTextStyle),
                            Text(offer.subcategoryName,
                                style: MyTextStyles.drawerButtonTextStyle5),
                            SizedBox(height: screenHeight * 0.01),
                            Text('Servicio:',
                                style: MyTextStyles.drawerButtonTextStyle),
                            Text(
                                offer.expertises
                                    .map((e) => e.name)
                                    .join(', '),
                                style: MyTextStyles.drawerButtonTextStyle5),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                                'Precio Ofertado: \$${offer.offeredPrice.toStringAsFixed(2)}',
                                style: MyTextStyles.drawerButtonTextStyle),
                          ],
                      ),
                    ),
                    SizedBox(width: 10),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Image.asset(
                        'assets/animations/manito.png',
                        width: 64,
                        height: 64,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}


  Widget _buildServiceList(List<ServiceRequest> services, double screenWidth,
      double screenHeight, String userId) {
    final serviceDataFetcher = ServiceDataFetcher();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: ListView.builder(
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          print('Construyendo tarjeta para servicio: ${service.id}');

          return GestureDetector(
            onTap: () async {
              try {
                print(
                    'Cargando detalles del trabajador para servicio: ${service.id}');
                final workerDetails = await serviceDataFetcher
                    .fetchWorkerDetails(service.workerId);
                print('Detalles del trabajador cargados: $workerDetails');

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceFormWithTimeline(
                      serviceRequest: service,
                      initialStatus: service.status.id,
                      onComplete: (status) {
                        print('Estado completado: $status');
                      },
                      onStatusChanged: (newStatus) {
                        print('Estado cambiado a: $newStatus');
                      },
                      userData: userData,
                      workerId: service.workerId,
                      images: service.images ?? [],
                      workerDetails: workerDetails,
                      offers: service.offers ?? [],
                    ),
                  ),
                );
              } catch (e) {
                print('Error al cargar los detalles del trabajador: $e');
              }
            },
            child: Container(
              margin: EdgeInsets.only(bottom: screenHeight * 0.02),
              width: screenWidth,
              height: screenHeight * 0.24,
              child: CustomPaint(
                size: Size(screenWidth, screenHeight * 0.35),
                painter: CustomTicketShapePainter(status: service.status),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 30),
                            Text('Categoría:',
                                style: MyTextStyles.drawerButtonTextStyle),
                            Text(service.subcategoryName,
                                style: MyTextStyles.drawerButtonTextStyle5),
                            SizedBox(height: screenHeight * 0.01),
                            Text('Servicio:',
                                style: MyTextStyles.drawerButtonTextStyle),
                            Text(
                                service.expertises
                                    .map((e) => e.name)
                                    .join(', '),
                                style: MyTextStyles.drawerButtonTextStyle5),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                                'Precio Ofertado: \$${service.offeredPrice.toStringAsFixed(2)}',
                                style: MyTextStyles.drawerButtonTextStyle),
                          ],
                        ),
                      ),
                      SizedBox(width: 10),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Image.asset(
                          'assets/animations/manito.png',
                          width: 64,
                          height: 64,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void calculateUnreadMessagesCount() async {
    int count = 0;
    for (var request in serviceRequests) {
      final messages = await FirebaseFirestore.instance
          .collection('chats')
          .doc(request.id)
          .collection('messages')
          .where('unread', isEqualTo: true)
          .get();
      count += messages.docs.length;
    }
    setState(() {
      unreadMessagesCount = count;
    });
  }

  double _parseOfferedPrice(dynamic value) {
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Error al convertir el precio ofrecido a double: $e');
        return 0.0;
      }
    } else if (value is num) {
      return value.toDouble();
    }
    return 0.0;
  }
}

String truncateDescription(String description) {
  final words = description.split(' ');
  if (words.length > 6) {
    return '${words.take(6).join(' ')}...';
  }
  return description;
}
