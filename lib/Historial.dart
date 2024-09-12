import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:manitoscliente_new/ServicesResponse/ResponseGet.dart';
import 'package:manitoscliente_new/ServicesResponse/dataprofile.dart';

import 'package:manitoscliente_new/ServicesResponse/resquest.dart';
import 'package:manitoscliente_new/Styles/stilo.dart';
import 'package:manitoscliente_new/chatscreen.dart';
import 'package:manitoscliente_new/metodos/RegisController.dart';
import 'package:manitoscliente_new/metodos/ticketController.dart';
import 'package:manitoscliente_new/utils/cacheLocal.dart';
import 'package:manitoscliente_new/utils/status.dart';
import 'package:manitoscliente_new/utils/timeLines.dart';

class Historial extends StatefulWidget {
  final VoidCallback? onTabTapped;

  const Historial({Key? key, this.onTabTapped}) : super(key: key);

  @override
  _HistorialState createState() => _HistorialState();
}

class _HistorialState extends State<Historial>
    with SingleTickerProviderStateMixin {
  List<ServiceRequest> serviceRequests = [];
  List<String> statuses = [];
  late final UserData userData;
  int unreadMessagesCount = 0;
  int offerServiceCount = 0;
  


  late final RegistrationData registrationData;
  late TabController _tabController;
 

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
      email: '',
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

    _tabController = TabController(length: 5, vsync: this);
    fetchDataForUserId();
    calculateUnreadMessagesCount();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<double?> fetchOfferedPrice(String serviceId) async {
  try {
    // Consultar Firestore en la colección 'offers'
    final querySnapshot = await FirebaseFirestore.instance
        .collection('offers')
        .where('serviceId', isEqualTo: serviceId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Obtener el precio ofertado
      final offerData = querySnapshot.docs.first.data();
      final offeredPrice = offerData['offeredPrice'];

      // Verificar el tipo de offeredPrice y convertirlo a double si es necesario
      if (offeredPrice is String) {
        return double.tryParse(offeredPrice);
      } else if (offeredPrice is double) {
        return offeredPrice;
      } else {
        return null;
      }
    }
  } catch (e) {
    print('Error al obtener el precio ofertado: $e');
  }
  return null;
}

Future<WorkerDetails?> getWorkerDetails(String serviceId) async {
  try {
    // Paso 1: Obtener el workerId desde la colección 'offers' usando el serviceId
    print('Buscando en la colección "offers" con serviceId: $serviceId');
    final querySnapshot = await FirebaseFirestore.instance
        .collection('offers')
        .where('serviceId', isEqualTo: serviceId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final offerData = querySnapshot.docs.first.data();
      final workerId = offerData['workerId'];

      // Verificar si el workerId está presente
      if (workerId != null && workerId.isNotEmpty) {
        print('Obteniendo detalles del trabajador con workerId: $workerId');

        // Paso 2: Obtener los detalles del trabajador usando el workerId
        final workerDetails = await fetchWorkerDetails(workerId);

        if (workerDetails != null) {
          print('Detalles del trabajador obtenidos: ${workerDetails.displayName}, ${workerDetails.email}');
          return workerDetails;
        } else {
          print('No se encontraron detalles del trabajador para workerId: $workerId');
        }
      } else {
        print('workerId no válido o no encontrado en el documento de offers.');
      }
    } else {
      print('No se encontró ningún documento en la colección "offers" con serviceId: $serviceId');
    }
  } catch (e) {
    print('Error al obtener detalles del trabajador: $e');
  }
  return null;
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
      print('No se encontró ningún documento en la colección "workers" con workerId: $workerId');
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

        // Verificar si hay datos en caché
        final cachedRequest =
            await LocalCacheService.getCachedServiceRequest(userId);
        if (cachedRequest != null) {
          print('Datos del caché encontrados. Mostrando datos del caché...');
          setState(() {
            serviceRequests = [cachedRequest];
            statuses = [cachedRequest.status.name];
          });
        } else {
          // Si no hay datos en caché, hacer la solicitud al backend
          final column = ""; // Cambia según sea necesario
          final value = ""; // Cambia según sea necesario
          final type = ""; // Cambia según sea necesario

          final serviceResponse = await ApiService2()
              .getByUserId(userId, token!, column, value, type);

          if (serviceResponse.statusCode == 200) {
            try {
              final List<dynamic> jsonDataList =
                  json.decode(serviceResponse.body);

              // Filtrar los servicios que pertenecen al usuario actual
              final List<dynamic> filteredJsonDataList =
                  jsonDataList.where((item) {
                return item['userId'] == userId;
              }).toList();

              // Procesar cada item en la lista de respuestas filtradas
              final List<ServiceRequest> serviceRequestsList =
                  filteredJsonDataList.map((item) {
                // Obtener y mapear el estado del servicio
                final statusName = item['status'] as String? ?? 'unknown';
                final status = Status(
                    id: statusName, name: Status.getNameById(statusName));

                // Obtener y mapear expertises
                final List<dynamic> expertisesArray =
                    item['expertises'] as List<dynamic>? ?? [];
                final Map<String, dynamic> expertiseItem =
                    expertisesArray.isNotEmpty ? expertisesArray.first : {};

                return ServiceRequest(
                  expertises: [
                    Expertises(
                      id: expertiseItem['id'] ??
                          '', // Asegúrate de que no sea null
                      name: expertiseItem['name'] ??
                          '', // Asegúrate de que no sea null
                    )
                  ],
                  id: item['id'] ?? '', // Asegúrate de que no sea null
                  serviceDateTime: item['serviceDateTime'] ??
                      '', // Asegúrate de que no sea null
                  description:
                      item['description'] ?? '', // Asegúrate de que no sea null
                  images: (item['images'] as List<dynamic>?)
                          ?.map((image) =>
                              image as String? ?? '') // Verifica cada imagen
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
                  userId: item['userId'] ?? '', // Asegúrate de que no sea null
                  workerId: item['workerId'] ?? '',
                  status: status,
                  isFavorite: item['isFavorite'] as bool? ?? false,
                  acceptedTerms: item['acceptedTerms'] as bool? ?? false,
                  serviceType: ServiceType(
                    name: item['serviceType'] ??
                        '', // Asegúrate de que no sea null
                    id: '', // Si es necesario, asigna el ID
                    selectedDate: '', // Puedes agregar si es relevante
                    selectedTime: '', // Puedes agregar si es relevante
                  ),
                  subcategoryName: item['subcategoryName'] ?? '',
                );
              }).toList();

              // Actualizar el estado de la UI
              setState(() {
                serviceRequests = serviceRequestsList;
                statuses = serviceRequestsList
                    .map((request) => request.status.name)
                    .toList();
                

              });

              // Cachear cada servicio para uso posterior
              serviceRequests.forEach((request) {
                LocalCacheService.cacheServiceRequest(request);
              });

              print(
                  'Servicios cargados con éxito. Total de servicios obtenidos del backend: ${serviceRequests.length}');
            } catch (e) {
              print('Error al decodificar la respuesta JSON: $e');
            }
          } else {
            print(
                'Error al obtener datos del backend. Código de estado: ${serviceResponse.statusCode}');
          }
        }
      } else {
        print('Usuario no autenticado');
      }
    } catch (e) {
      print('Error en la solicitud HTTP:$e');
    }
  }

  void _openChatScreen() {
    if (serviceRequests.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay servicios disponibles para iniciar el chat.'),
        ),
      );
    }
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

 @override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  return Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Color(0xFF1A819A), // Color de fondo para el AppBar
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(10.0), // Ajusta la altura del TabBar
        child: Container(
          color: Color(0xFF1A819A), // Color de fondo para el TabBar
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelStyle: MyTextStyles.tabTextStyle,
            unselectedLabelStyle: MyTextStyles.unselectedTabTextStyle,
            tabs: [
              Tab(text: 'Disponibles'),
              Tab(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text('Ofertados'),
                    if (offerServiceCount > 0)
                      Positioned(
                        right: 7,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          child: Text(
                            offerServiceCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Tab(text: 'Asignados'),
              Tab(text: 'Completados'),
              Tab(text: 'Cancelados'),
            ],
          ),
        ),
      ),
    ),
    body: Column(
      children: [
        Container(
          color: Colors.white, // Fondo blanco para el título
          padding: const EdgeInsets.all(10.0),
          child: const Text(
            'Historial',
            style: MyTextStyles.buttonTextStyle3,
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildServiceListByStatus('available', screenWidth, screenHeight),
              _buildServiceListByStatus('offer', screenWidth, screenHeight),
              _buildServiceListByStatus('in_progress,pending_confirmation', screenWidth, screenHeight),
              _buildServiceListByStatus('completed', screenWidth, screenHeight),
              _buildServiceListByStatus('cancelled', screenWidth, screenHeight),
            ],
          ),
        ),
      ],
    ),
  );
}



 Widget _buildServiceListByStatus(
  String statusIds, double screenWidth, double screenHeight) {
  final statusIdList = statusIds.split(','); // Divide el string en una lista de IDs
  final filteredRequests = serviceRequests
      .where((request) => statusIdList.contains(request.status.id)) // Filtra por múltiples estados
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
            final workerDetails = await getWorkerDetails(filteredRequests[index].id);

            if (workerDetails != null) {
              print('Detalles del trabajador obtenidos: ${workerDetails.displayName}, ${workerDetails.email}');
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
                  workerId: workerDetails?.id ?? '', // Pasar el workerId
                  images: filteredRequests[index].images,
                  workerDetails: workerDetails, // Pasar los detalles completos o null
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
                margin: EdgeInsets.only(bottom: screenHeight * 0.02),
                child: CustomPaint(
                  size: Size(screenWidth, screenHeight * 0.05),
                  painter: CustomTicketShapePainter(
                    status: filteredRequests[index].status.name,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 15),
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
                        SizedBox(width: 40),
                          Image.asset(
                             'assets/animations/manito.png',
                            width: 84,
                            height: 84,
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



  String truncateDescription(String description) {
    final words = description.split(' ');
    if (words.length > 6) {
      return '${words.take(6).join(' ')}...';
    }
    return description;
  }

  void _refreshHistorial() async {
    await fetchDataForUserId();
    setState(() {});
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
        return const Color(0xFF84090D);
      default:
        return Colors.grey;
    }
  }
}
