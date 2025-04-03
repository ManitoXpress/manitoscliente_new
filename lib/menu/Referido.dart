import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../Styles/stilo.dart';
import 'package:share_plus/share_plus.dart';

class ReferralScreen extends StatelessWidget {
  final String referralCode; // Código de referido del usuario

  ReferralScreen({required this.referralCode});

  void _compartirEnlaceReferido(String referralCode) {
    final enlace =
        '¡Únete a ManitosXpress! Usa mi código de referido: $referralCode\nDescarga la app aquí: https://play.google.com/store/apps/details?id=com.xpress.manitosocio';

    Share.share(enlace, subject: 'Únete a ManitosXpress');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          'Referidos',
          style: MyTextStyles.buttonTextStyle,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  '¡Gana puntos invitando a tus amigos!',
                  style: MyTextStyles.welcomeTotheJungle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tu código de referido:',
              style: MyTextStyles.inputTextStyle1,
            ),
            Text(
              referralCode,
              style: MyTextStyles.inputTextStyle1,
            ),
            const SizedBox(height: 30), // Espaciado antes del botón

            // Botón de compartir
            GestureDetector(
              onTap: () => _compartirEnlaceReferido(referralCode),
              child: Container(
                width: 250,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A819A),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.shareFromSquare,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Invitar a amigos',
                      style: MyTextStyles.serviceTitleTextStyle,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
