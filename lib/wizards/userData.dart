import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // Ahora siempre retorna true
  bool isStep1Valid() {
    return true;
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
  late TextEditingController fullNameController;
  final TextEditingController idCardController = TextEditingController();
  final TextEditingController referralCodeController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  
  // Variables para la animación (se mantienen igual)
  late String animationURL;
  Artboard? _teddyArtboard;
  SMITrigger? successTrigger, failTrigger;
  SMIBool? isHandsUp, isChecking;
  SMINumber? numLook;
  StateMachineController? stateMachineController;

  String? verificationId;
  String errorText = '';
  late bool _isNameEditable;

  @override
void initState() {
  super.initState();

  final user = FirebaseAuth.instance.currentUser;
  final providers = user?.providerData.map((p) => p.providerId).toList() ?? [];

  if (providers.contains('google.com')) {
    // Si vino por Google: mostramos su nombre y NO es editable
    fullNameController = TextEditingController(text: user?.displayName ?? '');
    _isNameEditable = false;
  } else if (providers.contains('apple.com')) {
    // Si vino por Apple/iCloud: ponemos “Private” y NO editable
    fullNameController = TextEditingController(text: 'Private');
    _isNameEditable = false;
  } else {
    // Si es otro flujo (registro manual, etc): sí permitimos editar
    fullNameController = TextEditingController(text: widget.userData.displayName);
    _isNameEditable = true;
  }
}

  // Ahora siempre retorna true
  bool isStep1Valid() {
    return true;
  }

  Future<void> _verifyReferralCode(String referralCode) async {
    try {
      if (referralCode.isEmpty) {
        // No hacemos nada si está vacío
        return;
      }

      final workersCollection =
          FirebaseFirestore.instance.collection('users');

      // Buscar si existe un trabajador con ese codeReferral
      final querySnapshot = await workersCollection
          .where('codeReferral', isEqualTo: referralCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        print('Código de referido válido.');
        setState(() {
          widget.userData.referrerUserId = querySnapshot.docs.first.id;
          widget.userData.referralCode = referralCode;
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
        setState(() {
          widget.userData.referrerUserId = '';
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
            'assets/animations/manito.png',
            width: 125,
            height: 125,
          ),
          Container(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Nombre completo editable
                TextField(
                  controller: fullNameController,
                  enabled: _isNameEditable,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person, color: Color(0xFF1A819A)),
                    hintText: 'Nombre completo',
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF1A819A)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: _isNameEditable
                      ? (value) {
                          widget.userData.displayName = value;
                          widget.registrationController.updateRegistrationData(
                            displayName: value,
                            paymentType: widget.userData.paymentType,
                            referralCode: widget.userData.referralCode,
                          );
                        }
                      : null,
                ),


                const SizedBox(height: 20),

                // Número de teléfono
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: MyTextStyles.inputTextStyle,
                  cursorColor: const Color(0xFF1A819A),
                  decoration: InputDecoration(
                    hintText: "Número de Teléfono",
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF1A819A)),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                  onChanged: (value) {
                    if (!value.startsWith('+591')) {
                      value = '+591$value';
                      phoneController.text = value;
                      phoneController.selection = TextSelection.fromPosition(
                        TextPosition(offset: value.length),
                      );
                    }
                    widget.registrationController.updateRegistrationData(
                      phoneNumber: value,
                      paymentType: '',
                      referralCode: '',
                    );
                    widget.userData.phoneNumber = value;
                  },
                ),

                const SizedBox(height: 20),

                // Código de referido (opcional)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: referralCodeController,
                        keyboardType: TextInputType.text,
                        style: MyTextStyles.inputTextStyle,
                        cursorColor: const Color(0xFF1A819A),
                        decoration: InputDecoration(
                          hintText: "Código de Referido (opcional)",
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF1A819A)),
                            borderRadius:
                                BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                        onChanged: (value) {
                          widget.registrationController
                              .updateRegistrationData(
                                referralCode: value,
                                paymentType: '',
                              );
                          widget.userData.referralCode = value;
                        },
                      ),
                    ),
                    const SizedBox(width: 7),
                    ElevatedButton(
                      onPressed: referralCodeController.text.isNotEmpty
                          ? () => _verifyReferralCode(
                              referralCodeController.text)
                          : null,
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

                // Selección para pagos con QR
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Realizará pagos con QR?',
                      style: MyTextStyles.inputTextStyle.copyWith(
                        color: const Color(0xFF1A819A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
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
                            .map((String value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                ))
                            .toList(),
                        style: MyTextStyles.inputTextStyle,
                        underline: SizedBox(),
                        isExpanded: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                // Aviso eliminado: no hay validación visible
              ],
            ),
          ),
        ],
      ),
    );
  }
}
