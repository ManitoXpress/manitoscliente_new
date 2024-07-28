
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';

import '../ServicesResponse/dataprofile.dart';
import '../Styles/stilo.dart';
import '../metodos/RegisController.dart';

class userDataWizard extends StatefulWidget {
  final RegistrationController registrationController;
  final void Function() onNextStep;
  final RegistrationData registrationData;
  final UserData userData;
  bool isStep1Complete = false;
  String selectedWorkerType = 'Marque aqui';
  late String selectedCountryCode;

  late _Step1FormState _step1FormState;

  bool isStep1Valid() {
    return _step1FormState.isStep1Valid();
  }

  userDataWizard({
    required this.registrationController,
    required this.onNextStep,
    required this.registrationData,
    required this.userData,
  });

  @override
  _Step1FormState createState() {
    _step1FormState = _Step1FormState();
    return _step1FormState;
  }
}

class _Step1FormState extends State<userDataWizard> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController idCardController = TextEditingController();
  late String animationURL;
  Artboard? _teddyArtboard;
  SMITrigger? successTrigger, failTrigger;
  SMIBool? isHandsUp, isChecking;
  SMINumber? numLook;
  StateMachineController? stateMachineController;

  String? verificationId;
  String errorText = '';

  @override
  void initState() {
    super.initState();

  }

  bool isStep1Valid() {
    return fullNameController.text.isNotEmpty;

  }


  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          Text(
            "Paso 1: Rellena el formulario con tus datos",
            style: MyTextStyles.drawerButtonTextStyle2,
          ),
          Image.asset(
            'assets/animations/manito.png', // Reemplaza 'your_image.png' con la ruta de tu imagen
            width: 250, // Ajusta el ancho de la imagen según sea necesario
          ),
          Container(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: fullNameController,
                  onTap: () {
                    if (isStep1Valid()) {
                      widget.onNextStep();
                    } else {
                      print(
                          'Complete all required fields before moving to the next step.');
                    }
                  },
                  onChanged: (value) {
                    setState(() {

                      widget.registrationController.updateRegistrationData(
                          displayName: value, paymentType: '', );
                      widget.userData.displayName = value;
                    });
                  },
                  keyboardType: TextInputType.text,
                  style: MyTextStyles.inputTextStyle,
                  cursorColor: const Color(0xFF1A819A),
                  decoration: InputDecoration(
                    hintText: "Nombre completo",
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    focusColor: Color(0xFF1A819A),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFF1A819A),
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Realizará pagos con QR?',
                        style: MyTextStyles.inputTextStyle.copyWith(
                          color: const Color(0xFF1A819A),
                        ),
                      ),
                      SizedBox(
                        height: 60,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            border: Border.all(color: const Color(0xFF1A819A),),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0),
                            child: DropdownButton<String>(
                              value: widget.selectedWorkerType,
                              onChanged: (value) {
                                setState(() {
                                  widget.selectedWorkerType = value!;
                                  widget.registrationController.updateRegistrationData(
                                    paymentType: value,);
                                  widget.userData.paymentType = value;
                                });
                              },
                              items: ['Marque aqui', 'SI', 'NO'].map((
                                  String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              style: MyTextStyles.inputTextStyle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isStep1Valid())
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Completa todos los campos obligatorios.',
                      style: TextStyle(color: Color(0xFF830A09)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
