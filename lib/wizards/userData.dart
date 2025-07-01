import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart' hide Image;

import '../request/dataprofile.dart';
import '../Styles/stilo.dart';
import '../controller/RegisController.dart';

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
  final TextEditingController referralCodeController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
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

  Future<void> _verifyReferralCode(String referralCode) async {
    try {
      if (referralCode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Por favor, ingrese un código de referido.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final workersCollection =
          FirebaseFirestore.instance.collection('users');

      // Buscar si existe un trabajador con ese idCardNumber
      final querySnapshot = await workersCollection
          .where('codeReferral', isEqualTo: referralCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        print('Código de referido válido.');
        // Guardamos el ID del trabajador que refirió
        setState(() {
          widget.userData.referrerUserId = querySnapshot.docs.first.id;
          widget.userData.referralCode = referralCode;

          // También actualizamos los datos de registro
          widget.registrationController.updateRegistrationData(
            referralCode: referralCode,
            paymentType: '',
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Código de referido válido.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('Código de referido inválido.');
        // Limpiamos el referrerWorkerId si el código es inválido
        setState(() {
          widget.userData.referrerUserId = '';
          // Mantenemos el código ingresado por el usuario para que pueda corregirlo
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Código de referido inválido.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error al verificar el código de referido: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al verificar el código de referido.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          Text(
            "Paso 1: Rellena el formulario con tus datos",
            style: MyTextStyles.drawerButtonTextStyle8,
          ),
          Image.asset(
            'assets/animations/manito.png', // Reemplaza 'your_image.png' con la ruta de tu imagen
            width: 125,
            height: 125,
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
                        displayName: value,
                        paymentType: '',
                        referralCode: '',
                      );
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
                TextField(
                  controller: phoneController,
                  onTap: () {},
                  onChanged: (value) {
                    setState(() {
                      // Verifica si el prefijo +591 está presente, si no, lo agrega automáticamente
                      if (!value.startsWith('+591')) {
                        value = '+591$value';
                        phoneController.text =
                            value; // Actualiza el valor del controlador para reflejar el prefijo
                        phoneController.selection = TextSelection.fromPosition(
                          TextPosition(
                              offset: value
                                  .length), // Posiciona el cursor al final del texto
                        );
                      }

                      // Actualiza los datos de registro con el número modificado
                      widget.registrationController.updateRegistrationData(
                          phoneNumber: value,
                          paymentType: '',
                          referralCode: '');
                      widget.userData.phoneNumber = value;
                    });
                  },
                  keyboardType: TextInputType.phone,
                  style: MyTextStyles.inputTextStyle,
                  cursorColor: const Color(0xFF1A819A),
                  decoration: InputDecoration(
                    hintText: "Número de Teléfono",
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: referralCodeController,
                        onChanged: (value) {
                          setState(() {
                            // Actualiza los datos de registro con el código de referido
                            widget.registrationController
                                .updateRegistrationData(
                              referralCode: value,
                              paymentType: '',
                            );
                            widget.userData.referralCode = value;
                          });
                        },
                        keyboardType: TextInputType.text,
                        style: MyTextStyles.inputTextStyle,
                        cursorColor: const Color(0xFF1A819A),
                        decoration: InputDecoration(
                          hintText: "Código de Referido (opcional)",
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
                    ),
                    const SizedBox(width: 7),
                    ElevatedButton(
                      onPressed: () async {
                        await _verifyReferralCode(referralCodeController.text);
                      },
                      child: Text(
                        'Verificar',
                        style: MyTextStyles.drawerButtonLabelTextStyle,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A819A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
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
                      const SizedBox(height: 5),
                      SizedBox(
                        height: 60,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            border: Border.all(
                              color: const Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                            child: DropdownButton<String>(
                              value: widget.selectedWorkerType,
                              onChanged: (value) {
                                setState(() {
                                  widget.selectedWorkerType = value!;
                                  widget.registrationController
                                      .updateRegistrationData(
                                    paymentType: value,
                                    referralCode: '',
                                  );
                                  widget.userData.paymentType = value;
                                });
                              },
                              items: ['Marque aqui', 'SI', 'NO']
                                  .map((String value) {
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
                const SizedBox(height: 10),
                if (!isStep1Valid())
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Completa todos los campos obligatorios.',
                      style: TextStyle(color: Color(0xFF1A819A)),
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
