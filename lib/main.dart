// Handler para mensajes en segundo plano
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:manitoscliente_new/Loading.dart';
import 'package:manitoscliente_new/controller/RegisController.dart';
import 'package:manitoscliente_new/controller/home_Provider.dart';

import 'package:manitoscliente_new/firebase_options.dart';
import 'package:manitoscliente_new/home.dart';
import 'package:manitoscliente_new/menu/Login.dart';
import 'package:manitoscliente_new/provider/dataProvider.dart';
import 'package:manitoscliente_new/provider/providerController.dart';
import 'package:manitoscliente_new/provider/service_provider.dart';

import 'package:manitoscliente_new/provider/workerProvider.dart';
import 'package:manitoscliente_new/request/dataprofile.dart';
import 'package:manitoscliente_new/utils/fcmToken.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isIOS) {
    final status = await AppTrackingTransparency.requestTrackingAuthorization();
    print("📊 Estado ATT inicial: $status");
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest,
  );

  if (Platform.isIOS) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
  }

  try {
    debugPrint('🔔 Iniciando FCM Service...');
    await FCMService().init();

    // Esperar un poco antes de ejecutar el diagnóstico
    await Future.delayed(const Duration(seconds: 2));

    // Ejecutar diagnóstico después de la inicialización
    await FCMService().diagnoseFCMStatus();
  } catch (e) {
    debugPrint('❌ Error inicializando FCM Service: $e');
    // Continuar con la ejecución aunque FCM falle
  }

  final deviceId = await obtenerDeviceId();
  print("📱 Device ID: $deviceId");

  // Inicializa la localización para fechas en español
  await initializeDateFormatting('es', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ServiceDataProvider()),
        ChangeNotifierProvider(create: (_) => HomeServicesProvider()),
        ChangeNotifierProvider(create: (_) => ProfessionalServicesProvider()),
        ChangeNotifierProvider(create: (_) => WorkerProvider()),
        ChangeNotifierProvider(create: (_) => UserDataProvider()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) => MyApp(deviceId: deviceId),
      ),
    ),
  );
}

Future<void> requestNotificationPermissions() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  print('User granted permission: ${settings.authorizationStatus}');
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

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool isLoading = true;
  bool isLoggedIn = false;
  late UserData userData;
  RegistrationData? registrationData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Inicializar userData con valores vacíos
    userData = UserData.empty();
    registrationData = userData.registrationData;

    // Espera al primer render para no bloquear la UI:
    WidgetsBinding.instance.addPostFrameCallback((_) {
      requestNotificationPermissions(); // 🔔 Solicita permiso de notificaciones
      _checkLoginStatus();
    });
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool loggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (loggedIn) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          userData = await fetchUserData(user.uid);
          registrationData = userData.registrationData;
        } catch (e) {
          print('Error obteniendo datos del usuario: $e');
          // Si hay error, crear un UserData vacío pero válido
          userData = UserData.empty();
          registrationData = userData.registrationData;
        }
      } else {
        // Si no hay usuario de Firebase pero está marcado como logueado, limpiar el estado
        loggedIn = false;
        await prefs.setBool('isLoggedIn', false);
        userData = UserData.empty();
        registrationData = userData.registrationData;
      }
    } else {
      // Si no está logueado, inicializar con valores vacíos
      userData = UserData.empty();
      registrationData = userData.registrationData;
    }

    // Simula tiempo de carga si es necesario
    await Future.delayed(const Duration(seconds: 5));

    setState(() {
      isLoggedIn = loggedIn;
      isLoading = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
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
          backgroundColor: Color(0xFF1A819A),
        ),
      ),
      home: isLoading
          ? LoadingScreen()
          : isLoggedIn
              ? HomeScreen(
                  userData: userData,
                )
              : LoginScreen(
                  deviceId: widget.deviceId,
                  onLoginSuccess: () {},
                ),
    );
  }
}

// Ejemplo de función para obtener los datos del usuario
Future<UserData> fetchUserData(String userId) async {
  // Aquí debes implementar la lógica para obtener los datos del usuario
  // Por ejemplo, desde una base de datos o un servicio web
  // Este es solo un ejemplo de retorno
  return UserData(
    userId: userId,
    displayName: '',
    phoneNumber: '',
    getToken: null,
    selectedCountryCode: '',
    location: null,
    paymentType: '',
    email: '',
    registrationData: RegistrationData(
      userId: userId,
      devicesId: '',
      fcmToken: '',
      displayName: '',
      phoneNumber: '',
      paymentType: '',
      selectedCountryCode: '',
      location: null,
      email: '',
      points: 0,
    ),
    referralCode: '',
    points: 0,
    referrerUserId: '',
  );
}
