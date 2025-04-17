import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../request/ResponseGet.dart';
import '../Styles/stilo.dart';
import '../controller/RegisController.dart';
import '../utils/validation.dart';

class FirstTimeLoginScreen extends StatelessWidget {
  final RegistrationController registrationController;

  FirstTimeLoginScreen({required this.registrationController});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween, // Distribuir elementos
          children: [
            // Texto en la parte izquierda
            Text(
              'ManitoXpress',
              style: MyTextStyles.buttonTextStyle,
            ),
            // Logo en la parte derecha
            Flexible(
              child: Container(
                padding: EdgeInsets.all(10.w),
                constraints: BoxConstraints(maxWidth: 0.22.sw),
                child: Image.asset(
                  'assets/images/LOGO1_Blanco.png',
                  width: 0.22.sw,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Imagen
            Image.asset(
              'assets/animations/manito.png', // Reemplaza 'your_image.png' con la ruta de tu imagen
              width: 300, // Ajusta el ancho de la imagen según sea necesario
            ),
            SizedBox(height: 20), // Espacio entre la imagen y el texto
            Text(
              '¡Bienvenido!',
              style: MyTextStyles.welcomeTotheJungle2,
            ),
            SizedBox(height: 20), // Espacio entre los textos
            Text(
              'Presiona "Comenzar registro" para crear la cuenta',
              style: MyTextStyles.drawerButtonTextStyle2,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20), // Espacio entre el texto y el botón
            ElevatedButton(
              onPressed: () {
                // Iniciar el proceso de registro
                print(
                    "Comenzar registro presionado"); // Agrega esta línea para depurar
                registrationController.nextStep();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegistrationScreen(
                      registrationController: registrationController,
                      completeRegistrationCallback: () {},
                      apiService2: ApiService2(),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                    horizontal: 40, vertical: 16), // Ajusta el tamaño del botón
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(30.0), // Bordes redondeados
                ),
                backgroundColor: Color(0xFF1A819A), // Color personalizado
              ),
              child: Text(
                'Comenzar registro',
                style: MyTextStyles.buttonTextStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
