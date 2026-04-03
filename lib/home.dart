import 'dart:ui'; // Para ImageFilter
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manitoscliente_new/request/ResponsePost.dart';
import 'package:manitoscliente_new/request/dataprofile.dart';
import 'package:manitoscliente_new/utils/fcmToken.dart';
import 'package:manitoscliente_new/widgets/maps.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:url_launcher/url_launcher.dart';

import 'Historial.dart';
import 'Styles/stilo.dart';
import 'categorias/service_screen.dart';
import 'menu/Referido.dart';
import 'menu/UserProfile.dart';
import 'menu/help.dart';
import 'controller/RegisController.dart';
import 'provider/providerService.dart';
import 'package:provider/provider.dart';
import 'services/historial_preload_service.dart';

class HomeScreen extends StatefulWidget {
  final int initialPageIndex;
  final UserData userData;

  HomeScreen({
    this.initialPageIndex = 0,
    required this.userData,
    // ← lo hacemos requerido
    Key? key,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RestorationMixin {
  final RestorableInt _currentIndex = RestorableInt(0);
  late PageController _pageController;
  late final UserData userData;

  @override
  String? get restorationId => 'home_screen';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FCMService().registerTokenForUser(widget.userData.userId);
      
      // 🚀 PRECARGA: Iniciar precarga del historial en background
      _preloadHistorialInBackground();
    });
    // Inicializa con 0, el valor real se ajusta en restoreState
    _pageController = PageController(initialPage: 0);
  }

  /// 🚀 Precarga el historial en background para mejorar la experiencia
  Future<void> _preloadHistorialInBackground() async {
    try {
      // Esperar un poco para no interferir con la carga inicial del home
      await Future.delayed(const Duration(milliseconds: 1000));
      
      final preloadService = HistorialPreloadService();
      await preloadService.preloadHistorial(context, widget.userData.userId);
      
    } catch (e) {
      null;
    }
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_currentIndex, 'current_tab_index');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pageController.jumpToPage(_currentIndex.value);
      }
    });
  }

  Future<String?> getCodeReferral() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    return doc.data()?['codeReferral'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = Uri.encodeComponent(user?.displayName ?? 'Usuario');
    final supportUrl =
        'https://wa.me/59173666393?text=Hola%20Soy%20$name,%20Necesito%20soporte%20';
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A819A).withOpacity(0.65), // Teal with transparency
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.25), // Subtle glassy highlight
                    width: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ),
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
                            points: 0,
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
                onPressed: () async {
                  final code = await getCodeReferral();
                  if (code != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReferralScreen(codeReferral: code),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("No se encontró tu código de referido."),
                      ),
                    );
                  }
                },
                icon: Icon(Icons.share, color: Color(0xFF1A819A)),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Referidos", style: MyTextStyles.linkTextStyle),
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
                onPressed: () => _abrirEnlace(supportUrl),
                icon: const Icon(
                  Icons.support_agent,
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
              SizedBox(height: 18.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton(
                      icon: Icons.facebook,
                      url: 'https://www.facebook.com/ManitosXpress'),
                  SizedBox(width: 18.w),
                  _buildSocialButton(
                      icon: Icons.camera_alt,
                      url: 'https://www.instagram.com/manitosxpress'),
                  SizedBox(width: 18.w),
                  _buildSocialButton(
                      icon: Icons.tiktok,
                      url: 'https://www.tiktok.com/@manitosxpress'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: PageView(
        physics: NeverScrollableScrollPhysics(),
        controller: _pageController,
        children: _buildScreens(),
        onPageChanged: (index) {
          setState(() {
            _currentIndex.value = index;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex.value,
        onTap: (index) {
          setState(() {
            _currentIndex.value = index;
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
        selectedItemColor: Colors.white,
        unselectedItemColor: Color(0xFF6AB8D6),
        selectedLabelStyle: MyTextStyles.navBarTextStyle,
        unselectedLabelStyle: MyTextStyles.navBarTextStyle,
        selectedIconTheme: IconThemeData(color: Colors.white),
        unselectedIconTheme: IconThemeData(color: Color(0xFF6AB8D6)),
        backgroundColor: const Color(0xFF1A819A),
      ),
    );
  }

  Widget _buildSocialButton({required IconData icon, required String url}) =>
      IconButton(
        icon: Icon(icon, size: 45.w, color: Colors.white),
        onPressed: () => _abrirEnlace(url),
      );

  Future<void> _abrirEnlace(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  List<Widget> _buildScreens() {
    return [
      ServiceScreen(),
      MapScreen(), // Pantalla del mapa
      ChangeNotifierProvider<HistorialProvider>(
        create: (_) => HistorialProvider(),
        child: HistorialScreen(
          onTabTapped: () {
            _refreshHistorial();
          },
          userData: UserData.empty(),
        ),
      ),
    ];
  }

  void _refreshHistorial() {
    // Aquí puedes actualizar el historial desde tu backend
  }

  @override
  void dispose() {
    _currentIndex.dispose();
    _pageController.dispose();
    super.dispose();
  }
}
