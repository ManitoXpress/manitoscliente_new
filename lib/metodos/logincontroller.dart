import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:manitoscliente_new/ServicesResponse/ResponsePost.dart';
import 'package:manitoscliente_new/home.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../widgets/welcome.dart';
import 'RegisController.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:manitoscliente_new/ServicesResponse/ResponsePost.dart';
import 'package:manitoscliente_new/home.dart';

import '../widgets/welcome.dart';
import 'RegisController.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
class LoginScreenController {
  static final ApiService apiService = ApiService();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _tokenCollection = '';

  // Almacena datos del usuario en Firestore si no existen
  static Future<void> storeUserData(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final userDoc = await userRef.get();

    if (!userDoc.exists) {
      await userRef.set({
        'displayName': user.displayName,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'imagePath': user.photoURL,
      });
    }
  }

  // Obtiene o crea un token para el usuario
  static Future<String?> getToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final existingToken = await _getExistingToken(user.uid);
        if (existingToken != null) {
          return existingToken;
        }
        final newToken = await user.getIdToken();
        if (newToken != null) {
          await _storeToken(user.uid, newToken);
        }
        return newToken;
      }
      print('El usuario no está autenticado.');
      return null;
    } catch (e) {
      print('Error al obtener el token: $e');
      return null;
    }
  }

  static Future<String?> _getExistingToken(String userId) async {
    try {
      final tokenDoc = await _firestore.collection(_tokenCollection).doc(userId).get();
      if (tokenDoc.exists) {
        return tokenDoc['token'] as String?;
      }
      return null;
    } catch (e) {
      print('Error al obtener el token existente: $e');
      return null;
    }
  }

  static Future<void> _storeToken(String userId, String newToken) async {
    try {
      await _firestore.collection(_tokenCollection).doc(userId).set({'token': newToken});
    } catch (e) {
      print('Error al almacenar el token: $e');
    }
  }

  // Verifica si el usuario ya está registrado
  static Future<bool> _checkIfUserIsRegistered(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.exists;
    } catch (e) {
      print('Error al verificar el registro del usuario: $e');
      return false;
    }
  }

  // Navegación según el estado del usuario
  static void _navigateToRegisterScreen(BuildContext context, {bool alreadyRegistered = false}) {
    final registrationController = RegistrationController();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => alreadyRegistered
            ? HomeScreen()
            : FirstTimeLoginScreen(registrationController: registrationController),
      ),
    );
  }

  // Inicio de sesión con Apple
  static Future<void> signInWithApple(BuildContext context) async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oAuthProvider = OAuthProvider("apple.com");
      final credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final authResult = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = authResult.user;

      if (user != null) {
        final alreadyRegistered = await _checkIfUserIsRegistered(user.uid);
        await storeUserData(user);
        print('Inicio de sesión con Apple exitoso para ${user.displayName}');
        _navigateToRegisterScreen(context, alreadyRegistered: alreadyRegistered);
      }
    } catch (e) {
      print('Error durante el inicio de sesión con Apple: $e');
      _showErrorDialog(context, 'No se pudo iniciar sesión con Apple. Inténtelo de nuevo.');
    }
  }

  // Inicio de sesión con Google
  static Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final googleSignInAccount = await GoogleSignIn().signIn();
      if (googleSignInAccount != null) {
        final googleAuth = await googleSignInAccount.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final authResult = await FirebaseAuth.instance.signInWithCredential(credential);
        final user = authResult.user;

        if (user != null) {
          final alreadyRegistered = await _checkIfUserIsRegistered(user.uid);
          await storeUserData(user);
          print('Inicio de sesión con Google exitoso para ${user.displayName}');
          _navigateToRegisterScreen(context, alreadyRegistered: alreadyRegistered);
        }
      }
    } catch (e) {
      print('Error durante el inicio de sesión con Google: $e');
      _showErrorDialog(context, 'No se pudo iniciar sesión con Google. Inténtelo de nuevo.');
    }
  }

  // Inicio de sesión con email y contraseña
  Future<User?> login(BuildContext context, String email, String password) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        if (user.emailVerified) {
          await storeUserData(user);
          _navigateToRegisterScreen(context);
          return user;
        } else {
          _showErrorDialog(context, 'Por favor, verifica tu correo electrónico.');
          await FirebaseAuth.instance.signOut();
        }
      }
    } catch (e) {
      print('Error al iniciar sesión: $e');
      _showErrorDialog(context, 'Email o contraseña incorrectos.');
    }
    return null;
  }

  // Mostrar error en diálogo
  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}
