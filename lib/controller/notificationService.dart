import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final BuildContext context;

  NotificationService(this.context);

  Future<void> init() async {
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

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings, onDidReceiveNotificationResponse: (NotificationResponse response) {
      null;
    });

    FirebaseMessaging.onMessage.listen(_handleNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotification);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  void _handleNotification(RemoteMessage message) {
    if (message.data['status'] == 'offer') {
      _showNotificationWithAction(
        message.notification?.title ?? 'Nuevo servicio ofertado',
        message.notification?.body ?? 'Tienes una nueva oferta para tu servicio.',
        message.data['serviceId'] ?? '',
      );
    }
  }

  Future<void> _showNotificationWithAction(String title, String body, String serviceId) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'service_offers_channel',
      'Service Offers',
      importance: Importance.max,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('accept', 'Aceptar'),
        AndroidNotificationAction('reject', 'Rechazar'),
      ],
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidDetails);
    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: serviceId,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    null;
  }

  void dispose() {
    _flutterLocalNotificationsPlugin.cancelAll();
  }
}
