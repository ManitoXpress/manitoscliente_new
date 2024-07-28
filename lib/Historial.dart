import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:http/http.dart';
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
import 'package:timeline_tile/timeline_tile.dart';

class Historial extends StatefulWidget {
  final VoidCallback? onTabTapped;

  const Historial({Key? key, this.onTabTapped}) : super(key: key);

  @override
  _HistorialState createState() => _HistorialState();
}

class _HistorialState extends State<Historial> {
  List<ServiceRequest> serviceRequests = [];
  List<String> statuses = []; // Lista para almacenar los estados
  late final UserData userData;
  int unreadMessagesCount = 0;
  late final RegistrationData registrationData = RegistrationData(
    userId: '',
    displayName: '',
    phoneNumber: '',
    paymentType: '',
    selectedCountryCode: '',
    location: {},
    email: '',
  );

  @override
  void initState() {
    super.initState();
    userData = UserData(
      displayName: '',
      // Puedes proporcionar valores iniciales aquí
      email: '',
      phoneNumber: '',
      userId: '',
      location: {},
      paymentType: '',
      selectedCountryCode: '',
      registrationData: registrationData,
      getToken: '',
    );
    fetchDataForUserId();
    calculateUnreadMessagesCount();
  }

  Future<void> fetchDataForUserId() async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;

      if (user != null) {
        final userId = user.uid;
        final token = await user.getIdToken();

        // Intentar obtener los datos del caché primero
        final cachedRequest =
            await LocalCacheService.getCachedServiceRequest(userId);
        if (cachedRequest != null) {
          print('Datos del caché encontrados. Mostrando datos del caché...');
          setState(() {
            serviceRequests = [cachedRequest];
            // Usa el estado almacenado en caché en lugar del estado en el objeto ServiceRequest
            statuses = [cachedRequest.status.name];
          });
        }

        // Si no se encuentran en caché, obtener datos del servidor
        if (cachedRequest == null) {
          final column = "";
          final value = "";
          final type = "";

          final serviceResponse = await ApiService2()
              .getByUserId(userId, token!, column, value, type);

          print('Respuesta del servidor: ${serviceResponse.body}');

          if (serviceResponse.statusCode == 200) {
            try {
              final List<dynamic> jsonDataList =
                  json.decode(serviceResponse.body);

              final List<ServiceRequest> serviceRequestsList =
                  jsonDataList.map((item) {
                final statusName = item['status'] as String? ?? '';
                final status = statusName != null
                    ? Status(
                        id: statusName, name: Status.getNameById(statusName))
                    : Status(id: "unknown", name: 'Desconocido');

                return ServiceRequest(
                  expertises: item['expertises'],
                  id: item['id'],
                  serviceDateTime: item['serviceDateTime'],
                  description: item['description'],
                  images: List<String>.from(item['images']),
                  location: Map<String, double>.from(
                    item['location']?.map((key, value) {
                          if (value is int) {
                            return MapEntry(key, value.toDouble());
                          } else {
                            return MapEntry(key, value);
                          }
                        }) ??
                        {},
                  ),
                  offeredPrice: _parseOfferedPrice(item['offeredPrice']),
                  userId: item['userId'],
                  status: status,
                  isFavorite: item['isFavorite'] as bool? ?? false,
                  acceptedTerms: item['acceptedTerms'] as bool? ?? false,
                  serviceType: ServiceType(
                    name: item['serviceType'],
                    id: '',
                    selectedDate: '',
                    selectedTime: '',
                  ),
                );
              }).toList();

              setState(() {
                serviceRequests = serviceRequestsList;
                // Utiliza el estado de cada solicitud obtenida del servidor
                statuses = serviceRequestsList
                    .map((request) => request.status.name)
                    .toList();
              });

              // Cachear los datos obtenidos del backend
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
      print('Error en la solicitud HTTP: $e');
    }
  }

  void _openChatScreen() {
    // Verificar si hay algún servicio seleccionado para iniciar el chat
    if (serviceRequests.isNotEmpty) {
      // Abrir la pantalla de chat pasando el primer servicio de la lista
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(),
        ),
      );
    } else {
      // Mostrar un mensaje si no hay servicios disponibles
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay servicios disponibles para iniciar el chat.'),
        ),
      );
    }
  }

  void calculateUnreadMessagesCount() async {
    // Calcular el número de mensajes sin leer en cada solicitud de servicio
    int count = 0;
    for (var request in serviceRequests) {
      final messages = await FirebaseFirestore.instance
          .collection('chats')
          .doc(request.id)
          .collection('messages')
          .where('unread',
              isEqualTo:
                  true) // Suponiendo que hay un campo 'unread' en cada mensaje
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

  void _refreshHistorial() {
    fetchDataForUserId();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historial',
          style: MyTextStyles.buttonTextStyle,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshHistorial,
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 10.0),
        // Ajuste del margen horizontal
        child: ListView.builder(
          itemCount: serviceRequests.length,
          itemBuilder: (context, index) {
            return Container(
              margin: EdgeInsets.only(bottom: screenHeight * 0.05),
              // Espacio vertical entre elementos
              child: CustomPaint(
                size: Size(screenWidth, screenHeight * 0.05),
                painter: CustomTicketShapePainter(
                  status: serviceRequests[index].status.name,
                ),
                // Utiliza el CustomClipper
                child: Padding(
                  padding: EdgeInsets.all(20.0), // Ajuste del margen interno
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                                height: 15), // Añadir espacio para el título
                            Text(
                              'Categoría: ',
                              style: MyTextStyles.ButtonTextStyle,
                            ),
                            Text(
                              '${truncateDescription(serviceRequests[index].expertises)}',
                              style: MyTextStyles.drawerButtonTextStyle5,
                              textAlign: TextAlign.left,
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              'Servicio: ',
                              style: MyTextStyles.ButtonTextStyle,
                            ),
                            Text(
                              '${serviceRequests[index].serviceType.name}',
                              style: MyTextStyles.drawerButtonTextStyle5,
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                          width: 40), // Espacio entre la imagen y el texto
                      Image.asset(
                        'assets/animations/manito.png', // Ruta de la imagen en tus recursos
                        width:
                            84, // Ancho de la imagen (ajústalo según sea necesario)
                        height:
                            84, // Alto de la imagen (ajústalo según sea necesario)
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }



  String truncateDescription(String description) {
    // Divide la descripción en palabras
    final words = description.split(' ');

    // Toma la primera palabra
    final firstWord = words.isNotEmpty ? words[0] : '';

    // Verifica si hay más palabras después de la primera
    if (words.length > 1) {
      // Devuelve la primera palabra seguida de puntos suspensivos
      return '$firstWord...';
    } else {
      // Si solo hay una palabra, devuelve esa palabra
      return firstWord;
    }
  }



  Color _getTextColorByStatus(String statusId) {
    // Obtener el estado usando el ID en lugar del nombre
    final status = StatusUtils.getStatusById(statusId);

    // Devolver el color del texto basado en el estado
    switch (status.id) {
      case "available":
        return Colors.green; // Color del texto para "Disponible"
      case "assigned":
        return Colors.orange; // Color del texto para "Asignado"
      case "in_progress":
        return Colors.black; // Color del texto para "En curso"
      case "completed":
        return Colors.blue; // Color del texto para "Completado"
      case "cancelled":
        return Color(0xFF84090D); // Color del texto para "Cancelado"
      default:
        return Colors.grey; // Color del texto para cualquier otro estado
    }
  }
}