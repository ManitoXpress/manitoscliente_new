import 'package:flutter/material.dart';
import 'package:manitoscliente_new/request/ResponsePost.dart';
import 'package:manitoscliente_new/menu/validators.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatelessWidget {
  final ApiService apiService = ApiService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _register(BuildContext context) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      User? user = userCredential.user;

      if (user != null) {
        print('User registered with UID: ${user.uid}');
        // Enviar un correo de verificación
        await user.sendEmailVerification();

        String? token = await user.getIdToken();
        print("User's ID Token: $token");

        final response = await apiService.sendTokenToServer(token);

        if (response.statusCode != 200) {
          print('Error en el servidor: ${response.body}');
        }

        await user.updateDisplayName(_usernameController.text);
        await user.reload();
        user = FirebaseAuth.instance.currentUser;

        CollectionReference users =
            FirebaseFirestore.instance.collection('users');
        await users.doc(user!.uid).set({
          'displayName': _usernameController.text,
          'email': _emailController.text,
          'phoneNumber': _phoneController.text,
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Registrado exitosamente')));

        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Ocurrió un error')));
    }
  }

  Future<void> getUserInfo(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        print('User data: $userData');
      } else {
        print('Usuario no existe!');
      }
    } catch (e) {
      print('Error getting user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffd6e2ea),
      appBar: AppBar(
        title: Text('Registrarse'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: Color(0xFF68B8D5),
            width: double.infinity,
            height: double.infinity,
          ),
          SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height / 6),
                  Text(
                    "CREA TU CUENTA",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(height: MediaQuery.of(context).size.height / 16),
                  Container(
                    alignment: Alignment.center,
                    width: 400,
                    padding: const EdgeInsets.only(bottom: 15),
                    margin: const EdgeInsets.only(bottom: 15 * 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        children: [
                          const SizedBox(height: 15),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(fontSize: 14),
                            cursorColor: const Color(0xffb04863),
                            decoration: const InputDecoration(
                              hintText: "Correo electrónico",
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                              ),
                              focusColor: Color(0xffb04863),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xffb04863),
                                ),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _passwordController,
                            keyboardType: TextInputType.text,
                            obscureText: true,
                            style: const TextStyle(fontSize: 14),
                            cursorColor: const Color(0xffb04863),
                            decoration: const InputDecoration(
                              hintText: "Contraseña",
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                              ),
                              focusColor: Color(0xffb04863),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xffb04863),
                                ),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(fontSize: 14),
                            cursorColor: const Color(0xffb04863),
                            decoration: const InputDecoration(
                              hintText: "Número de teléfono",
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                              ),
                              focusColor: Color(0xffb04863),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xffb04863),
                                ),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _usernameController,
                            style: const TextStyle(fontSize: 14),
                            cursorColor: const Color(0xffb04863),
                            decoration: const InputDecoration(
                              hintText: "Nombre de usuario",
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                              ),
                              focusColor: Color(0xffb04863),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xffb04863),
                                ),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          ElevatedButton(
                            onPressed: () async {
                              if (!_emailController.text.isValidEmail()) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Correo electrónico no válido')));
                                return;
                              }

                              if (_passwordController.text.length < 6) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(
                                        'La contraseña debe tener al menos 6 caracteres')));
                                return;
                              }

                              if (_phoneController.text.isNotEmpty &&
                                  !_phoneController.text.isValidPhoneNumber()) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Número de teléfono no válido')));
                                return;
                              }

                              await _register(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A819A),
                            ),
                            child: const Text("Registrarme"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
