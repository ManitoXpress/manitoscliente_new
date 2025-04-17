import 'package:flutter/material.dart';

import '../Styles/stilo.dart';



class ServiceDialogs {
  void showCustomDialog(
    BuildContext context,
    String title,
    String content,
    VoidCallback onConfirm,
    String confirmText,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: MyTextStyles.drawerButtonTextStyle4,
          ),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: onConfirm,
              child: Text(
                confirmText,
                style: MyTextStyles.ButtonTextStyle,
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                backgroundColor: Color(0xFF1A819A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: BorderSide(
                    color: Color(0xFF1A819A),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void showRejectCompletionDialog(BuildContext context, VoidCallback onReject) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Rechazar Finalización'),
          content: Text('¿Estás seguro de que quieres rechazar la finalización de este trabajo?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: onReject,
              child: Text('Rechazar'),
            ),
          ],
        );
      },
    );
  }
}