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
import 'package:manitoscliente_new/controller/service_provider.dart';
import 'package:manitoscliente_new/firebase_options.dart';
import 'package:manitoscliente_new/home.dart';
import 'package:manitoscliente_new/menu/Login.dart';
import 'package:manitoscliente_new/provider/data_provider.dart';
import 'package:manitoscliente_new/provider/userProvider.dart';
import 'package:manitoscliente_new/provider/workerProvider.dart';
import 'package:manitoscliente_new/request/dataprofile.dart';
import 'package:manitoscliente_new/utils/fcmToken.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  await FCMService().init();

  final deviceId = await obtenerDeviceId();
  print("📱 Device ID: $deviceId");

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
  UserData? userData;
  final _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      requestNotificationPermissions();
      _checkLoginStatus();
    });
  }

  Future<void> _checkLoginStatus() async {
  final value = await _secureStorage.read(key: 'isLoggedIn');
  final loggedIn = value == 'true';

  final firebaseUser = FirebaseAuth.instance.currentUser;

  if (loggedIn && firebaseUser != null) {
    final fetchedUser = await fetchUserData(firebaseUser.uid);
    userData = fetchedUser;
    setState(() {
      isLoggedIn = true;
      isLoading = false;
    });
  } else {
    // Corrige sesión inválida y limpia el flag guardado
    await _secureStorage.delete(key: 'isLoggedIn');
    setState(() {
      isLoggedIn = false;
      isLoading = false;
    });
  }
}


  Future<void> _onLoginSuccess() async {
    await _secureStorage.write(key: 'isLoggedIn', value: 'true');
    print('Guardado en secure storage');

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      final fetchedUser = await fetchUserData(firebaseUser.uid);
      setState(() {
        userData = fetchedUser;
        isLoggedIn = true;
      });
    } else {
      print('⚠️ Login exitoso pero no se encontró usuario en FirebaseAuth');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
      home: isLoading
          ? LoadingScreen()
          : isLoggedIn
              ? (userData != null
                  ? HomeScreen(userData: userData!)
                  : LoadingScreen())
              : LoginScreen(
                  deviceId: widget.deviceId,
                  onLoginSuccess: _onLoginSuccess,
                ),
      routes: {
        '/home': (context) => userData != null
            ? HomeScreen(userData: userData!)
            : LoadingScreen(),
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
        500: Color(0xFF1A819A),
        600: Color(0xFF15788D),
        700: Color(0xFF126F80),
        800: Color(0xFF0E6573),
        900: Color(0xFF084D59),
      },
    );
  }
}

// Ejemplo de función para obtener los datos del usuario
Future<UserData> fetchUserData(String userId) async {
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
