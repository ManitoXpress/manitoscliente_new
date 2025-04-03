import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

import '../Styles/stilo.dart';

class FullMapScreen extends StatelessWidget {
  final LatLng initialPosition;

  const FullMapScreen({required this.initialPosition});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Mapa Completo',
          style: MyTextStyles.buttonTextStyle,
        ),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: initialPosition,
          zoom: 16.0,
        ),
        markers: {
          Marker(
            markerId: MarkerId('fullServiceLocation'),
            position: initialPosition,
          ),
        },
      ),
    );
  }
}
