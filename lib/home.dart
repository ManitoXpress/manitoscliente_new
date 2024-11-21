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
  final int initialPageIndex; // Agregamos un parámetro para seleccionar la pestaña inicial.\
  

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
            
            Flexible(
              child: const Text(
                'SOLUCIONES RÁPIDAS',
                style: MyTextStyles.appBarTitleTextStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              
              child: Image.asset(
                'assets/images/LOGO2_BLANCO.png',
                width: 90,
                height: 90,
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
                    child: Image.asset(
                'assets/images/LOGO2_BLANCO.png'),
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

                    // Ejemplo: Crear un objeto UserData con valores predeterminados si userData es nulo
                    final userData = UserData.fromJson(user.metadata.creationTime != null
                        ? {'userId': 'defaultId', 'displayName': 'defaultName', 'email': 'defaultEmail', 'phoneNumber': 'defaultPhoneNumber', 'imagePath': 'defaultImagePath'}
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



                            email: userData.email, selectedCountryCode: '', location: {}, paymentType: '', devicesId: '', fcmToken: '',

                          ),  phoneNumber: '',  imagePath: '', paymentType: '',
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
              const SizedBox(height: 3.0),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReferralScreen(
                        referralCode: '12345',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.share),
                label: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Referidos",
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
              const SizedBox(height: 3.0),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HelpScreen()),
                  );
                },
                icon: const Icon(Icons.help),
                label: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Ayuda",
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
              const SizedBox(height: 3.0),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TrabajeConNosotrosScreen()),
                  );
                },
                icon: const Icon(Icons.trending_up),
                label: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Trabaja Con Nosotros",
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
              const SizedBox(height: 10.0),
              GestureDetector(
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: "ManitoXpress",
                    applicationVersion: "1.0.0",
                    applicationIcon: Image.asset(
                      'assets/images/manitoxpress_logo.png',
                      width: 10,
                      height: 10,
                    ),
                    children: const [
                      Text(
                        "Esta es una aplicación Demo",
                        style: MyTextStyles.drawerButtonTextStyle,
                      ),
                    ],
                  );
                },
                child: Text(
                  "Versión",
                  style: MyTextStyles.linkTextStyle2,
                ),
              ),
              const SizedBox(height: 3.0),
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
            icon: const Icon(Icons.app_registration_outlined),
            label: 'SERVICIOS',
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
    // Puedes implementar la lógica para actualizar los datos desde el backend
    }
}