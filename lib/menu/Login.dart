import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:rive/rive.dart' as rive;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controller/logincontroller.dart';
import '../request/dataprofile.dart';
import '../Styles/stilo.dart';


class LoginScreen extends StatefulWidget {
  final String deviceId;
  final VoidCallback onLoginSuccess;

  const LoginScreen({
    Key? key,
    required this.deviceId,
    required this.onLoginSuccess,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginScreen> {
  // Rive animation
  late String animationURL;
  rive.Artboard? _teddyArtboard;
  rive.SMITrigger? successTrigger, failTrigger;
  rive.SMIBool? isHandsUp, isChecking;
  rive.SMINumber? numLook;
  rive.StateMachineController? stateMachineController;

  // Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Loaders
  bool isLoadingGoogle = false;
  bool isLoadingApple = false;

  @override
  void initState() {
    super.initState();
    // Load Rive
    animationURL = defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS
        ? 'assets/animations/manito_cliente.riv'
        : 'assets/animations/manito_cliente.riv';
    rootBundle.load(animationURL).then((data) {
      final file = rive.RiveFile.import(data);
      final artboard = file.mainArtboard;
      stateMachineController = rive.StateMachineController.fromArtboard(
          artboard, "State Machine 1");
      if (stateMachineController != null) {
        artboard.addController(stateMachineController!);
        for (final input in stateMachineController!.inputs) {
          switch (input.name) {
            case "success":
              successTrigger = input as rive.SMITrigger;
              break;
            case "fail":
              failTrigger = input as rive.SMITrigger;
              break;
            case "hands_up":
              isHandsUp = input as rive.SMIBool;
              break;
            case "idle":
              isChecking = input as rive.SMIBool;
              break;
            case "Look_down_left":
              numLook = input as rive.SMINumber;
              break;
          }
        }
      }
      setState(() => _teddyArtboard = artboard);
    });

    // Mostrar términos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(
            "Términos y Condiciones",
            style: MyTextStyles.inputTextStyle4,
          ),
          content: TextButton(
            onPressed: () => launch(
                'https://manitoxpress-cf855.web.app/#/PrivacyPage'),
            child: Text(
              'Al iniciar sesión, aceptas nuestros Términos y Condiciones.',
              style: MyTextStyles.drawerButtonTextStyle6,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1A819A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: const BorderSide(color: Color(0xFF1A819A)),
                ),
              ),
              child: Text("Aceptar", style: MyTextStyles.linkTextStyle),
            ),
          ],
        ),
      );
    });
  }

  /// Inicio como invitado
  Future<void> _signInAsGuest() async {
    try {
      print("Usuario ingresó como invitado");
      widget.onLoginSuccess();
    } catch (e) {
      print('Error al iniciar como invitado: $e');
    }
  }

  /// Login con Google
  Future<void> signInWithGoogle() async {
    setState(() => isLoadingGoogle = true);
    try {
      await LoginScreenController.signInWithGoogle(context);
      widget.onLoginSuccess();
    } catch (e) {
      print('Error al iniciar sesión con Google: $e');
    } finally {
      setState(() => isLoadingGoogle = false);
    }
  }

  /// Login con Apple
  Future<void> signInWithApple() async {
    setState(() => isLoadingApple = true);
    try {
      await LoginScreenController.signInWithApple(context);
      widget.onLoginSuccess();
    } catch (e) {
      print('Error al iniciar sesión con Apple: $e');
    } finally {
      setState(() => isLoadingApple = false);
    }
  }

  void _launchDeleteAccountURL() async {
    const url = 'https://manitosxpress.com/#/DeleteAccount';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ManitoXpress', style: MyTextStyles.buttonTextStyle),
            Flexible(
              child: Container(
                padding: EdgeInsets.all(10.w),
                constraints: BoxConstraints(maxWidth: 0.22.sw),
                child: Image.asset(
                  'assets/images/LOGO1_Blanco.png',
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
                    child: rive.Rive(artboard: _teddyArtboard!, fit: BoxFit.fitWidth),
                  ),
                SizedBox(height: 10.h),
                Text('Bienvenidos a Manitos Xpress', style: MyTextStyles.welcomeTotheJungle1),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A819A),
                        shape: const CircleBorder(),
                        padding: EdgeInsets.all(3.w),
                      ),
                      onPressed: isLoadingGoogle ? null : signInWithGoogle,
                      child: isLoadingGoogle
                          ? const CircularProgressIndicator()
                          : CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 40.r,
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 37.r,
                                child: CircleAvatar(
                                  radius: 35.r,
                                  backgroundColor: Colors.white,
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                       Icon(FontAwesomeIcons.google, color: Color(0xFF1A819A)),
                                      Text('Google', style: MyTextStyles.linkTextStyle),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                    SizedBox(width: 10.w),
                    // Invitado
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        shape: const CircleBorder(),
                        padding: EdgeInsets.all(3.w),
                      ),
                      onPressed: _signInAsGuest,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 40.r,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.person_outline, color: Colors.black),
                            SizedBox(height: 4),
                            Text('Invitado', style: TextStyle(color: Colors.black)),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    // Apple
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A819A),
                        shape: const CircleBorder(),
                        padding: EdgeInsets.all(3.w),
                      ),
                      onPressed: isLoadingApple ? null : signInWithApple,
                      child: isLoadingApple
                          ? const CircularProgressIndicator()
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
                                      const Icon(Icons.apple, color: Color(0xFF1A819A)),
                                      Text('Apple', style: MyTextStyles.linkTextStyle),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                // Eliminar cuenta
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A819A),
                    shape: const CircleBorder(),
                    padding: EdgeInsets.all(3.w),
                  ),
                  onPressed: _launchDeleteAccountURL,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 40.r,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.delete, color: Colors.red),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
