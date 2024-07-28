import 'package:flutter/material.dart';
import 'package:manitoscliente_new/ServicesResponse/resquest.dart';
import 'package:manitoscliente_new/Styles/stilo.dart';
import 'package:manitoscliente_new/metodos/auth_utils.dart';
import 'package:manitoscliente_new/metodos/home_screen_functions.dart';
import 'package:manitoscliente_new/metodos/service_screen_functions.dart';
import 'package:manitoscliente_new/utils/status.dart';
import 'package:searchbar_animation/searchbar_animation.dart';
import 'package:manitoscliente_new/ServicesResponse/ResponseGet.dart';

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

  @override
  void initState() {
    super.initState();
    _loadServices();
    _pageController = PageController(initialPage: 0);
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

  void _showNotifications(BuildContext context) {
    ServiceFunctions.showNotifications(
      context,
      title: 'Nuevo Servicio Creado',
      body: 'Haz clic para ver los detalles del servicio.',
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF6AB8D6),
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
                  _showNotifications(context);
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
              )
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
                          final Status status =
                              StatusUtils.getStatusById(statusName);
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
                            isFavorite: false,
                            selectedDate: '',
                            selectedTime: '',
                            acceptedTerms: true,
                            expertises: '',
                            status: status,
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
                          height: MediaQuery.of(context).size.height *
                              0.5, // Aumenta la altura del contenedor
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
                  color: Colors.grey.withOpacity(
                      0.5), // Color de fondo del círculo (puedes ajustar la opacidad)
                ),
                child: IconButton(
                  icon: _currentPage == services.length - 1
                      ? Icon(Icons.arrow_back,
                          color: Colors.white) // Flecha hacia atrás blanca
                      : Icon(Icons.arrow_forward,
                          color: Colors.white), // Flecha hacia adelante blanca
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
    );
  }
}
