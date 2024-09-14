import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manitoscliente_new/Historial.dart';
import 'package:manitoscliente_new/ServicesResponse/resquest.dart';
import 'package:manitoscliente_new/Styles/stilo.dart';
import 'package:manitoscliente_new/metodos/auth_utils.dart';
import 'package:manitoscliente_new/metodos/home_screen_functions.dart';
import 'package:manitoscliente_new/metodos/service_screen_functions.dart';
import 'package:manitoscliente_new/utils/status.dart';
import 'package:searchbar_animation/searchbar_animation.dart';
import 'package:manitoscliente_new/ServicesResponse/ResponseGet.dart';

import 'package:flutter/material.dart';

import 'dart:async'; // Importa para usar Timer
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class ServiceScreen extends StatefulWidget {
  static int notificationCount = 0;

  @override
  _ServiceScreenState createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  List<ServiceResponse> services = [];
  int notificationCount = 0;
  late ApiService2 _apiService2 = ApiService2();
  TextEditingController _textEditingController = TextEditingController();
  bool _showClearButton = false;
  String searchText = '';
  PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _notificationTimer;

  @override
void initState() {
  super.initState();
  _loadServices();
  _pageController = PageController(initialPage: 0);
  _startNotificationTimer();
  
  // Configurar FCM
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("Recibido mensaje en primer plano: ${message.messageId}");
    _handleFCMMessage(message);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("Aplicación abierta desde notificación: ${message.messageId}");
    _handleFCMMessage(message);
  });
}

void _handleFCMMessage(RemoteMessage message) {
  if (message.data['status'] == 'offer') {
    _checkForNewNotifications();
  }
}

  @override
  void dispose() {
    _notificationTimer?.cancel(); // Cancelar el Timer cuando se destruya el widget
    super.dispose();
  }

  Future<void> _loadServices() async {
    try {
      String? token = await AuthUtils.getToken();

      if (token != null) {
        final List<ServiceResponse> serviceResponses =
        await _apiService2.fetchServicesFromBackend(token);

        // Ordenar los servicios para que HomeServices aparezca primero
        serviceResponses.sort((a, b) {
          // Puedes ajustar esta lógica según tus necesidades
          if (a.name == 'HomeServices') {
            return -1;
          } else if (b.name == 'HomeServices') {
            return 1;
          } else {
            return 0;
          }
        });

        setState(() {
          services = serviceResponses;
        });
      } else {
        print('No se pudo obtener el token.');
      }
    } catch (e) {
      print('Error al cargar los servicios: $e');
    }
  }

  Future<void> _checkForNewNotifications() async {
  try {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final serviceQuery = await FirebaseFirestore.instance
          .collection('serviceRequests')  // Asegúrate de que esta sea la colección correcta
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'offer')
          .get();

      final newOfferCount = serviceQuery.docs.length;

      if (newOfferCount > 0) {
        setState(() {
          notificationCount = newOfferCount;
        });
        _showNotifications(context, newOfferCount);
      }
    }
  } catch (e) {
    print('Error al comprobar las notificaciones: $e');
  }
}

  void _startNotificationTimer() {
    _notificationTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      _checkForNewNotifications();
    });
  }

  void _showNotifications(BuildContext context, int offerCount) {
  ServiceFunctions.showNotifications(
    context,
    title: 'Nuevas Ofertas Disponibles',
    body: 'Tienes $offerCount nueva(s) oferta(s) para tus servicios.',
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Historial()),
      );
    },
  );
}
  void _limpiarTextoBusqueda() {
    setState(() {
      searchText = '';
      _showClearButton = false;
      _textEditingController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Aquí se define lo que sucede al presionar el botón "Atrás"
        // Retorna "false" para evitar que la app se cierre
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF6AB8D6),
          automaticallyImplyLeading: false,
          title: Text(
            'Categorías',
            style: MyTextStyles.CategoriaButtonTextStyle,
          ),
          actions: [
            Stack(
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.notifications),
                  onPressed: () {
                    _checkForNewNotifications();
                  },
                ),
                Positioned(
                  right: 11,
                  top: 11,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6.5),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 13,
                      minHeight: 13,
                    ),
                    child: Text(
                      notificationCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Container(
          color: Color(0xFF6AB8D6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 15),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: services.length,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return GestureDetector(
                      onTap: () {
                        switch (index) {
                          case 0:
                            navigateToProfessionalServices(context);
                            break;
                          case 1:
                            final String statusName = 'En Proceso';
                            final Status status = StatusUtils.getStatusById(statusName);
                            ServiceRequest serviceRequest = ServiceRequest(
                              serviceDateTime: '',
                              id: '',
                              description: '',
                              images: ['', ''],
                              location: {'lat': 0.0, 'lng': 0.0},
                              offeredPrice: 100.0,
                              serviceType: ServiceType(
                                id: '1',
                                name: '',
                                selectedDate: '',
                                selectedTime: '',
                              ),
                              userId: '',
                              workerId: '',
                              isFavorite: false,
                              selectedDate: '',
                              selectedTime: '',
                              acceptedTerms: true,
                              expertises: [],
                              status: status, subcategoryName: '',
                            );
                            navigateToHomeServices(context, serviceRequest);
                            break;
                        }
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: MediaQuery.of(context).size.height * 0.5, // Aumenta la altura del contenedor
                            decoration: BoxDecoration(
                              color: Color(0xFF145073),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF145073),
                                  blurRadius: 10,
                                  spreadRadius: -3,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                service.image,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(height: 5),
                          // Ajusta la distancia entre la imagen y el texto
                          Text(
                            service.name,
                            style: MyTextStyles.buttonTextStyle,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.withOpacity(0.5), // Color de fondo del círculo (puedes ajustar la opacidad)
                  ),
                  child: IconButton(
                    icon: _currentPage == services.length - 1
                        ? Icon(Icons.arrow_back, color: Colors.white) // Flecha hacia atrás blanca
                        : Icon(Icons.arrow_forward, color: Colors.white), // Flecha hacia adelante blanca
                    onPressed: () {
                      if (_currentPage < services.length - 1) {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      } else {
                        _pageController.previousPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
