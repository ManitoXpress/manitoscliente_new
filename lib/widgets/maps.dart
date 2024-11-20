import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final LatLng _initialPosition = LatLng(-17.783327, -63.182139);
  final Set<Marker> _markers = {};
  BitmapDescriptor? _customIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    // Mostrar el AlertDialog después de que el widget se construya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInitialDialog();
    });
  }

  // Función para mostrar el AlertDialog
  Future<void> _showInitialDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // El usuario debe tocar un botón para cerrar
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Bienvenido al Mapa'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Este mapa muestra las ubicaciones de tiendas de utilizad para nuestros servicios relacionados.'),
                Text('Puede hacer zoom y desplazarse para explorar los diferentes lugares.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Entendido'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  void _launchWhatsApp(String phone) async {
    // Formato internacional del número (eliminar espacios y guiones)
    String whatsappUrl = "https://wa.me/$phone";

    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
    } else {
      throw 'No se pudo abrir WhatsApp.';
    }
  }

  Future<void> _loadCustomMarker() async {
    final customIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(8, 8)),
      'assets/gra.png',
    );
    setState(() {
      _customIcon = customIcon;
    });
    _setMarkers();
  }

  void _setMarkers() {
    if (_customIcon == null) return;

    setState(() {
      _markers.add(Marker(
        markerId: MarkerId('ubicacion_inicial'),
        position: _initialPosition,
        infoWindow: InfoWindow(
          title: 'MULTIPARTES',
          snippet: 'WhatsApp: +591 65884846', // Número de ejemplo
          onTap: () => _launchWhatsApp('59165884846'), // Número sin espacios ni símbolos
        ),
        icon: _customIcon!,
      ));

      _markers.add(Marker(
        markerId: MarkerId('ubicacion_especifica'),
        position: LatLng(-17.760530046301625, -63.15194373143163),
        infoWindow: InfoWindow(
          title: 'Repuesto Totti',
          snippet: 'WhatsApp: +591 60978792', // Número de ejemplo
          onTap: () => _launchWhatsApp('59160978792'), // Número sin espacios ni símbolos
        ),
        icon: _customIcon!,
      ));
    });
  }

  void _recenterMap() {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _initialPosition, zoom: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa Interactivo con Icono Personalizado'),
        backgroundColor: Color(0xFF1A819A),
      ),
      body: GoogleMap(
        onMapCreated: (controller) {
          mapController = controller;
        },
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 14,
        ),
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        tiltGesturesEnabled: true,
        scrollGesturesEnabled: true,
        zoomGesturesEnabled: true,
        rotateGesturesEnabled: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _recenterMap,
        child: Icon(Icons.my_location),
        backgroundColor: Color(0xFF1A819A),
      ),
    );
  }
}