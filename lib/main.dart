import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart'; // Importa la librería de ATT
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Importa flutter_screenutil
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/date_symbol_data_local.dart'; // Agregar para inicialización de localización
import 'package:manitoscliente_new/provider/dataProvider.dart';
import 'package:manitoscliente_new/provider/workerPRovider.dart';
import 'package:manitoscliente_new/request/ResponsePost.dart';
import 'package:manitoscliente_new/request/dataprofile.dart';
import 'package:manitoscliente_new/utils/fcmToken.dart';
import 'package:manitoscliente_new/utils/sync_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:manitoscliente_new/services/historial_preload_service.dart';
import 'package:manitoscliente_new/constant/cacheConstants.dart';
import 'package:manitoscliente_new/controller/auth_utils.dart';
import 'package:manitoscliente_new/request/ResponseGet.dart';


import 'package:manitoscliente_new/utils/validation.dart';
import 'Loading.dart';
import 'controller/RegisController.dart';
import 'provider/home_provider.dart';
import 'provider/providerController.dart';
import 'provider/service_provider.dart';
import 'provider/providerService.dart';
import 'firebase_options.dart';
import 'home.dart';
import 'menu/Login.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

// Handler para mensajes en segundo plano
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Es importante inicializar Firebase cuando se reciba una notificación en segundo plano.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    if (e is FirebaseException && e.code == 'duplicate-app') {
      null;
    } else {
      rethrow;
    }
  }
  null;

}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar localización para evitar errores de formato de fecha
  await initializeDateFormatting('es_ES', null);

  null;
  // 1. Pedimos permiso ATT inmediatamente
  if (Platform.isIOS) {
    final status = await AppTrackingTransparency.requestTrackingAuthorization();
    null;
  }
  null;

  null;
  // 2. Ahora inicializamos Firebase y el resto de SDKs
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e is FirebaseException && e.code == 'duplicate-app') {
      null;
    } else {
      rethrow;
    }
  }
  null;
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  null;
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest,
  );
  null;

  // 3. Firestore persistence (iOS)
  if (Platform.isIOS) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
  }

  null;
  // 4. Inicializamos tu servicio de FCM y demás
  await FCMService().init();
  null;

  null;
  // 5. Inicializar servicio de sincronización
  await SyncService().initialize();
  null;

  null;
  final deviceId = await obtenerDeviceId();
  null;
  null;

    runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ServiceDataProvider()),
        ChangeNotifierProvider(create: (_) => HomeServicesProvider()),
        ChangeNotifierProvider(create: (_) => ProfessionalServicesProvider()),
        ChangeNotifierProvider(create: (_) => WorkerProvider()),
        ChangeNotifierProvider(create: (_) => UserDataProvider()), 
        ChangeNotifierProvider(create: (_) => HistorialProvider()),
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

  null;
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
    null;
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
  UserData? userData;
  RegistrationData? registrationData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Pedimos ubicacion e inicializamos notificaciones sin bloquear _checkLoginStatus
      requestLocationPermissions();
      requestNotificationPermissions(); // 🔔 Solicita permiso de notificaciones
      
      _checkLoginStatus();
    });
  }

  Future<void> _checkLoginStatus() async {
    // Verificamos si hay un usuario autenticado en Firebase
    User? user = FirebaseAuth.instance.currentUser;
    bool loggedIn = user != null;

    if (loggedIn) {
      try {
        userData = await fetchUserData(user!.uid);
        registrationData = userData?.registrationData;

        // 🚀 PRECARGA: Iniciar carga del historial en background
        _preloadHistorialData(user.uid);
      } catch (e) {
        loggedIn = false; // Fallback so we don't crash
      }
    }

    // Reducir tiempo de carga inicial
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        isLoggedIn = loggedIn && userData != null;
        isLoading = false;
      });
    }
  }

  /// 🚀 Precarga datos del historial en background después del login
  Future<void> _preloadHistorialData(String userId) async {
    try {
      // Obtener token de forma asíncrona
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final token = await user.getIdToken();
      
      // Obtener device ID
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = 'unknown';
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id ?? 'unknown';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
      }

      // Precargar historial en background (no bloquea la UI)
      _preloadHistorialInBackground(userId, token ?? '', deviceId);
      
    } catch (e) {
      null;
    }
  }

  /// 🚀 OPTIMIZADO: Carga el historial en background usando el servicio de precarga
  Future<void> _preloadHistorialInBackground(String userId, String token, String deviceId) async {
    // Esperar un poco para no interferir con la carga inicial
    await Future.delayed(const Duration(milliseconds: CacheConstants.preloadDelayMs));
    
    try {
      null;
      
      // Usar el servicio de precarga global
      final preloadService = HistorialPreloadService();
      
      // La precarga se ejecutará cuando el contexto esté disponible
      // Por ahora solo registramos la intención
      null;
      
    } catch (e) {
      null;
    }
  }

  Future<void> requestLocationPermissions() async {
    try {
      // Pido permiso sólo mientras la app está en uso
      final status = await Permission.locationWhenInUse.request();

      if (status.isGranted) {
        // Si necesito ubicación en background:
        if (await Permission.locationAlways.isDenied) {
          await Permission.locationAlways.request();
        }
      } else if (status.isPermanentlyDenied) {
        // openAppSettings(); // Removido para evitar que se abran configuraciones automáticamente
      }
    } catch (e) {
      null;
    }
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
      null;
    } else if (state == AppLifecycleState.paused) {
      null;
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
          ? HomeScreen(userData: userData!,)
          : LoginScreen(deviceId: widget.deviceId, onLoginSuccess: () {  },),
    );
  }
}

// Función para obtener los datos del usuario usando la API
Future<UserData> fetchUserData(String userId) async {
  try {
    final token = await AuthUtils.getToken();
    if (token == null) {
      throw Exception('Token de autenticación nulo al iniciar sesión');
    }
    
    // Usamos ApiService2 (o ApiService) para llamar al backend real
    final apiService = ApiService2();
    return await apiService.fetchUserData(userId, token);
  } catch (e) {
    null;
    
    // Retornamos datos de fallback o propagamos el error si no quieres que pase.
    rethrow;
  }
}
