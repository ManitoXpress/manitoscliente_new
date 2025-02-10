import 'dart:io';
import 'package:flutter/widgets.dart';

import 'package:manitoscliente_new/request/resquest.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CartScreen extends StatelessWidget {
  final List<ServiceRequest> serviceRequests;
  final FormData formData;

  CartScreen({
    required this.serviceRequests,
    required this.formData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Solicitudes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 3,
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solicitudes',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  'Tipo de servicio: ${formData.serviceType}',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'Detalles de servicio: ${formData.additionalDetails}',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'Imagen seleccionada: ${formData.selectedImage}',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'Precio: ${formData.price}',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'Aceptar términos y condiciones: ${formData.acceptTerms}',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FormData {
  final String serviceType;
  final String additionalDetails;
  final File? selectedImage;
  final String? price;
  final bool acceptTerms;

  FormData({
    required this.serviceType,
    required this.additionalDetails,
    required this.selectedImage,
    required this.price,
    required this.acceptTerms,
  });
}
