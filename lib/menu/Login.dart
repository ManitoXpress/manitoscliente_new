import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:manitoscliente_new/request/ResponseGet.dart';
import 'package:manitoscliente_new/request/resquest.dart';
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

import '../request/dataprofile.dart';
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

  @override
  void initState() {
    super.initState();
    animationURL = defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS
        ? 'assets/animations/manito_cliente.riv'
        : 'assets/animations/manito_cliente.riv';

    rootBundle.load(animationURL).then((data) {
      final file = rive.RiveFile.import(data);
      final artboard = file.mainArtboard;
      stateMachineController =
          rive.StateMachineController.fromArtboard(artboard, "State Machine 1");
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
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              "Términos y Condiciones",
              style: MyTextStyles.inputTextStyle4,
            ),
            content: TextButton(
              onPressed: () {
                launch('https://manitoxpress-cf855.web.app/#/PrivacyPage');
              },
              child: Text(
                'Al iniciar sesión, aceptas nuestros Términos y Condiciones.',
                style: MyTextStyles.drawerButtonTextStyle6,
              ),
            ),
            actions: [
              TextButton(
                child: Text(
                  "Aceptar",
                  style: MyTextStyles.linkTextStyle,
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: Colors.white,
                  foregroundColor: Color(
                      0xFF1A819A), // Color del texto, el mismo que el borde
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(
                      color: Color(0xFF1A819A), // Color del borde
                    ),
                  ),
                ),
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween, // Distribuir elementos
          children: [
            // Texto en la parte izquierda
            Text(
              'ManitoXpress',
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
      ),
      body: SingleChildScrollView(
        child: Center(
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
                  style: MyTextStyles.welcomeTotheJungle1,
                ),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Botón de Google
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
                                        FontAwesomeIcons.google,
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
                    SizedBox(width: 10.w), // Espacio entre los botones
                    // Botón de Apple
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}