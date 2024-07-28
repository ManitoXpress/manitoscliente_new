import 'package:flutter/material.dart';
import 'package:manitoscliente_new/ServicesResponse/ResponseGet.dart';

import 'package:manitoscliente_new/Styles/stilo.dart';

class ServiceFunctions {
  static int notificationCount = 0;

  static void showNotifications(BuildContext context,
      {required String title, required String body}) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Container(
          padding: EdgeInsets.only(
              top: 16.0,
              left: 16.0,
              right: 16.0,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'NOTIFICACIONES',
                style: MyTextStyles.notification,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.0),
              Container(
                margin: EdgeInsets.symmetric(vertical: 5.0),
                padding: EdgeInsets.all(3.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 1.0),
                  borderRadius: BorderRadius.circular(25.0),
                  color: Colors.transparent,
                ),
                child: ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  leading: Icon(Icons.message),
                  title: Text('Nuevo Servicio Creado'),
                  subtitle:
                      Text('Haz clic para ver los detalles del servicio.'),
                  onTap: () {
                    // Agrega la lógica para navegar o mostrar los detalles del servicio
                    // Puedes implementar esto según tus necesidades
                    Navigator.pop(context); // Cerrar el bottom sheet
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static void notifyNewService(BuildContext context) {
    notificationCount++;
    showNotifications(
      context,
      title: 'Nuevo Servicio Creado',
      body: 'Haz clic para ver los detalles del servicio.',
    );
  }

  static void limpiarTextoBusqueda(
      TextEditingController textEditingController, bool showClearButton) {
    textEditingController.clear();
    showClearButton = false;
  }
}
