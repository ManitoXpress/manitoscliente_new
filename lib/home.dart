import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:manitoscliente_new/Historial.dart';
import 'package:manitoscliente_new/ServicesResponse/dataprofile.dart';
import 'package:manitoscliente_new/Styles/stilo.dart';
import 'package:manitoscliente_new/categorias/service_screen.dart';
import 'package:manitoscliente_new/maps.dart';
import 'package:manitoscliente_new/menu/Referido.dart';
import 'package:manitoscliente_new/menu/UserProfile.dart';
import 'package:manitoscliente_new/menu/help.dart';
import 'package:manitoscliente_new/menu/trabaja.dart';
import 'package:manitoscliente_new/metodos/RegisController.dart';

class HomeScreen extends StatefulWidget {
  final int initialPageIndex; // Agregamos un parámetro para seleccionar la pestaña inicial.

  HomeScreen({this.initialPageIndex = 0}); // Valor predeterminado para la primera pestaña.

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialPageIndex; // Inicializar con la página seleccionada.
    _pageController = PageController(initialPage: widget.initialPageIndex); // Controlador de PageView.
  }

  List<Widget> _buildScreens() {
    return [
      ServiceScreen(),
      FavoriteScreen(),
      Historial(
        onTabTapped: () {
          // Actualizar solicitudes de historial aquí
          _refreshHistorial();
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.only(right: 0.5),
              child: Image.network(
                'https://i.imgur.com/0MgQOI2.png',
                width: 90,
                height: 90,
              ),
            ),
            Flexible(
              child: const Text(
                'SOLUCIONES RÁPIDAS',
                style: MyTextStyles.appBarTitleTextStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: Container(
          color: Color(0xFF1A819A),
          child: ListView(
            padding: const EdgeInsets.all(10.0),
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    constraints:
                        const BoxConstraints(maxWidth: 200, maxHeight: 200),
                    child: Image.network("https://i.imgur.com/AWrWerE.png"),
                    margin: const EdgeInsets.only(top: 70, bottom: 40),
                  ),
                  const SizedBox(height: 1.0),
                ],
              ),
              const SizedBox(height: 1.0),
              ElevatedButton.icon(
                onPressed: () async {
                  // Obtener el usuario autenticado
                  final user = FirebaseAuth.instance.currentUser;

                  if (user != null) {
                    // Obtener el nombre y el correo electrónico del usuario
                    final displayName = user.displayName ?? '';
                    final email = user.email ?? '';

                    // Crear un objeto UserData
                    final userData =
                        UserData.fromJson(user.metadata.creationTime != null
                            ? {
                                'userId': 'defaultId',
                                'displayName': 'defaultName',
                                'email': 'defaultEmail',
                                'phoneNumber': 'defaultPhoneNumber',
                                'imagePath': 'defaultImagePath'
                              }
                            : {});

                    // Navegar a la página del perfil pasando los datos del usuario
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(
                          displayName: displayName,
                          email: email,
                          userData: userData,
                          registrationData: RegistrationData(
                            userId: userData.userId,
                            displayName: userData.displayName,
                            phoneNumber: userData.phoneNumber,
                            email: userData.email,
                            selectedCountryCode: '',
                            location: {},
                            paymentType: '',
                          ),
                          phoneNumber: '',
                          imagePath: '',
                          paymentType: '',
                        ),
                      ),
                    );
                  }
                },
                icon: Icon(Icons.person),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Perfil",
                    style: MyTextStyles.drawerButtonTextStyle4,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  shadowColor: Colors.grey.withOpacity(0.5),
                  elevation: 5,
                ),
              ),
              // Más botones en el drawer...
            ],
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        children: _buildScreens(),
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.jumpToPage(index); // Navegar a la página seleccionada.
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_circle),
            label: 'SERVICIOS',
            backgroundColor: Color(0xFF1A819A),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite),
            label: 'FAVORITOS',
            backgroundColor: Color(0xFF1A819A),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.library_books_outlined),
            label: 'SOLICITUDES',
            backgroundColor: Color.fromARGB(166, 50, 196, 233),
          ),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Color.fromARGB(255, 59, 154, 191),
        selectedLabelStyle: MyTextStyles.navBarTextStyle,
        unselectedLabelStyle: MyTextStyles.navBarTextStyle,
        selectedIconTheme: IconThemeData(color: Colors.blue),
        unselectedIconTheme: IconThemeData(color: Color.fromARGB(255, 5, 87, 119)),
        backgroundColor: Colors.white,
      ),
    );
  }

  void _refreshHistorial() {
    // Actualiza el historial aquí
    // Puedes implementar la lógica para actualizar los datos desde el backend
  }
}
