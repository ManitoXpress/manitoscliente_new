import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';
class AuthService {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Método para guardar el token
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
  }

  // Método para obtener el token almacenado
  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  // Método para eliminar el token
  Future<void> deleteToken() async {
    await _secureStorage.delete(key: 'auth_token');
  }

  // Método para verificar si el token ha expirado
  Future<bool> isTokenExpired() async {
    String? token = await getToken();

    if (token == null) {
      return true; // Si no hay token, considerar que ha expirado
    }

    try {
      // Decodificar el token sin validar la firma
      Map<String, dynamic> payload = Jwt.parseJwt(token);

      // Obtener el tiempo de expiración
      int exp = payload['exp'];

      // Convertir el tiempo de expiración a DateTime
      DateTime expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);

      // Verificar si el token ha expirado
      return expiryDate.isBefore(DateTime.now());
    } catch (e) {
      print("Error al decodificar el token: $e");
      return true; // Si hay un error, considerar que el token ha expirado
    }
  }
  

  // Método para verificar si el token es válido
  Future<bool> isTokenValid() async {
    return !await isTokenExpired();
  }
}