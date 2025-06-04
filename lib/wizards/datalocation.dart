import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc_pkg;
import 'package:manitoscliente_new/controller/mapsController.dart';
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
  LatLng? selectedLocation;
  bool isFavorite = false;
  late GoogleMapController mapController;
  Set<Marker> markers = {};
  TextEditingController writtenLocationController = TextEditingController();
  Uint8List? mapSnapshot;
  TextEditingController additionalInfoController = TextEditingController();
  Completer<GoogleMapController> _controller = Completer();
  final LatLng santaCruzDefaultLocation = LatLng(-17.7833, -63.1821);
  final LatLng _initialPosition = LatLng(-17.7833, -63.1833);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _persistFavorite(LatLng loc) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'favoriteLocations';
    List<String> favs = prefs.getStringList(key) ?? [];
    final entry = '${loc.latitude},${loc.longitude}';
    if (!favs.contains(entry)) {
      favs.add(entry);
      await prefs.setStringList(key, favs);
    }
    widget.onFavoritesSelected(true);
    widget.onLocationSelected(loc);
  }

  Future<void> _getCurrentLocation() async {
    try {
      final loc = loc_pkg.Location();
      if (!await loc.serviceEnabled() && !(await loc.requestService())) {
        return;
      }
      var perm = await loc.hasPermission();
      if (perm == loc_pkg.PermissionStatus.denied &&
          await loc.requestPermission() != loc_pkg.PermissionStatus.granted) {
        return;
      }
      final data = await loc.getLocation();
      final curr = LatLng(data.latitude!, data.longitude!);
      _updateSelectedLocation(curr);
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: curr, zoom: 14),
        ),
      );
    } catch (_) {
      _updateSelectedLocation(santaCruzDefaultLocation);
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: santaCruzDefaultLocation, zoom: 14),
        ),
      );
    }
  }

  void _updateSelectedLocation(LatLng loc) async {
    widget.onLocationSelected(loc);
    final address = await _getAddressFromLatLng(loc);
    setState(() {
      selectedLocation = loc;
      markers = {
        Marker(
          markerId: MarkerId(loc.toString()),
          position: loc,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        )
      };
      writtenLocationController.text = address;
    });

    // Centra el mapa en la ubicación seleccionada
    if (mapController != null) {
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: loc, zoom: 14),
        ),
      );
    }
  }

  Future<String> _getAddressFromLatLng(LatLng latLng) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return "${place.street}, ${place.locality}, ${place.country}";
      }
    } catch (_) {}
    return "Ubicación desconocida";
  }

  Future<void> _showMapScreen() async {
    LatLng? tempSelected = selectedLocation;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            iconTheme: IconThemeData(color: Colors.white),
            title: Text(
              'Seleccionar Ubicación',
              style: MyTextStyles.buttonTextStyle,
            ),
          ),
          body: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                children: [
                  Expanded(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: tempSelected ?? _initialPosition,
                        zoom: 14,
                      ),
                      onMapCreated: (controller) {
                        mapController = controller;
                      },
                      onTap: (loc) {
                        setStateDialog(() {
                          tempSelected = loc;
                        });
                      },
                      markers: tempSelected != null
                          ? {
                              Marker(
                                markerId: MarkerId(tempSelected.toString()),
                                position: tempSelected!,
                              )
                            }
                          : {},
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Volver',
                            style: MyTextStyles.tabTextStyle1,
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
                          if (tempSelected != null) {
                            if (isFavorite) {
                              await _persistFavorite(tempSelected!);
                            }
                            _updateSelectedLocation(tempSelected!);
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Por favor, selecciona una ubicación.')),
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Seleccionar',
                            style: MyTextStyles.tabTextStyle1,
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
              );
            },
          ),
        ),
      ),
    );
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
                SizedBox(
                  height: 75,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _showMapScreen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1A819A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Center(
                      // Centrar el texto
                      child: Text(
                        'Click para seleccionar ubicación',
                        style: MyTextStyles.buttonTextStyle,
                        textAlign: TextAlign
                            .center, // Esto también asegura que el texto esté centrado
                      ),
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
          onChanged: (val) async {
            setState(() => isFavorite = val);
            if (val && selectedLocation != null) {
              await _persistFavorite(selectedLocation!);
            }
          },
          activeColor: Color(0xFF1A819A), // Color cuando está activado
          inactiveTrackColor: Colors.grey, // Color cuando está desactivado
          inactiveThumbColor: const Color.fromRGBO(0, 0, 0, 1),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            final LatLng? fav = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FavoriteLocationsScreen()),
            );
            if (fav != null) {
              _updateSelectedLocation(fav);
            }
          },
          icon: Icon(Icons.star, color: Color(0xFF1A819A)),
          label: Align(
            alignment: Alignment.centerLeft,
            child: Text("Ubicaciones Favoritas",
                style: MyTextStyles.linkTextStyle),
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
          controller: additionalInfoController,
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
