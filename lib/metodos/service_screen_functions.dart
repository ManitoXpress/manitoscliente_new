import 'package:flutter/material.dart';

import 'package:manitoscliente_new/categorias/Home_services.dart';
import 'package:manitoscliente_new/categorias/Professional_services.dart';
import 'package:manitoscliente_new/ServicesResponse/resquest.dart';

void navigateToServiceDetails(BuildContext context, int index) {
  // Lógica para navegar a los detalles del servicio seleccionado
}

void navigateToHomeServices(
    BuildContext context, ServiceRequest serviceRequest) {
  Navigator.push(
    context,
    MaterialPageRoute(
        builder: (context) =>
            HomeServicesScreen(serviceRequest: serviceRequest)),
  );
}

void navigateToProfessionalServices(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => ProfessionalServicesScreen()),
  );
}

void navigateToBusinessServices(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Muy Pronto!'),
        content: const Text(
            'Los servicios empresariales estarán disponibles próximamente.'),
        actions: [
          TextButton(
            child: const Text('Aceptar'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
