import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../request/dataprofile.dart';

/// Proveedor (Provider) para gestionar la información de usuario (`UserData`).
///
/// Este ChangeNotifier se encarga de:
/// 1. Almacenar el estado actual de `UserData`.
/// 2. Proveer métodos para cargar la información desde Firestore (o actualizarla).
/// 3. Notificar a los listeners cuando `UserData` cambie.
class UserDataProvider extends ChangeNotifier {
  /// Instancia interna de `UserData`.
  /// Inicialmente, vacío hasta que se llame a `loadCurrentUserData()`.
  UserData _userData = UserData.empty();

  /// Indica si estamos en proceso de carga (ej. llamada a Firestore).
  bool _isLoading = false;

  /// Accesor para el estado de carga.
  bool get isLoading => _isLoading;

  /// Accesor público a la instancia de `UserData`.
  /// Si no se ha cargado aún, devolverá un objeto vacío (`UserData.empty()`).
  UserData get userData => _userData;

  /// Carga la información de usuario desde Firestore basándose en el usuario autenticado de FirebaseAuth.
  ///
  /// 1. Verifica si existe un usuario logueado en `FirebaseAuth.instance.currentUser`.
  /// 2. Si existe, obtiene el documento correspondiente de la colección `users` (collection "users", document = uid).
  /// 3. Convierte el `Map<String, dynamic>` a `UserData` usando `UserData.fromJson(...)`.
  /// 4. Asigna el resultado a `_userData` y notifica a los listeners.
  ///
  /// En caso de error (por ejemplo, el documento no existe o no hay usuario autenticado), se deja `_userData` intacto y se imprime el error.
  Future<void> loadCurrentUserData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        // Si no hay usuario autenticado, dejamos userData vacío
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
        // Si no existe el documento en Firestore, dejamos userData vacío
        _userData = UserData.empty();
      } else {
        final dataMap = docSnapshot.data()!;
        _userData = UserData.fromJson(dataMap);
      }
    } catch (e) {
      // Si ocurre cualquier excepción, imprimimos en consola y no modificamos el userData actual
      null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualiza manualmente el objeto `UserData` y notifica a los listeners.
  ///
  /// Útil si se modifica esta información localmente (por ejemplo, después de editar perfil).
  void setUserData(UserData newData) {
    _userData = newData;
    notifyListeners();
  }

  /// Guarda (sube) el contenido de `UserData` actual a Firestore.
  ///
  /// Este método sobrescribe el documento en `users/{uid}` con los valores contenidos en `_userData`.
  /// Retorna `true` si la operación fue exitosa, y `false` en caso contrario.
  Future<bool> saveUserDataToFirestore() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('No hay usuario autenticado para guardar datos.');
      }
      final uid = firebaseUser.uid;

      // Convertir a JSON
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
        // Agregar otros campos necesarios según tu modelo
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(jsonMap, SetOptions(merge: true));

      return true;
    } catch (e) {
      null;
      return false;
    }
  }
}
