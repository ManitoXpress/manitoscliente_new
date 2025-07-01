import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../request/ResponseGet.dart';
import '../Styles/stilo.dart';
import '../controller/RegisController.dart';
import '../request/dataprofile.dart';
import '../utils/validation.dart';
class FirstTimeLoginScreen extends StatelessWidget {
  final RegistrationController registrationController;
  final UserData userData;
  final VoidCallback onTabTapped;

  const FirstTimeLoginScreen({
    Key? key,
    required this.registrationController,
    required this.userData,
    required this.onTabTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ManitoXpress', style: MyTextStyles.buttonTextStyle),
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
            Image.asset(
              'assets/animations/manito.png',
              width: 300,
            ),
            SizedBox(height: 20),
            Text('¡Bienvenido!', style: MyTextStyles.welcomeTotheJungle2),
            SizedBox(height: 20),
            Text(
              'Presiona "Comenzar registro" para crear la cuenta',
              style: MyTextStyles.drawerButtonTextStyle2,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                registrationController.nextStep();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegistrationScreen(
                      registrationController: registrationController,
                      completeRegistrationCallback: onTabTapped,
                      apiService2: ApiService2(),

                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0)),
                backgroundColor: Color(0xFF1A819A),
              ),
              child: Text('Comenzar registro', style: MyTextStyles.buttonTextStyle),
            ),
          ],
        ),
      ),
    );
  }
}