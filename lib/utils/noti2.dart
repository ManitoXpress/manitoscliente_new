import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _firebaseMessaging.requestPermission();

    _initLocalNotifications();
    _initFirebaseMessagingListeners();
  }

  // Inicializar notificaciones locales
  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        null;
      },
    );
  }

  void _initFirebaseMessagingListeners() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Obtener y mostrar el token
    String? fcmToken = await messaging.getToken();
    null;

    // Listener para notificaciones recibidas en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      null;

      if (message.notification != null) {
        // Mostrar notificación con título y cuerpo enviados por el backend
        showLocalNotification(
          message.notification!.title ?? 'Nueva Notificación',
          message.notification!.body ?? 'Tienes una nueva alerta',
        );
      } else if (message.data.isNotEmpty) {
        // Si los datos vienen en la sección 'data', mostrar notificación usando esos datos
        showLocalNotification(
          message.data['title'] ?? 'Nueva Notificación',
          message.data['body'] ?? 'Tienes una nueva alerta',
        );
      }
    });

    // Listener para cuando se abre la app desde una notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      null;
      // Aquí puedes manejar la navegación o acciones adicionales
    });
  }


  Future<void> showLocalNotification(String title, String body,
      {String? payload}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Este canal es para notificaciones importantes',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      0, // ID de la notificación
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }
}