import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as location;
import 'package:shared_preferences/shared_preferences.dart';

import '../Styles/stilo.dart';
import '../utils/favoriteubi.dart';

class LocationAndFavoritesWizard extends StatefulWidget {
  final Map<String, double> location;
  final Function(LatLng selectedLocation) onLocationSelected;
  final Function(bool isFavorite) onFavoritesSelected;
  final Function onNextStep;

  LocationAndFavoritesWizard({
    required this.location,
    required this.onLocationSelected,
    required this.onFavoritesSelected,
    required this.onNextStep,
  });

  @override
  _LocationAndFavoritesWizardState createState() =>
      _LocationAndFavoritesWizardState();
}

class _LocationAndFavoritesWizardState
    extends State<LocationAndFavoritesWizard> {
  LatLng? selectedLocation; // Ubicación seleccionada
  bool isFavorite = false; // Indica si es favorito
  late GoogleMapController mapController; // Controlador del mapa de Google
  Set<Marker> markers = {}; // Conjunto de marcadores para el mapa
  TextEditingController locationController =
      TextEditingController(); // Controlador de texto para la ubicación
  TextEditingController writtenLocationController =
      TextEditingController(); // Controlador de texto para la dirección escrita
  Uint8List? mapSnapshot; // Instantánea del mapa
  TextEditingController additionalInfoController =
      TextEditingController(); // Controlador para la información adicional
  Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>(); // Controlador asíncrono del mapa
  final LatLng santaCruzLocation = LatLng(-17.7833, -63.1833);
  final LatLng santaCruzDefaultLocation = LatLng(-17.7833,
      -63.1821); // Coordenadas predeterminadas de Santa Cruz de la Sierra
  TextEditingController searchController = TextEditingController();
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Llamamos a _showMapScreen al iniciar el widget
  

    _getCurrentLocation();
    // Obtención de la ubicación actual cuando se inicializa el estado

  }

  // Verifica si la ubicación y los favoritos son válidos
  bool isLocationAndFavoritesValid() {
    return selectedLocation != null;
  }

  void _searchLocation(dynamic searchController) {
    // Aquí pondrías la lógica para realizar la búsqueda de la ubicación
    print("Buscando ubicación: ${searchController.text}");
    // Llamar a la función de búsqueda o mostrar la ubicación en el mapa
  }

  // Función para obtener la ubicación actual del dispositivo
  Future<void> _getCurrentLocation() async {
    try {
      location.Location loc = location.Location();

      // Verificar si los servicios de ubicación están habilitados
      bool serviceEnabled = await loc.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await loc.requestService();
        if (!serviceEnabled) {
          return;
        }
      }

      // Verificar si los permisos de ubicación han sido otorgados
      location.PermissionStatus permissionGranted = await loc.hasPermission();
      if (permissionGranted == location.PermissionStatus.denied) {
        permissionGranted = await loc.requestPermission();
        if (permissionGranted != location.PermissionStatus.granted) {
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

      _handleTap(currentLocation); // Maneja el toque en el mapa
    } catch (e) {
      print("Error obteniendo la ubicación actual: $e");

      // Si no se puede obtener la ubicación actual, usa una ubicación predeterminada
      setState(() {
        selectedLocation = santaCruzDefaultLocation;
        markers.clear();
        markers.add(
          Marker(
            markerId: MarkerId(santaCruzDefaultLocation.toString()),
            position: santaCruzDefaultLocation,
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      });

      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: santaCruzDefaultLocation,
            zoom: 14.0,
          ),
        ),
      );

      _handleTap(
          santaCruzDefaultLocation); // Maneja el toque en la ubicación predeterminada
    }
  }

  // Función para capturar y guardar una instantánea del mapa
  Future<void> _captureAndSaveMapSnapshot() async {
    final Uint8List? snapshotBytes = await mapController.takeSnapshot();
    setState(() {
      mapSnapshot = snapshotBytes;
    });
  }

  // Función que se llama cuando se crea el mapa
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    print("Mapa creado correctamente");
  }

  // Maneja el toque en el mapa para actualizar la ubicación seleccionada
  void _handleTap(LatLng loc) async {
    widget.onLocationSelected(
        loc); // Llama al callback para pasar la ubicación seleccionada

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
      // Obtener la dirección basada en las coordenadas
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

  // Muestra la pantalla del mapa para que el usuario seleccione una ubicación
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
      position = Position(
        latitude: santaCruzDefaultLocation.latitude,
        longitude: santaCruzDefaultLocation.longitude,
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

    // Navegar a la pantalla del mapa
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            iconTheme: IconThemeData(color: Colors.white),
            title: Text(
              'Seleccionar Ubicación',
              style: MyTextStyles.buttonTextStyle,
            ),
          ),
          body: StatefulBuilder(
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
                                  final locations =
                                      await locationFromAddress(query);
                                  if (locations.isNotEmpty) {
                                    final location = locations.first;
                                    // Aquí es donde puedes manejar el latLng, si es necesario
                                    print("Ubicación encontrada: $location");
                                    // Actualizar la posición en el mapa
                                    setStateDialog(() {
                                      _handleTap(LatLng(location.latitude,
                                          location.longitude));
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
                            _onMapCreated(controller);
                            _controller.complete(controller);
                            // Establecer la posición inicial del mapa con la ubicación del usuario
                            setStateDialog(() {
                              _handleTap(LatLng(
                                  position.latitude, position.longitude));
                            });
                          },
                          onTap: (LatLng loc) {
                            setStateDialog(() {
                              _handleTap(loc);
                            });
                          },
                          initialCameraPosition: CameraPosition(
                            target:
                                LatLng(position.latitude, position.longitude),
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
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Volver',
                                style: MyTextStyles.drawerButtonLabelTextStyle,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A819A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              if (selectedLocation != null) {
                                widget.onLocationSelected(selectedLocation!);
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                      'Por favor, selecciona una ubicación.'),
                                ));
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Aceptar',
                                style: MyTextStyles.drawerButtonLabelTextStyle,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A819A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
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
                          final currentPosition =
                              await Geolocator.getCurrentPosition(
                            desiredAccuracy: LocationAccuracy.high,
                          );
                          setStateDialog(() {
                            _handleTap(LatLng(currentPosition.latitude,
                                currentPosition.longitude));
                          });
                        } catch (e) {
                          print("Error obteniendo la ubicación actual: $e");
                        }
                      },
                      child: Icon(Icons.gps_fixed),
                      tooltip: "Ir a mi ubicación",
                      backgroundColor: Color(0xFF1A819A),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    // Captura una instantánea después de seleccionar la ubicación
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
              style: MyTextStyles.formServiceTextStyle2,
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
                            'assets/map.png',
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: writtenLocationController,
                  decoration: InputDecoration(
                    labelText: 'Ubicación seleccionada',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF9E9E9E)),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    labelStyle: TextStyle(
                        color: Colors
                            .grey), // Color del label cuando no está enfocado
                    floatingLabelStyle: TextStyle(color: Color(0xFF9E9E9E)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2.0),
        SwitchListTile(
          title: Text(
            'Marcar ubicación como favorita',
            style: MyTextStyles.drawerButtonTextStyle,
          ),
          value: isFavorite,
          onChanged: (bool value) async {
            setState(() {
              isFavorite = value; // Actualiza el estado del switch
            });

            if (isFavorite && writtenLocationController.text.isNotEmpty) {
              // Si el switch está activado y la ubicación no está vacía, guarda la ubicación
              String location = writtenLocationController.text;

              // Guardar ubicación en SharedPreferences
              SharedPreferences prefs = await SharedPreferences.getInstance();
              List<String> _favoriteLocations =
                  prefs.getStringList('favoriteLocations') ?? [];

              // Añadir la ubicación a la lista de favoritos
              _favoriteLocations.add(location);

              // Guardar la lista actualizada
              await prefs.setStringList(
                  'favoriteLocations', _favoriteLocations);

              print('Ubicación guardada: $location');
            } else {
              print('Ubicación no guardada porque el switch está apagado.');
            }

            widget.onFavoritesSelected(
                value); // Pasamos el valor de favorito al callback
          },
          activeColor: Color(0xFF1A819A), // Color cuando está activado
          inactiveTrackColor: Colors.grey, // Color cuando está desactivado
          inactiveThumbColor: const Color.fromRGBO(
              0, 0, 0, 1), // Color del pulgar cuando está desactivado
        ), // Cambiado a screenutil
        ElevatedButton.icon(
          onPressed: () async {
            // Navegar a FavoriteLocationsScreen y esperar el resultado
            final selectedLocation = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FavoriteLocationsScreen()),
            );
            
            // Si se recibió una ubicación válida
            if (selectedLocation != null && selectedLocation is LatLng) {
              // Actualizar el estado del wizard
              setState(() {
                this.selectedLocation = selectedLocation;
                markers.clear();
                markers.add(Marker(
                  markerId: MarkerId(selectedLocation.toString()),
                  position: selectedLocation,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                ));
              });
              
              // Mover la cámara del mapa a la nueva ubicación
              if (mapController != null) {
                mapController.animateCamera(
                  CameraUpdate.newLatLng(selectedLocation),
                );
              }
              
              // Actualizar la dirección escrita en el TextField
              _handleTap(selectedLocation);
            }
          },
          icon: Icon(Icons.star, color: Color(0xFF1A819A)),
          label: Align(
            alignment: Alignment.centerLeft,
            child: Text("Ubicaciones Favoritas", style: MyTextStyles.linkTextStyle),
          ),
        ),
        SizedBox(height: 3.h),
        Padding(
          padding: EdgeInsets.only(bottom: 10.0, left: 20.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Añadir información adicional',
              style: MyTextStyles.formServiceTextStyle2,
              textAlign: TextAlign.left,
            ),
          ),
        ),
        TextFormField(
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Añadir información adicional',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.circular(20.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF9E9E9E)),
              borderRadius: BorderRadius.circular(20.0),
            ),
            // Cambiar el color del label cuando el campo está enfocado
            labelStyle: TextStyle(
                color: Colors.grey), // Color del label cuando no está enfocado
            floatingLabelStyle: TextStyle(
                color:
                    Color(0xFF9E9E9E)), // Color del label cuando está enfocado
          ),
          onChanged: (value) {},
        )
      ],
    );
  }
}
