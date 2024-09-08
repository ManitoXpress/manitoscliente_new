import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
class FullMapScreen extends StatelessWidget {
  final LatLng initialPosition;

  const FullMapScreen({required this.initialPosition});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa Completo'),
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