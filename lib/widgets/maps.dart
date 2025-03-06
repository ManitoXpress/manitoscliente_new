import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  LatLng? selectedLocation;
  final Set<Marker> _markers = {};
  BitmapDescriptor? _customIcon;
  final LatLng _initialPosition = LatLng(-17.783327, -63.182139);
  TextEditingController writtenLocationController = TextEditingController();

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
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
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
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
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
          snippet: 'WhatsApp: +591 65884846',
          onTap: () => _launchWhatsApp('59165884846'),
        ),
        icon: _customIcon!,
      ));

      _markers.add(Marker(
        markerId: MarkerId('ubicacion_especifica'),
        position: LatLng(-17.760530046301625, -63.15194373143163),
        infoWindow: InfoWindow(
          title: 'Repuesto Totti',
          snippet: 'WhatsApp: +591 60978792',
          onTap: () => _launchWhatsApp('59160978792'),
        ),
        icon: _customIcon!,
      ));
    });
  }

  void _launchWhatsApp(String phone) async {
    String whatsappUrl = "https://wa.me/$phone";
    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
    } else {
      throw 'No se pudo abrir WhatsApp.';
    }
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
      List<Placemark> placemarks = await placemarkFromCoordinates(loc.latitude, loc.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = "${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}";
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

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return Stack(
              children: [
                Column(
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
                                final locations = await locationFromAddress(query);
                                if (locations.isNotEmpty) {
                                  final location = locations.first;
                                  setStateDialog(() {
                                    _handleTap(LatLng(location.latitude, location.longitude));
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
                    Expanded(
                      child: GoogleMap(
                        onMapCreated: (controller) {
                          mapController = controller;
                          setStateDialog(() {
                            _handleTap(LatLng(position.latitude, position.longitude));
                          });
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
                        markers: _markers,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Volver'),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (selectedLocation != null) {
                              Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Por favor, selecciona una ubicación.'),
                              ));
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Aceptar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  bottom: 160,
                  right: 10,
                  child: FloatingActionButton(
                    onPressed: () async {
                      try {
                        final currentPosition = await Geolocator.getCurrentPosition(
                          desiredAccuracy: LocationAccuracy.high,
                        );
                        setStateDialog(() {
                          _handleTap(LatLng(currentPosition.latitude, currentPosition.longitude));
                        });
                      } catch (e) {
                        print("Error obteniendo la ubicación actual: $e");
                      }
                    },
                    child: Icon(Icons.gps_fixed),
                    tooltip: "Ir a mi ubicación",
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa Interactivo con Icono Personalizado'),
        backgroundColor: Color(0xFF1A819A),
      ),
      body: GestureDetector(
        onHorizontalDragStart: (details) {
          // Evitar que el deslizamiento horizontal se propague al TabBarView
        },
        child: GoogleMap(
          onMapCreated: (controller) {
            mapController = controller;
            _setMarkers(); // Asegúrate de que los marcadores personalizados se establezcan al crear el mapa
          },
          initialCameraPosition: CameraPosition(
            target: _initialPosition,
            zoom: 12,
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showMapScreen,
        child: Icon(Icons.map),
        backgroundColor: Color(0xFF1A819A),
      ),
    );
  }
}
