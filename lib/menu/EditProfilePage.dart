
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';


class ProfileData {
  final String name;
  final String email;
  final String phoneNumber;

  ProfileData({
    required this.name,
    required this.email,
    required this.phoneNumber,
  });
}

class EditProfilePage extends StatefulWidget {
  final ProfileData currentProfile;

  EditProfilePage({required this.currentProfile});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _phoneNumberController = TextEditingController();

  Future<void> updateUserProfile({
    required String userId,
    required String newName,
    required String newPhoneNumber,
    required String imageUrl,
  }) async {
    final Uri apiUrl = Uri.parse('https://us-central1-manito-399201.cloudfunctions.net/api/users/$userId'); // Reemplaza con la URL de tu API
    final Map<String, String> headers = {'Content-Type': 'application/json'};

    final Map<String, dynamic> data = {
      'displayName': newName,
      'phoneNumber': newPhoneNumber,
      'imagePath': imageUrl,
    };

    final String jsonData = jsonEncode(data);

    try {
      final http.Response response = await http.patch(
        apiUrl,
        headers: headers,
        body: jsonData,
      );

      if (response.statusCode == 200) {
        print('Perfil actualizado con éxito');
        // Maneja la respuesta del backend según sea necesario
      } else {
        print('Error en la solicitud PATCH: ${response.statusCode}');
        print('Mensaje de error: ${response.body}');
        throw Exception('Error al actualizar el perfil');
      }
    } catch (e) {
      print('Error en la solicitud PATCH: $e');
      throw Exception('Error al actualizar el perfil');
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentProfile.name;
    _phoneNumberController.text = widget.currentProfile.phoneNumber;
  }

  void _saveChanges() async {
    final newName = _nameController.text;
    final newPhoneNumber = _phoneNumberController.text;

    try {
      await updateUserProfile(
        userId: 'user_id_here', // Reemplaza con el ID real del usuario
        newName: newName,
        newPhoneNumber: newPhoneNumber,
        imageUrl: 'image_url_here', // Reemplaza con la URL de la imagen
      );

      final updatedProfile = ProfileData(
        name: newName,
        email: widget.currentProfile.email,
        phoneNumber: newPhoneNumber,
      );

      Navigator.of(context).pop(updatedProfile);
    } catch (e) {
      // Maneja errores aquí, como mostrar un mensaje de error al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar cambios')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Perfil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Nombre'),
            ),
            TextFormField(
              controller: _phoneNumberController,
              decoration: InputDecoration(labelText: 'Número de Teléfono'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveChanges,
              child: Text('Guardar Cambios'),
            ),
          ],
        ),
      ),
    );
  }
}
