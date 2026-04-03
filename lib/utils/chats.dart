import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Styles/stilo.dart';

class WhatsAppUserContactScreen extends StatefulWidget {
  final String userId;

  WhatsAppUserContactScreen({required this.userId});

  @override
  _WhatsAppUserContactScreenState createState() =>
      _WhatsAppUserContactScreenState();
}

class _WhatsAppUserContactScreenState extends State<WhatsAppUserContactScreen> {
  String? phoneNumber;
  String? displayName;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    try {
      final workerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (workerDoc.exists) {
        setState(() {
          displayName = workerDoc['displayName'];
          phoneNumber = workerDoc['phoneNumber'];
        });
      }
    } catch (e) {
      null;
    }
  }

  void _openWhatsApp() async {
    if (phoneNumber == null) return;

    final whatsappUrl = Uri.parse(
        "https://wa.me/$phoneNumber?text=Hola $displayName, soy el cliente de tu trabajo asignado desde la app.");
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir WhatsApp.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(displayName != null
            ? 'Contactar a $displayName'
            : 'Contacto por WhatsApp'),
      ),
      body: Center(
        child: phoneNumber == null
            ? CircularProgressIndicator()
            : ElevatedButton.icon(
                icon: FaIcon(FontAwesomeIcons.whatsapp),
                label: Text('Chatear con $displayName'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: _openWhatsApp,
              ),
      ),
    );
  }
}
