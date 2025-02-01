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
import 'package:manitoscliente_new/utils/serviceCancelled.dart';
import 'package:manitoscliente_new/utils/serviceComplete.dart';
import 'package:manitoscliente_new/utils/serviceFetcher.dart';
import 'package:manitoscliente_new/utils/serviceInProgress.dart';
import 'package:manitoscliente_new/utils/status.dart';

import 'package:manitoscliente_new/utils/timeLines.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:manitoscliente_new/widgets/offerRepository.dart';
import 'package:manitoscliente_new/widgets/serviceList.dart';

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
  String token = '';

  String deviceId = '';
  late ServiceRequest? serviceRequest;
  String value = '';

  final ServiceRepository _serviceRepository = ServiceRepository(
    apiService: ApiService(),
    firestore: FirebaseFirestore.instance,
  );
  final ServiceRepository2 _serviceRepository2 = ServiceRepository2(
    apiService: ApiService2(),
    firestore: FirebaseFirestore.instance,
  );
  final ServiceRepository3 _serviceRepository3 = ServiceRepository3(
    apiService: ApiService(),
    firestore: FirebaseFirestore.instance,
  );
  final ServiceRepository4 _serviceRepository4 = ServiceRepository4(
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
      location: Location(
        lat: 0.0, // Latitud predeterminada
        lng: 0.0, // Longitud predeterminada
      ),
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


  _offerRepository = OfferRepository(
    apiService2: ApiService2(),
    serviceDataFetcher: ServiceDataFetcher(),
    firestore: FirebaseFirestore.instance,
  );
}

