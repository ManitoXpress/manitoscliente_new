import 'package:flutter/material.dart';

class DetallesServicioPage extends StatelessWidget {
  final String serviceName;
  final String description;
  final String status;
  final String serviceType;

  DetallesServicioPage({
    required this.serviceName,
    required this.description,
    required this.status,
    required this.serviceType, required Map<String, dynamic> serviceDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del Servicio'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tipo de Servicio: $serviceName',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Descripción: $description',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'Estado del Servicio: $status',
              style: TextStyle(
                fontSize: 16,
                color: status == 'open' ? Colors.green : Colors.orange,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Aquí puedes abrir el formulario detallado
                // Puedes usar la información del servicio, como serviceType, para personalizar el formulario
                // Por ejemplo:
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => TuFormulario(serviceType: serviceType),
                //   ),
                // );
              },
              child: Text('Abrir Formulario'),
            ),
          ],
        ),
      ),
    );
  }
}
