import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1) Pide permisos
    await _firebaseMessaging.requestPermission();

    // 2) En iOS, indica que en primer plano muestre alert, badge y sonido
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3) Inicializa tu plugin de notificaciones locales
    await _initLocalNotifications();

    // 4) Arranca los listeners de Firebase Messaging
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
        print("Notificación seleccionada con payload: ${response.payload}");
      },
    );
  }

  void _initFirebaseMessagingListeners() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Obtener y mostrar el token
    String? fcmToken = await messaging.getToken();
    print("FCM Token: $fcmToken");

    // Listener para notificaciones recibidas en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Notificación recibida en primer plano: ${message.notification
          ?.title}");

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
      print("Notificación abierta por el usuario");
      // Aquí puedes manejar la navegación o acciones adicionales
    });
  }


  Future<void> showLocalNotification(String title, String body, {String? payload}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Este canal es para notificaciones importantes',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    // DarwinNotificationDetails para iOS
    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }
}