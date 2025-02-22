import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manitoscliente_new/Historial.dart';
import 'package:manitoscliente_new/request/dataprofile.dart';
import 'package:manitoscliente_new/Styles/stilo.dart';
import 'package:manitoscliente_new/categorias/service_screen.dart';
import 'package:manitoscliente_new/maps.dart';
import 'package:manitoscliente_new/menu/Referido.dart';
import 'package:manitoscliente_new/menu/UserProfile.dart';
import 'package:manitoscliente_new/menu/help.dart';
import 'package:manitoscliente_new/menu/trabaja.dart';
import 'package:manitoscliente_new/metodos/RegisController.dart';
import 'package:manitoscliente_new/widgets/maps.dart';
import 'package:url_launcher/url_launcher.dart';


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

 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween, // Distribuir elementos
          children: [
            // Texto en la parte izquierda
            Text(
              'Soluciones Rápidas',
              style: MyTextStyles.buttonTextStyle,
            ),
            // Logo en la parte derecha
            Flexible(
              child: Container(
                padding: EdgeInsets.all(10.w),
                constraints: BoxConstraints(maxWidth: 0.22.sw),
                child: Image.asset(
                  'assets/images/LOGO1_Blanco.png',
                  width: 0.22.sw,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
        iconTheme: IconThemeData(
            color: Colors.white), // Cambia el color del ícono del menú a blanco
      ),
      drawer: Drawer(
        child: Container(
          color: Color(0xFF1A819A),
          child: ListView(
            padding: const EdgeInsets.all(10.0),
            children: [
              // Aquí va tu código para el menú del Drawer...
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

                    // Ejemplo: Crear un objeto UserData con valores predeterminados si userData es nulo
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
                            devicesId: '',
                            fcmToken: '',
                          ),
                          phoneNumber: '',
                          imagePath: '',
                          paymentType: '',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.person, color: Color(0xFF1A819A)),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    "Perfil",
                    style: MyTextStyles.linkTextStyle,
                  ),
                ),
              ),
              SizedBox(height: 3.h), // Cambiado a screenutil
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ReferralScreen(
                              referralCode: '12345',
                            )),
                  );
                },
                icon: const Icon(
                  Icons.share,
                  color: Color(0xFF1A819A),
                ),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    "Referidos",
                    style: MyTextStyles.linkTextStyle,
                  ),
                ),
              ),
              SizedBox(height: 3.h), // Cambiado a screenutil
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HelpScreen()),
                  );
                },
                icon: const Icon(
                  Icons.help,
                  color: Color(0xFF1A819A),
                ),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    "Ayuda",
                    style: MyTextStyles.linkTextStyle,
                  ),
                ),
              ),
              SizedBox(height: 3.h), // Cambiado a screenutil
              ElevatedButton.icon(
                onPressed: _openWhatsApp,
                icon: const Icon(
                  Icons.help,
                  color: Color(0xFF1A819A),
                ),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    "Soporte Técnico",
                    style: MyTextStyles.linkTextStyle,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.facebook, color: Colors.white),
                    iconSize: 40,
                    onPressed: () async {
                      const facebookUrl =
                          'fb://facewebmodal/f?href=https://www.facebook.com/ManitosXpress';
                      if (await canLaunchUrl(Uri.parse(facebookUrl))) {
                        await launchUrl(Uri.parse(facebookUrl));
                      } else {
                        // Si la app de Facebook no está instalada, abre en navegador
                        await _abrirEnlace(
                            'https://www.facebook.com/ManitosXpress');
                      }
                    },
                  ),
                  SizedBox(width: 20),
                  IconButton(
                    icon: const Icon(Icons.camera_alt,
                        color: Color.fromARGB(255, 255, 255, 255)),
                    iconSize: 40,
                    onPressed: () async {
                      const instagramUrl =
                          'https://www.instagram.com/manitosxpress?utm_source=ig_web_button_share_sheet&igsh=ZDNlZDc0MzIxNw==';
                      await _abrirEnlace(instagramUrl);
                    },
                  ),
                  SizedBox(width: 20), // Separación entre íconos
                  IconButton(
                    icon: const Icon(Icons.tiktok,
                        color: Color.fromARGB(255, 255, 255, 255)),
                    iconSize: 40,
                    onPressed: () async {
                      const tiktokUrl =
                          'https://www.tiktok.com/@manitosxpress?_t=ZM-8tG9ZrTUYjO&_r=1';
                      await _abrirEnlace(tiktokUrl);
                    },
                  ),
                ],
              )
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
          _pageController.jumpToPage(index);
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.app_registration_outlined),
            label: 'SERVICIOS',
            backgroundColor: const Color(0xFF1A819A),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.map_outlined),
            label: 'MAPA',
            backgroundColor: const Color(0xFF1A819A),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.library_books_outlined),
            label: 'SOLICITUDES',
            backgroundColor: const Color(0xFF1A819A),
          ),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: const Color.fromARGB(255, 59, 154, 191),
        selectedLabelStyle: MyTextStyles.navBarTextStyle.copyWith(
          color: Colors.blue, // Cambia el color al estar seleccionado
          fontWeight: FontWeight.bold, // Resalta el ítem seleccionado
        ),
        unselectedLabelStyle: MyTextStyles.navBarTextStyle.copyWith(
          color: const Color.fromARGB(
              255, 5, 87, 119), // Color más tenue para ítems no seleccionados
          fontWeight: FontWeight.w400, // Peso más ligero
        ),
        selectedIconTheme: const IconThemeData(color: Colors.blue),
        unselectedIconTheme:
            const IconThemeData(color: Color.fromARGB(255, 5, 87, 119)),
        backgroundColor: Colors.white,
      ),
    );
  }

  void _openWhatsApp() async {
    final String supportPhoneNumber = "59173666393"; // Número sin '+'
    final String supportMessage =
        "Hola, necesito soporte técnico en ManitosXpress.";
    final String encodedMessage = Uri.encodeComponent(supportMessage);

    final String whatsappUrl =
        "https://wa.me/$supportPhoneNumber?text=$encodedMessage";

    final Uri uri = Uri.parse(whatsappUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("No se pudo abrir WhatsApp.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "No se pudo abrir WhatsApp. Asegúrate de tenerlo instalado."),
        ),
      );
    }
  }

  Future<void> _abrirEnlace(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('No se pudo abrir $url');
    }
  }

  List<Widget> _buildScreens() {
    return [
      ServiceScreen(),
      MapScreen(), // Pantalla del mapa
      Historial(
        onTabTapped: () {
          _refreshHistorial();
        },
      ),
    ];
  }

  void _refreshHistorial() {
    // Aquí puedes actualizar el historial desde tu backend
  }
}