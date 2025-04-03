import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';

import 'package:http/http.dart';

import 'package:flutter/material.dart';

import '../home.dart';



class NotificationService {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  NotificationService() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  }

  Future<void> initNotifications(BuildContext context) async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notificación seleccionada: ${response.payload}');
        // Navegar a la pantalla de inicio cuando la notificación es seleccionada
        if (response.payload != null) {
          _navigateToHomeScreen(context, response.payload!);
        }
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      handleNotification(message, context); // Pasar el contexto aquí
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleNotification(message, context); // Pasar el contexto aquí
    });

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  void handleNotification(RemoteMessage message, BuildContext context) {
    if (message.data['status'] == 'offer') {
      showNotificationWithAction(
        message.notification?.title ?? 'Nuevo servicio ofertado',
        message.notification?.body ?? 'Tienes una nueva oferta para tu servicio.',
        message.data['serviceId'] ?? '',
      );
    }
  }

  Future<void> showNotificationWithAction(
      String title, String body, String serviceId) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'service_offers_channel',
      'Service Offers',
      importance: Importance.max,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('accept', 'Aceptar'),
        AndroidNotificationAction('reject', 'Rechazar'),
      ],
    );
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: serviceId,
    );
  }

  void _navigateToHomeScreen(BuildContext context, String serviceId) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => HomeScreen(initialPageIndex: 0)), // Cambia el índice según la lógica que desees
    );
  }

  static Future<void> firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    // Maneja los mensajes en segundo plano aquí si es necesario
  }

  Future<void> requestNotificationPermissions() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
  }

  // Método para registrar el FCM Token y el deviceId en Firestore
  Future<void> registerFCMToken() async {
    try {
      // Obtener el FCM Token
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      // Obtener el deviceId usando "device_info_plus"
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String? deviceId;

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id; // Para Android, usa 'id'
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor; // Para iOS
      }

      // Verifica si ambos valores no son nulos
      if (fcmToken != null && deviceId != null) {
        // Verificar si ya existe un documento con este deviceId
        DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
            .collection('services')
            .doc(deviceId)
            .get();

        if (documentSnapshot.exists) {
          // Si ya existe el documento, solo actualizamos el FCM token
          await FirebaseFirestore.instance
              .collection('services')
              .doc(deviceId)
              .update({
            'fcmToken': fcmToken,
          });
          print("FCM Token actualizado en Firestore.");
        } else {
          // Si no existe el documento, lo creamos
          await FirebaseFirestore.instance
              .collection('services')
              .doc(deviceId)
              .set({
            'deviceId': deviceId,
            'fcmToken': fcmToken,
          });
          print("FCM Token y Device ID guardados en Firestore con éxito.");
        }
      } else {
        print("Error: No se pudo obtener el deviceId o el fcmToken.");
      }
    } catch (e) {
      print("Error al registrar el FCM Token: $e");
    }
  }
}
