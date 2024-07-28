import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'package:manitoscliente_new/Loading.dart';
import 'package:manitoscliente_new/firebase_options.dart';
import 'menu/Login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Firebase App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest,
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 10), () {
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true, // Opcional: habilitar la persistencia local
    );

    return MaterialApp(
      title: 'Manitos Xpress',
      theme: ThemeData(
        primarySwatch: MaterialColor(
          0xFF84090D,
          <int, Color>{
            50: Color(0xFF1A819A),
            100: Color(0xFF1A819A),
            200: Color(0xFF1A819A),
            300: Color(0xFF1A819A),
            400: Color(0xFF1A819A),
            500: Color(0xFF1A819A),
            600: Color(0xFF1A819A),
            700: Color(0xFF1A819A),
            800: Color(0xFF1A819A),
            900: Color(0xFF1A819A),
          },
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.grey,
          background: Colors.white,
          onBackground: Colors.grey,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A819A), // Color de fondo del AppBar
        ),
      ),
      home: isLoading ? LoadingScreen() : LoginScreen(), // Reemplaza LoginScreen con tu pantalla de inicio
    );
  }
}
