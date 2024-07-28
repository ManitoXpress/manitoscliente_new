import 'dart:convert';
import 'package:rive/rive.dart' as rive;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:manitoscliente_new/ServicesResponse/ResponseGet.dart';
import 'package:manitoscliente_new/ServicesResponse/resquest.dart';
import 'package:manitoscliente_new/menu/Register.dart';
import 'package:manitoscliente_new/metodos/animationcontroller.dart';
import 'package:manitoscliente_new/metodos/logincontroller.dart';
import 'package:rive/rive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ServicesResponse/dataprofile.dart';
import '../Styles/stilo.dart';
import '../home.dart';
import '../metodos/RegisController.dart';
import '../widgets/welcome.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginScreen> {
  late String animationURL;
  Artboard? _teddyArtboard;
  SMITrigger? successTrigger, failTrigger;
  SMIBool? isHandsUp, isChecking;
  SMINumber? numLook;
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FacebookAuth facebookAuth = FacebookAuth.instance;
  List<ServiceRequest> serviceRequests = [];

  StateMachineController? stateMachineController;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final loginController = LoginScreenController();
  void _navigateToCardScreenPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  // Función para obtener los servicios del backend
  Future<void> fetchData(String userId, String token) async {
    try {
      String column = "serviceType";
      String value = "pipe-repair";
      String type = "match";

      final response = await ApiService2()
          .getByUserId(userId, token, column, value, type);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          serviceRequests =
              data.map((item) => ServiceRequest.fromSnapshot(item)).toList();
        });
      } else {
        print(
            'Error al obtener datos del backend. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en la solicitud HTTP: $e');
    }
  }

  Future<void> login() async {
    isChecking?.change(false);
    isHandsUp?.change(false);
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      successTrigger?.fire();
      _navigateToCardScreenPage(); // Redirige al perfil si la autenticación es exitosa
    } catch (e) {
      failTrigger?.fire();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Inicio de sesión fallido"),
            content: Text("Email o contraseña incorrectos. Inténtalo de nuevo."),
            actions: [
              TextButton(
                child: Text("Aceptar"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();
    animationURL = defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS
        ? 'assets/animations/login.riv'
        : 'animations/login.riv';
    rootBundle.load(animationURL).then(
      (data) {
        final file = RiveFile.import(data);
        final artboard = file.mainArtboard;
        stateMachineController =
            StateMachineController.fromArtboard(artboard, "State Machine 1");
        if (stateMachineController != null) {
          artboard.addController(stateMachineController!);

          stateMachineController!.inputs.forEach((element) {
            switch (element.name) {
              case "success":
                successTrigger = element as SMITrigger;
                break;
              case "fail":
                failTrigger = element as SMITrigger;
                break;
              case "hands_up":
                isHandsUp = element as SMIBool;
                break;
              case "idle":
                isChecking = element as SMIBool;
                break;
              case "Look_down_left":
                numLook = element as SMINumber;
                break;
              default:
                break;
            }
          });
        }

        setState(() => _teddyArtboard = artboard);
      },
    );
  }
  Future<void> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      _navigateToCardScreenPage(); // Redirige al perfil si la autenticación es exitosa
    } catch (e) {
      print('Error al iniciar sesión con Apple: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xffd6e2ea),
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(
              child: Container(
                padding: EdgeInsets.all(screenWidth * 0.01),
                constraints: BoxConstraints(maxWidth: screenWidth * 0.2),
                child: Image.asset(
                  'assets/images/LOGO1_Blanco.png',
                  width: 90,
                  height: 90,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Text(
              'ManitoXpress',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Xpress Heavy',
                fontWeight: FontWeight.normal,
                fontStyle: FontStyle.italic,
                fontSize: screenHeight * 0.025,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_teddyArtboard != null)
                SizedBox(
                  width: 300,
                  height: 300,
                  child: rive.Rive(
                    artboard: _teddyArtboard!,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              Container(
                alignment: Alignment.center,
                width: 500,
                padding: const EdgeInsets.only(bottom: 30),
                margin: const EdgeInsets.only(bottom: 15 * 6),
                decoration: BoxDecoration(
                  color: const Color(0xffd6e2ea), // Cambia el color aquí
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          SizedBox(height: 12),
                          Text(
                            'Bienvenidos a Manitos Xpress',
                            style: MyTextStyles.buttonTextStyle3,
                          ),
                          SizedBox(height: 12),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF84090D), // Color del AppBar
                                  shape: CircleBorder(),
                                  padding: EdgeInsets.all(8),
                                ),
                                onPressed: () {
                                  try {
                                    LoginScreenController.signInWithGoogle(context);
                                  } catch (e) {
                                    print('Error al iniciar sesión con Google: $e');
                                  }
                                },
                                child: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  radius: 40,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 37,
                                    child: CircleAvatar(
                                      radius: 35,
                                      backgroundColor: Colors.white,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            FontAwesomeIcons.google,
                                            color: Color(0xFF84090D), // Color del AppBar
                                          ),
                                          Text(
                                            'Inicio',
                                            style: GoogleFonts.lato(
                                              color: Color(0xFF84090D), // Color del AppBar
                                              fontSize: 14, // Ajusta el tamaño del texto
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                               SizedBox(width: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF84090D), // Color del AppBar
                                  shape: CircleBorder(),
                                  padding: EdgeInsets.all(8),
                                ),
                                onPressed: signInWithApple,
                                child: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  radius: 40,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 37,
                                    child: CircleAvatar(
                                      radius: 35,
                                      backgroundColor: Colors.white,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            FontAwesomeIcons.apple,
                                            color: Color(0xFF84090D), // Color del AppBar
                                          ),
                                          Text(
                                            'Inicio',
                                            style: GoogleFonts.lato(
                                              color: Color(0xFF84090D), // Color del AppBar
                                              fontSize: 14, // Ajusta el tamaño del texto
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
