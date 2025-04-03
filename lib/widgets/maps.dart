import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Styles/stilo.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();

  void onLocationSelected(LatLng latLng) {}
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  LatLng? selectedLocation;
  final Set<Marker> _markers = {};
  BitmapDescriptor? _customIcon;
  final LatLng _initialPosition = LatLng(-17.7833, -63.1821);
  TextEditingController writtenLocationController = TextEditingController();
  Completer<GoogleMapController> _controller = Completer<GoogleMapController>();

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      LatLng currentLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        selectedLocation = currentLocation;
        _markers.clear();
        _markers.add(
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
      setState(() {
        selectedLocation = _initialPosition;
        _markers.clear();
        _markers.add(
          Marker(
            markerId: MarkerId(_initialPosition.toString()),
            position: _initialPosition,
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      });
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _initialPosition,
            zoom: 14.0,
          ),
        ),
      );
      _handleTap(_initialPosition);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    print("Mapa creado correctamente");
  }

  Future<void> _loadCustomMarker() async {
    final customIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(8, 8)),
      'assets/gra.png',
    );
    setState(() {
      _customIcon = customIcon;
    });
  }

  void _handleTap(LatLng loc) async {
    setState(() {
      selectedLocation = loc;
      _markers.clear();
      _markers.add(Marker(
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

  @override
  Widget build(BuildContext context) {
    TextEditingController searchController = TextEditingController();

    // Definir una variable para el marcador seleccionado
    Marker? selectedMarker;

    // Obtener la ubicación actual del usuario
    Future<Position> getPosition() async {
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        print("Error obteniendo la ubicación actual: $e");
        position = Position(
          latitude: _initialPosition.latitude,
          longitude: _initialPosition.longitude,
          timestamp: DateTime.now(),
          accuracy: 1.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 1.0,
          headingAccuracy: 1.0,
        );
      }
      return position;
    }

    return FutureBuilder<Position>(
      future: getPosition(), // Llamar a la función que obtiene la posición
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child:
                  CircularProgressIndicator()); // Mostrar un cargando mientras se obtiene la ubicación
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        // Una vez obtenida la ubicación
        Position position = snapshot.data!;

        return Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
              return Stack(
                children: [
                  Column(
                    children: [
                      // Barra de búsqueda de dirección
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
                                    setStateDialog(() {
                                      selectedMarker = Marker(
                                        markerId: MarkerId('selected_location'),
                                        position: LatLng(location.latitude,
                                            location.longitude),
                                        infoWindow: InfoWindow(
                                            title: 'Ubicación seleccionada'),
                                      );
                                    });
                                  } else {
                                    print("No se encontró la dirección");
                                  }
                                } catch (e) {
                                  print("Error buscando dirección: $e");
                                }
                              }
                            },
                          ),
                        ),
                      ),
                      // Mapa de Google
                      Expanded(
                        child: GoogleMap(
                          onMapCreated: (controller) {
                            _onMapCreated(controller);
                            _controller.complete(controller);
                            // Establecer la posición inicial del mapa con la ubicación del usuario
                            setStateDialog(() {
                              selectedMarker = Marker(
                                markerId: MarkerId('user_location'),
                                position: LatLng(
                                    position.latitude, position.longitude),
                                infoWindow: InfoWindow(title: 'Tu ubicación'),
                              );
                            });
                          },
                          onTap: (LatLng loc) {
                            setStateDialog(() {
                              selectedMarker = Marker(
                                markerId: MarkerId('selected_location'),
                                position: loc,
                                infoWindow:
                                    InfoWindow(title: 'Ubicación seleccionada'),
                              );
                            });
                          },
                          initialCameraPosition: CameraPosition(
                            target:
                                LatLng(position.latitude, position.longitude),
                            zoom: 14.0,
                          ),
                          markers:
                              selectedMarker != null ? {selectedMarker!} : {},
                        ),
                      ),
                    ],
                  ),
                  // Botón flotante para obtener la ubicación actual
                  Positioned(
                    bottom: 100,
                    right: 10,
                    child: FloatingActionButton(
                      onPressed: () async {
                        try {
                          final currentPosition =
                              await Geolocator.getCurrentPosition(
                            desiredAccuracy: LocationAccuracy.high,
                          );
                          setStateDialog(() {
                            selectedMarker = Marker(
                              markerId: MarkerId('current_location'),
                              position: LatLng(currentPosition.latitude,
                                  currentPosition.longitude),
                              infoWindow:
                                  InfoWindow(title: 'Mi ubicación actual'),
                            );
                          });
                        } catch (e) {
                          print("Error obteniendo la ubicación actual: $e");
                        }
                      },
                      child: Icon(Icons.gps_fixed),
                      tooltip: "Ir a mi ubicación",
                      backgroundColor:
                          Color(0xFF1A819A), // Cambiar el color de fondo aquí
                    ),
                  )
                ],
              );
            },
          ),
        );
      },
    );
  }
}
