import 'package:firebase_auth/firebase_auth.dart';

class AuthUtils {
  static Future<String?> getToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        String? idToken = await user.getIdToken();
        return idToken;
      } catch (e) {
        print('Error al obtener el token: $e');
        return null;
      }
    }
    return null;
  }
}
