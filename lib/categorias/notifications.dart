import 'package:flutter/material.dart';
import 'package:manitoscliente_new/Styles/stilo.dart';

void _showNotifications(BuildContext context) {
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
              style: MyTextStyles.drawerButtonTextStyle2,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.0),
            Container(
              margin: EdgeInsets.symmetric(vertical: 5.0),
              // Margen externo
              padding: EdgeInsets.all(3.0),
              // Espaciado entre el borde azul y el ListTile
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 1.0),
                borderRadius: BorderRadius.circular(25.0),
                // Haciendo el borde más redondeado para que parezca ovalado
                color: Colors
                    .transparent, // Asegurarse de que el fondo sea transparente
              ),
              child: ListTile(
                contentPadding:
                    EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                // Ajuste adicional para tener espacio alrededor del contenido
                leading: Icon(Icons.mail_outline),
                title: Text('Verificación de correo'),
                subtitle: Text('Haz clic para verificar tu correo.'),
                onTap: () {
                  Navigator.pop(context); // Cerrar el bottom sheet
                },
              ),
            ),
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
                leading: Icon(Icons.photo_camera_outlined),
                title: Text('Verificación de foto de perfil'),
                subtitle: Text('Haz clic para verificar tu foto de perfil.'),
                onTap: () {
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
