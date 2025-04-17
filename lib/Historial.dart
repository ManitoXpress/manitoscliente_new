import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../request/ResponseGet.dart';
import '../request/ResponsePost.dart';
import '../request/dataprofile.dart';
import '../request/requestLocation.dart';
import '../request/requestServiceType.dart';
import '../request/requestStatus.dart';
import '../request/requestWoker.dart';
import '../request/resquest.dart';
import '../utils/offerRepository.dart';
import '../utils/serviceCancelled.dart';
import '../utils/serviceComplete.dart';
import '../utils/serviceFetcher.dart';
import '../utils/serviceInProgress.dart';
import '../widgets/serviceList.dart';

import 'Styles/stilo.dart';
import 'controller/RegisController.dart';
import 'controller/notificationService.dart';
import 'controller/serviceFetcher.dart';

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
      hasOffer: false,
      offers: [],
      workerDetails: WorkerDetails(
        id: '',
        phoneNumber: '',
        certificateImagePaths: '',
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
      subcategoryName: '',
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
      points: 0,
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
      referrerUserId: '',
      referralCode: '',
      points: 0,
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
          'status', // Corregido de 'available' a 'status'
          userId,
          token ?? '',
          [],
        ),
        _offerRepository.fetchOffersForUser(
            'offer', // type: String (por ejemplo, el estado "offer")
            userId, // userId: String (ID del usuario autenticado)
            token ?? '', // token: String
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
              userId: userId, // Se asigna el userId real aquí
              workerId: '',
              isFavorite: false,
              acceptedTerms: false,
              expertises: [],
              status: Status(id: 'offer', name: 'Ofertado'),
              hasOffer: false,
              offers: [],
              workerDetails: WorkerDetails(
                id: '',
                phoneNumber: '',
                certificateImagePaths: '',
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
              subcategoryName: '',
            ),
            userId // Aquí se pasa el deviceId; si cuentas con un deviceId real, reemplázalo.
            ),
        _serviceRepository2.fetchServicesByInProgress(
          'in_progress', // type: String
          'status', // column: String (nombre de columna para filtrar)
          userId, // userId: String
          token ?? '', // token: String
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
    double? _fetchedOfferedPrice;

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
          preferredSize: Size.fromHeight(18.0),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelPadding: EdgeInsets.symmetric(horizontal: 8.0),
              labelStyle: MyTextStyles.tabTextStyle,
              unselectedLabelStyle: MyTextStyles.unselectedTabTextStyle,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(width: 3.0, color: Color(0xFF1A819A)),
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
                  _fetchedOfferedPrice,
                  screenWidth,
                  screenHeight,
                  userId,
                  token,
                  deviceId,
                ),
                _buildServiceListByStatus(
                  'offer',
                  _fetchedOfferedPrice,
                  screenWidth,
                  screenHeight,
                  userId,
                  token,
                  deviceId,
                ),
                _buildServiceListByStatus(
                  'in_progress',
                  _fetchedOfferedPrice,
                  screenWidth,
                  screenHeight,
                  userId,
                  token,
                  deviceId,
                ),
                _buildServiceListByStatus(
                  'completed',
                  _fetchedOfferedPrice,
                  screenWidth,
                  screenHeight,
                  userId,
                  token,
                  deviceId,
                ),
                // Agrega esta quinta pestaña
                _buildServiceListByStatus(
                  'cancelled',
                  _fetchedOfferedPrice,
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
    double? _fetchedOfferedPrice,
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
          'status', // Corregido de 'available' a 'status'
          userId,
          token,
          [],
        );
        break;
      case 'offer':
        future = offerRepository.fetchOffersForUser(
            statusIds, // type: String (por ejemplo, el status que deseas filtrar)
            userId, // userId: String (ID del usuario autenticado)
            token, // token: String
            ServiceRequest(
              // service: ServiceRequest de ejemplo
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
              userId: userId, // se asigna el userId real
              workerId: '',
              isFavorite: false,
              acceptedTerms: false,
              expertises: [],
              status: Status(id: 'offer', name: 'Ofertado'),
              hasOffer: false,
              offers: [],
              workerDetails: WorkerDetails(
                id: '',
                phoneNumber: '',
                certificateImagePaths: '',
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
              subcategoryName: '',
            ),
            userId // deviceId: aquí puedes usar el userId o reemplazarlo por el deviceId real
            );
        break;

      case 'in_progress':
        future = Future.wait([
          _serviceRepository2
              .fetchServicesByInProgress(
            'in_progress',
            userId,
            'status',
            token,
          )
              .catchError((e) {
            print("Error al obtener in_progress: $e");
            return <ServiceRequest>[]; // Retornar lista vacía en caso de error
          }),
          _serviceRepository2
              .fetchServicesByInProgress(
            'pending_confirmation',
            userId,
            'status',
            token,
          )
              .catchError((e) {
            print("Error al obtener pending_confirmation: $e");
            return <ServiceRequest>[]; // Retornar lista vacía en caso de error
          }),
          _serviceRepository2
              .fetchServicesByInProgress(
            'pending_confirmation2',
            userId,
            'status',
            token,
          )
              .catchError((e) {
            print("Error al obtener pending_confirmation2: $e");
            return <ServiceRequest>[]; // Retornar lista vacía en caso de error
          }),
        ]).then((results) {
          final servicesInProgress = results[0] ?? [];
          final pendingConfirmationServices = results[1] ?? [];
          final pendingConfirmationServices2 = results[2] ?? [];
          return [
            ...servicesInProgress,
            ...pendingConfirmationServices,
            ...pendingConfirmationServices2
          ];
        });
        break;

      case 'completed':
        future = _serviceRepository3.fetchServicesByComplete(
          statusIds,
          'status', // Corregido de 'available' a 'status'
          userId,
          token,
          [],
        );
        break;

      case 'cancelled':
        future = _serviceRepository4.fetchServicesByCancelled(
          statusIds,
          'status', // Corregido de 'available' a 'status'
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
          return Center(child: Text("No hay servicios."));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
              child: Text("No hay servicios disponibles para este estado."));
        }

        final services = snapshot.data!;
        if (statusIds == 'available') {
          final services = snapshot.data!;

          return ServiceListBuilder.buildServiceListAvailable(
            services, // Servicio asociado

            screenWidth,
            screenHeight,
            userId,
            userData,
          );
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
          final offers = services.expand((s) => s.offers).toList();
          return ServiceListBuilder.buildServiceList(
            services, // Servicio asociado
            offers,
            screenWidth,
            screenHeight,
            userId,
            userData,
          );
        }
        if (statusIds == 'completed') {
          final services = snapshot.data!;

          return ServiceListBuilder.buildServiceListComplete(
            services, // Servicio asociado

            screenWidth,
            screenHeight,
            userId,
            userData,
          );
        }
        if (statusIds == 'cancelled') {
          final services = snapshot.data!;

          return ServiceListBuilder.buildServiceListCancelled(
            services, // Servicio asociado

            screenWidth,
            screenHeight,
            userId,
            userData,
          );
        }
        final offers = services.expand((s) => s.offers).toList();
        return ServiceListBuilder.buildServiceList(
          services, // Servicio asociado

          offers,
          screenWidth,
          screenHeight,
          userId,
          userData,
        );
      },
    );
  }
}
