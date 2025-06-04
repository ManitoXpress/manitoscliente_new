import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:manitoscliente_new/controller/historialProvider.dart';
import 'package:manitoscliente_new/request/dataprofile.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../home.dart';
import '../request/ResponsePost.dart';
import '../widgets/welcome.dart';
import 'RegisController.dart';


class LoginScreenController {
  static final ApiService apiService = ApiService();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _tokenCollection = '';
  late UserData userData;

  /// Almacena datos del usuario en Firestore si no existen
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

  /// Recupera userData desde Firestore
  static Future<UserData> _fetchUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return UserData.fromJson(doc.data()!);
  }

  /// Navega al HomeScreen pasándole userData y onTabTapped
  static void _navigateToHomeScreen(
      BuildContext context,
      UserData userData,
      VoidCallback onTabTapped,
      ) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          initialPageIndex: 0,userData: userData!

        ),
      ),
    );
  }
  // Inicio de sesión anónimo

  static Future<void> signInAnonymously(BuildContext context) async {
  try {
    final authResult = await FirebaseAuth.instance.signInAnonymously();
    final user = authResult.user;
    if (user == null) return;

    // (Opcional) Si quieres mantener hospedado un UserData mínimo, créalo aquí.
    final userData = UserData(
      userId: user.uid,
      displayName: '',
      email: '',
      phoneNumber: '',
      location: {},
      paymentType: '',
      selectedCountryCode: '',
      registrationData: RegistrationData(
        userId: user.uid,
        displayName: '',
        devicesId: '',
        fcmToken: '',
        phoneNumber: '',
        paymentType: '',
        selectedCountryCode: '',
        email: '',
        location: {},
        points: 0,
      ),
      getToken: '',
      referrerUserId: '',
      referralCode: '',
      points: 0,
    );

    // Guarda en Firestore si lo necesitas
    await storeUserData(user);

    // Ahora indicamos que YA está “registrado”
    _navigateToRegisterScreen(
      context,
      alreadyRegistered: true,    // ← aquí
          // aunque no lo uses en HomeScreen
    );
  } catch (e) {
    print('Error durante el inicio de sesión anónima: $e');
    _showErrorDialog(context, 'No se pudo iniciar sesión como invitado.');
  }
}

  /// Decide si lleva a Home o a registro, inyectando userData y callback
  static Future<void> _navigateToRegisterScreen(
      BuildContext context, {
        required bool alreadyRegistered,
      }) async {
    if (alreadyRegistered) {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userData = await _fetchUserData(uid);
      VoidCallback onTabTapped = () {
        // Ejemplo: refrescar historial
        context.read<HistorialProvider>().refresh(
          userId: userData.userId,
          token: '',     // si lo guardas, recupera aquí
          deviceId: '',  // idem
        );
      };
      _navigateToHomeScreen(context, userData, onTabTapped);
    } else {
      // Nuevo usuario
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => FirstTimeLoginScreen(
            registrationController: RegistrationController(),
            userData: UserData(
              userId: '',
              displayName: '',
              email: '',
              phoneNumber: '',
              location: {},
              paymentType: '',
              selectedCountryCode: '',
              registrationData: RegistrationData(
                userId: '',
                displayName: '',
                phoneNumber: '',
                location: {},
                email: '',
                selectedCountryCode: '',
                paymentType: '',
                devicesId: '',
                fcmToken: '',
                points: 0,
              ),
              getToken: '',
              referrerUserId: '',
              referralCode: '',
              points: 0,
            ), onTabTapped: () {  },

          ),
        ),
      );
    }
  }

  /// Sign in with Apple
  static Future<void> signInWithApple(BuildContext context) async {
    try {
      final appleCred = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );
      final oAuth = OAuthProvider("apple.com").credential(
        idToken: appleCred.identityToken,
        accessToken: appleCred.authorizationCode,
      );
      final result = await FirebaseAuth.instance.signInWithCredential(oAuth);
      final user = result.user!;
      final alreadyRegistered = await _checkIfUserIsRegistered(user.uid);
      await storeUserData(user);
      await _navigateToRegisterScreen(context, alreadyRegistered: alreadyRegistered);
    } catch (e) {
      _showErrorDialog(context, 'No se pudo iniciar sesión con Apple. Inténtelo de nuevo.');
    }
  }

  /// Sign in with Google
  static Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = result.user!;
      final alreadyRegistered = await _checkIfUserIsRegistered(user.uid);
      await storeUserData(user);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await _navigateToRegisterScreen(context, alreadyRegistered: alreadyRegistered);
    } catch (e) {
      _showErrorDialog(context, 'No se pudo iniciar sesión con Google. Inténtelo de nuevo.');
    }
  }

  /// Sign in with Email & Password
  Future<User?> login(
      BuildContext context,
      String email,
      String password,
      ) async {
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user!;
      if (!user.emailVerified) {
        _showErrorDialog(context, 'Por favor, verifica tu correo electrónico.');
        await FirebaseAuth.instance.signOut();
        return null;
      }
      await storeUserData(user);
      await _navigateToRegisterScreen(context, alreadyRegistered: true);
      return user;
    } catch (e) {
      _showErrorDialog(context, 'Email o contraseña incorrectos.');
      return null;
    }
  }

  /// Verifica si el usuario ya está en Firestore
  static Future<bool> _checkIfUserIsRegistered(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists;
  }

  static void _showErrorDialog(BuildContext context, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(msg),
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