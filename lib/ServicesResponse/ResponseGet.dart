import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:manitoscliente_new/metodos/auth_utils.dart';
import 'package:manitoscliente_new/ServicesResponse/resquest.dart';
import 'package:manitoscliente_new/metodos/baseurl.dart';

import 'dataprofile.dart';

class ApiService2 {
  String? getToken; // Variable para almacenar el token del usuario
  final String baseUrl = ApiConfiguration.baseUrl;

  Future<List<ServiceResponse>> fetchServicesFromBackend(String token) async {
    try {
      final String? authToken = await AuthUtils.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/categories/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        if (responseData != null) {
          final List<ServiceResponse> services = responseData
              .map((data) => ServiceResponse.fromJson(data))
              .toList();

          print('Total de servicios obtenidos del backend: ${services.length}');

          return services;
        } else {
          throw Exception('La respuesta del backend está vacía.');
        }
      } else {
        print('Error: ${response.statusCode}');
        print('Mensaje de error: ${response.body}');

        throw Exception('Error al cargar los servicios desde el backend');
      }
    } catch (e) {
      print('Error en la solicitud HTTP: $e');
      throw Exception('Error al cargar los servicios desde el backend');
    }
  }
  Future<List<ServiceResponse>> getOffers(String serviceId) async {
    try {
      final String? authTokenValue = await AuthUtils.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/offers/$serviceId'),
        // Reemplaza esta URL con la URL real de tu endpoint
        headers: <String, String>{
          'Authorization': 'Bearer $authTokenValue',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        final List<ServiceResponse> offers = responseData
            .map((data) => ServiceResponse.fromJson(data))
            .toList();
        return offers;
      } else {
        throw Exception(
            'Error al obtener las ofertas. Código de estado: ${response
                .statusCode}');
      }
    } catch (e) {
      print('Error en la solicitud HTTP para obtener las ofertas: $e');
      throw Exception('Error al obtener las ofertas desde el backend: $e');
    }
  }

  Future<UserData> fetchUserData(String userId, String getIdToken) async {
    try {
      // Construir el header con el token
      Map<String, String> headers = {
        'Authorization': 'Bearer $getIdToken',
        'Content-Type': 'application/json', // Ajusta esto según tus necesidades
      };

      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: headers,
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData is Map<String, dynamic>) {
          return UserData.fromJson(responseData);
        } else {
          throw Exception('El formato de la respuesta no es válido');
        }
      } else {
        throw Exception('Solicitud HTTP fallida: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en la solicitud HTTP: $e');
      throw Exception('Error al obtener datos del backend');
    }
  }

  Future<String?> fetchProfileImage(String userId) async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;

      if (user == null) {
        // Manejar el caso en el que el usuario no está autenticado
        print('Error: Usuario no autenticado.');
        return null;
      }

      final FirebaseStorage storage = FirebaseStorage.instance;

      // Ruta de la carpeta del usuario
      String userFolderPath = '${user.uid}/';

      // Obtener la referencia de la carpeta del usuario
      Reference userFolderRef = storage.ref().child(userFolderPath);

      // Listar los elementos en la carpeta del usuario
      ListResult result = await userFolderRef.listAll();

      // Filtrar solo las imágenes que tienen el prefijo "profileImage_"
      List<Reference> profileImages = result.items
          .where((item) => item.name.startsWith('profileImage_'))
          .toList();

      if (profileImages.isNotEmpty) {
        // Obtener la referencia de la primera imagen en la carpeta
        Reference firstImageRef = profileImages.first;

        // Obtener la URL de descarga de la primera imagen
        final imageUrl = await firstImageRef.getDownloadURL();
        print('URL de la primera imagen en Firebase Storage: $imageUrl');

        return imageUrl;
      } else {
        print('No se encontraron imágenes de perfil en la carpeta del usuario.');
        return null;
      }
    } catch (e) {
      print('Error al obtener la URL de la imagen desde Firebase Storage: $e');
      throw Exception('Error al obtener la URL de la imagen desde Firebase Storage: $e');
    }
  }

  Future<http.Response> getByUserId(String userId, String authToken, String column, String value, String type) async {
    try {
      final String? authTokenValue = await AuthUtils.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/services?columns=$column&values=$value&type=$type'),
        headers: <String, String>{
          'Authorization': 'Bearer $authTokenValue',
        },
      );

      if (response.statusCode == 200) {
        print('Datos recibidos del backend con éxito');
      } else {
        print('Solicitud HTTP: ${response.statusCode}');
      }
      return response;
    } catch (e) {
      print('Error en la solicitud HTTP: $e');
      throw Exception('Error al obtener datos del backend');
    }
  }

  Future<http.Response> fetchServiceDetailsFromBackend(String userId, String serviceId) async {
    try {
      final String? token = await AuthUtils.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/services/$serviceId/details'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData != null) {
          return response;
        } else {
          throw Exception('La respuesta del backend está vacía.');
        }
      } else {
        print('Error: ${response.statusCode}');
        print('Mensaje de error: ${response.body}');

        throw Exception(
            'Error al cargar los detalles del servicio desde el backend');
      }
    } catch (e) {
      print('Error en la solicitud HTTP: $e');
      throw Exception(
          'Error al cargar los detalles del servicio desde el backend');
    }
  }

  // Método para cargar las imágenes desde el backend
  Future<String> getImage(String userId,) async {
    try {
      final FirebaseStorage storage = FirebaseStorage.instance;

      // Modifica la ruta de la referencia según la nueva dirección
      final String directoryPath = '/images/$userId';
      final Reference ref = storage.ref().child(directoryPath);

      // Lista los elementos en el directorio
      final ListResult result = await ref.list();
      if (result.items.isNotEmpty) {
        // Asegúrate de declarar firstItem antes de usarlo en la expresión await
        final Reference firstItem = result.items.first;

        // Obtén la URL de descarga desde los metadatos
        final String images = await firstItem.getDownloadURL();
        return images;
      } else {
        throw Exception('No se encontraron imágenes en el directorio.');
      }
    } catch (e) {
      print('Error al obtener la imagen desde Firebase Storage: $e');
      throw Exception('Error al obtener la imagen desde Firebase Storage');
    }
  }

  Future<List<ServiceResponse>> fetchServicesFromBackend2(String token, String parentId) async {
    try {
      final String? authToken = await AuthUtils.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/categories/parent/$parentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        if (responseData != null) {
          final List<ServiceResponse> services = responseData
              .map((data) => ServiceResponse.fromJson(data))
              .toList();
          return services;
        } else {
          throw Exception('La respuesta del backend está vacía.');
        }
      } else {
        print('Error: ${response.statusCode}');
        print('Mensaje de error: ${response.body}');
        throw Exception('Error al cargar los servicios desde el backend');
      }
    } catch (e) {
      print('Error en la solicitud HTTP: $e');
      throw Exception('Error al cargar los servicios desde el backend');
    }
  }

  Future<List<ServiceResponse>> fetchServicesParent1(String token, String parentId) async {
    try {
      final String? authToken = await AuthUtils.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/categories/parent/h3ZOnJLzLTKldW8Py7wC'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        if (responseData != null) {
          final List<ServiceResponse> services = responseData
              .map((data) => ServiceResponse.fromJson(data))
              .toList();
          return services;
        } else {
          throw Exception('La respuesta del backend está vacía.');
        }
      } else {
        print('Error: ${response.statusCode}');
        print('Mensaje de error: ${response.body}');
        throw Exception('Error al cargar los servicios desde el backend');
      }
    } catch (e) {
      print('Error en la solicitud HTTP: $e');
      throw Exception('Error al cargar los servicios desde el backend');
    }
  }
}
class ServiceResponse {
  final String id;
  final String name;
  final String image;
  final String description;
  final List<ServiceType> serviceTypes;
  final String? parentId;
  final List<String> buttonTexts;
  final List<dynamic> priceRanges;
  final String typeName;

  ServiceResponse({
    required this.id,
    required this.name,
    required this.image,
    required this.description,
    required this.serviceTypes,
    this.parentId,
    required this.buttonTexts,
    required this.priceRanges,
    required this.typeName,
  });

  factory ServiceResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> serviceTypesData = json['serviceTypes'] ?? [];
    final List<ServiceType> serviceTypes = serviceTypesData
        .map((data) => ServiceType(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      selectedDate: data['selectedDate'] ?? '',
      selectedTime: data['selectedTime'] ?? '',
    ))
        .toList();
    return ServiceResponse(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      description: json['description'] ?? '',
      serviceTypes: serviceTypes,
      parentId: json['parentId'] ?? '', // Asegúrate de proporcionar un valor por defecto si es nulo
      buttonTexts: json['buttonTexts'] != null ? List<String>.from(json['buttonTexts']) : [],
      priceRanges: json['priceRanges'] != null ? List<dynamic>.from(json['priceRanges']) : [],
      typeName: json['typeName'] ?? '', // Corregido el nombre del campo
    );
  }
}