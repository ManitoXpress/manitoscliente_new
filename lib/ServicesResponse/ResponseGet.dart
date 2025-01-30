import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:manitoscliente_new/main.dart';
import 'package:manitoscliente_new/metodos/auth_utils.dart';
import 'package:manitoscliente_new/ServicesResponse/resquest.dart';
import 'package:manitoscliente_new/metodos/baseurl.dart';

import 'dataprofile.dart';

class ApiService2 {
  String? getToken; // Variable para almacenar el token del usuario
  ServiceRequest? serviceRequest;

  final String baseUrl = ApiConfiguration.baseUrl;
  Future<List<ServiceRequest>> fetchServicesByUserId(String userId) async {
    try {
      // Construir la URL para la solicitud
      final url = Uri.parse('$baseUrl/services/byUserId?userId=$userId');

      // Realizar la solicitud GET
      final response = await http.get(url, headers: {
        'Authorization':
            'Bearer $getToken', // Enviar el token en los headers si es necesario
      });

      if (response.statusCode == 200) {
        // Si la respuesta es exitosa, parsear los datos JSON
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ServiceRequest.fromSnapshot(json)).toList();
      } else {
        throw Exception(
            'Error al obtener los servicios: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en la solicitud de servicios: $e');
      throw Exception('Error en la solicitud de servicios');
    }
  }

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

  Future<http.Response> getAllServices(String authToken, String column,
      String value, String type, String deviceId) async {
    try {
      final String? authTokenValue = await AuthUtils.getToken();

      // Imprimir los valores de los parámetros para depuración
      print('Parámetro column: $column');
      print('Parámetro value: $value');
      print('Parámetro type: $type');
      print('Parámetro deviceId: $deviceId');

      // Construir la URL con los parámetros
      final url = Uri.parse(
          '$baseUrl/services?userId=$value&columns=$column&values=$value&type=$type&deviceId=$deviceId');

      // Imprimir la URL solicitada para depuración
      print('URL solicitada: $url');

      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $authTokenValue',
        },
      );

