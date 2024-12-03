import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart'; // Importa la librería de ATT
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Importa flutter_screenutil
import 'package:manitoscliente_new/utils/notification.dart';
import 'package:manitoscliente_new/utils/notificationFcm.dart';

import 'Loading.dart';
import 'firebase_options.dart';
import 'menu/Login.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Handler para mensajes en segundo plano
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Es importante inicializar Firebase cuando se reciba una notificación en segundo plano.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");

  // Manejar la notificación en segundo plano con NotificationService

}



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configurar el handler para mensajes en segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Inicializar Firebase App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest,
  );

  // Inicializar el servicio de notificaciones
  await FCMService().init();



  // Obtener y guardar Device ID
  final deviceId = await obtenerDeviceId();
  print("Device ID: $deviceId");

  runApp(MyApp(deviceId: deviceId));
}
Future<String> obtenerDeviceId() async {
  try {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      final id = androidInfo.id?.toString() ?? 'Unknown Device ID';
      return id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      final id = iosInfo.identifierForVendor?.toString() ?? 'Unknown Device ID';
      return id;
    } else {
      return 'Unsupported Platform';
    }
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
      persistenceEnabled: true,
    );

    return ScreenUtilInit(
      designSize: Size(375, 800),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Manitos Xpress',
        theme: ThemeData(
          primarySwatch: MaterialColor(
            0xFF1A819A,
            <int, Color> {
              50: Color(0xFF1A819A),
              100: Color(0xFF1A819A),
              200: Color(0xFF1A819A),
              300: Color(0xFF1A819A),
              400: Color(0xFF1A819A),
              500: Color(0xFF1A819A),
              600: Color(0xFF1A819A),
              700: Color(0xFF1A819A),
              800: Color(0xFF1A819A),
              900: Color.fromRGBO(26, 129, 154, 1),
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
        home: isLoading ? LoadingScreen() : LoginScreen(deviceId: widget.deviceId),
      ),
    );
  }
}