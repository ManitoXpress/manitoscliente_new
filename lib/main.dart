import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart'; // Importa la librería de ATT
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Importa flutter_screenutil
import 'package:manitoscliente_new/utils/notification.dart';

import 'Loading.dart';
import 'firebase_options.dart';
import 'menu/Login.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


// Manejador para los mensajes en segundo plano
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
  // Aquí puedes agregar lógica adicional para manejar el mensaje en segundo plano
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

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLoading = true;
  late NotificationService notificationService;

  @override
  void initState() {
    super.initState();
    notificationService = NotificationService(); // Inicializar el NotificationService
    notificationService.initNotifications(context); // Pasar el contexto aquí
    _requestTrackingPermission(); // Solicitar permisos de tracking para iOS
    _initializeFirebaseMessaging(); // Inicializar Firebase Messaging
    Future.delayed(const Duration(seconds: 10), () {
      setState(() {
        isLoading = false; // Simulación de carga
      });
    });
  }

  // Función para solicitar permiso de App Tracking Transparency en iOS
  Future<void> _requestTrackingPermission() async {
    final TrackingStatus status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await Future.delayed(const Duration(milliseconds: 200));
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }

  // Función para inicializar Firebase Messaging
  Future<void> _initializeFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Solicitar permisos para notificaciones en iOS
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Obtener el token FCM para enviar notificaciones a este dispositivo
    String? token = await messaging.getToken();
    print('FCM Token: $token');

    // Configurar handlers para mensajes cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Recibido mensaje en primer plano: ${message.messageId}");
      // Aquí puedes manejar el mensaje, por ejemplo, mostrar una notificación local
      notificationService.handleNotification(message, context); // Llama a tu servicio de notificaciones con el contexto
    });

    // Configurar handlers para cuando la app se abre desde una notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Aplicación abierta desde notificación: ${message.messageId}");
      // Aquí puedes manejar la acción cuando se abre la app desde una notificación
      notificationService.handleNotification(message, context); // Llama a tu servicio de notificaciones con el contexto
    });
  }

  @override
  Widget build(BuildContext context) {
    // Configurar Firestore para habilitar la persistencia
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );

    return ScreenUtilInit(
      designSize: const Size(375, 800),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Manitos Xpress',
        theme: ThemeData(
          primarySwatch: MaterialColor(
            0xFF1A819A,
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
        home: isLoading ? LoadingScreen() : LoginScreen(), // Muestra pantalla de carga si aún está cargando
      ),
    );
  }
}