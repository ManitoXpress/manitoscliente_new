import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:manitoscliente_new/request/ResponsePost.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

// FCMService ajustado para prevenir el error en iOS al llamar getToken()
class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Inicializa permisos y listeners de notificación (foreground/background).
  Future<void> init() async {
    try {
      debugPrint('🔔 Iniciando FCM Service...');

      // Verificar que Firebase esté inicializado
      if (!Firebase.apps.isNotEmpty) {
        debugPrint('❌ Firebase no está inicializado');
        return;
      }

      // Esperar un poco para asegurar que Firebase esté completamente inicializado
      await Future.delayed(const Duration(milliseconds: 500));

      // 1) Solicitar permisos con manejo de errores específico
      try {
        NotificationSettings settings =
            await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        debugPrint(
            '📱 Permisos de notificación: ${settings.authorizationStatus}');

        // Si los permisos no están autorizados, intentar solicitar provisionalmente
        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          debugPrint(
              '⚠️ Permisos denegados, intentando solicitar provisionalmente...');
          settings = await _firebaseMessaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: true,
          );
          debugPrint(
              '📱 Estado después de solicitud provisional: ${settings.authorizationStatus}');
        }
      } catch (e) {
        debugPrint('❌ Error solicitando permisos: $e');
      }

      // 2) En iOS, indicar que en primer plano muestre alert, badge y sonido
      try {
        await _firebaseMessaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('✅ Opciones de presentación configuradas');
      } catch (e) {
        debugPrint('❌ Error configurando opciones de presentación: $e');
      }

      // 3) Inicializar el plugin de notificaciones locales
      try {
        await _initLocalNotifications();
        debugPrint('✅ Notificaciones locales inicializadas');
      } catch (e) {
        debugPrint('❌ Error inicializando notificaciones locales: $e');
      }

      // 4) Arrancar los listeners de Firebase Messaging
      try {
        _initFirebaseMessagingListeners();
        debugPrint('✅ Listeners de Firebase Messaging configurados');
      } catch (e) {
        debugPrint('❌ Error configurando listeners: $e');
      }

      debugPrint('✅ FCM Service inicializado correctamente');
    } catch (e) {
      debugPrint('❌ Error general inicializando FCM Service: $e');
    }
  }

  /// Llamar esto DESPUÉS de un login exitoso, pasando el userId.
  Future<void> registerTokenForUser(String userId) async {
    try {
      debugPrint('🔔 Registrando token FCM para usuario: $userId');

      // Verificar que Firebase esté inicializado
      if (!Firebase.apps.isNotEmpty) {
        debugPrint('❌ Firebase no está inicializado');
        return;
      }

      // Verificar que el userId no esté vacío
      if (userId.isEmpty) {
        debugPrint('❌ userId está vacío');
        return;
      }

      // 1) Obtener el token actual de FCM con el método de recuperación
      String? fcmToken = await getFCMTokenWithRetry();

      if (fcmToken != null) {
        debugPrint('✅ FCM Token obtenido: ${fcmToken.substring(0, 20)}...');
        await _sendTokenToBackend(userId, fcmToken);
      } else {
        debugPrint(
            '⚠️ No se pudo obtener FCM Token después de múltiples intentos');
        // Continuar sin FCM token, pero registrar el intento
        await _sendTokenToBackend(userId, 'no_fcm_token_available');
      }

      // 2) Escuchar futuros cambios de token (reinstalaciones, refresh automático)
      try {
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          debugPrint('🔄 Token FCM refrescado');
          _sendTokenToBackend(userId, newToken);
        });
        debugPrint('✅ Listener de refresh de token configurado');
      } catch (e) {
        debugPrint('❌ Error configurando listener de refresh: $e');
      }

      debugPrint('✅ Registro de token FCM completado');
    } catch (e) {
      debugPrint('❌ Error general registrando token para usuario: $e');
    }
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
      debugPrint('❌ Error actualizando FCM token: $e');
    }
  }

  // ------------------------------
  // Resto igual que antes:
  // ------------------------------

  Future<void> _initLocalNotifications() async {
    try {
      debugPrint('🔔 Inicializando notificaciones locales...');

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      final DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
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
          try {
            debugPrint(
                '📱 Notificación local seleccionada con payload: ${resp.payload}');
          } catch (e) {
            debugPrint(
                '❌ Error procesando respuesta de notificación local: $e');
          }
        },
      );

      debugPrint('✅ Notificaciones locales inicializadas correctamente');
    } catch (e) {
      debugPrint('❌ Error inicializando notificaciones locales: $e');
    }
  }

  void _initFirebaseMessagingListeners() {
    try {
      debugPrint('🔔 Configurando listeners de Firebase Messaging...');

      // Notificaciones en primer plano
      FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
        try {
          debugPrint('📨 Notificación recibida en primer plano');
          final notification = msg.notification;
          if (notification != null) {
            showLocalNotification(
              notification.title ?? 'Nueva Notificación',
              notification.body ?? 'Tienes una nueva alerta',
            );
          } else if (msg.data.isNotEmpty) {
            showLocalNotification(
              msg.data['title'] ?? 'Nueva Notificación',
              msg.data['body'] ?? 'Tienes una nueva alerta',
            );
          }
        } catch (e) {
          debugPrint('❌ Error procesando notificación en primer plano: $e');
        }
      }, onError: (error) {
        debugPrint('❌ Error en listener de mensajes en primer plano: $error');
      });

      // Cuando la app se abre desde la notificación
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
        try {
          debugPrint('📱 Notificación abierta por el usuario');
          // Navegación u otra lógica
        } catch (e) {
          debugPrint('❌ Error procesando apertura de notificación: $e');
        }
      }, onError: (error) {
        debugPrint('❌ Error en listener de apertura de notificación: $error');
      });

      // Manejar mensaje inicial cuando la app se abre desde terminada
      FirebaseMessaging.instance
          .getInitialMessage()
          .then((RemoteMessage? message) {
        if (message != null) {
          debugPrint('📱 App abierta desde estado terminado via notificación');
        }
      }).catchError((error) {
        debugPrint('❌ Error obteniendo mensaje inicial: $error');
      });

      debugPrint(
          '✅ Listeners de Firebase Messaging configurados correctamente');
    } catch (e) {
      debugPrint('❌ Error general configurando listeners: $e');
    }
  }

  Future<void> showLocalNotification(
    String title,
    String body, {
    String? payload,
  }) async {
    try {
      debugPrint('🔔 Mostrando notificación local: $title');

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

      debugPrint('✅ Notificación local mostrada correctamente');
    } catch (e) {
      debugPrint('❌ Error mostrando notificación local: $e');
    }
  }

  /// Método de diagnóstico para verificar el estado de Firebase Messaging
  Future<void> diagnoseFCMStatus() async {
    try {
      debugPrint('🔍 Diagnóstico de FCM Service...');

      // Verificar Firebase
      if (!Firebase.apps.isNotEmpty) {
        debugPrint('❌ Firebase no está inicializado');
        return;
      }
      debugPrint('✅ Firebase está inicializado');

      // Verificar permisos
      try {
        NotificationSettings settings =
            await _firebaseMessaging.requestPermission();
        debugPrint('📱 Estado de permisos: ${settings.authorizationStatus}');
        debugPrint('📱 Alertas: ${settings.alert}');
        debugPrint('📱 Badge: ${settings.badge}');
        debugPrint('📱 Sonido: ${settings.sound}');
      } catch (e) {
        debugPrint('❌ Error verificando permisos: $e');
      }

      // Verificar token con más detalles
      try {
        debugPrint('🔍 Intentando obtener FCM Token...');
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          debugPrint('✅ FCM Token disponible: ${token.substring(0, 20)}...');
        } else {
          debugPrint('⚠️ FCM Token es null');

          // Intentar obtener más información sobre el error
          try {
            // Verificar si el dispositivo está registrado
            final apnsToken = await _firebaseMessaging.getAPNSToken();
            debugPrint('📱 APNS Token: $apnsToken');
          } catch (apnsError) {
            debugPrint('❌ Error obteniendo APNS Token: $apnsError');
          }
        }
      } catch (e) {
        debugPrint('❌ Error obteniendo FCM Token: $e');

        // Intentar obtener más información sobre el error específico
        if (e.toString().contains('unknown')) {
          debugPrint('🔍 Error desconocido detectado. Posibles causas:');
          debugPrint(
              '   - Certificados APNs no configurados en Firebase Console');
          debugPrint('   - Bundle ID incorrecto en Firebase Console');
          debugPrint('   - Configuración de APNs faltante');
        }
      }

      // Verificar configuración de iOS
      if (Platform.isIOS) {
        try {
          await _firebaseMessaging.setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
          debugPrint('✅ Opciones de presentación configuradas en iOS');
        } catch (e) {
          debugPrint('❌ Error configurando opciones de presentación: $e');
        }
      }

      debugPrint('🔍 Diagnóstico completado');
    } catch (e) {
      debugPrint('❌ Error en diagnóstico: $e');
    }
  }

  /// Método de recuperación para obtener FCM token con múltiples intentos
  Future<String?> getFCMTokenWithRetry({int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('🔄 Intento $attempt de obtener FCM Token...');

        // Verificar que Firebase esté inicializado
        if (!Firebase.apps.isNotEmpty) {
          debugPrint('❌ Firebase no está inicializado en intento $attempt');
          await Future.delayed(Duration(seconds: attempt));
          continue;
        }

        // Solicitar permisos si es necesario
        NotificationSettings settings =
            await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          debugPrint('⚠️ Permisos denegados en intento $attempt');
          await Future.delayed(Duration(seconds: attempt));
          continue;
        }

        // Intentar obtener el token
        String? token = await _firebaseMessaging.getToken();

        if (token != null && token.isNotEmpty) {
          debugPrint('✅ FCM Token obtenido exitosamente en intento $attempt');
          return token;
        } else {
          debugPrint('⚠️ FCM Token es null o vacío en intento $attempt');
        }

        // Esperar antes del siguiente intento
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      } catch (e) {
        debugPrint('❌ Error en intento $attempt: $e');

        // Si es el último intento, mostrar información detallada
        if (attempt == maxRetries) {
          debugPrint('🔍 Información de diagnóstico final:');
          debugPrint('   - Firebase apps: ${Firebase.apps.length}');
          debugPrint('   - Platform: ${Platform.operatingSystem}');
          debugPrint('   - Error específico: $e');
        }

        // Esperar antes del siguiente intento
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }

    debugPrint(
        '❌ No se pudo obtener FCM Token después de $maxRetries intentos');
    return null;
  }
}
