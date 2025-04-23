import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:manitoscliente_new/Styles/stilo.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppContactScreen extends StatefulWidget {
  final String workerId;

  WhatsAppContactScreen({required this.workerId});

  @override
  _WhatsAppContactScreenState createState() => _WhatsAppContactScreenState();
}

class _WhatsAppContactScreenState extends State<WhatsAppContactScreen> {
  String? workerName;
  String? phoneNumber;

  @override
  void initState() {
    super.initState();
    _fetchWorkerData();
  }

  Future<void> _fetchWorkerData() async {
    try {
      final workerDoc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(widget.workerId)
          .get();
      if (workerDoc.exists) {
        setState(() {
          workerName = workerDoc['displayName'];
          phoneNumber = workerDoc['phoneNumber'];
        });
      }
    } catch (e) {
      print('Error al obtener datos del trabajador: $e');
    }
  }

  void _openWhatsApp() async {
    if (phoneNumber != null) {
      final whatsappUrl = "https://wa.me/$phoneNumber?text=Hola $workerName, necesito comunicarme contigo desde la app.";
      if (await canLaunch(whatsappUrl)) {
        await launch(whatsappUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No se pudo abrir WhatsApp")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contactar por WhatsApp'),
      ),
      body: Center(
        child: phoneNumber == null
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿Deseas contactar a $workerName por WhatsApp?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: FaIcon(FontAwesomeIcons.whatsapp),
                    onPressed: _openWhatsApp,
                    label: Text('Abrir WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
