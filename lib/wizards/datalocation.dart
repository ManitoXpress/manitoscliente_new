import 'dart:async';
import 'dart:typed_data';

import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as location;
import 'package:manitoscliente_new/Styles/stilo.dart';

class LocationAndFavoritesWizard extends StatefulWidget {
  final Function(LatLng) onLocationSelected;
  final Function(bool) onFavoritesSelected;
  final VoidCallback onNextStep;
  final Map<String, double> location;

  _LocationAndFavoritesWizardState? _locationAndFavoritesWizardState;

  bool? isLocationAndFavoritesValid() {
    return _locationAndFavoritesWizardState?.isLocationAndFavoritesValid();
  }

  LocationAndFavoritesWizard({
    required this.onLocationSelected,
    required this.onFavoritesSelected,
    required this.onNextStep,
    required this.location,
  });

  @override
  _LocationAndFavoritesWizardState createState() =>
      _LocationAndFavoritesWizardState();
}

class _LocationAndFavoritesWizardState
    extends State<LocationAndFavoritesWizard> {
  LatLng? selectedLocation;
  bool isFavorite = false;
  late GoogleMapController mapController;
  Set<Marker> markers = {};
  TextEditingController locationController = TextEditingController();
  TextEditingController writtenLocationController = TextEditingController();
  Uint8List? mapSnapshot;
  TextEditingController additionalInfoController = TextEditingController();
  Completer<GoogleMapController> _controller = Completer<GoogleMapController>();

  @override
  void initState() {
    super.initState();
    _controller = Completer<GoogleMapController>();
    _getCurrentLocation();
  }

  bool isLocationAndFavoritesValid() {
    return selectedLocation != null;
  }

  Future<void> _getCurrentLocation() async {
    try {
      location.Location loc = location.Location();

      // Verificar si los servicios de ubicación están habilitados
      bool serviceEnabled = await loc.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await loc.requestService();
        if (!serviceEnabled) {
          // Servicios de ubicación deshabilitados, puedes mostrar un mensaje al usuario
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Por favor, habilita los servicios de ubicación.'),
          ));
          return;
        }
      }

      // Verificar si se tienen permisos de ubicación
      location.PermissionStatus permissionGranted = await loc.hasPermission();
      if (permissionGranted == location.PermissionStatus.denied) {
        permissionGranted = await loc.requestPermission();
        if (permissionGranted != location.PermissionStatus.granted) {
          // Permiso de ubicación denegado, puedes mostrar un mensaje al usuario
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Permiso de ubicación denegado.'),
          ));
          return;
        }
      }

      // Obtener la ubicación actual
      location.LocationData locationData = await loc.getLocation();
      LatLng currentLocation =
          LatLng(locationData.latitude!, locationData.longitude!);

      setState(() {
        selectedLocation = currentLocation;
        markers.clear();
        markers.add(
          Marker(
            markerId: MarkerId(currentLocation.toString()),
            position: currentLocation,
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      });

      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentLocation,
            zoom: 14.0,
          ),
        ),
      );

      _handleTap(currentLocation);
    } catch (e) {
      print("Error obteniendo la ubicación actual: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error obteniendo la ubicación actual: $e'),
      ));
    }
  }

  Future<void> _captureAndSaveMapSnapshot() async {
    final Uint8List? snapshotBytes = await mapController.takeSnapshot();
    setState(() {
      mapSnapshot = snapshotBytes;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    print("Mapa creado correctamente");
  }

  void _handleTap(LatLng loc) async {
    widget.onLocationSelected(loc);

    setState(() {
      selectedLocation = loc;
      markers.clear();
      markers.add(Marker(
        markerId: MarkerId(loc.toString()),
        position: loc,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    });

    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(loc.latitude, loc.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}";
        writtenLocationController.text = address;
      } else {
        writtenLocationController.text = "Dirección no encontrada";
      }
    } catch (e) {
      print("Error obteniendo dirección: $e");
      writtenLocationController.text = "Error obteniendo dirección";
    }
  }

  Future<void> _showMapScreen() async {
    TextEditingController searchController = TextEditingController();

    // Obtener la ubicación actual del usuario
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print("Error obteniendo la ubicación actual: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error obteniendo la ubicación actual: $e'),
      ));
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(
              'Seleccionar Ubicación',
              style: MyTextStyles.buttonTextStyle,
            ),
          ),
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
              return Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Buscar dirección',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.search),
                        onPressed: () async {
                          final query = searchController.text;
                          if (query.isNotEmpty) {
                            try {
                              final locations =
                                  await locationFromAddress(query);
                              if (locations.isNotEmpty) {
                                final location = locations.first;
                                _handleTap(LatLng(location.latitude, location.longitude));
                              } else {
                                print("No se encontró la dirección");
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('No se encontró la dirección.'),
                                ));
                              }
                            } catch (e) {
                              print("Error buscando dirección: $e");
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Error buscando dirección: $e'),
                              ));
                            }
                          }
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: GoogleMap(
                      onMapCreated: (controller) {
                        _onMapCreated(controller);
                        _controller.complete(controller);
                        _handleTap(LatLng(position.latitude, position.longitude));
                      },
                      onTap: (LatLng loc) {
                        setStateDialog(() {
                          _handleTap(loc);
                        });
                      },
                      initialCameraPosition: CameraPosition(
                        target: LatLng(position.latitude, position.longitude),
                        zoom: 14.0,
                      ),
                      markers: markers,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          backgroundColor: Color(0xFF84090D),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Volver',
                            style: MyTextStyles.buttonTextStyle.copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (selectedLocation != null) {
                            widget.onLocationSelected(selectedLocation!);
                            await _captureAndSaveMapSnapshot();
                            Navigator.pop(context);
                            setState(
                                () {}); // Actualizar la interfaz de usuario
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Por favor, selecciona una ubicación.'),
                            ));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          backgroundColor: Color(0xFF84090D),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Aceptar',
                            style: MyTextStyles.buttonTextStyle.copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await _captureAndSaveMapSnapshot();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 10.0, left: 20.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Paso 2: Coloque su ubicación en el mundo',
              style: MyTextStyles.formServiceTextStyle,
              textAlign: TextAlign.left,
            ),
          ),
        ),
        Card(
          elevation: 5.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50.0),
          ),
          child: InkWell(
            onTap: _showMapScreen,
            borderRadius: BorderRadius.circular(50.0),
            child: CircleAvatar(
              radius: 50.0,
              backgroundImage: AssetImage('assets/images/mundo.png'),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Container(
            height: 60.0,
            child: TextField(
              controller: writtenLocationController,
              decoration: InputDecoration(
                labelText: 'Dirección seleccionada',
                labelStyle: MyTextStyles.formsdetails,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide(color: Color(0xFF1A819A)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide(color: Color(0xFF1A819A)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide(color: Color(0xFF1A819A)),
                ),
              ),
              readOnly: true,
            ),
          ),
        ),
        SizedBox(height: 8.0),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Container(
            height: 60.0,
            child: TextField(
              controller: additionalInfoController,
              decoration: InputDecoration(
                labelText: 'Información adicional',
                labelStyle: MyTextStyles.formsdetails,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide(color: Color(0xFF1A819A)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide(color: Color(0xFF1A819A)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide(color: Color(0xFF1A819A)),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 8.0),
        mapSnapshot != null
            ? Padding(
                padding: EdgeInsets.all(8.0),
                child: Image.memory(mapSnapshot!),
              )
            : Container(),
        SizedBox(height: 8.0),
      ],
    );
  }
}
