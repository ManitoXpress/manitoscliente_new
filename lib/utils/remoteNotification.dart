import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:http/http.dart' as http;

import '../controller/auth_utils.dart';
class RemoteNotificationService {
  DateTime? _lastNotificationTime;
  Timer? _serviceCheckTimer;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  RemoteNotificationService() {
    initialize();
  }

  void initialize() {
    _initLocalNotifications();
    _initFirebaseMessagingListeners();
    setupPeriodicServiceCheck();
  }

  void dispose() {
    _serviceCheckTimer?.cancel();
  }

  void setupPeriodicServiceCheck() {
    _serviceCheckTimer?.cancel();
    _serviceCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await checkForNewNotifications();
    });
  }

  // Inicializar notificaciones locales
  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        null;
      },
    );
  }

  // Manejar las notificaciones entrantes de Firebase
  void _initFirebaseMessagingListeners() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Obtener y mostrar el token
    String? fcmToken = await messaging.getToken();
    null;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      null;
      if (message.notification != null) {
        _showLocalNotification(
          message.notification!.title ?? 'Nueva Notificación',
          message.notification!.body ?? 'Tienes una nueva alerta',
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      null;
    });
  }

  Future<void> checkForNewNotifications() async {
    try {
      // Obtener FCM Token y Auth Token
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      String? authToken = await AuthUtils.getToken();

      if (fcmToken == null || authToken == null) {
        null;
        return;
      }

      // Headers con autenticación
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'fcmToken': fcmToken,
        'Authorization': 'Bearer $authToken', // Autenticación con token JWT
      };


      final response = await http.post(
        Uri.parse('https://us-central1-manitoxpress-cf855.cloudfunctions.net/api/services/test'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        null;
        await _handleBackendNotification('{"Notification": true, "title": "Hola", "message": "Este es un mensaje de prueba"}');

      } else {
        null;
      }
    } catch (e) {
      null;
    }
  }

  Future<void> _handleBackendNotification(String responseBody) async {
    try {
      // Verificar si responseBody está vacío
      if (responseBody.isEmpty) {
        null;
        return;
      }

      // Intentar decodificar el JSON
      final Map<String, dynamic> data = jsonDecode(responseBody);

      if (data['Notification'] == true) {
        String title = data['title'] ?? 'Nueva Notificación';
        String body = data['message'] ?? 'Tienes una nueva alerta';
        await _showLocalNotification(title, body);
      }
    } on FormatException catch (e) {
      null;
      null;
    } catch (e) {
      null;
    }
  }

  Future<void> _showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Este canal es para notificaciones importantes',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0, // ID de la notificación
      title,
      body,
      platformChannelSpecifics,
    );
  }
}