import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:manitoscliente_new/menu/Login.dart';

import 'package:manitoscliente_new/request/ResponsePost.dart';

class DeleteAccountByIdDialog extends StatefulWidget {
  final String userId;
  final String authToken;
  const DeleteAccountByIdDialog({Key? key, required this.userId, required this.authToken}) : super(key: key);
  @override
  State<DeleteAccountByIdDialog> createState() => _DeleteAccountByIdDialogState();
}

class _DeleteAccountByIdDialogState extends State<DeleteAccountByIdDialog> {
  bool isDeleting = false;
  String? errorMessage;

  Future<void> _deleteAccount() async {
  setState(() { isDeleting = true; errorMessage = null; });

  try {
    bool success = await ApiService().deleteWorker(widget.userId, widget.authToken);
    if (!success) {
      setState(() {
        errorMessage = 'No se pudo eliminar tu cuenta en el servidor.';
        isDeleting = false;
      });
      return;
    }

    // Opcional: elimina en Firestore aquí si aún no lo haces
    // await FirebaseFirestore.instance.collection('workers').doc(widget.userId).delete();

    await FirebaseAuth.instance.signOut(); // Solo cerramos sesión

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => LoginScreen(deviceId: '', onLoginSuccess: () {  },),
        ),
        (route) => false,
      );
    }

  } catch (e) {
    setState(() {
      errorMessage = 'Error eliminando cuenta: $e';
      isDeleting = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.delete_forever, color: Colors.red),
          SizedBox(width: 8),
          Text('Eliminar cuenta'),
        ],
      ),
      content: isDeleting
          ? SizedBox(height: 70, child: Center(child: CircularProgressIndicator()))
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '¿Estás seguro que deseas eliminar tu cuenta? Esta acción es irreversible y perderás todos tus datos y acceso.',
                  style: GoogleFonts.lato(fontSize: 16),
                ),
                if (errorMessage != null) ...[
                  SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ]
              ],
            ),
      actions: isDeleting
          ? []
          : [
              TextButton(
                child: Text('Cancelar', style: GoogleFonts.lato()),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.delete, color: Colors.white),
                label: Text('Eliminar', style: GoogleFonts.lato(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: _deleteAccount,
              ),
            ],
    );
  }
}
