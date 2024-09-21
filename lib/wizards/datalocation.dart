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

class _LocationAndFavoritesWizardState extends State<LocationAndFavoritesWizard> {
  LatLng? selectedLocation;
  bool isFavorite = false;
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  TextEditingController locationController = TextEditingController();
  TextEditingController writtenLocationController = TextEditingController();
  Uint8List? mapSnapshot;
  TextEditingController additionalInfoController = TextEditingController();
  Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  // Santa Cruz de la Sierra coordinates
  final LatLng santaCruzLocation = LatLng(-17.7833, -63.1833);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    
  }

  bool isLocationAndFavoritesValid() {
    return selectedLocation != null;
  }

  Future<void> _getCurrentLocation() async {
    try {
      location.Location loc = location.Location();

      bool serviceEnabled = await loc.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await loc.requestService();
        if (!serviceEnabled) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Por favor, habilita los servicios de ubicación.'),
          ));
          return;
        }
      }

      location.PermissionStatus permissionGranted = await loc.hasPermission();
      if (permissionGranted == location.PermissionStatus.denied) {
        permissionGranted = await loc.requestPermission();
        if (permissionGranted != location.PermissionStatus.granted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Permiso de ubicación denegado.'),
          ));
          return;
        }
      }

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

      mapController?.animateCamera(
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
    final Uint8List? snapshotBytes = await mapController?.takeSnapshot();
    if (snapshotBytes != null) {
      setState(() {
        mapSnapshot = snapshotBytes;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _controller.complete(controller);
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
                        icon: Icon(Icons.maps_home_work),
                        onPressed: () async {
                          final query = searchController.text;
                          if (query.isNotEmpty) {
                            try {
                              final locations =
                                  await locationFromAddress(query);
                              if (locations.isNotEmpty) {
                                final location = locations.first;
                                _handleTap(LatLng(
                                    location.latitude, location.longitude));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('No se encontró la dirección.'),
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Error buscando dirección: $e'),
                                ),
                              );
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
                        _handleTap(santaCruzLocation);
                      },
                      onTap: (LatLng loc) {
                        setStateDialog(() {
                          _handleTap(loc);
                        });
                      },
                      initialCameraPosition: CameraPosition(
                        target: santaCruzLocation,
                        zoom: 12.0,
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
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16), // Ajusta el tamaño del botón
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0), // Bordes redondeados
                          ),
                          backgroundColor: Color(0xFF1A819A),// Color personalizado
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
                            setState(() {});
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  'Por favor, selecciona una ubicación.'),
                            ));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16), // Ajusta el tamaño del botón
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0), // Bordes redondeados
                            ),
                            backgroundColor: Color(0xFF1A819A),// Color personalizado
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
              'Coloque su ubicación en el mapa',
              style: MyTextStyles.formServiceTextStyle,
              textAlign: TextAlign.left,
            ),
          ),
        ),
        Card(
          elevation: 5.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _showMapScreen,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      color: Colors.grey[200],
                    ),
                    child: mapSnapshot != null
                        ? Image.memory(
                            mapSnapshot!,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            'assets/map.jpeg',
                            fit: BoxFit.cover,
                          ),
                  ),
                ),

                SizedBox(height: 10),
                TextField(
                  controller: writtenLocationController,
                  decoration: InputDecoration(
                    labelText: 'Ubicación seleccionada',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 10.0, left: 20.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '¿Quieres marcar esta ubicación como favorita?',
              style: MyTextStyles.formServiceTextStyle,
              textAlign: TextAlign.left,
            ),
          ),
        ),
        SwitchListTile(
          title: Text(
            'Marcar como favorita',
            style: MyTextStyles.formServiceTextStyle3,
          ),
          value: isFavorite,
          onChanged: (bool value) {
            setState(() {
              isFavorite = value;
              widget.onFavoritesSelected(value);
            });
          },
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 10.0, left: 20.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Añadir información adicional',
              style: MyTextStyles.formServiceTextStyle,
              textAlign: TextAlign.left,
            ),
          ),
        ),
        TextFormField(
          
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Detalles del servicio',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xA3C9D2D2)),
              borderRadius: BorderRadius.circular(20.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF1A819A)),
              borderRadius: BorderRadius.circular(20.0),
            ),
            labelStyle: MyTextStyles.formsdetails,
          ),
          onChanged: (value) {
            
          },
        ),
      ],
    );
  }
}

