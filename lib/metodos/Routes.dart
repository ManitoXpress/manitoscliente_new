import 'package:flutter/material.dart';
import 'package:manitoscliente_new/Historial.dart';
import 'package:manitoscliente_new/categorias/Service_DetailsScreen.dart';
import 'package:manitoscliente_new/ServicesResponse/resquest.dart';
import 'package:manitoscliente_new/home.dart';
import 'package:manitoscliente_new/utils/status.dart';

class Routes {
  static const String home = '/';
  static const String historial = '/historial';
  static const String serviceForm =
      '/serviceForm'; // Nueva ruta para ServiceFormPage

  static final Map<String, WidgetBuilder> routes = {
    home: (context) => HomeScreen(),
    historial: (context) => Historial(),
    serviceForm: (context) {
      // Utiliza StatusUtils para obtener un objeto Status con el nombre adecuado
      final Status status = StatusUtils.getStatusById('En proceso');

      // Crea una instancia de ServiceFormPage con el objeto Status proporcionado
      return ServiceFormPage(
        serviceRequest: ServiceRequest(
          description: '',
          images: [],
          location: {'lat': 0.0, 'lng': 0.0},
          offeredPrice: 0.0,
          userId: '',
          isFavorite: false,
          acceptedTerms: false,
          serviceType: ServiceType(
            name: 'Servicio',
            id: '',
            selectedDate: '',
            selectedTime: '',
          ),
          id: '',
          serviceDateTime: '',
          status: status, // Asigna el objeto Status aquí
          expertises: '',
        ),
        acceptTerms: true,
        serviceRequests: [],
        selectedDate: DateTime.now(),
        selectedServiceTitle: 'Servicio',
        token: 'token',
        selectedTime: '', categoryId: '',
        subcategoryId: '', // Ajusta según tus necesidades
      );
    },
  };
}
