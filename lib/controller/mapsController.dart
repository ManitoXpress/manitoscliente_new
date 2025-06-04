import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:manitoscliente_new/Styles/stilo.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng initialLocation;
  const MapPickerScreen({Key? key, required this.initialLocation}) : super(key: key);

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng selectedLocation;
  Set<Marker> markers = {};
  GoogleMapController? mapController;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedLocation = widget.initialLocation;
    markers.add(Marker(
      markerId: MarkerId('select'),
      position: selectedLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ));
  }

  void _updateLocation(LatLng loc) {
    setState(() {
      selectedLocation = loc;
      markers = {
        Marker(
          markerId: MarkerId(loc.toString()),
          position: loc,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        )
      };
    });
    if (mapController != null) {
      mapController!.animateCamera(CameraUpdate.newLatLng(loc));
    }
  }

  Future<void> _searchLocation() async {
    final query = searchController.text;
    if (query.isNotEmpty) {
      try {
        final locations = await locationFromAddress(query);
        if (locations.isNotEmpty) {
          final loc = LatLng(locations.first.latitude, locations.first.longitude);
          _updateLocation(loc);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo encontrar la dirección')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seleccionar Ubicación', style: MyTextStyles.buttonTextStyle),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Buscar dirección',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.search),
                        onPressed: _searchLocation,
                      ),
                    ),
                    onSubmitted: (_) => _searchLocation(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.gps_fixed, color: Color(0xFF1A819A)),
                  onPressed: () async {
                    try {
                      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                      _updateLocation(LatLng(pos.latitude, pos.longitude));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No se pudo obtener la ubicación actual')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: selectedLocation,
                zoom: 14,
              ),
              onMapCreated: (controller) {
                mapController = controller;
                // Centra la cámara al inicializar si hace falta
                controller.animateCamera(CameraUpdate.newLatLng(selectedLocation));
              },
              markers: markers,
              onTap: _updateLocation,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A819A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Volver', style: MyTextStyles.drawerButtonLabelTextStyle),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, selectedLocation),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A819A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Aceptar', style: MyTextStyles.drawerButtonLabelTextStyle),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
