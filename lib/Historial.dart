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
import 'package:manitoscliente_new/metodos/RegisController.dart';

import 'package:manitoscliente_new/metodos/ticketController.dart';
import 'package:manitoscliente_new/utils/cacheLocal.dart';
import 'package:manitoscliente_new/utils/notification.dart';
import 'package:manitoscliente_new/utils/status.dart';

import 'package:manitoscliente_new/utils/timeLines.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Historial extends StatefulWidget {
  final VoidCallback? onTabTapped;

  const Historial({Key? key, this.onTabTapped}) : super(key: key);

  @override
  _HistorialState createState() => _HistorialState();
}

class _HistorialState extends State<Historial> with SingleTickerProviderStateMixin {
  List<ServiceRequest> serviceRequests = [];
  List<String> statuses = [];
  late final UserData userData;
  int unreadMessagesCount = 0;
  int offerServiceCount = 0;
  StreamSubscription? _foregroundServiceListener;

  late final RegistrationData registrationData;
  late TabController _tabController;
  final ApiService apiService = ApiService();
  late NotificationService notificationService;
  Timer? _notificationTimer;
  bool isLoading = false;
  int notificationCount = 0;
  NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    registrationData = RegistrationData(
      userId: '',
      displayName: '',
      phoneNumber: '',
      paymentType: '',
      selectedCountryCode: '',
      location: {},
      email: '', devicesId: '', fcmToken: '',
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

    // Calcular mensajes no leídos
    calculateUnreadMessagesCount();





 
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
  Future<WorkerDetails?> getWorkerDetails(String serviceId) async {
    try {
      print('Buscando en la colección "offers" con serviceId: $serviceId');
      final querySnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('serviceId', isEqualTo: serviceId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final offerData = querySnapshot.docs.first.data();
        final workerId = offerData['workerId'];

        if (workerId != null && workerId.isNotEmpty) {
          print('Obteniendo detalles del trabajador con workerId: $workerId');
          return await fetchWorkerDetails(workerId);
        } else {
          print(
              'workerId no válido o no encontrado en el documento de offers.');
        }
      } else {
        print(
            'No se encontró ningún documento en la colección "offers" con serviceId: $serviceId');
      }
    } catch (e) {
      print('Error al obtener detalles del trabajador: $e');
    }
    return null;
  }
  Future<String> obtenerDeviceId() async {
  try {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      final id = androidInfo.id?.toString() ?? 'Unknown Device ID';
      return id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      final id = iosInfo.identifierForVendor?.toString() ?? 'Unknown Device ID';
      return id;
    } else {
      return 'Unsupported Platform';
    }
  } catch (e) {
    print('Error obteniendo Device ID: $e');
    return 'Error Device ID';
  }
}

