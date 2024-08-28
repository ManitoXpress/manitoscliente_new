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

class LoginScreenController {
  static final ApiService apiService = ApiService();
  static final String _tokenCollection = 'user_tokens';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> storeUserData(User user) async {
    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(user.uid);

    final userDoc = await userRef.get();
    if (!userDoc.exists) {
      await userRef.set({
        'displayName': user.displayName,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'imagePath': user.photoURL,
        // Otros campos que desees almacenar
      });
    }
  }

  static Future<String?> getToken() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Verificar si ya existe un token
        String? existingToken = await _getExistingToken(user.uid);

        if (existingToken != null) {
          // Si hay un token existente, devolverlo
          return existingToken;
        } else {
          // Si no hay un token existente, obtener uno nuevo
          String? newToken = await user.getIdToken();

          // Almacenar el nuevo token para uso futuro
          if (newToken != null) {
            await _storeToken(user.uid, newToken);
          }

          return newToken;
        }
      } else {
        print('El usuario no está autenticado.');
        return null;
      }
    } catch (e) {
      print('Error al obtener el token: $e');
      return null;
    }
  }

  static Future<String?> _getExistingToken(String userId) async {
    try {
      DocumentSnapshot tokenDoc =
          await _firestore.collection(_tokenCollection).doc(userId).get();

      if (tokenDoc.exists) {
        return tokenDoc['token'] as String?;
      } else {
        return null;
      }
    } catch (e) {
      print('Error al obtener el token existente: $e');
      return null;
    }
  }

  static Future<void> _storeToken(String userId, String newToken) async {
    try {
      await _firestore
          .collection(_tokenCollection)
          .doc(userId)
          .set({'token': newToken});
    } catch (e) {
      print('Error al almacenar el token: $e');
    }
  }

  static void _navigateToRegisterScreen(BuildContext context,
      {bool alreadyRegistered = false}) {
    final registrationController = RegistrationController();

    if (alreadyRegistered) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              HomeScreen(), // Ir directamente a la pantalla principal
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FirstTimeLoginScreen(
            registrationController: registrationController,
          ),
        ),
      );
    }
  }

  static Future<User?> signInWithGoogle(BuildContext context) async {
    final GoogleSignIn _googleSignIn = GoogleSignIn();
    final FirebaseAuth _auth = FirebaseAuth.instance;

    try {
      final GoogleSignInAccount? googleSignInAccount =
          await _googleSignIn.signIn();
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        final UserCredential authResult =
            await _auth.signInWithCredential(credential);
        final User? user = authResult.user;

        if (user != null) {
          // Verificar si el usuario ya está registrado en la base de datos
          bool alreadyRegistered = await _checkIfUserIsRegistered(user.uid);

          String? token = await getToken();
          await storeUserData(user);
          print('Token después de la autenticación con Google: $token');

          print('Inicio de sesión con Google exitoso para ${user.displayName}');

          _navigateToRegisterScreen(context,
              alreadyRegistered: alreadyRegistered);
        }

        return user;
      }
    } catch (error) {
      print(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de autenticación con Google: $error'),
          duration: Duration(seconds: 5),
        ),
      );
    }
    return null;
  }
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
        // Manejar la autenticación exitosa y redirigir a la pantalla principal
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      print('Error durante el inicio de sesión con Apple: $e');
      // Manejar errores o mostrar un mensaje al usuario
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text("No se pudo iniciar sesión con Apple. Inténtelo de nuevo."),
            actions: [
              TextButton(
                child: Text("Aceptar"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  static Future<bool> _checkIfUserIsRegistered(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      return userDoc.exists;
    } catch (e) {
      print('Error al verificar el registro del usuario: $e');
      return false;
    }
  }

  Future<User?> login(
    BuildContext context,
    TextEditingController emailController,
    TextEditingController passwordController,
  ) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;

    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      final User? user = userCredential.user;

      if (user != null) {
        if (user.emailVerified) {
          String? token = await getToken();

          final displayName = user.displayName;
          final email = user.email;
          final phoneNumber = user.phoneNumber;
          final imagePath = user.photoURL;

          final ServiceResponse = await apiService.sendTokenAndUserDataToServer(
            token: token,
            displayName: displayName,
            email: email,
            phoneNumber: phoneNumber,
            imagePath: imagePath,
          );

          _navigateToRegisterScreen(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'El correo electrónico no ha sido verificado. Por favor, verifica tu correo electrónico.',
              ),
              duration: Duration(seconds: 5),
            ),
          );
          _signOutUser();
        }
      } else {
        _showFailedLoginDialog(context);
      }

      return user; // Return the user after the login attempt
    } catch (e) {
      print("Error al iniciar sesión: $e");
      _showFailedLoginDialog(context);
      return null;
    }
  }

  static void _signOutUser() async {
    await FirebaseAuth.instance.signOut();
  }

  static void _showFailedLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Inicio de sesión fallido"),
          content:
              const Text("Email o contraseña incorrectos. Inténtalo de nuevo."),
          actions: [
            TextButton(
              child: const Text("Aceptar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}