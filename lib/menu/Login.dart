import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:manitoscliente_new/ServicesResponse/ResponseGet.dart';
import 'package:manitoscliente_new/ServicesResponse/resquest.dart';
import 'package:manitoscliente_new/menu/Register.dart';
import 'package:manitoscliente_new/metodos/animationcontroller.dart';
import 'package:manitoscliente_new/metodos/logincontroller.dart';
import 'package:manitoscliente_new/utils/animation.dart';
import 'package:rive/rive.dart' as rive;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ServicesResponse/dataprofile.dart';
import '../Styles/stilo.dart';
import '../home.dart';
import '../metodos/RegisController.dart';
import '../widgets/welcome.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key? key, required String deviceId}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginScreen> {
  late String animationURL;
  rive.Artboard? _teddyArtboard;
  rive.SMITrigger? successTrigger, failTrigger;
  rive.SMIBool? isHandsUp, isChecking;
  rive.SMINumber? numLook;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  List<ServiceRequest> serviceRequests = [];
  bool isPasswordVisible = false;
  bool isLoadingGoogle = false;
  bool isLoadingApple = false;

  rive.StateMachineController? stateMachineController;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final loginController = LoginScreenController();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _navigateToCardScreenPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
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
        final file = rive.RiveFile.import(data);
        final artboard = file.mainArtboard;
        stateMachineController = rive.StateMachineController.fromArtboard(
            artboard, "State Machine 1");
        if (stateMachineController != null) {
          artboard.addController(stateMachineController!);

          stateMachineController!.inputs.forEach((element) {
            switch (element.name) {
              case "success":
                successTrigger = element as rive.SMITrigger;
                break;
              case "fail":
                failTrigger = element as rive.SMITrigger;
                break;
              case "hands_up":
                isHandsUp = element as rive.SMIBool;
                break;
              case "idle":
                isChecking = element as rive.SMIBool;
                break;
              case "Look_down_left":
                numLook = element as rive.SMINumber;
                break;
              default:
                break;
            }
          });
        }

        setState(() => _teddyArtboard = artboard);
      },
    );

    // Mostrar el AlertDialog después de cargar la pantalla de inicio de sesión
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Términos y Condiciones"),
            content: TextButton(
              onPressed: () {
                launch('https://manitoxpress-cf855.web.app/#/PrivacyPage');
              },
              child: Text(
                'Al iniciar sesión, aceptas nuestros Términos y Condiciones.',
                style: TextStyle(
                  color: Color.fromARGB(255, 2, 8, 168),
                  fontSize: 16, // Cambia el tamaño según tu preferencia
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
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
    });
  }

  Future<void> login() async {
    isChecking?.change(false);
    isHandsUp?.change(false);
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      final userDoc = await _firestore
          .collection('workers')
          .doc(userCredential.user?.uid)
          .get();

      if (userDoc.exists) {
        successTrigger?.fire();
        _navigateToCardScreenPage();
      } else {
        failTrigger?.fire();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Usuario no encontrado"),
              content: Text("El usuario no existe en la colección de workers."),
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
    } catch (e) {
      failTrigger?.fire();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Inicio de sesión fallido"),
            content:
                Text("Email o contraseña incorrectos. Inténtalo de nuevo."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF090909),
                  backgroundColor: const Color(0xFFE8E8E8), // Color del texto
                  padding: EdgeInsets.symmetric(
                      vertical: 12, horizontal: 28), // Padding
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(8), // Bordes redondeados
                  ),
                  side: BorderSide(
                    color: const Color(0xFFE8E8E8), // Color del borde
                    width: 1, // Ancho del borde
                  ),
                ),
                child: Text(
                  "Aceptar",
                  style: TextStyle(
                    fontSize: 18, // Tamaño de fuente
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> signInWithGoogle() async {
    setState(() => isLoadingGoogle = true);
    try {
      await LoginScreenController.signInWithGoogle(context);
    } catch (e) {
      print('Error al iniciar sesión con Google: $e');
    } finally {
      setState(() => isLoadingGoogle = false);
    }
  }
  Future<void> signInWithApple() async {
    setState(() => isLoadingGoogle = true);
    try {
      await LoginScreenController.signInWithApple(context);
    } catch (e) {
      print('Error al iniciar sesión con Google: $e');
    } finally {
      setState(() => isLoadingGoogle = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffd6e2ea),
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(
              child: Container(
                padding: EdgeInsets.all(10.w),
                constraints: BoxConstraints(maxWidth: 0.2.sw),
                child: Image.asset(
                  'assets/images/LOGO1_Blanco.png',
                  width: 0.2.sw,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              'ManitoXpress',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Xpress Heavy',
                fontWeight: FontWeight.normal,
                fontStyle: FontStyle.italic,
                fontSize: 20.sp,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Blob azul animado

            Center(
              child: Container(
                width: 1.sw,
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_teddyArtboard != null)
                      SizedBox(
                        width: 0.8.sw,
                        height: 0.38.sh,
                        child: rive.Rive(
                          artboard: _teddyArtboard!,
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    SizedBox(height: 10.h),
                    Text(
                      'Bienvenidos a Manitos Xpress',
                      style: MyTextStyles.loginWelcomeStyle,
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1A819A),
                            shape: CircleBorder(),
                            padding: EdgeInsets.all(3.w),
                          ),
                          onPressed: isLoadingGoogle ? null : signInWithGoogle,
                          child: isLoadingGoogle
                              ? CircularProgressIndicator()
                              : CircleAvatar(
                                  backgroundColor: Colors.white,
                                  radius: 40.r,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 37.r,
                                    child: CircleAvatar(
                                      radius: 35.r,
                                      backgroundColor: Colors.white,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            FontAwesomeIcons.google,
                                            color: Color(0xFF1A819A),
                                          ),
                                          Text(
                                            'Inicio',
                                            style: GoogleFonts.lato(
                                              color: Color(0xFF1A819A),
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        SizedBox(width: 10.w),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1A819A),
                            shape: CircleBorder(),
                            padding: EdgeInsets.all(3.w),
                          ),
                          onPressed: isLoadingApple ? null : signInWithApple,
                          child: isLoadingApple
                              ? CircularProgressIndicator()
                              : CircleAvatar(
                                  backgroundColor: Colors.white,
                                  radius: 40.r,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 37.r,
                                    child: CircleAvatar(
                                      radius: 35.r,
                                      backgroundColor: Colors.white,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            FontAwesomeIcons.apple,
                                            color: Color(0xFF1A819A),
                                          ),
                                          Text(
                                            'Apple',
                                            style: GoogleFonts.lato(
                                              color: Color(0xFF1A819A),
                                              fontSize: 14.sp,
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
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
