import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:manitoscliente_new/request/ResponsePost.dart';
import 'package:shared_preferences/shared_preferences.dart';
// FCMService ajustado para prevenir el error en iOS al llamar getToken()
class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  /// Inicializa permisos y listeners de notificación (foreground/background).
  Future<void> init() async {
    // 1) Solicitar permisos
    await _firebaseMessaging.requestPermission();

    // 2) En iOS, indicar que en primer plano muestre alert, badge y sonido
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3) Inicializar el plugin de notificaciones locales
    await _initLocalNotifications();

    // 4) Arrancar los listeners de Firebase Messaging (sin tocar el token aquí)
    _initFirebaseMessagingListeners();
  }

  /// Llamar esto DESPUÉS de un login exitoso, pasando el userId.
  Future<void> registerTokenForUser(String userId) async {
    // 1) Obtener el token actual de FCM
    final String? fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken != null) {
      await _sendTokenToBackend(userId, fcmToken);
    }

    // 2) Escuchar futuros cambios de token (reinstalaciones, refresh automático)
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _sendTokenToBackend(userId, newToken);
    });
  }

  /// Envía el token al backend junto con el ID de usuario y authToken.
  Future<void> _sendTokenToBackend(String userId, String fcmToken) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Obtener ID token de Firebase Auth
      final String? authToken = await user.getIdToken();

      // Llamar al API con los parámetros posicionales esperados
      await ApiService().updateFcmToken(userId, authToken!, fcmToken);
      debugPrint('✅ FCM token enviado al backend');
    } catch (e) {
      debugPrint('❌ Error actualizando FCM token: \$e');
    }
  }

  // ------------------------------
  // Resto igual que antes:
  // ------------------------------

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse resp) {
        debugPrint(
            'Notificación seleccionada con payload: \${resp.payload}');
      },
    );
  }

  void _initFirebaseMessagingListeners() {
    // Notificaciones en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      final notification = msg.notification;
      if (notification != null) {
        showLocalNotification(
          notification.title ?? 'Nueva Notificación',
          notification.body ?? 'Tienes una nueva alerta',
        );
      } else if (msg.data.isNotEmpty) {
        showLocalNotification(
          msg.data['title']   ?? 'Nueva Notificación',
          msg.data['body']    ?? 'Tienes una nueva alerta',
        );
      }
    });

    // Cuando la app se abre desde la notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
      debugPrint('Notificación abierta por el usuario');
      // Navegación u otra lógica
    });
  }

  Future<void> showLocalNotification(
      String title,
      String body, {
        String? payload,
      }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Canal para notificaciones importantes',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
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