      if (response.statusCode == 200) {
        print('Datos recibidos del backend con éxito');
      } else {
        print('Solicitud HTTP fallida con código: ${response.statusCode}');
      }
      return response;
    } catch (e) {
      print('Error en la solicitud HTTP: $e');
      throw Exception('Error al obtener datos del backend');
    }
  }

  Future<String> getImageUrls(String userId, String imageName) async {
    try {
      String filePath = '$userId/$imageName';
      print('Accediendo a la ruta de la imagen: $filePath');

      final Reference ref = FirebaseStorage.instance.ref().child(filePath);

      // Obtener la URL de descarga
      final String downloadUrl = await ref.getDownloadURL();

      print('URL de descarga de la imagen: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('Error al obtener la URL de la imagen: $e');
      // Manejo del caso donde la imagen no existe o no se puede acceder
      return '';
    }
  }

Future<List<ServiceRequest>> getOffers(
  String column,
  String value,
  String type,
  String deviceId,
  List<ServiceRequest> services,
  String status, // Nuevo parámetro para filtrar por estado
) async {
  try {
    final String? authTokenValue = await AuthUtils.getToken();

    if (authTokenValue == null) {
      throw Exception('Token de autorización no encontrado');
    }

    if (services.isEmpty || services.any((service) => service.id.isEmpty)) {
      throw Exception('ID del servicio no encontrado');
    }

    List<ServiceRequest> allOffers = [];

    List<Future> requests = services.map((service) async {
      final url = Uri.parse(
        '$baseUrl/offers/${service.id}?'
        'columns=$column&'
        'values=$value&'
        'type=$type&'
        'deviceId=$deviceId&'
        'status=$status', // Añadir parámetro de estado
      );

      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $authTokenValue',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> offersJson = json.decode(response.body);
        allOffers.addAll(offersJson
            .map((offer) => ServiceRequest.fromSnapshot(offer))
            .where((offer) => offer.status.id == status) // Filtro adicional en cliente
            .toList());
      } else {
        print('Error al obtener ofertas para el servicio ${service.id}: ${response.statusCode}');
      }
    }).toList();

    await Future.wait(requests);
    return allOffers;
  } catch (e) {
    print('Error al obtener ofertas del backend: $e');
    throw Exception('Error al obtener ofertas');
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
        print(
            'No se encontraron imágenes de perfil en la carpeta del usuario.');
        return null;
      }
    } catch (e) {
      print('Error al obtener la URL de la imagen desde Firebase Storage: $e');
      throw Exception(
          'Error al obtener la URL de la imagen desde Firebase Storage: $e');
    }
  }

  Future<http.Response> getByUserId({
    required String userId,
    required String authToken,
    required String column,
    required String value,
    required String type,
    required String deviceId, // Añadir deviceId como parámetro
  }) async {
    try {
      // Asegúrate de que los parámetros estén correctamente codificados
      final url = Uri.parse(
          '$baseUrl/services?userId=$value&columns=$column&values=$value&type=$type&deviceId=$deviceId');

      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        print('Datos recibidos del backend con éxito');
      } else {
        print('Solicitud HTTP fallida: ${response.statusCode}');
      }
      return response;
    } catch (e) {
      print('Error en la solicitud HTTP: $e');
      throw Exception('Error al obtener datos del backend');
    }
  }

  Future<http.Response> getServiceByIdAndName(
      String categoryId, String serviceName, String token) async {
    print('getServiceByIdAndName() called');
    print('Obteniendo servicio del backend:');

    // Construimos la URL con los parámetros necesarios
    final String url =
        '$baseUrl/services?categoryId=$categoryId&name=$serviceName';

    print('URL: $url');
    print('Token: $token');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print('Servicio obtenido con éxito');
      } else {
        print('Solicitud HTTP fallida con código: ${response.statusCode}');
      }
      return response;
    } catch (e) {
      print('Error en la solicitud HTTP: $e');
      throw Exception('Error al obtener el servicio del backend');
    }
  }

  Future<http.Response> fetchServiceDetailsFromBackend(
      String userId, String serviceId) async {
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
  Future<String> getImage(
    String userId,
  ) async {
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

  Future<List<ServiceResponse>> fetchServicesFromBackend2(
      String token, String parentId) async {
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

  Future<List<ServiceResponse>> fetchServicesParent1(
      String token, String parentId) async {
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
  WorkerDetails? workerDetails;
  String workerId;
  String userId;
  final Map<String, double> location; // Campo de ubicación agregado

  // Propiedades faltantes
  final String offerId; // Asumido que es un campo adicional
  final List<String> images; // Imágenes asociadas con la oferta
  final List<Expertise> expertises; // Lista de especializaciones
  final String subcategoryName; // Subcategoría del servicio

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
    this.workerDetails,
    required this.workerId,
    required this.userId,
    required this.location, // Requiere la ubicación
    required this.offerId, // Asumido
    required this.images, // Asumido
    required this.expertises, // Asumido
    required this.subcategoryName, // Asumido
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

    final List<dynamic> expertisesData = json['expertises'] ?? [];
    final List<Expertise> expertises = expertisesData
        .map((data) => Expertise(
              id: data['id'] ?? '',
              name: data['name'] ?? '',
            ))
        .toList();

    return ServiceResponse(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      description: json['description'] ?? '',
      serviceTypes: serviceTypes,
      parentId: json['parentId'] ?? '',
      buttonTexts: json['buttonTexts'] != null
          ? List<String>.from(json['buttonTexts'])
          : [],
      priceRanges: json['priceRanges'] != null
          ? List<dynamic>.from(json['priceRanges'])
          : [],
      typeName: json['typeName'] ?? '',
      workerId: json['workerId'] ?? '',
      userId: json['userId'] ?? '',
      location: json['location'] != null
          ? Map<String, double>.from(json['location'])
          : {},
      offerId: json['offerId'] ?? '', // Asumido que es un campo adicional
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      expertises: expertises,
      subcategoryName: json['subcategoryName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'description': description,
      'serviceTypes':
          serviceTypes.map((serviceType) => serviceType.toMap()).toList(),
      'parentId': parentId,
      'buttonTexts': buttonTexts,
      'priceRanges': priceRanges,
      'typeName': typeName,
      'workerId': workerId,
      'userId': userId,
      'location': location,
      'offerId': offerId, // Asumido
      'images': images,
      'expertises': expertises.map((expertise) => expertise.toMap()).toList(),
      'subcategoryName': subcategoryName,
    };
  }

  @override
  String toString() {
    return 'ServiceResponse(id: $id, name: $name, image: $image, description: $description, serviceTypes: $serviceTypes, parentId: $parentId, buttonTexts: $buttonTexts, priceRanges: $priceRanges, typeName: $typeName, workerId: $workerId, userId: $userId, location: $location, offerId: $offerId, images: $images, expertises: $expertises, subcategoryName: $subcategoryName)';
  }
}
