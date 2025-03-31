import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart'; // Importa la librería de ATT
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Importa flutter_screenutil
import 'package:manitoscliente_new/home.dart';
import 'package:manitoscliente_new/utils/notification.dart';
import 'package:manitoscliente_new/utils/notificationFcm.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Loading.dart';
import 'firebase_options.dart';
import 'menu/Login.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Handler para mensajes en segundo plano

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest,
  );

  await FCMService().init();

  final deviceId = await obtenerDeviceId();
  print("Device ID: $deviceId");

  runApp(
    ScreenUtilInit(
      designSize: Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MyApp(deviceId: deviceId),
    ),
  );
}

Future<String> obtenerDeviceId() async {
  try {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id?.toString() ?? 'Unknown Device ID';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor?.toString() ?? 'Unknown Device ID';
    }
    return 'Unsupported Platform';
  } catch (e) {
    print('Error obteniendo Device ID: $e');
    return 'Error Device ID';
  }
}

class MyApp extends StatefulWidget {
  final String deviceId;
  const MyApp({required this.deviceId});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool isLoading = true;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLoginStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool loggedIn = prefs.getBool('isLoggedIn') ?? false;

    // Espera 2 segundos MÍNIMO (pero no bloquea otras operaciones)
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isLoggedIn = loggedIn;
      isLoading = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('App is in foreground');
    } else if (state == AppLifecycleState.paused) {
      print('App is in background');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Manitos Xpress',
      theme: ThemeData(
        primarySwatch: MaterialColor(
          0xFF1A819A,
          const <int, Color>{
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
          backgroundColor: Color(0xFF1A819A),
        ),
      ),
      home: isLoading
          ? LoadingScreen()
          : isLoggedIn
          ? HomeScreen()
          : LoginScreen(deviceId: widget.deviceId),
    );
  }
}