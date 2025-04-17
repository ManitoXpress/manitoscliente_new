import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../request/ResponseGet.dart';
import '../request/dataprofile.dart';
import '../Styles/stilo.dart';

import '../controller/RegisController.dart';
import '../utils/colors.dart';
import '../utils/editController.dart';
import '../utils/favoriteUbi.dart';
import 'Login.dart';

class ProfileData {
  late final String displayName;
  final String email;
  late final String phoneNumber;
  final String paymentType;
  final RegistrationData registrationData;
  final UserData userData;
  final String imagePath;
  int points;

  ProfileData({
    required this.displayName,
    required this.email,
    required this.phoneNumber,
    required this.paymentType,
    required this.registrationData,
    required this.userData,
    required this.imagePath,
    required this.points,
  });
}

class ProfilePage extends StatefulWidget {
  final RegistrationData registrationData;
  String displayName;
  String email;
  String phoneNumber;
  String paymentType;
  final UserData userData;
  String imagePath;

  ProfilePage({
    Key? key,
    required this.registrationData,
    required this.displayName,
    required this.email,
    required this.phoneNumber,
    required this.paymentType,
    required this.userData,
    required this.imagePath,
  }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final customColor = CustomColor.materialColor;
  late Future<ProfileData> userData;
  final userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    userData = _loadUserData(widget.registrationData);
  }

  Future<ProfileData> _loadUserData(RegistrationData registrationData) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final userPhoneNumber = currentUser?.phoneNumber ?? '';

      final userId = FirebaseAuth.instance.currentUser?.uid;
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();

      if (userId != null && token != null) {
        final userData = await ApiService2().fetchUserData(userId, token);
        String? profileImageUrl = await ApiService2().fetchProfileImage(userId);
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        final points = userDoc.data()?['points'] ?? 0;

        return ProfileData(
          displayName: userData.displayName,
          email: userData.email,
          phoneNumber: FirebaseAuth.instance.currentUser?.phoneNumber ?? '',
          paymentType: userData.paymentType,
          imagePath: profileImageUrl ?? '',
          userData: UserData(
            userId: userData.userId,
            displayName: userData.displayName,
            email: userData.email,
            phoneNumber: userData.phoneNumber,
            selectedCountryCode: userData.selectedCountryCode,
            location: userData.location,
            paymentType: userData.paymentType,
            registrationData: registrationData,
            getToken: '',
            referrerUserId: userData.referrerUserId,
            referralCode: userData.referralCode,
            points: userData.points,
          ),
          registrationData: registrationData,
          points: points,
        );
      } else {
        throw 'No se pudo obtener el ID del usuario autenticado.';
      }
    } catch (e) {
      print('Error loading user data: $e');
      return ProfileData(
        displayName: 'Error',
        email: '',
        phoneNumber: FirebaseAuth.instance.currentUser?.phoneNumber ?? '',
        paymentType: '',
        imagePath: '',
        userData: UserData(
          userId: '',
          displayName: 'Error',
          email: '',
          phoneNumber: '',
          location: {},
          paymentType: '',
          registrationData: registrationData,
          selectedCountryCode: '',
          getToken: '',
          referrerUserId: '',
          referralCode: '',
          points: 0,
        ),
        registrationData: registrationData,
        points: 0,
      );
    }
  }

  Future<void> _loadAndRefreshUserData() async {
    try {
      final updatedUserData = await _loadUserData(widget.registrationData);
      setState(() {
        userData = Future.value(updatedUserData);
      });
    } catch (e) {
      print('Error durante la carga de datos de usuario: $e');
    }
  }

  void _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => LoginScreen(
                deviceId: '',
                onLoginSuccess: () {
                  // Add your logic here for successful login
                  _loadAndRefreshUserData();
                },
              )));
    } catch (e) {
      print('Error al cerrar sesión: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          'Perfil',
          style: MyTextStyles.buttonTextStyle,
        ),
      ),
      body: FutureBuilder<ProfileData>(
        future: userData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            final profileData = snapshot.data;
            return SingleChildScrollView(
              child: _buildProfileInfo(profileData),
            );
          }
        },
      ),
    );
  }

  Widget _buildProfileInfo(ProfileData? profileData) {
    if (profileData == null) {
      return Text('Error: No se pudo cargar la información del perfil');
    }
    print('Display Name: ${profileData.displayName}');

    return Container(
      margin: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/animations/manito.png', // Reemplaza 'your_image.png' con la ruta de tu imagen
            width: 250, // Ajusta el ancho de la imagen según sea necesario
          ),
          const SizedBox(height: 10),
          Text(
            'Puntos: ${profileData.points}', // Muestra los puntos del usuario
            style: MyTextStyles.inputTextStyle1,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _signOut,
                child: const Text(
                  'Cerrar Sesión',
                  style: MyTextStyles.buttonTextStyle,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: customColor,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Navegar a la pantalla de ubicaciones favoritas
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            FavoriteLocationsScreen()), // Asegúrate de usar el nombre correcto de la pantalla
                  );
                },
                child: Text(
                  'Ubicaciones',
                  style: MyTextStyles.buttonTextStyle,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: customColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
            ),
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                _buildProfileInfoRow('Nombre:', profileData.displayName),

                const SizedBox(height: 10),
                _buildProfileInfoRow('Correo electronico:', profileData.email),
                const SizedBox(height: 10),
                // Boton de documentos debajo del cuadro
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: MyTextStyles.inputTextStyle3,
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight, // Align to the right
                  child: Text(
                    value,
                    overflow:
                        TextOverflow.ellipsis, // Adds "..." when text overflows
                    maxLines: 1, // Restricts to one line
                    style: MyTextStyles.formsdetails1,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 8.0),
          child: Divider(
            color: Color(0xFF1A819A),
            height: 2,
          ),
        ),
      ],
    );
  }
}