  Future<WorkerDetails?> fetchWorkerDetails(String workerId) async {
    try {
      print('Buscando en la colección "workers" con workerId: $workerId');
      final workerSnapshot = await FirebaseFirestore.instance
          .collection('workers')
          .doc(workerId)
          .get();

      if (workerSnapshot.exists) {
        print('Documento del trabajador encontrado.');
        final data = workerSnapshot.data()!;
        return WorkerDetails.fromMap(data);
      } else {
        print(
            'No se encontró ningún documento en la colección "workers" con workerId: $workerId');
      }
    } catch (e) {
      print('Error al obtener detalles del trabajador: $e');
    }
    return null;
  }
  Future<void> fetchDataForUserId() async {
  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userId = user.uid;
      final token = await user.getIdToken();

      // Verificar si los datos están en caché
      final cachedRequest = await LocalCacheService.getCachedServiceRequest(userId);
      if (cachedRequest != null) {
        print('Datos del caché encontrados. Mostrando datos del caché...');
        setState(() {
          serviceRequests = [cachedRequest];
          statuses = [cachedRequest.status.name];
        });
        return; // Salir si los datos del caché ya están disponibles
      }

      // Obtener el Device ID
      final deviceId = await obtenerDeviceId();
      final column = "";
      final value = "";
      final type = "";

      // Realizar solicitud al backend
      final serviceResponse = await ApiService2().getByUserId(
        userId,
        token ?? '',
        column,
        value,
        type,
        deviceId: deviceId,
      );

      if (serviceResponse.statusCode == 200) {
        // Procesar los datos recibidos
        final List<dynamic> jsonDataList =
          (json.decode(serviceResponse.body) as List<dynamic>? ?? [])
              .where((item) => item != null && item['userId'] == userId) // Filtrar por userId
              .toList();


        final List<ServiceRequest> serviceRequestsList = jsonDataList.map((item) {
          try {
            // Validar y procesar cada campo
            final id = item['id']?.toString() ?? 'ID no disponible';
            final description = item['description']?.toString() ?? 'Sin descripción';
            final devicesId = item['devicesId']?.toString() ?? 'Dispositivo no disponible';
            final categoryId = item['categoryId']?.toString() ?? 'Categoría no disponible';
            final serviceDateTime = item['serviceDateTime']?.toString() ?? '';
            final statusName = item['status']?.toString() ?? 'unknown';
            final subcategoryName = item['subcategoryName']?.toString() ?? 'Sin subcategoría';
            final userId = item['userId']?.toString() ?? 'Usuario no disponible';

            // Validar status
            final status = Status(
              id: statusName,
              name: Status.getNameById(statusName),
            );

            // Validar imágenes
            final images = (item['images'] as List<dynamic>?)
                    ?.map((image) => image?.toString() ?? '')
                    .toList() ??
                [];

            // Validar ubicación
            final locationData = item['location'] as Map<String, dynamic>? ?? {};
            final location = locationData.map((key, value) {
              return MapEntry(
                key.toString(),
                value is int ? value.toDouble() : (value as double? ?? 0.0),
              );
            });

            // Validar expertises
            final expertisesArray = item['expertises'] as List<dynamic>? ?? [];
            final expertisesList = expertisesArray.map((expertiseItem) {
              final expertiseId = expertiseItem['id']?.toString() ?? 'Sin ID';
              final expertiseName = expertiseItem['name']?.toString() ?? 'Sin nombre';
              return Expertises(id: expertiseId, name: expertiseName);
            }).toList();

            // Crear y devolver el objeto ServiceRequest
            return ServiceRequest(
              id: id,
              description: description,
              devicesId: devicesId,
              serviceDateTime: serviceDateTime,
              status: status,
              images: images,
              location: location,
              expertises: expertisesList,
              userId: userId,
              subcategoryName: subcategoryName,
              serviceType: ServiceType(
                id: categoryId,
                name: subcategoryName,
                selectedDate: '',
                selectedTime: '',
              ),
              offeredPrice: _parseOfferedPrice(item['offeredPrice']),
              workerId: item['workerId']?.toString() ?? 'Sin trabajador',
              isFavorite: item['isFavorite'] as bool? ?? false,
              acceptedTerms: item['acceptedTerms'] as bool? ?? false,
            );
          } catch (e) {
            print('Error procesando item: $e');
            return null; // Si algo falla, devolver null
          }
        }).where((request) => request != null).cast<ServiceRequest>().toList();

        // Actualizar estado y guardar en caché
        setState(() {
          serviceRequests = serviceRequestsList;
          statuses = serviceRequestsList.map((request) => request.status.name).toList();
        });

        // Cachear los resultados
        serviceRequests.forEach((request) {
          LocalCacheService.cacheServiceRequest(request);
        });

        print(
            'Servicios cargados con éxito. Total de servicios obtenidos del backend: ${serviceRequests.length}');
      } else {
        print('Error al obtener datos del backend. Código de estado: ${serviceResponse.statusCode}');
      }
    } else {
      print('Usuario no autenticado');
    }
  } catch (e, stackTrace) {
    print('Error en la solicitud HTTP: $e');
    print('Stack trace: $stackTrace');
  }
}






  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF1A819A),
        title: Text(
          'Historial',
          style: MyTextStyles.buttonTextStyle3,
        ),

        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelPadding: EdgeInsets.symmetric(
                  horizontal: 8.0), // Ajuste de espacio entre tabs
              labelStyle: MyTextStyles.tabTextStyle,
              unselectedLabelStyle: MyTextStyles.unselectedTabTextStyle,
              indicator: UnderlineTabIndicator(
                // Línea fina como indicador
                borderSide: BorderSide(width: 3.0, color: Color(0xFF1A819A)),
                insets: EdgeInsets.symmetric(
                    horizontal: 20.0), // Añade espacio en los extremos
              ),
              tabs: [
                Tab(
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Icon(Icons.task_alt, color: Colors.black),
                  ),
                  text: 'Disponibles',
                ),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize
                        .min, // Minimiza el espacio ocupado por la columna
                    children: [
                      Stack(
                        clipBehavior: Clip
                            .none, // Permite desbordar el badge de notificación
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Icon(Icons.local_offer, color: Colors.black),
                          ),
                          if (offerServiceCount > 0)
                            Positioned(
                              top: -10, // Ajusta la posición del badge
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
                      SizedBox(
                          height: 4.0), // Espacio entre el ícono y el texto
                      Text(
                        'Ofertados',
                        style: TextStyle(
                            fontSize: 12.0), // Ajuste de tamaño del texto
                      ),
                    ],
                  ),
                ),
                Tab(
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Icon(Icons.assignment_ind, color: Colors.black),
                  ),
                  text: 'Asignados',
                ),
                Tab(
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Icon(Icons.check_circle, color: Colors.black),
                  ),
                  text: 'Completados',
                ),
                Tab(
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Icon(Icons.cancel, color: Colors.black),
                  ),
                  text: 'Cancelados',
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
                Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh, color: Color(0xFF1A819A)),
                  onPressed: _refreshHistorial,
                ),
              ],
            ),
          ),

          SizedBox(height: 1.0),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildServiceListByStatus(
                    'available', screenWidth, screenHeight),
                _buildServiceListByStatus('offer', screenWidth, screenHeight),
                _buildServiceListByStatus('in_progress,pending_confirmation',
                    screenWidth, screenHeight),
                _buildServiceListByStatus(
                    'completed', screenWidth, screenHeight),
                _buildServiceListByStatus(
                    'cancelled', screenWidth, screenHeight),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceListByStatus(
      String statusIds, double screenWidth, double screenHeight) {
    final statusIdList = statusIds.split(',');
    final filteredRequests = serviceRequests
        .where((request) => statusIdList.contains(request.status.id))
        .toList();

    if (statusIds.contains('offer')) {
      offerServiceCount = filteredRequests.length;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: ListView.builder(
        itemCount: filteredRequests.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () async {
              final workerDetails =
              await getWorkerDetails(filteredRequests[index].id);

              if (workerDetails != null) {
                print(
                    'Detalles del trabajador obtenidos: ${workerDetails.displayName}, ${workerDetails.email}');
              } else {
                print('No se encontraron detalles del trabajador.');
              }

              final newStatus = await showDialog<String>(
                context: context,
                builder: (BuildContext context) {
                  return ServiceFormWithTimeline(
                    serviceRequest: filteredRequests[index],
                    initialStatus: statuses[index],
                    onComplete: (status) {
                      setState(() {
                        statuses[index] = status;
                      });
                    },
                    userData: userData,
                    onStatusChanged: (newStatus) {},
                    workerId: workerDetails?.id ?? '',
                    images: filteredRequests[index].images,
                    workerDetails: workerDetails,
                  );
                },
              );

              if (newStatus != null && newStatus != statuses[index]) {
                setState(() {
                  statuses[index] = newStatus;
                });
              }
            },
            child: FutureBuilder<double?>(
              future: fetchOfferedPrice(filteredRequests[index].id),
              builder: (context, snapshot) {
                final offeredPrice = snapshot.data ?? 0.0;

                return Container(
                  margin: EdgeInsets.only(bottom: screenHeight * 0.0),
                  width:
                  screenWidth, // Asegura que el contenedor use todo el ancho disponible
                  height: screenHeight * 0.24, // Altura del contenedor
                  child: CustomPaint(
                    size: Size(screenWidth, screenHeight * 0.35),
                    painter: CustomTicketShapePainter(
                      status: filteredRequests[index].status,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Contenido textual
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 30),
                                Text(
                                  'Categoría: ',
                                  style: MyTextStyles.drawerButtonTextStyle,
                                ),
                                Text(
                                  truncateDescription(
                                      filteredRequests[index].subcategoryName),
                                  style: MyTextStyles.drawerButtonTextStyle5,
                                  textAlign: TextAlign.left,
                                ),
                                SizedBox(height: screenHeight * 0.01),
                                Text(
                                  'Servicio: ',
                                  style: MyTextStyles.drawerButtonTextStyle,
                                ),
                                Text(
                                  truncateDescription(
                                    filteredRequests[index]
                                        .expertises
                                        .map((e) => e.name)
                                        .join(', '),
                                  ),
                                  style: MyTextStyles.drawerButtonTextStyle5,
                                  textAlign: TextAlign.left,
                                ),
                                SizedBox(height: screenHeight * 0.01),
                                Text(
                                  'Precio Ofertado: \$${offeredPrice.toStringAsFixed(2)}',
                                  style: MyTextStyles.drawerButtonTextStyle,
                                ),
                              ],
                            ),
                          ),
                          // Espacio entre texto e imagen
                          SizedBox(width: 10),
                          // Imagen ajustada dentro del Row
                          Align(
                            alignment: Alignment
                                .bottomLeft, // Alinea la imagen verticalmente
                            child: Image.asset(
                              'assets/animations/manito.png',
                              width: 64, // Ajusta el tamaño de la imagen
                              height: 64, // Ajusta el tamaño de la imagen
                              fit: BoxFit
                                  .contain, // Asegura que la imagen no se salga de su contenedor
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
 

  void _refreshHistorial() async {
    await fetchDataForUserId();
    setState(() {});
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