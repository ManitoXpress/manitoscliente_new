import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:manitoscliente_new/metodos/auth_utils.dart';


import '../request/ResponseGet.dart';
import '../request/ResponsePost.dart';
import '../Styles/stilo.dart';

import '../metodos/RegisController.dart';

import 'colors.dart';
class EditProfileDialog extends StatefulWidget {
  final String displayName;
  final String phoneNumber;



  final Function()? onUpdateProfile;
  EditProfileDialog({
    required this.displayName,

    required this.phoneNumber,
    this.onUpdateProfile,
  });

  @override
  _EditProfileDialogState createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController displayNameController;
  late TextEditingController idCardNumberController;
  late TextEditingController phoneNumberController;

  final customColor = CustomColor.materialColor;
  String? fcmToken;

  @override
  void initState() {
    super.initState();
    displayNameController = TextEditingController(text: widget.displayName);

    phoneNumberController = TextEditingController(text: widget.phoneNumber);
    idCardNumberController = TextEditingController();
  }

  Future<void> _updateUserProfile() async {
    try {
      final apiService = ApiService();
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String? token = await user.getIdToken();
        final updatedDisplayName = displayNameController.text;
        final updatedIdCardNumber = idCardNumberController.text;
        final updatedPhoneNumber = phoneNumberController.text;

        // Recuperar los datos actuales del usuario
        final userData = await ApiService2().fetchUserData(user.uid, token!);
        // Actualizar expertises y expLevel con los nuevos valores del widget

        // Construir un nuevo RegistrationData con los cambios y mantener los valores antiguos si los campos están vacíos
        RegistrationData registrationData = RegistrationData(
          userId: user.uid, displayName: '', phoneNumber: '', selectedCountryCode: '', email: '', location: {}, paymentType: '', devicesId: '', fcmToken: '',
        );
        String? devicesId = await AuthUtils.getDeviceId();
        final response = await apiService.updateUser(
          user.uid,
          registrationData,
          token!, devicesId, fcmToken,
        );

        if (response.statusCode == 200) {
          print('Usuario actualizado con éxito');
          Navigator.pop(context);
          widget.onUpdateProfile?.call();
        } else {
          print('Error en la respuesta del servidor: ${response.statusCode}');
        }
      } else {
        print(
            'Advertencia: usuario es nulo. Asegúrate de que el usuario esté autenticado correctamente.'
        );
      }
    } catch (error) {
      print('Error durante el proceso de registro: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editar Perfil'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: displayNameController,
            decoration: InputDecoration(
              labelText: 'Nombre',
              labelStyle: MyTextStyles.formServiceTextStyle,
            ),
            style: MyTextStyles.formServiceTextStyle,
          ),
          TextFormField(
            controller: idCardNumberController,
            decoration: InputDecoration(
              labelText: 'Número de Carné',
              labelStyle: MyTextStyles.formServiceTextStyle,
            ),
            style: MyTextStyles.formServiceTextStyle,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(
            foregroundColor: customColor,
          ),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            _updateUserProfile(); // Llamar a la función de actualización de perfil
            widget.onUpdateProfile?.call();
            Navigator.pop(context); // Cerrar la ventana de diálogo
          },
          child: Text("Guardar Cambios"),
        ),
      ],
    );
  }
}