import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para HapticFeedback
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../controller/auth_utils.dart';
import '../provider/dataProvider.dart';
import '../request/ResponseGet.dart';
import '../request/requestServiceType.dart';
import '../request/resquest.dart';
import '../utils/status.dart';
import 'Service_DetailsScreen.dart';

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({Key? key}) : super(key: key);

  @override
  _ServiceScreenState createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  final ApiService2 _apiService2 = ApiService2();
  
  List<ServiceResponse> _allServices = [];
  List<ServiceResponse> _displayedServices = [];
  List<ServiceResponse> _recommendedServices = [];
  List<ServiceResponse> _parentCategories = []; // Para las pestañas
  
  String _selectedParentId = 'all'; // 'all' para mostrar todos
  bool _isLoading = true;
  
  final TextEditingController _searchController = TextEditingController();

  // Design Colors - Teal Theme (Basado en 0xFF1A819A)
  final Color azureWhite = const Color(0xFFF4F9FA);   // Fondo principal
  final Color pureWhite = const Color(0xFFFFFFFF);    // Tarjetas
  final Color tealAccent = const Color(0xFF1A819A);   // Color principal/Acentos
  final Color deepTealText = const Color(0xFF0F3A45); // Tipografía

  @override
  void initState() {
    super.initState();
    _loadAllServices();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeDialog();
    });
  }

  void _showWelcomeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: pureWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          title: Text(
            '¡Bienvenido a ManitosXpress!',
            style: TextStyle(
              color: deepTealText,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'En ManitosXpress, estamos para ayudarte a encontrar soluciones a tus problemas. ¿Necesitas ayuda con algún servicio en específico? ¡Tenemos una amplia gama de servicios disponibles!',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Icon(
                Icons.handyman,
                size: 60,
                color: tealAccent,
              ),
              const SizedBox(height: 20),
              Text(
                'Encuentra el servicio que necesitas, desde reparaciones hasta asesorías. ¡Estamos para ayudarte!',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: tealAccent,
                  foregroundColor: pureWhite,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text("Empezar", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadAllServices() async {
    try {
      String? token = await AuthUtils.getToken();
      if (token == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 1. Obtener categorias padre
      final parentCategories = await _apiService2.fetchServicesFromBackend(token);
      
      List<ServiceResponse> tempServices = [];
      
      // 2. Por cada categoría padre, obtener sub-categorías concurrentemente
      List<Future<List<ServiceResponse>>> fetchTasks = [];
      for (var parent in parentCategories) {
        fetchTasks.add(_apiService2.fetchServicesFromBackend2(token, parent.id));
      }

      final results = await Future.wait(fetchTasks);
      
      for (int i = 0; i < parentCategories.length; i++) {
        var children = results[i];
        for (var child in children) {
          // Asegurar que cada hijo tenga el parentId correcto localmente
          if (child.parentId == null || child.parentId!.isEmpty) {
             // Este fallback asume que si viene vacío, hereda del padre
             // Para Dart no podemos mutarlo fácilmente si no hay setter, 
             // confiamos en que parentId en API viene con parent.id
          }
        }
        tempServices.addAll(children);
      }

      if (mounted) {
        setState(() {
            _parentCategories = parentCategories;
            _allServices = tempServices;
            _displayedServices = tempServices;
            // Recomendados: tomamos algunos genéricos o los primeros
            if (tempServices.isNotEmpty) {
              _recommendedServices = tempServices.take(5).toList();
            }
            _isLoading = false;
        });
      }
      
    } catch (e) {
      null;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
     List<ServiceResponse> filtered = _allServices;
     
     // Filtrar por categoría padre (Hogar / Profesionales)
     if (_selectedParentId != 'all') {
       filtered = filtered.where((s) => s.parentId == _selectedParentId).toList();
     }
     
     // Filtrar por texto
     final query = _searchController.text.toLowerCase();
     if (query.isNotEmpty) {
       filtered = filtered.where((s) => s.name.toLowerCase().contains(query)).toList();
     }
     
     setState(() {
       _displayedServices = filtered;
     });
  }

  void _setFilter(String parentId) {
    setState(() {
      _selectedParentId = parentId;
    });
    _applyFilters();
  }

  void _filterServices(String query) {
    _applyFilters();
  }

  void _navigateToBooking(ServiceResponse svc, ServiceType type) async {
    final userData = context.read<UserDataProvider>().userData;
    final nowIso = DateTime.now().toUtc().toIso8601String();
    
    final status = StatusUtils.getStatusById('');
    final req = ServiceRequest(
      id: '',
      serviceDateTime: nowIso,
      description: '',
      images: [],
      location: {'lat': 0.0, 'lng': 0.0},
      offeredPrice: 0.0,
      serviceType: type,
      userId: userData.userId,
      workerId: '',
      isFavorite: false,
      selectedDate: nowIso,
      selectedTime: type.selectedTime ?? '',
      acceptedTerms: true,
      status: status,
      expertises: [],
      devicesId: '',
      hasOffer: false,
      offers: [],
      subcategoryName: svc.name,
      createdAt: DateTime.now(),
    );

    String? token = await AuthUtils.getToken();
    if (!mounted) return;
    
    Navigator.pop(context); // Cerrar el bottom sheet
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceFormPage(
          serviceRequest: req,
          acceptTerms: true,
          selectedDate: DateTime.now(),
          token: token ?? '',
          selectedServiceTitle: type.name,
          selectedTime: '',
          serviceRequests: [],
          categoryId: svc.parentId ?? '',
          expertiseId: svc.id,
          expertiseName: svc.name,
          userData: userData,
        ),
      ),
    );
  }

  void _showServiceOptions(ServiceResponse svc) {
    HapticFeedback.lightImpact(); // Feedback háptico premium
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: pureWhite.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: tealAccent.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                )
              ]
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 Container(
                   width: 50,
                   height: 5,
                   decoration: BoxDecoration(
                     color: Colors.grey[300],
                     borderRadius: BorderRadius.circular(10),
                   ),
                 ),
                 const SizedBox(height: 20),
                 Text(
                   svc.name, 
                   style: TextStyle(
                     fontSize: 22, 
                     fontWeight: FontWeight.bold, 
                     color: deepTealText,
                   ),
                   textAlign: TextAlign.center,
                 ),
                 const SizedBox(height: 10),
                 Text(
                   'Selecciona el tipo de servicio que deseas reservar',
                   style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                   textAlign: TextAlign.center,
                 ),
                 const SizedBox(height: 30),
                 ...svc.serviceTypes.map((type) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tealAccent,
                          foregroundColor: pureWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          minimumSize: const Size(double.infinity, 55),
                          elevation: 0,
                        ),
                        onPressed: () => _navigateToBooking(svc, type),
                        child: Text(
                          type.name, 
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                 }).toList(),
                 const SizedBox(height: 20),
              ]
            )
          )
        );
      }
    );
  }

  Widget _buildTab(String id, String name) {
    final isSelected = _selectedParentId == id;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _setFilter(id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? tealAccent : pureWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? tealAccent : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: tealAccent.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Center(
          child: Text(
            name,
            style: TextStyle(
              color: isSelected ? pureWhite : deepTealText,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBentoCard(ServiceResponse svc) {
    return GestureDetector(
      onTap: () => _showServiceOptions(svc),
      child: Container(
        decoration: BoxDecoration(
          color: pureWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: tealAccent.withOpacity(0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: tealAccent.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: svc.image,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(child: CircularProgressIndicator(color: tealAccent)),
                    errorWidget: (context, url, error) => Icon(Icons.error, color: tealAccent, size: 40),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Text(
                svc.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: deepTealText,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        )
      )
    );
  }

  Widget _buildRecommendedCard(ServiceResponse svc) {
    return GestureDetector(
      onTap: () => _showServiceOptions(svc),
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 16, bottom: 10, top: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [tealAccent, tealAccent.withOpacity(0.65)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: tealAccent.withOpacity(0.25),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: pureWhite,
                ),
                padding: const EdgeInsets.all(2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: svc.image,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(strokeWidth: 2, color: tealAccent),
                    ),
                    errorWidget: (context, url, error) => Icon(Icons.error, color: tealAccent),
                  )
                ),
              )
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Text(
                       svc.name, 
                       style: TextStyle(color: pureWhite, fontWeight: FontWeight.bold, fontSize: 16, height: 1.2),
                       maxLines: 2,
                       overflow: TextOverflow.ellipsis,
                     ),
                     const SizedBox(height: 6),
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                       decoration: BoxDecoration(
                         color: pureWhite.withOpacity(0.25),
                         borderRadius: BorderRadius.circular(10),
                       ),
                       child: Text(
                         "Reserva ahora", 
                         style: TextStyle(color: pureWhite, fontSize: 11, fontWeight: FontWeight.w600),
                       ),
                     ),
                  ]
                )
              )
            )
          ]
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Evitar cierre con botón atrás
      child: Scaffold(
        backgroundColor: azureWhite,
        body: SafeArea(
          child: _isLoading 
            ? Center(child: CircularProgressIndicator(color: tealAccent))
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header & Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 30, 24, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "¿Qué necesitas hoy?",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: deepTealText,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Encuentra los mejores profesionales para tu hogar",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Search Bar
                          Container(
                            decoration: BoxDecoration(
                              color: pureWhite,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: tealAccent.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: _filterServices,
                              style: TextStyle(color: deepTealText, fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                hintText: 'Buscar servicios...',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                border: InputBorder.none,
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Icon(Icons.search, color: tealAccent, size: 28),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Category Filters / Tabs
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 15, bottom: 5),
                      child: SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          children: [
                            _buildTab('all', 'Todos'),
                            ..._parentCategories.map((parent) => _buildTab(parent.id, parent.name)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Recommended Section
                  if (_recommendedServices.isNotEmpty && _searchController.text.isEmpty && _selectedParentId == 'all')
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 25, 24, 10),
                            child: Text(
                              "Recomendados para ti",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: deepTealText,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 160,
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _recommendedServices.length,
                              itemBuilder: (context, index) {
                                 return _buildRecommendedCard(_recommendedServices[index]);
                              }
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Bento Box Grid Title
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 25, 24, 10),
                      child: Text(
                        _selectedParentId == 'all' && _searchController.text.isEmpty 
                            ? "Todos los servicios" 
                            : "Resultados",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: deepTealText,
                        ),
                      ),
                    ),
                  ),

                  // Bento Box Grid
                  _displayedServices.isEmpty 
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Center(
                          child: Text(
                            "No se encontraron servicios",
                            style: TextStyle(color: Colors.grey[500], fontSize: 16),
                          ),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.82,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _buildBentoCard(_displayedServices[index]);
                          },
                          childCount: _displayedServices.length,
                        ),
                      ),
                    ),
                ],
              ),
        ),
      ),
    );
  }
}
