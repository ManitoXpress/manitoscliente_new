import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart'; // Importa flutter_screenutil
import '../utils/fcmToken.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'Loading.dart';
import 'firebase_options.dart';
import 'home.dart';
import 'menu/Login.dart';


import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'dart:io';
// Handler para mensajes en segundo plano
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: \${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest,
  );

  if (Platform.isIOS) {
    await requestTrackingPermission(); // Solo en iOS
    FirebaseFirestore.instance.settings = 
      Settings(persistenceEnabled: true);
  }
  
  await FCMService().init();
  final deviceId = await obtenerDeviceId();
  print("Device ID: \$deviceId");

  runApp(
    ScreenUtilInit(
      designSize: Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MyApp(deviceId: deviceId),
    ),
  );
}

Future<void> requestTrackingPermission() async {
  if (Platform.isIOS) {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      final result = await AppTrackingTransparency.requestTrackingAuthorization();
      print("Estado de ATT: \$result");
    }
  }
}

Future<String> obtenerDeviceId() async {
  try {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'Unknown Device ID';
    }
    return 'Unsupported Platform';
  } catch (e) {
    print('Error obteniendo Device ID: \$e');
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
        primarySwatch: _customPrimarySwatch(),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.grey,
          background: Colors.white,
          onBackground: Colors.grey,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A819A),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => isLoading ? LoadingScreen() : (isLoggedIn ? HomeScreen() : LoginScreen(deviceId: widget.deviceId)),
        '/home': (context) => HomeScreen(),  // Ruta definida para 'HomeScreen'
      },
    );
  }

  MaterialColor _customPrimarySwatch() {
    return const MaterialColor(
      0xFF1A819A,
      <int, Color>{
        50: Color(0xFFE1F5F7),
        100: Color(0xFFB3E0E5),
        200: Color(0xFF80CCD3),
        300: Color(0xFF4DB8C1),
        400: Color(0xFF26A7B1),
        500: Color(0xFF1A819A), // Color principal
        600: Color(0xFF15788D),
        700: Color(0xFF126F80),
        800: Color(0xFF0E6573),
        900: Color(0xFF084D59),
      },
    );
  }
}
