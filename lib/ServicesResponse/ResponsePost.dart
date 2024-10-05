import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:manitoscliente_new/ServicesResponse/resquest.dart';
import 'package:manitoscliente_new/metodos/RegisController.dart';
import 'package:manitoscliente_new/metodos/baseurl.dart';

class ApiService {
  final String baseUrl = ApiConfiguration
      .baseUrl; // Utiliza la URL base desde la clase de configuración
  String? getToken;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

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


  Future<http.Response> sendTokenFCM(String? token) async {
    try {
      // Si el token es nulo, no tiene sentido continuar
      if (token == null) {
        throw Exception('Token FCM es nulo');
      }

      // Construir el cuerpo de la solicitud con el token
      final body = jsonEncode({
        'fcmToken': token, // Ajusta el nombre del campo según lo que espere tu backend
      });

      // Enviar el token al servidor
      final response = await http.post(
        Uri.parse('$baseUrl/fcm-token'), // Cambia la URL si es necesario
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

      return response;
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
        Reference ref = storage.ref().child(imagePath);
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
  ) async {
    print('sendDataToBackend() called');
    print('Enviando datos al backend:');

    // Convierte la latitud y longitud a double o usa 0.0 si son nulas
    double latitude = serviceRequest.location['lat'] ?? 0.0;
    double longitude = serviceRequest.location['lng'] ?? 0.0;

    // Convertir offeredPrice a double antes de asignarlo

    // Construir expertises con el serviceType y el subcategoryId
    final expertisesList = [
      {
        'id': subcategoryId,
        'name': serviceRequest.serviceType.name,
      }
    ];

    // Crear una instancia de FormData
    final formData = {
      'subcategoryName': subcategoryName,
      'serviceDateTime': serviceRequest.serviceDateTime,
      'description': serviceRequest.description,
      'images': imageUrls,
      'location': {
        'lat': latitude,
        'lng': longitude,
      },
      'userId': serviceRequest.userId,
      'status': status.id,
      'expertises':
          expertisesList, // Aquí es donde se agrega la lista de expertises
      'categoryId': categoryId,
    };

    print('FormData: $formData');
    print('Token: $token');

    try {
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
    } catch (e) {
      print('Error en la solicitud HTTP: $e');
      throw Exception('Error al enviar datos al backend');
    }
  }



  Future<http.Response> updateUser(
      String userId, RegistrationData registrationData, String token) async {
    try {
      Map<String, dynamic> requestBody = {
        'displayName': registrationData.displayName,
        'phoneNumber': FirebaseAuth.instance.currentUser?.phoneNumber ?? '',
        'location': registrationData.location ?? {},
        'paymentType': registrationData.paymentType,
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
