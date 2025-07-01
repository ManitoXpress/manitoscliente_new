// service_data_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';

import '../request/requestServiceType.dart';
import '../request/resquest.dart';

class ServiceDataProvider extends ChangeNotifier {
  String description = '';
  double? offeredPrice;
  List<File?> images = List.generate(3, (index) => null);
  ServiceType? serviceType;
  String selectedServiceTitle = '';

  // Método para actualizar la descripción
  void updateDescription(String newDescription) {
    description = newDescription;
    notifyListeners();
  }

  // Método para actualizar el precio
  void updatePrice(String price) {
    if (price.isNotEmpty) {
      offeredPrice = double.tryParse(price);
    } else {
      offeredPrice = null;
    }
    notifyListeners();
  }

  // Método para actualizar el tipo de servicio
  void updateServiceType(ServiceType type) {
    serviceType = type;
    notifyListeners();
  }

  // Método para actualizar o agregar una imagen en una posición específica
  void updateImage(int index, File? file) {
    if (index >= 0 && index < images.length) {
      images[index] = file;
      notifyListeners();
    }
  }

  // Método para eliminar una imagen
  void removeImage(int index) {
    if (index >= 0 && index < images.length) {
      images[index] = null;
      notifyListeners();
    }
  }

  // Obtener las rutas de las imágenes como strings
  List<String> getImagePaths() {
    return images.map((image) => image?.path ?? "").toList();
  }

  // Actualizar el ServiceRequest con los datos actuales
  void updateServiceRequest(ServiceRequest request) {
    request.description = description;
    request.offeredPrice = offeredPrice!;
    request.images = getImagePaths();
    if (serviceType != null) {
      request.serviceType = serviceType!;
    }
  }

  // Cargar datos desde un ServiceRequest existente
  void loadFromServiceRequest(ServiceRequest request, String title) {
    description = request.description;
    offeredPrice = request.offeredPrice;
    selectedServiceTitle = title;

    if (request.serviceType != null) {
      serviceType = request.serviceType as ServiceType?;
    }

    // Cargar las imágenes si existen
    List<String> imagePaths = request.images;
    for (int i = 0; i < imagePaths.length && i < images.length; i++) {
      if (imagePaths[i].isNotEmpty) {
        images[i] = File(imagePaths[i]);
      }
    }

    notifyListeners();
  }
}