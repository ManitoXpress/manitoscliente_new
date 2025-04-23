import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../request/dataprofile.dart';
import '../widgets/maps.dart';

import 'package:url_launcher/url_launcher.dart';

import 'Historial.dart';
import 'Styles/stilo.dart';
import 'categorias/service_screen.dart';
import 'menu/Referido.dart';
import 'menu/UserProfile.dart';
import 'menu/help.dart';
import 'controller/RegisController.dart';

class HomeScreen extends StatefulWidget {
  final int initialPageIndex;
  final bool isGuest; // Indica si es modo invitado

  HomeScreen({this.initialPageIndex = 0, this.isGuest = false});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialPageIndex;
    _pageController = PageController(initialPage: widget.initialPageIndex);
  }

  void _openWhatsApp() async {
    final String supportPhoneNumber = "59173666393";
    final String supportMessage = "Hola, necesito soporte técnico en ManitosXpress.";
    final String encodedMessage = Uri.encodeComponent(supportMessage);
    final String whatsappUrl = "https://wa.me/$supportPhoneNumber?text=$encodedMessage";

    final Uri uri = Uri.parse(whatsappUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("No se pudo abrir WhatsApp.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No se pudo abrir WhatsApp. Asegúrate de tenerlo instalado."),
        ),
      );
    }
  }
   Future<String?> getCodeReferral() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    return doc.data()?['codeReferral'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Soluciones Rápidas', style: MyTextStyles.buttonTextStyle),
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
                    constraints: BoxConstraints(maxWidth: 200, maxHeight: 200),
                    child: Image.network("https://i.imgur.com/AWrWerE.png"),
                    margin: const EdgeInsets.only(top: 70, bottom: 40),
                  ),
                ],
              ),
              SizedBox(height: 1.0),

              // Botón de Perfil (Deshabilitado en modo invitado)
              ElevatedButton.icon(
                onPressed: widget.isGuest ? null : () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    final displayName = user.displayName ?? '';
                    final email = user.email ?? '';

                    final userData = UserData.fromJson({
                      'userId': 'defaultId',
                      'displayName': 'defaultName',
                      'email': 'defaultEmail',
                      'phoneNumber': 'defaultPhoneNumber',
                      'imagePath': 'defaultImagePath'
                    });

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
                icon: Icon(Icons.person, color: Color(0xFF1A819A)),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Perfil", style: MyTextStyles.linkTextStyle),
                ),
              ),

              SizedBox(height: 3.h),
              
              // Solo usuarios autenticados pueden compartir referidos
              if (!widget.isGuest)
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

              SizedBox(height: 3.h),
              ElevatedButton.icon(
                onPressed: _openWhatsApp,
                icon: Icon(Icons.help, color: Color(0xFF1A819A)),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Soporte Técnico", style: MyTextStyles.linkTextStyle),
                ),
              ),
              
              SizedBox(height: 10.h),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.facebook, color: Colors.white),
                    iconSize: 40,
                    onPressed: () async {
                      const facebookUrl = 'fb://facewebmodal/f?href=https://www.facebook.com/ManitosXpress';
                      if (await canLaunchUrl(Uri.parse(facebookUrl))) {
                        await launchUrl(Uri.parse(facebookUrl));
                      } else {
                        await _abrirEnlace('https://www.facebook.com/ManitosXpress');
                      }
                    },
                  ),
                  SizedBox(width: 20),
                  IconButton(
                    icon: Icon(Icons.camera_alt, color: Colors.white),
                    iconSize: 40,
                    onPressed: () async {
                      const instagramUrl = 'https://www.instagram.com/manitosxpress';
                      await _abrirEnlace(instagramUrl);
                    },
                  ),
                ],
              )
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
            _currentIndex = index;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (!widget.isGuest || index == 0) {
            setState(() {
              _currentIndex = index;
            });
            _pageController.jumpToPage(index);
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.app_registration_outlined), label: 'SERVICIOS'),
          if (!widget.isGuest)
            BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'MAPA'),
          if (!widget.isGuest)
            BottomNavigationBarItem(icon: Icon(Icons.library_books_outlined), label: 'SOLICITUDES'),
        ],
        selectedItemColor: Colors.white,
        unselectedItemColor: Color(0xFF6AB8D6),
        backgroundColor: Color(0xFF1A819A),
      ),
    );
  }

  Future<void> _abrirEnlace(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  List<Widget> _buildScreens() {
    return [
      ServiceScreen(),
      if (!widget.isGuest) MapScreen(),
      if (!widget.isGuest) Historial(onTabTapped: _refreshHistorial),
    ];
  }

  void _refreshHistorial() {}
}
