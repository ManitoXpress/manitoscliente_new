import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../request/dataprofile.dart';
import '../Styles/stilo.dart';
import '../controller/RegisController.dart';

class userDataWizard extends StatefulWidget {
  final RegistrationController registrationController;
  final void Function() onNextStep;
  final RegistrationData registrationData;
  final UserData userData;
  bool isStep1Complete = false;
  String selectedWorkerType = 'Selecciona una opción';
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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String? verificationId;

  @override
  void initState() {
    super.initState();
    // Default fallback if empty
    if(widget.userData.paymentType.isEmpty || widget.userData.paymentType == 'Marque aqui') {
       widget.selectedWorkerType = 'Selecciona una opción';
    } else {
       widget.selectedWorkerType = widget.userData.paymentType;
    }
  }

  bool isStep1Valid() {
    if (_formKey.currentState != null) {
      return _formKey.currentState!.validate();
    }
    return false;
  }

  InputDecoration _buildInputDecoration({required String hintText, required IconData icon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.inter(color: const Color(0xFFADB5BD), fontSize: 16),
      filled: true,
      fillColor: const Color(0xFFFFFFFF),
      prefixIcon: Icon(icon, color: const Color(0xFFADB5BD)),
      contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.transparent),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF115E70), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.0),
        borderRadius: BorderRadius.circular(12),
      ),
      errorStyle: GoogleFonts.inter(color: Colors.red.shade500, fontSize: 12),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Text(
              "Paso 1: Rellena el formulario con tus datos",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF495057),
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 30),
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF115E70).withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 64,
                  color: Color(0xFF115E70),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                controller: fullNameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre completo es obligatorio';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    widget.registrationController.updateRegistrationData(
                      displayName: value,
                      paymentType: widget.selectedWorkerType == 'Selecciona una opción' ? '' : widget.selectedWorkerType,
                      referralCode: '',
                    );
                    widget.userData.displayName = value;
                  });
                },
                keyboardType: TextInputType.text,
                style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF212529)),
                cursorColor: const Color(0xFF115E70),
                decoration: _buildInputDecoration(hintText: "Nombre completo", icon: Icons.person_outline),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                controller: phoneController,
                validator: (value) {
                  if (value == null || value.trim().length <= 4) {
                    return 'Ingrese un número de teléfono válido';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    if (!value.startsWith('+591')) {
                      value = '+591$value';
                      phoneController.text = value;
                      phoneController.selection = TextSelection.fromPosition(
                        TextPosition(offset: value.length),
                      );
                    }
                    widget.registrationController.updateRegistrationData(
                      phoneNumber: value,
                      paymentType: widget.selectedWorkerType == 'Selecciona una opción' ? '' : widget.selectedWorkerType,
                      referralCode: '',
                    );
                    widget.userData.phoneNumber = value;
                  });
                },
                keyboardType: TextInputType.phone,
                style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF212529)),
                cursorColor: const Color(0xFF115E70),
                decoration: _buildInputDecoration(hintText: "Número de Teléfono", icon: Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿Realizará pagos con QR?',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF115E70),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: DropdownButtonFormField<String>(
                      validator: (value) {
                         if (value == null || value == 'Selecciona una opción') {
                           return 'Debe seleccionar una opción';
                         }
                         return null;
                      },
                      dropdownColor: Colors.white,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFADB5BD)),
                      decoration: InputDecoration(
                         border: InputBorder.none,
                         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                         errorStyle: GoogleFonts.inter(color: Colors.red.shade500, fontSize: 12),
                      ),
                      value: widget.selectedWorkerType,
                      onChanged: (value) {
                        setState(() {
                          widget.selectedWorkerType = value!;
                          widget.registrationController.updateRegistrationData(
                            paymentType: value == 'Selecciona una opción' ? '' : value,
                            referralCode: '',
                          );
                          widget.userData.paymentType = value == 'Selecciona una opción' ? '' : value;
                        });
                      },
                      items: ['Selecciona una opción', 'SI', 'NO'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: value == 'Selecciona una opción' ? const Color(0xFFADB5BD) : const Color(0xFF212529),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
