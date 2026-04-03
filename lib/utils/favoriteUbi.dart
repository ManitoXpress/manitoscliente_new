import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/services.dart';

import '../Styles/stilo.dart';
import '../wizards/datalocation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/services.dart';

import '../Styles/stilo.dart';
import '../wizards/datalocation.dart';

class FavoriteLocationsScreen extends StatefulWidget {
  @override
  _FavoriteLocationsScreenState createState() =>
      _FavoriteLocationsScreenState();
}

class _FavoriteLocationsScreenState extends State<FavoriteLocationsScreen> {
  final TextEditingController _locationController = TextEditingController();
  List<String> _favoriteLocations = [];

  @override
  void initState() {
    super.initState();
    _loadFavoriteLocations();
  }

  // Cargar ubicaciones favoritas desde SharedPreferences
  _loadFavoriteLocations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoriteLocations = prefs.getStringList('favoriteLocations') ?? [];
    });
  }

  // Guardar ubicación en SharedPreferences
  _saveLocation() async {
    if (_locationController.text.isNotEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _favoriteLocations.add(_locationController.text);
      await prefs.setStringList('favoriteLocations', _favoriteLocations);
      _locationController.clear();
      _loadFavoriteLocations();
    }
  }

  // Eliminar una ubicación de la lista de favoritos
  _removeFavoriteLocation(String location) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _favoriteLocations.remove(location); // Eliminar la ubicación de la lista
    await prefs.setStringList('favoriteLocations',
        _favoriteLocations); // Guardar la lista actualizada
    setState(() {
      // Actualizar el estado para reflejar el cambio en la interfaz
    });
  }

  // Copiar una ubicación al portapapeles
  _copyLocationToClipboard(String location) {
    Clipboard.setData(ClipboardData(text: location)); // Copiar al portapapeles
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ubicación copiada al portapapeles')),
    );
  }

  void _navigateToLocationAndFavoritesWizard(String location) async {
    try {
      // Convertir la dirección guardada en coordenadas (geocodificación)
      List<Location> locations = await locationFromAddress(location);
      if (locations.isNotEmpty) {
        LatLng coords = LatLng(locations[0].latitude, locations[0].longitude);
        // Retornar las coordenadas a la pantalla anterior (LocationAndFavoritesWizard)
        Navigator.pop(context, coords);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo encontrar la ubicación')),
        );
      }
    } catch (e) {
      null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar la ubicación')),
      );
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Ubicaciones Favoritas',
          style: MyTextStyles.buttonTextStyle,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: "Agregar Ubicacion",
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                focusColor: Color(0xFF1A819A),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color(0xFF1A819A),
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveLocation,
              child: Text(
                'Guardar Ubicación',
                style: MyTextStyles.drawerButtonLabelTextStyle,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A819A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Ubicaciones Guardadas:',
              style: MyTextStyles.drawerButtonTextStyle1,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _favoriteLocations.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      _favoriteLocations[index],
                      style: MyTextStyles.formServiceTextStyle,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Botón de copiar
                        IconButton(
                          icon: Icon(Icons.copy),
                          onPressed: () => _copyLocationToClipboard(
                              _favoriteLocations[index]),
                        ),
                        // Botón de eliminar
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _removeFavoriteLocation(
                              _favoriteLocations[index]),
                        ),
                        // Botón de seleccionar para abrir LocationAndFavoritesWizard
                        IconButton(
                          icon: Icon(Icons.location_on),
                          onPressed: () {
                            final location = _favoriteLocations[index];
                            _navigateToLocationAndFavoritesWizard(location);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
