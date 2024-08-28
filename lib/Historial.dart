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

class _HistorialState extends State<Historial> with SingleTickerProviderStateMixin {
  List<ServiceRequest> serviceRequests = [];
  List<String> statuses = [];
  late final UserData userData;
  int unreadMessagesCount = 0;
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

  Future<void> fetchDataForUserId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final userId = user.uid;
        final token = await user.getIdToken();

        final cachedRequest = await LocalCacheService.getCachedServiceRequest(userId);
        if (cachedRequest != null) {
          print('Datos del caché encontrados. Mostrando datos del caché...');
          setState(() {
            serviceRequests = [cachedRequest];
            statuses = [cachedRequest.status.name];
          });
        }

        if (cachedRequest == null) {
          final column = "";
          final value = "";
          final type = "";

          final serviceResponse = await ApiService2().getByUserId(userId, token!, column, value, type);

          print('Respuesta del servidor: ${serviceResponse.body}');

          if (serviceResponse.statusCode == 200) {
            try {
              final List<dynamic> jsonDataList = json.decode(serviceResponse.body);

              final List<ServiceRequest> serviceRequestsList = jsonDataList.map((item) {
              final statusName = item['status'] as String? ?? '';
              final status = statusName.isNotEmpty
                  ? Status(id: statusName, name: Status.getNameById(statusName))
                  : Status(id: "unknown", name: 'Desconocido');

              final List<dynamic> expertisesArray = item['expertises'] as List<dynamic>? ?? [];
              final Map<String, dynamic> expertiseItem = expertisesArray.isNotEmpty ? expertisesArray.first : {};

              return ServiceRequest(
                expertises: [
                  Expertises(
                    id: expertiseItem['id'] ?? '', // Verifica si el valor es null
                    name: expertiseItem['name'] ?? '', // Verifica si el valor es null
                  )
                ],
                id: item['id'] ?? '', // Verifica si el valor es null
                serviceDateTime: item['serviceDateTime'] ?? '', // Verifica si el valor es null
                description: item['description'] ?? '', // Verifica si el valor es null
                images: (item['images'] as List<dynamic>?)
                    ?.map((image) => image ?? '') // Verifica si cada imagen es null
                    .cast<String>()
                    .toList() ?? [],
                location: Map<String, double>.from(
                  (item['location']?.map((key, value) {
                    if (value is int) {
                      return MapEntry(key, value.toDouble());
                    } else {
                      return MapEntry(key, value);
                    }
                  }) ?? {}),
                ),
                offeredPrice: _parseOfferedPrice(item['offeredPrice']),
                userId: item['userId'] ?? '', // Verifica si el valor es null
                status: status,
                isFavorite: item['isFavorite'] as bool? ?? false,
                acceptedTerms: item['acceptedTerms'] as bool? ?? false,
                serviceType: ServiceType(
                  name: item['serviceType'] ?? '', // Verifica si el valor es null
                  id: '',
                  selectedDate: '',
                  selectedTime: '',
                ),
              );
            }).toList();


              setState(() {
                serviceRequests = serviceRequestsList;
                statuses = serviceRequestsList.map((request) => request.status.name).toList();
              });

              serviceRequests.forEach((request) {
                LocalCacheService.cacheServiceRequest(request);
              });

              print('Servicios cargados con éxito. Total de servicios obtenidos del backend: ${serviceRequests.length}');
            } catch (e) {
              print('Error al decodificar la respuesta JSON: $e');
            }
          } else {
            print('Error al obtener datos del backend. Código de estado: ${serviceResponse.statusCode}');
          }
        }
      } else {
        print('Usuario no autenticado');
      }
    } catch (e) {
      print('Error en la solicitud HTTP: $e');
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
        title: const Text(
          'Historial',
          style: MyTextStyles.buttonTextStyle,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshHistorial,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'Disponible'),
            Tab(text: 'Asignado'),
            Tab(text: 'En curso'),
            Tab(text: 'Completado'),
            Tab(text: 'Cancelado'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildServiceListByStatus('available', screenWidth, screenHeight),
          _buildServiceListByStatus('assigned', screenWidth, screenHeight),
          _buildServiceListByStatus('in_progress', screenWidth, screenHeight),
          _buildServiceListByStatus('completed', screenWidth, screenHeight),
          _buildServiceListByStatus('cancelled', screenWidth, screenHeight),
        ],
      ),
    );
  }

  Widget _buildServiceListByStatus(String statusId, double screenWidth, double screenHeight) {
    final filteredRequests = serviceRequests.where((request) => request.status.id == statusId).toList();

    return Padding(
      padding: EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0), // Añadir espacio en la parte superior e izquierda/derecha
        child: ListView.builder(
        itemCount: filteredRequests.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () async {
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
                  );
                },
              );

              if (newStatus != null && newStatus != statuses[index]) {
                setState(() {
                  statuses[index] = newStatus;
                });
              }
            },
            child: Container(
              margin: EdgeInsets.only(bottom: screenHeight * 0.05), // Espacio vertical entre elementos
              child: CustomPaint(
                size: Size(screenWidth, screenHeight * 0.05),
                painter: CustomTicketShapePainter(
                  status: filteredRequests[index].status.name,
                ),
                child: Padding(
                  padding: EdgeInsets.all(20.0), // Ajuste del margen interno
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 15), // Añadir espacio para el título
                            Text(
                              'Categoría: ',
                              style: MyTextStyles.ButtonTextStyle,
                            ),
                            Text(
                              truncateDescription(
                                filteredRequests[index].expertises.map((e) => e.name).join(', '),
                                ),
                                style: MyTextStyles.drawerButtonTextStyle5,
                                textAlign: TextAlign.left,
                            ),

                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              'Servicio: ',
                              style: MyTextStyles.ButtonTextStyle,
                            ),
                            Text(
                              filteredRequests[index].serviceType.name,
                              style: MyTextStyles.drawerButtonTextStyle5,
                              textAlign: TextAlign.left,
                            ),
                            Text(
                              'Descripcion del problema',
                              style: MyTextStyles.ButtonTextStyle,
                            ),
                            Text(
                              truncateDescription(filteredRequests[index].description),
                              style: MyTextStyles.drawerButtonTextStyle5,
                            )
                          ],
                        ),
                      ),
                      SizedBox(width: 40), // Espacio entre la imagen y el texto
                      Image.asset(
                        'assets/animations/manito.png',
                        width: 84,
                        height: 84,
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

  String truncateDescription(String description) {
    final words = description.split(' ');
    final firstWord = words.isNotEmpty ? words[0] : '';

    if (words.length > 1) {
      return '$firstWord...';
    } else {
      return firstWord;
    }
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
        return Color(0xFF84090D);
      default:
        return Colors.grey;
    }
  }
}