// Método corregido _refreshHistorial
Future<void> _refreshHistorial() async {
  setState(() {
    isLoading = true;
    availableServiceCount = 0;
    offerServiceCount = 0;
    inProgressServiceCount = 0;
    completedServiceCount = 0;
    cancelledServiceCount = 0;
  });

  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Usuario no autenticado.");
      return;
    }
    final userId = user.uid;
    final token = await user.getIdToken();

    // Crear todas las llamadas en paralelo
    final futures = [
      _serviceRepository.fetchServicesByStatus(
        'available',
        'status',  // Corregido de 'available' a 'status'
        userId,
        token ?? '',
        [],
      ),
      _offerRepository.fetchOffersForUser(
        'offer',           // type: String
        'status',          // column: String (nombre de columna para filtrar)
        userId,            // userId: String
        token ?? '',       // token: String
        ServiceRequest(
          serviceDateTime: '',
          id: '',
          devicesId: '',
          description: '',
          images: [],
          location: {},
          offeredPrice: 0.0,
          serviceType: ServiceType(
            id: '',
            name: '',
            selectedDate: '',
            selectedTime: '',
          ),
          userId: '',
          workerId: '',
          isFavorite: false,
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
            location: Location(lat: 0.0, lng: 0.0),
            verificationStatus: '',
            idCardNumber: '',
          ),
        ),
        userId,
      ),
      _serviceRepository2.fetchServicesByInProgress(
        'offer',           // type: String
        'status',          // column: String (nombre de columna para filtrar)
        userId,            // userId: String
        token ?? '',       // token: String
        [],
    
      ),
      _serviceRepository.fetchServicesByStatus(
        'completed',
        'completed',
        userId,
        token ?? '',
        [],
      ),
      _serviceRepository.fetchServicesByStatus(
        'cancelled',
        'cancelled',
        userId,
        token ?? '',
        [],
      ),
    ];

    // Ejecutar todas las llamadas en paralelo
    final results = await Future.wait(futures);

    // Extraer resultados
    final availableServices = results[0] as List<ServiceRequest>;
    final offerServices = results[1] as List<ServiceRequest>;
    final inProgressServices = results[2] as List<ServiceRequest>;
    final completedServices = results[3] as List<ServiceRequest>;
    final cancelledServices = results[4] as List<ServiceRequest>;

    // Calcular total de ofertas
    final totalOffers = offerServices.fold<int>(
      0,
      (sum, service) => sum + service.offers.length,
    );

    // Actualizar estado
    setState(() {
      availableServiceCount = availableServices.length;
      offerServiceCount = totalOffers;
      inProgressServiceCount = inProgressServices.length;
      completedServiceCount = completedServices.length;
      cancelledServiceCount = cancelledServices.length;
      serviceRequests = [
        ...availableServices,
        ...offerServices,
        ...inProgressServices,
        ...completedServices,
        ...cancelledServices,
      ];
      isLoading = false;
    });

    // Navegar a ofertas si hay nuevas
    if (totalOffers > 0) {
      _tabController.animateTo(1);
    }

  } catch (e) {
    print("Error al actualizar el historial: $e");
    setState(() => isLoading = false);
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
                  'available',
                  screenWidth,
                  screenHeight,
                  userId,
                  token,
                  deviceId,
                ),
                _buildServiceListByStatus(
                  'offer',
                  screenWidth,
                  screenHeight,
                  userId,
                  token,
                  deviceId,
                ),
                _buildServiceListByStatus(
                  'in_progress',
                  screenWidth,
                  screenHeight,
                  userId,
                  token,
                  deviceId,
                ),
                _buildServiceListByStatus(
                  'complete',
                  screenWidth,
                  screenHeight,
                  userId,
                  token,
                  deviceId,
                ),
                // Agrega esta quinta pestaña
                _buildServiceListByStatus(
                  'cancelled',
                  screenWidth,
                  screenHeight,
                  userId,
                  token,
                  deviceId,
                ),
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
    String deviceId,
  ) {
    Future<List<ServiceRequest>>? future;

    final offerRepository = OfferRepository(
      apiService2: ApiService2(),
      serviceDataFetcher: ServiceDataFetcher(),
      firestore: FirebaseFirestore.instance,
    );

    switch (statusIds) {
      case 'available':
      future = _serviceRepository.fetchServicesByStatus(
        statusIds,
        'status',  // Corregido de 'available' a 'status'
        userId,
        token,
        [],
      );
      break;
      case 'offer':
  future = offerRepository.fetchOffersForUser(
    statusIds,          // type: String
    'offer',           // column: String (nombre de la columna en DB)
    userId,             // userId: String
    token,              // token: String
    ServiceRequest(     // service: ServiceRequest
      id: '',
      serviceDateTime: '',
      devicesId: '',
      description: '',
      images: [],
      location: {},
      offeredPrice: 0.0,
      serviceType: ServiceType(
        id: '',
        name: '',
        selectedDate: '',
        selectedTime: '',
      ),
      userId: userId,   // Usar el userId real
      workerId: '',
      isFavorite: false,
      acceptedTerms: false,
      expertises: [],
      status: Status(id: 'offer', name: 'Ofertado'), // Estado correcto
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
        location: Location(lat: 0.0, lng: 0.0),
        verificationStatus: '',
        idCardNumber: '',
      ),
      
    ),
    userId,

  );
  break;
  case 'in_progress':
      future = _serviceRepository2.fetchServicesByInProgress(
        statusIds,
        'status',  // Corregido de 'available' a 'status'
        userId,
        token,
         [],
        
      );
      break;
  case 'complete':
      future = _serviceRepository3.fetchServicesByComplete(
        statusIds,
        'status',  // Corregido de 'available' a 'status'
        userId,
        token,
        [],
      );
      break;

  case 'cancelled':
      future = _serviceRepository4.fetchServicesByCancelled(
        statusIds,
        'status',  // Corregido de 'available' a 'status'
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
          return Center(
              child: Text("No hay servicios disponibles para este estado."));
        }

        final services = snapshot.data!;
        if (statusIds == 'available') {
          final services = snapshot.data!;
          return ServiceListBuilder.buildServiceList(
              services, screenWidth, screenHeight, userId, userData);
        }

        if (statusIds == 'offer') {
            final services = snapshot.data!;
            // Extrae todas las ofertas de los servicios
            final offers = services.expand((s) => s.offers).toList();
            
            return ServiceListBuilder.buildOfferList(
              services, // Servicio asociado
              offers,
              screenWidth,
              screenHeight,
              userId,
              userData,
            );
          }
        if (statusIds == 'in_progress') {
          final services = snapshot.data!;
          return ServiceListBuilder.buildServiceList(
              services, screenWidth, screenHeight, userId, userData);
        }
        if (statusIds == 'complete') {
          final services = snapshot.data!;
          return ServiceListBuilder.buildServiceList(
              services, screenWidth, screenHeight, userId, userData);
        }
        if (statusIds == 'cancelled') {
          final services = snapshot.data!;
          return ServiceListBuilder.buildServiceList(
              services, screenWidth, screenHeight, userId, userData);
        }


        return ServiceListBuilder.buildServiceList(
            services, screenWidth, screenHeight, userId, userData);
      },
    );
  }
}
