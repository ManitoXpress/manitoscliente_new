import 'package:flutter/material.dart';

class TermsAndConditionsWizard extends StatefulWidget {
  final bool isChecked;
  final Function(bool) onAcceptTerms;
  final Function onNextStep; // Agrega esta línea

  const TermsAndConditionsWizard({
    Key? key,
    required this.isChecked,
    required this.onAcceptTerms,
    required this.onNextStep, // Agrega esta línea
  }) : super(key: key);

  @override
  _TermsAndConditionsWizardState createState() => _TermsAndConditionsWizardState();
}

class _TermsAndConditionsWizardState extends State<TermsAndConditionsWizard> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Interfaz de usuario para mostrar los términos y condiciones
        // Incluye una casilla de verificación y un botón "Aceptar"
        // Utiliza widget.isChecked y widget.onAcceptTerms para manejar la casilla de verificación
      ],
    );
  }
}
