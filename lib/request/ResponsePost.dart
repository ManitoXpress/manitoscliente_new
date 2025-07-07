import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';

import '../controller/RegisController.dart';
import '../controller/baseurl.dart';
import 'requestStatus.dart';
import 'resquest.dart';

class ApiService {
  final String baseUrl = ApiConfiguration.baseUrl; // URL base de la API
  String? getToken;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 1) Obtiene el token actual de Firebase Auth (para enviarlo en el header “Authorization”).
  Future<String?> _getFirebaseToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  /// 2) Actualiza un servicio dado su [serviceId] con los campos que incluyas en [data].
  ///    Llamará a PUT { baseUrl }/services/{serviceId}
  Future<void> updateService({
    required String serviceId,
    required Map<String, dynamic> data,
  }) async {
    final token = await _getFirebaseToken();
    if (token == null) {
      throw Exception('Usuario no autenticado (no hay token disponible)');
    }

    final uri = Uri.parse('$baseUrl/services/$serviceId');
    final response = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    debugPrint('🔵 PATCH /services/$serviceId');
    debugPrint('🔵 Body enviado: ' + jsonEncode(data));
    debugPrint('🟢 StatusCode:  [32m${response.statusCode} [0m');
    debugPrint('🟢 Response body: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint(
          '🔴 Error PATCH: statusCode=${response.statusCode}, body=${response.body}');
      throw Exception(
          'Error ${response.statusCode} al actualizar servicio: ${response.body}');
    }
  }

  /// 3) Actualiza una oferta dada su [offerId] con los campos que incluyas en [data].
  ///    Llamará a PUT { baseUrl }/offers/{offerId}
  /// PATCH /offers/{offerId}
  Future<void> updateOffer({
    required String offerId,
    required Map<String, dynamic> data,
  }) async {
    final token = await _getFirebaseToken();
    if (token == null) {
      throw Exception('Usuario no autenticado (no hay token disponible)');
    }

    final urlString = '$baseUrl/offers/$offerId';
    print('🤖→ PATCH a oferta: $urlString');
    print('    body: ${jsonEncode(data)}');
    final uri = Uri.parse(urlString);

    final response = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    print(
        '🤖← Oferta → statusCode: ${response.statusCode}, body: ${response.body}');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          'Error ${response.statusCode} al actualizar oferta: ${response.body}');
    }
  }

  Future<bool> deleteWorker(String userId, String authToken) async {
    try {
      final url = Uri.parse('$baseUrl/workers/$userId');
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('✅ Worker eliminado correctamente');
        return true;
      } else {
        debugPrint(
            '❌ Error al eliminar worker: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Excepción al eliminar worker: $e');
      return false;
    }
  }

  Future<http.Response> addCommentToService({
    required String serviceId,
    required Map<String, String> comment,
  }) async {
    final token = await _getAuthToken();

    final url = Uri.parse('$baseUrl/services/$serviceId');
    final body = jsonEncode({
      'comments': [comment]
    });

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error añadiendo comentario: '
          '${response.statusCode} ${response.body}');
    }
    return response;
  }

  Future<http.Response> addCommentToOffer({
    required String offerId,
    required Map<String, String> comment,
    required String token,
  }) async {
    // Preparamos el body con el array de un solo comentario
    final body = jsonEncode({
      'comments': [comment]
    });

    // PATCH directo a /offer/{offerId}
    final url = Uri.parse('$baseUrl/offer/$offerId');
    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error añadiendo comentario a la oferta: '
          '${response.statusCode} ${response.body}');
    }
    return response;
  }

  Future<http.Response> updateFcmToken(
    String userId,
    String authToken,
    String fcmToken,
  ) async {
    try {
      final body = jsonEncode({'fcmToken': fcmToken});

      final response = await http.patch(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: body,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('✅ FCM token actualizado en backend');
      } else {
        debugPrint('❌ Error al actualizar FCM token: ${response.statusCode}');
      }

      return response;
    } catch (e) {
      debugPrint('❌ Excepción actualizando FCM token: $e');
      rethrow;
    }
  }

  // Método para obtener el token de autenticación desde Firebase
  Future<String?> _getAuthToken() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        print('Usuario no autenticado. Por favor, inicia sesión.');
        return null;
      }
      final token =
          await user.getIdToken(true); // Fuerza la renovación del token
      print('Token obtenido: $token');
      return token;
    } catch (e) {
      print('Error al obtener el token: $e');
      return null;
    }
  }

  Future<String?> getAuthToken() => _getAuthToken();

  // Método para realizar la solicitud GET a la API del backend
  Future<List<Map<String, dynamic>>> getServices(
      String? userId, String status, String? token, String deviceId) async {
    // Obtener userId y token si no se pasan como parámetros
    userId ??= _auth.currentUser?.uid;
    token ??= await _getAuthToken();

    if (userId == null || userId.isEmpty) {
      print('Error: userId no está disponible.');
      return [];
    }

    final url = Uri.parse('$baseUrl/services?');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Device-Id': deviceId,
    };

    try {
      print('Realizando solicitud a $url');
      print('Encabezados: $headers');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        print('Respuesta recibida: ${response.body}');
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        print(
            'Error al obtener servicios: Código ${response.statusCode}, Respuesta: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Excepción al obtener servicios: $e');
      return [];
    }
  }

  Future<http.Response> sendTokenAndUserDataToServer({
    required String? token,
    required String? displayName,
    required String? email,
    required String? phoneNumber,
    required String? imagePath,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'displayName': displayName,
          'email': email,
          'phoneNumber': phoneNumber,
          'imagePath': imagePath,
        }),
      );
      return response;
    } catch (e) {
      print('Error al enviar datos al servidor: $e');
      throw Exception('Error al enviar datos al servidor');
    }
  }

  Future<void> updateOfferStatus({
    required String offerId,
    required String newStatus,
  }) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('Token nulo');

    final url = Uri.parse('$baseUrl/offers/$offerId');
    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': newStatus}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          'Error al actualizar oferta: ${response.statusCode} ${response.body}');
    }
    debugPrint('✅ Oferta $offerId actualizada a $newStatus');
  }

  Future<void> updateServiceStatus(
      ServiceRequest serviceRequest, String newStatusId, String token) async {
    try {
      final String? refreshedToken =
          await FirebaseAuth.instance.currentUser?.getIdToken(true);

      if (refreshedToken == null) {
        print('Token de autenticación nulo o vacío');
        throw Exception('Token de autenticación nulo o vacío');
      }

      Map<String, dynamic> requestBody = {
        'status': newStatusId, // Usar el id del estado en lugar del nombre
      };

      print('URL de la solicitud: $baseUrl/services/${serviceRequest.id}');
      print('Token de autenticación: $refreshedToken');
      print('Datos de formulario: $requestBody');

      final response = await http.patch(
        Uri.parse('$baseUrl/services/${serviceRequest.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshedToken',
        },
        body: jsonEncode(requestBody),
      );

      print('Código de estado de la respuesta: ${response.statusCode}');
      print('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 200) {
        print('Estado actualizado con éxito en el backend');
      } else {
        print(
            'Error al actualizar el estado en el backend. Código de estado: ${response.statusCode}');
        print('Cuerpo de la respuesta de error: ${response.body}');
        throw Exception(
            'Error al actualizar el estado en el backend. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al realizar la solicitud HTTP de actualización: $e');
      throw Exception('Error al actualizar el estado en el backend: $e');
    }
  }

  Future<void> sendTokenFCM(String? token) async {
    try {
      // Si el token es nulo, no tiene sentido continuar
      if (token == null) {
        throw Exception('Token FCM es nulo');
      }

      // Construir el cuerpo de la solicitud con el token
      final body = jsonEncode({
        'fcmToken':
            token, // Ajusta el nombre del campo según lo que espere tu backend
      });

      // Enviar el token al servidor
      final response = await http.post(
        Uri.parse('$baseUrl/token'), // Cambia la URL si es necesario
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      // Verifica la respuesta del servidor
      if (response.statusCode == 200) {
        print('Token FCM enviado exitosamente al backend.');
      } else {
        print(
            'Error al enviar el token al backend. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al enviar token FCM al servidor: $e');
      throw Exception('Error al enviar token al servidor');
    }
  }

  Future<http.Response> sendTokenToServer(String? token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );
      return response;
    } catch (e) {
      print('Error al enviar token al servidor: $e');
      throw Exception('Error al enviar token al servidor');
    }
  }

  Future<String> uploadImageToFirebaseStorage(File image, String userId) async {
    try {
      final String extension = image.path.split('.').last;
      final String imageName =
          'userID_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final String userFolderPath = '$userId/';
      final String imagePath = '$userFolderPath$imageName';

      if (await image.exists()) {
        Reference ref = _storage.ref().child(imagePath);
        UploadTask uploadTask = ref.putFile(image);

        await uploadTask.whenComplete(() {
          print('Imagen cargada con éxito en Firebase Storage');
        });

        final imageUrl = await ref.getDownloadURL();
        print('URL de la imagen en Firebase Storage: $imageUrl');
        return imageUrl;
      } else {
        throw Exception('El archivo de imagen no existe.');
      }
    } catch (e) {
      print('Error al cargar la imagen en Firebase Storage: $e');
      throw Exception('Error al cargar la imagen en Firebase Storage: $e');
    }
  }

  Future<http.Response> sendDataToBackend(
      ServiceRequest serviceRequest,
      String token,
      String id,
      String expertises,
      String categoryId,
      String subcategoryId,
      Status status,
      String subcategoryName,
      List<String> imageUrls,
      String? devicesId,
      String? fcmToken,
      String date, // yyyy-MM-dd
      String time // HH:mm
      ) async {
    // Timestamp de creación en UTC
    final String createdAt = DateTime.now().toUtc().toIso8601String();

    double latitude = serviceRequest.location['lat'] ?? 0.0;
    double longitude = serviceRequest.location['lng'] ?? 0.0;

    final formData = {
      'subcategoryName': subcategoryName,
      'date': date, // tu date
      'time': time, // tu time
      'createdAt': createdAt,
      // 'serviceDateTime': serviceRequest.serviceDateTime,  // <- quitas esta línea
      'description': serviceRequest.description,
      'images': imageUrls,
      'location': {
        'lat': latitude,
        'lng': longitude,
      },
      'userId': serviceRequest.userId,
      'status': status.id,
      'expertises': [
        {
          'id': serviceRequest.serviceType.id,
          'name': serviceRequest.serviceType.name,
        }
      ],
      'categoryId': categoryId,
      'subcategory': {
        'id': subcategoryId,
        'name': subcategoryName,
      },
      'devicesId': devicesId,
      'fcmToken': fcmToken,
      'token': token,
    };

    print('FormData: $formData');

    final response = await http.post(
      Uri.parse('$baseUrl/services'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      print('Datos enviados al backend con éxito');
    } else {
      print('Solicitud HTTP: ${response.statusCode}');
    }
    return response;
  }

  Future<http.Response> updateUser(
    String userId,
    RegistrationData registrationData,
    String token,
    String? devicesId,
    String? fcmToken,
  ) async {
    try {
      String codeReferral =
          '${registrationData.displayName.split(' ').first}_${registrationData.phoneNumber.length >= 4 ? registrationData.phoneNumber.substring(registrationData.phoneNumber.length - 4) : registrationData.phoneNumber}';
      Map<String, dynamic> requestBody = {
        'displayName': registrationData.displayName,
        'phoneNumber': registrationData.phoneNumber,
        'location': registrationData.location ?? {},
        'paymentType': registrationData.paymentType,
        'deviceId': registrationData.devicesId,
        'fcmToken': registrationData.fcmToken,
        'points': registrationData.points,
        'successfulReferrals': 0,
        'codeReferral': codeReferral,
      };

      print('Request Body: $requestBody');

      final response = await http.patch(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      return response;
    } catch (e) {
      print('Error al actualizar el usuario: $e');
      throw Exception('Error al actualizar el usuario: $e');
    }
  }
}

class FormData {
  final String dateTime;
  final String description;
  final List<String> images;
  final Map<String, double> location;
  final int offeredPrice;
  final String serviceType; // Cambiar a String
  final String userId;

  FormData({
    required this.dateTime,
    required this.description,
    required this.images,
    required this.location,
    required this.offeredPrice,
    required this.serviceType, // Cambiar el tipo a String
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'dateTime': dateTime,
      'description': description,
      'images': images,
      'location': {
        'lat': location['lat'],
        'lng': location['lng'],
      },
      'offeredPrice': offeredPrice,
      'serviceType': serviceType,
      'userId': userId,
    };
  }
}
