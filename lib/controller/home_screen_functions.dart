import 'package:flutter/material.dart';
import 'package:manitoscliente_new/request/dataprofile.dart';

import '../Historial.dart';
import '../Styles/stilo.dart';


class ServiceFunctions {
  static int notificationCount = 0;

  static void showNotifications(BuildContext context,
      {required String title, required String body, VoidCallback? onTap}) {
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
                  title: Text(title),
                  subtitle: Text(body),
                  onTap: () {
                    // Ejecuta la función onTap cuando el usuario toque la notificación
                    if (onTap != null) {
                      onTap();
                    }
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

static void notifyNewService(
      BuildContext context, {
        required UserData userData,
        required VoidCallback onTabTapped,
      }) {
    notificationCount++;
    showNotifications(
      context,
      title: 'Nuevo Servicio Creado',
      body: 'Haz clic para ver los detalles del servicio.',
      onTap: () {
        Navigator.pop(context); // cerrar el bottom sheet
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HistorialScreen(
              userData: userData,
              onTabTapped: onTabTapped,
            ),
          ),
        );
      },
    );
  }
  static void limpiarTextoBusqueda(
      TextEditingController textEditingController, bool showClearButton) {
    textEditingController.clear();
    showClearButton = false;
  }
}
