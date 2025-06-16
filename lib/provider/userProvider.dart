import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:manitoscliente_new/request/dataprofile.dart';

/// Proveedor (Provider) para gestionar la información de usuario (UserData).
///
/// Este ChangeNotifier se encarga de:
/// 1. Almacenar el estado actual de UserData.
/// 2. Proveer métodos para cargar la información desde Firestore (o actualizarla).
/// 3. Notificar a los listeners cuando UserData cambie.
class UserDataProvider extends ChangeNotifier {
  UserData _userData = UserData.empty();
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  UserData get userData => _userData;

  Future<void> loadCurrentUserData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        _userData = UserData.empty();
        _isLoading = false;
        notifyListeners();
        return;
      }

      final uid = firebaseUser.uid;
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!docSnapshot.exists) {
        _userData = UserData.empty();
      } else {
        final dataMap = docSnapshot.data()!;
        _userData = UserData.fromJson(dataMap);
      }
    } catch (e) {
      debugPrint('Error cargando UserData desde Firestore: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setUserData(UserData newData) {
    _userData = newData;
    notifyListeners();
  }

  Future<bool> saveUserDataToFirestore() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('No hay usuario autenticado para guardar datos.');
      }

      final Map<String, dynamic> jsonMap = {
        'id': _userData.userId,
        'displayName': _userData.displayName,
        'email': _userData.email,
        'phoneNumber': _userData.phoneNumber,
        'selectedCountryCode': _userData.selectedCountryCode,
        'location': _userData.location ?? {},
        'paymentType': _userData.paymentType,
        'getToken': _userData.getToken ?? '',
        'referrerUserId': _userData.referrerUserId,
        'referralCode': _userData.referralCode,
        'points': _userData.points,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .set(jsonMap, SetOptions(merge: true));

      return true;
    } catch (e) {
      debugPrint('Error guardando UserData en Firestore: $e');
      return false;
    }
  }

  /// 🔴 Método para limpiar completamente los datos de usuario
  void clearUser() {
    _userData = UserData.empty();
    _isLoading = false;
    notifyListeners();
  }
}
