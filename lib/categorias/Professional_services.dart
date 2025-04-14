import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:searchbar_animation/searchbar_animation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../Styles/stilo.dart';
import '../metodos/auth_utils.dart';
import '../metodos/home_screen_functions.dart';
import '../request/ResponseGet.dart';
import '../request/requestExpertise.dart';
import '../request/requestServiceType.dart';
import '../request/resquest.dart';
import '../utils/status.dart';
import 'Service_DetailsScreen.dart';
class ProfessionalServicesScreen extends StatefulWidget {
  static int notificationCount = 0;
  @override
  _ProfessionalServicesScreenState createState() =>
      _ProfessionalServicesScreenState();
}

class _ProfessionalServicesScreenState
    extends State<ProfessionalServicesScreen> {
  late List<ServiceResponse> services = [];
  int _selectedServiceIndex = -1;

  String selectedButtonType = '';
  int notificationCount = 0;
  bool _showClearButton = false;
  TextEditingController _textEditingController = TextEditingController();
  late ScrollController _scrollController;
  String selectedCategoryId = "";
  String subcategoryName = '';

  List<ServiceResponse> subcategoriesToShow = [];
  List<ServiceResponse> filteredSubcategories = []; // Lista filtrada para búsqueda
  TextEditingController searchController = TextEditingController();
  String searchText = '';
  bool _isSearching = false; // Para controlar cuando se está buscando
  late ApiService2 _apiService2 =
      ApiService2(); // Crea una instancia de ApiService2
  String getFormattedDateTime() {
    DateTime now = DateTime.now().toUtc();
    String formattedDateTime = now.toIso8601String();
    return formattedDateTime;
  }

  void openNewPage(
      ServiceType serviceType,
      List<Expertise> expertises, // Cambio aquí: usaremos List<Expertise>
      String categoryId,
      String expertiseId,
      String expertiseName,
      BuildContext context) {
    print(
        'Abriendo formulario para ${expertises.map((e) => e.name).join(', ')}');

    // Obtén el objeto Status basado en el nombre del estado utilizando StatusUtils
    final status = StatusUtils.getStatusById(
        expertises.isNotEmpty ? expertises.first.id : '');

    // Formatea la fecha y hora actual en formato ISO 8601
    final formattedDateTime = getFormattedDateTime();

    // Formatea la fecha seleccionada en el formato requerido
    String? formattedSelectedDate;
    if (serviceType.selectedDate != null &&
        serviceType.selectedDate.isNotEmpty) {
      final selectedDateTime = DateTime.tryParse(serviceType.selectedDate);

      if (selectedDateTime != null) {
        formattedSelectedDate = selectedDateTime.toUtc().toIso8601String();
      } else {
        print('Fecha en formato incorrecto: ${serviceType.selectedDate}');
        return;
      }
    } else {
      // Si selectedDate es nulo o está vacío, asignar la fecha y hora actual en formato ISO 8601
      final now = DateTime.now().toUtc();
      formattedSelectedDate = now.toIso8601String();
    }

    // Crea una instancia de ServiceRequest con la información del servicio
    final serviceRequest = ServiceRequest(
      serviceDateTime: formattedDateTime,
      description: '',
      images: [],
      location: {'lat': 0.0, 'lng': 0.0},
      offeredPrice: 0.0,
      serviceType: serviceType, // Pasa el objeto ServiceType directamente
      userId: '', // Reemplaza con el usuario real
      workerId: '',
      isFavorite: false,
      selectedDate: formattedSelectedDate,
      selectedTime: serviceType.selectedTime ?? '',
      acceptedTerms: true,
      id: '',
      status: status, // Utiliza el objeto Status obtenido de StatusUtils
      expertises:
          expertises, // Usa la lista de Expertises (debería ser List<Expertise>)

      devicesId: '',
      hasOffer: false,
      offers: [],
      subcategoryName: subcategoryName, // Usa la lista de Expertises
    );

    // Llama al formulario del servicio con el serviceRequest y los ids de categoría y subcategoría
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceFormPage(
          serviceRequest: serviceRequest,
          acceptTerms: true,
          selectedDate: DateTime.now(), // Usar una fecha predeterminada
          token: '', // Proporciona un token válido
          selectedServiceTitle: expertises
              .map((e) => e.name)
              .join(', '), // Agrega los nombres de expertises
          selectedTime: '',
          serviceRequests: [], // Agrega el título del servicio
          categoryId: categoryId, // Pasa categoryId
          expertiseId: expertiseId, // Pasa subcategoryId
          expertiseName: expertiseName,
        ),
      ),
    );

    print('Formulario abierto');
  }

  // Define una función para cargar los servicios
  Future<void> _loadServices() async {
    print('Cargando servicios...');

    try {
      // Obtén el token
      String? token = await AuthUtils.getToken();

      if (token != null) {
        print('Token: $token');

        // Carga datos desde el almacenamiento local antes de llamar al backend
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final cachedServices = prefs.getString('cached_services');
        final cacheTimestamp = prefs.getInt('cache_timestamp');

        if (cachedServices != null) {
          // Deserializa los servicios en caché
          final List<dynamic> decodedJson = jsonDecode(cachedServices);
          final List<ServiceResponse> cachedServiceResponses = decodedJson
              .map((json) => ServiceResponse.fromJson(json))
              .toList();

          // Muestra los servicios en caché inmediatamente
          setState(() {
            subcategoriesToShow = cachedServiceResponses;
            filteredSubcategories = cachedServiceResponses; // Inicializar la lista filtrada
          });

          print('Servicios cargados desde caché.');
        }

        // Verifica si el caché es reciente (por ejemplo, 1 hora)
        final now = DateTime.now().millisecondsSinceEpoch;
        final isCacheStale =
            cacheTimestamp == null || (now - cacheTimestamp > 3600000);

        if (isCacheStale || cachedServices == null) {
          // Llama al backend si el caché está vacío o desactualizado
          String parentId = 'wZvEJHJ6Q2eBOEWn3if2';

          final List<ServiceResponse> serviceResponses =
              await _apiService2.fetchServicesFromBackend2(token, parentId);

          // Ordena y actualiza el estado con los servicios del servidor
          serviceResponses.sort((a, b) => a.name.compareTo(b.name));
          setState(() {
            subcategoriesToShow = serviceResponses;
            filteredSubcategories = serviceResponses; // Inicializar la lista filtrada
          });

          // Guarda los datos en caché
          prefs.setInt('cache_timestamp', now);

          print('Servicios cargados del backend y almacenados en caché.');
        }
      } else {
        print('No se pudo obtener el token.');
      }
    } catch (e) {
      print('Error al cargar los servicios: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Llama a la función para obtener los servicios desde el backend aquí
    _loadServices();
    
    // Añadir listener para controlar la visibilidad del botón de limpiar
    _textEditingController.addListener(() {
      setState(() {
        _showClearButton = _textEditingController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Nueva función para cargar servicios principales y subcategorías
  List<ServiceResponse> loadSubcategories(
      List<ServiceResponse> allServices, String categoryId) {
    return allServices
        .where((service) => service.parentId == categoryId)
        .toList();
  }

  // En tu función loadServicesForSubcategory, carga las subcategorías específicas
  void loadServicesForSubcategory(String categoryId) {
    // Limpia la selección actual
    final subcategories = loadSubcategories(subcategoriesToShow, categoryId);

    setState(() {
      subcategoriesToShow = subcategories;
      filteredSubcategories = subcategories; // Actualizar la lista filtrada
      searchText = ''; // Limpiar el texto de búsqueda
      _textEditingController.clear(); // Limpiar el campo de búsqueda
    });
  }

  // Método para filtrar servicios según el texto de búsqueda
  void _filterServices(String query) {
    setState(() {
      searchText = query;
      if (query.isEmpty) {
        filteredSubcategories = subcategoriesToShow;
      } else {
        filteredSubcategories = subcategoriesToShow
            .where((service) =>
                service.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
      
      // Si hay un servicio seleccionado y ya no está en la lista filtrada, deseleccionarlo
      if (_selectedServiceIndex != -1) {
        final selectedId = subcategoriesToShow[_selectedServiceIndex].id;
        if (!filteredSubcategories.any((service) => service.id == selectedId)) {
          _selectedServiceIndex = -1;
        }
      }
    });
  }

  void _showNotifications(BuildContext context) {
    ServiceFunctions.showNotifications(
      context,
      title: 'Nuevo Servicio Creado',
      body: 'Haz clic para ver los detalles del servicio.',
    );
  }

  void _limpiarTextoBusqueda() {
    setState(() {
      searchText = '';
      _showClearButton = false;
      _textEditingController.clear();
      filteredSubcategories = subcategoriesToShow; // Restaurar la lista original
    });
  }

  void _toggleSearchMode() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _limpiarTextoBusqueda();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        automaticallyImplyLeading: true,
        title: _isSearching
            ? Container(
                width: double.infinity,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _textEditingController,
                  onChanged: _filterServices,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 0),
                    hintText: 'Buscar servicios...',
                    border: InputBorder.none,
                    suffixIcon: _showClearButton
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Color(0xFF1A819A)),
                            onPressed: _limpiarTextoBusqueda,
                          )
                        : null,
                  ),
                ),
              )
            : Text(
                'Servicios de hogar',
                style: MyTextStyles.buttonTextStyle,
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: _toggleSearchMode,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          // Cierra el cuadro deslizable al tocar fuera de él
          if (_selectedServiceIndex != -1) {
            setState(() {
              _selectedServiceIndex = -1;
            });
          }
        },
        child: Container(
          color: Color(0xFF6AB8D6), // Cambiado el color de fondo
          child: Column(
            children: [
              SizedBox(height: 20),
              filteredSubcategories.isEmpty
                  ? Expanded(
                      child: Center(
                        child: Text(
                          'No se encontraron servicios',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : Expanded(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 10),
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 20.0,
                            mainAxisSpacing: 20.0,
                          ),
                          itemCount: filteredSubcategories.length,
                          itemBuilder: (context, index) {
                            final subcategory = filteredSubcategories[index];
                            return GestureDetector(
                              onTap: () {
                                _onSubcategoryTap(subcategory);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1A819A).withOpacity(0.15),
                                      spreadRadius: 0.5,
                                      blurRadius: 2,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white70,
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(50),
                                        child: CachedNetworkImage(
                                          imageUrl: subcategory.image,
                                          height: 80,
                                          width: 80,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              CircularProgressIndicator(),
                                          errorWidget: (context, url, error) =>
                                              Icon(Icons.error),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      subcategory.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: MyTextStyles.drawerButtonTextStyle1,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
              SizedBox(height: 10),
              // Cuadro deslizable desde abajo
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeOut,
                height: _selectedServiceIndex != -1 ? 500 : 0,
                alignment: Alignment.bottomCenter,
                child: _selectedServiceIndex != -1
                    ? Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        // Ajusta el padding para el espacio adicional y márgenes laterales
                        child: _buildServiceDetails(),
                      )
                    : null,
              ),
              if (selectedButtonType.isNotEmpty)
                Text(
                  'Tipo de botón seleccionado: $selectedButtonType',
                  style: const TextStyle(fontSize: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceDetails() {
    // Necesitamos encontrar el servicio seleccionado en la lista filtrada
    if (_selectedServiceIndex < 0 ||
        _selectedServiceIndex >= subcategoriesToShow.length) {
      return Container(); // No mostrar si el índice es inválido.
    }

    final selectedService = subcategoriesToShow[_selectedServiceIndex];
    final subcategory = filteredSubcategories.firstWhere(
      (service) => service.id == selectedService.id,
      orElse: () => selectedService,
    );

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 4,
      margin: EdgeInsets.all(10),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                subcategory.name,
                style: MyTextStyles.titleTextStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                subcategory.description,
                style: MyTextStyles.formServiceTextStyle,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.arrow_drop_down, // Ícono de flecha hacia abajo
                    color: Color(0xFF20819A),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Deslice hacia abajo para más:',
                    style: TextStyle(
                      color: Color(0xFF20819A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                alignment:
                    WrapAlignment.center, // Alinear los botones al centro
                direction: Axis
                    .horizontal, // Asegurar que los botones se distribuyan horizontalmente
                children:
                    subcategory.serviceTypes.map((ServiceType serviceType) {
                  return SizedBox(
                    width: MediaQuery.of(context).size.width *
                        0.8, // Ancho del botón (40% del ancho de la pantalla)
                    child: ElevatedButton(
                      onPressed: () {
                        // Obtén categoryId y subcategoryId de la subcategoría seleccionada
                        final categoryId = subcategory.parentId;
                        final subcategoryId = subcategory.id;
                        final subcategoryName = subcategory.name;

                        // Asegúrate de tener una lista de Expertises, no una cadena
                        final List<Expertises> expertises =
                            []; // Aquí debes obtener los expertises correspondientes.

                        // Llama a openNewPage con todos los argumentos necesarios
                        openNewPage(
                          serviceType,
                          List<Expertise>.from(
                              expertises), // Conversión explícita de Expertises a Expertise
                          categoryId!,
                          subcategoryId,
                          subcategoryName,
                          context,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF20819A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 4,
                        minimumSize: Size(0, 50), // Altura mínima del botón
                        maximumSize: Size(double.infinity,
                            50), // Altura máxima del botón (ancho completo)
                      ),
                      child: Text(
                        serviceType.name,
                        style: MyTextStyles.buttonTextStyle,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSubcategoryTap(ServiceResponse subcategory) {
    if (subcategory.id.isNotEmpty) {
      // Encontrar el índice en la lista original, no en la filtrada
      final index = subcategoriesToShow
          .indexWhere((service) => service.id == subcategory.id);

      if (index != -1) {
        setState(() {
          _selectedServiceIndex = index;
        });
      }
    }
  }
}