import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../Styles/stilo.dart';
import '../utils/favoriteubi.dart';

import 'package:location/location.dart' as loc_pkg;

// Modelo para ubicaciones favoritas
class FavoriteLocation {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final String? icon; // Ícono personalizado (casa, trabajo, etc.)

  FavoriteLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.icon,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'icon': icon,
    };
  }

  factory FavoriteLocation.fromJson(Map<String, dynamic> json) {
    return FavoriteLocation(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      createdAt: DateTime.parse(json['createdAt']),
      icon: json['icon'],
    );
  }
}

class LocationAndFavoritesWizard extends StatefulWidget {
  final Map<String, double> location;
  final Function(LatLng selectedLocation) onLocationSelected;
  final Function(bool isFavorite) onFavoritesSelected;
  final Function onNextStep;

  const LocationAndFavoritesWizard({
    required this.location,
    required this.onLocationSelected,
    required this.onFavoritesSelected,
    required this.onNextStep,
    Key? key,
  }) : super(key: key);

  @override
  _LocationAndFavoritesWizardState createState() =>
      _LocationAndFavoritesWizardState();
}

class _LocationAndFavoritesWizardState
    extends State<LocationAndFavoritesWizard>
    with TickerProviderStateMixin {
  LatLng? selectedLocation;
  bool isFavorite = false;
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  final TextEditingController writtenLocationController =
  TextEditingController();
  final TextEditingController additionalInfoController =
  TextEditingController();
  final Completer<GoogleMapController> _controller = Completer();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final LatLng santaCruzDefaultLocation = LatLng(-17.7833, -63.1821);
  final LatLng _initialPosition = LatLng(-17.7833, -63.1833);

  // Mapa de iconos para favoritos
  static const Map<String, IconData> _iconMap = {
    'home': Icons.home,
    'work': Icons.work,
    'fitness_center': Icons.fitness_center,
    'shopping_cart': Icons.shopping_cart,
    'local_hospital': Icons.local_hospital,
    'school': Icons.school,
    'location_on': Icons.location_on,
  };

  @override
  void initState() {
    super.initState();
    
    // Configurar animaciones
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _getCurrentLocation();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  // Nuevo método para guardar ubicación favorita con nombre
  Future<void> _saveFavoriteLocation(LatLng location, String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'favoriteLocations_v2';
      
      // Obtener ubicaciones existentes
      final existingJson = prefs.getString(key) ?? '[]';
      final List<dynamic> existingList = json.decode(existingJson);
      final List<FavoriteLocation> favorites = existingList
          .map((item) => FavoriteLocation.fromJson(item))
          .toList();
      
      // Crear nueva ubicación favorita
      final address = await _getAddressFromLatLng(location);
      final newFavorite = FavoriteLocation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        address: address,
        latitude: location.latitude,
        longitude: location.longitude,
        createdAt: DateTime.now(),
        icon: _getIconForName(name),
      );
      
      // Agregar a la lista
      favorites.add(newFavorite);
      
      // Guardar en SharedPreferences
      final updatedJson = json.encode(favorites.map((f) => f.toJson()).toList());
      await prefs.setString(key, updatedJson);
      
      // Mostrar confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.favorite, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ubicación "$name" guardada en favoritos',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint('Error al guardar ubicación favorita: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al guardar ubicación favorita',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          backgroundColor: const Color(0xFFF44336),
        ),
      );
    }
  }

  // Obtener ícono basado en el nombre
  String _getIconForName(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('casa') || lowerName.contains('home')) return 'home';
    if (lowerName.contains('trabajo') || lowerName.contains('work') || lowerName.contains('oficina')) return 'work';
    if (lowerName.contains('gimnasio') || lowerName.contains('gym')) return 'fitness_center';
    if (lowerName.contains('super') || lowerName.contains('mercado')) return 'shopping_cart';
    if (lowerName.contains('hospital') || lowerName.contains('clínica')) return 'local_hospital';
    if (lowerName.contains('escuela') || lowerName.contains('universidad')) return 'school';
    return 'location_on';
  }

  // Cargar ubicaciones favoritas
  Future<List<FavoriteLocation>> _loadFavoriteLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'favoriteLocations_v2';
      
      final jsonString = prefs.getString(key);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((item) => FavoriteLocation.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error al cargar ubicaciones favoritas: $e');
      return [];
    }
  }

  // Eliminar ubicación favorita
  Future<void> _deleteFavoriteLocation(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'favoriteLocations_v2';
      
      final favorites = await _loadFavoriteLocations();
      favorites.removeWhere((favorite) => favorite.id == id);
      
      final updatedJson = json.encode(favorites.map((f) => f.toJson()).toList());
      await prefs.setString(key, updatedJson);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ubicación eliminada de favoritos',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          backgroundColor: const Color(0xFFFF9800),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Error al eliminar ubicación favorita: $e');
    }
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
      (await _controller.future).animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: curr, zoom: 14),
        ),
      );
    } catch (_) {
      _updateSelectedLocation(santaCruzDefaultLocation);
      (await _controller.future).animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: santaCruzDefaultLocation, zoom: 14),
        ),
      );
    }
  }

  Future<void> _updateSelectedLocation(LatLng loc) async {
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
    if (mapController != null) {
      mapController!.animateCamera(
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
        final place = placemarks.first;
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
            elevation: 0,
            backgroundColor: const Color(0xFF1A819A),
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              'Seleccionar Ubicación',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        GoogleMap(
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
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueBlue),
                            )
                          }
                              : {},
                        ),
                        // Botón flotante de GPS
                        Positioned(
                          top: 20,
                          right: 20,
                          child: FloatingActionButton(
                            onPressed: () async {
                              try {
                                final loc = loc_pkg.Location();
                                if (!await loc.serviceEnabled() && !(await loc.requestService())) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Servicio de ubicación no disponible',
                                        style: GoogleFonts.poppins(),
                                      ),
                                      backgroundColor: const Color(0xFFF44336),
                                    ),
                                  );
                                  return;
                                }
                                
                                var perm = await loc.hasPermission();
                                if (perm == loc_pkg.PermissionStatus.denied &&
                                    await loc.requestPermission() != loc_pkg.PermissionStatus.granted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Permiso de ubicación denegado',
                                        style: GoogleFonts.poppins(),
                                      ),
                                      backgroundColor: const Color(0xFFF44336),
                                    ),
                                  );
                                  return;
                                }
                                
                                final data = await loc.getLocation();
                                final currentLocation = LatLng(data.latitude!, data.longitude!);
                                
                                setStateDialog(() {
                                  tempSelected = currentLocation;
                                });
                                
                                // Animar la cámara a la ubicación actual
                                mapController?.animateCamera(
                                  CameraUpdate.newCameraPosition(
                                    CameraPosition(
                                      target: currentLocation,
                                      zoom: 16,
                                    ),
                                  ),
                                );
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.my_location, color: Colors.white),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Text(
                                            'Ubicación actual marcada',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFF4CAF50),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              } catch (e) {
                                debugPrint('Error al obtener ubicación GPS: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error al obtener ubicación: $e',
                                      style: GoogleFonts.poppins(),
                                    ),
                                    backgroundColor: const Color(0xFFF44336),
                                  ),
                                );
                              }
                            },
                            backgroundColor: const Color(0xFF1A819A),
                            foregroundColor: Colors.white,
                            elevation: 8,
                            child: const Icon(Icons.my_location),
                          ),
                        ),
                        // Botón flotante de ubicaciones favoritas
                        Positioned(
                          top: 20,
                          left: 20,
                          child: FloatingActionButton(
                            onPressed: () async {
                              await _showFavoriteLocationsDialog(setStateDialog, tempSelected);
                            },
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            elevation: 8,
                            child: const Icon(Icons.favorite),
                          ),
                        ),
                        // Botón flotante para agregar ubicación favorita
                        Positioned(
                          top: 90,
                          left: 20,
                          child: FloatingActionButton(
                            onPressed: () async {
                              if (tempSelected != null) {
                                await _showAddFavoriteDialog(tempSelected!);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Primero selecciona una ubicación en el mapa',
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                    backgroundColor: const Color(0xFFFF9800),
                                  ),
                                );
                              }
                            },
                            backgroundColor: const Color(0xFFFF9800),
                            foregroundColor: Colors.white,
                            elevation: 8,
                            child: const Icon(Icons.add_location),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1A819A),
                              side: const BorderSide(color: Color(0xFF1A819A)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancelar',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (tempSelected != null) {
                                if (isFavorite) {
                                  await _persistFavorite(tempSelected!);
                                }
                                await _updateSelectedLocation(tempSelected!);
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Por favor selecciona una ubicación',
                                      style: GoogleFonts.poppins(),
                                    ),
                                    backgroundColor: const Color(0xFFF44336),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A819A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Confirmar Ubicación',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showFavoriteLocationsDialog(Function setStateDialog, LatLng? tempSelected) async {
    final favorites = await _loadFavoriteLocations();
    
    if (favorites.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'No hay ubicaciones favoritas guardadas',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFFF9800),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final maxHeight = MediaQuery.of(context).size.height * 0.8;
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: maxHeight,
                  minWidth: 280,
                ),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ubicaciones Favoritas',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Selecciona una ubicación guardada',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Lista de ubicaciones favoritas
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: favorites.length,
                          itemBuilder: (context, index) {
                            final favorite = favorites[index];
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Icon(
                                    _getIconData(favorite.icon ?? 'location_on'),
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  favorite.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      favorite.address,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Guardado el ${_formatDate(favorite.createdAt)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Botón de eliminar
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: IconButton(
                                        icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 20),
                                        onPressed: () async {
                                          await _deleteFavoriteLocation(favorite.id);
                                          Navigator.of(context).pop();
                                          _showFavoriteLocationsDialog(setState, tempSelected);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Botón de seleccionar
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4CAF50),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.check, color: Colors.white, size: 20),
                                        onPressed: () {
                                          final selectedLocation = LatLng(favorite.latitude, favorite.longitude);
                                          setState(() {
                                            tempSelected = selectedLocation;
                                          });
                                          
                                          // Animar la cámara a la ubicación seleccionada
                                          mapController?.animateCamera(
                                            CameraUpdate.newCameraPosition(
                                              CameraPosition(
                                                target: selectedLocation,
                                                zoom: 16,
                                              ),
                                            ),
                                          );
                                          
                                          Navigator.of(context).pop();
                                          
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(Icons.check_circle, color: Colors.white),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      'Ubicación "${favorite.name}" seleccionada',
                                                      style: GoogleFonts.poppins(fontSize: 14),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: const Color(0xFF4CAF50),
                                              behavior: SnackBarBehavior.floating,
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Botón para agregar nueva ubicación
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            if (tempSelected != null) {
                              _showAddFavoriteDialog(tempSelected!);
                            }
                          },
                          icon: const Icon(Icons.add_location),
                          label: Text(
                            'Agregar Nueva Ubicación',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4CAF50),
                            side: const BorderSide(color: Color(0xFF4CAF50)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Obtener ícono de Material Icons
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'school':
        return Icons.school;
      default:
        return Icons.location_on;
    }
  }

  // Formatear fecha
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Mostrar diálogo para agregar ubicación favorita
  Future<void> _showAddFavoriteDialog(LatLng location) async {
    final TextEditingController nameController = TextEditingController();
    String selectedIcon = 'location_on';
    
    final List<Map<String, dynamic>> iconOptions = [
      {'icon': 'home', 'label': 'Casa'},
      {'icon': 'work', 'label': 'Trabajo'},
      {'icon': 'fitness_center', 'label': 'Gimnasio'},
      {'icon': 'shopping_cart', 'label': 'Supermercado'},
      {'icon': 'local_hospital', 'label': 'Hospital'},
      {'icon': 'school', 'label': 'Escuela'},
      {'icon': 'location_on', 'label': 'Otro'},
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final maxHeight = MediaQuery.of(context).size.height * 0.8;
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: maxHeight,
                  minWidth: 280,
                ),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A819A), Color(0xFF0D4A5A)],
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Guardar Ubicación Favorita',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A819A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Dale un nombre a esta ubicación',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      // Campo de nombre
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Nombre de la ubicación',
                          hintText: 'Ej: Casa, Trabajo, Gimnasio...',
                          prefixIcon: Icon(Icons.edit_location, color: Color(0xFF1A819A)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF1A819A), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      // Selector de ícono
                      Text(
                        'Selecciona un ícono',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A819A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: iconOptions.length,
                          itemBuilder: (context, index) {
                            final option = iconOptions[index];
                            final isSelected = selectedIcon == option['icon'];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedIcon = option['icon'];
                                });
                              },
                              child: Container(
                                width: 70,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF1A819A) : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF1A819A) : Colors.grey[300]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _iconMap[option['icon']] ?? Icons.location_on,
                                      color: isSelected ? Colors.white : Color(0xFF1A819A),
                                      size: 24,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      option['label'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: isSelected ? Colors.white : Color(0xFF1A819A),
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Botones
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1A819A),
                                side: const BorderSide(color: Color(0xFF1A819A)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancelar',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (nameController.text.trim().isNotEmpty) {
                                  Navigator.of(context).pop();
                                  await _saveFavoriteLocation(location, nameController.text.trim());
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Por favor ingresa un nombre para la ubicación',
                                        style: GoogleFonts.poppins(fontSize: 14),
                                      ),
                                      backgroundColor: const Color(0xFFF44336),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A819A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Guardar Favorito',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLocationCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: selectedLocation != null
            ? const LinearGradient(
                colors: [Color(0xFF1A819A), Color(0xFF0D4A5A)],
              )
            : null,
        color: selectedLocation != null ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: selectedLocation != null
                ? const Color(0xFF1A819A).withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: selectedLocation != null ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: selectedLocation != null
            ? null
            : Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: selectedLocation != null
                  ? Colors.white.withOpacity(0.2)
                  : const Color(0xFF1A819A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.location_on,
              color: selectedLocation != null ? Colors.white : const Color(0xFF1A819A),
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ubicación del servicio',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: selectedLocation != null ? Colors.white : const Color(0xFF1A819A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            selectedLocation != null
                ? writtenLocationController.text
                : 'Toca para seleccionar ubicación',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: selectedLocation != null
                  ? Colors.white.withOpacity(0.9)
                  : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A819A), Color(0xFF0D4A5A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A819A).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ubicación del servicio',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selecciona dónde necesitas el servicio',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Selector de ubicación
              GestureDetector(
                onTap: _showMapScreen,
                child: _buildLocationCard(),
              ),
              
              const SizedBox(height: 24),
              
              // Información adicional
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A819A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1A819A).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF1A819A),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ubicación precisa',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A819A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Una ubicación precisa ayuda a los profesionales a llegar más rápido y ofrecer un mejor servicio.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF1A819A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Resumen de selección
              if (selectedLocation != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ubicación seleccionada',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                              ),
                            ),
                            Text(
                              writtenLocationController.text,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.green[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
