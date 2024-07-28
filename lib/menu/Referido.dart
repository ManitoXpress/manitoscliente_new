
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:flutter/widgets.dart';


class ReferralScreen extends StatelessWidget {
  final String referralCode; // Código de referido del usuario

  ReferralScreen({required this.referralCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Referidos'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '¡Muy pronto Ganarás puntos invitando a tus amigos!',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tu código de referido:',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'x-x-x-x',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            IconButton(
              onPressed: () {
                _compartirEnlaceReferido(referralCode, SharePlatform.Whatsapp);
              },
              icon: const FaIcon(FontAwesomeIcons.whatsapp),
              iconSize: 48,
            ),
            IconButton(
              onPressed: () {
                _compartirEnlaceReferido(referralCode, SharePlatform.Facebook);
              },
              icon: const FaIcon(FontAwesomeIcons.facebook),
              iconSize: 48,
            ),
            IconButton(
              onPressed: () {
                _compartirEnlaceReferido(referralCode, SharePlatform.Twitter);
              },
              icon: const FaIcon(FontAwesomeIcons.twitter),
              iconSize: 48,
            ),
          ],
        ),
      ),
    );
  }

  void _compartirEnlaceReferido(String referralCode, SharePlatform platform) {
    // Lógica para compartir el enlace de referido
  }
}

enum SharePlatform {
  Whatsapp,
  Facebook,
  Twitter,
}
void _shareReferralLink(String referralCode) {
  // Lógica para compartir el enlace de referido
  // Aquí puedes implementar la funcionalidad para compartir el código de referido con amigos a través de diferentes canales (mensajes, redes sociales, etc.)
}

class RaisedButton {
}

