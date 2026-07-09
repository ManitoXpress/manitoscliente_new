import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'terms.dart';
import 'package:audioplayers/audioplayers.dart';

import '../Historial.dart';
import '../Styles/stilo.dart';
import '../home.dart';
import '../controller/auth_utils.dart';
import '../request/ResponsePost.dart';
import '../request/dataprofile.dart';
import '../request/resquest.dart';
import '../utils/compress.dart';
import '../utils/status.dart';
import '../wizards/datalocation.dart';
import '../wizards/dataservice.dart';
import '../wizards/datetime.dart';

class ServiceFormPage extends StatefulWidget {
  final ServiceRequest serviceRequest;
  final bool acceptTerms;
  final List<ServiceRequest> serviceRequests;
  final DateTime? selectedDate;
  final String selectedTime;
  final String selectedServiceTitle;
  final String token;
  final String categoryId;
  final String expertiseId;
  final String expertiseName;
  final UserData userData;

  ServiceFormPage({
    Key? key,
    required this.serviceRequest,
    required this.acceptTerms,
    required this.serviceRequests,
    required this.selectedDate,
    required this.selectedTime,
    required this.selectedServiceTitle,
    required this.token,
    required this.categoryId,
    required this.expertiseId,
    required this.expertiseName,
    required this.userData,
  }) : super(key: key);

  @override
  _ServiceFormPageState createState() => _ServiceFormPageState();
}

class _ServiceFormPageState extends State<ServiceFormPage>
    with TickerProviderStateMixin {
  int currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Cambiar de "late" a nullable para evitar LateInitializationError
  ServiceDataWizard? dataWizard;
  TermsAndConditionsWizard? termsWizard;
  LocationAndFavoritesWizard? locationAndFavoritesWizard;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late UserData userData;

  // Local copies for date/time:
  DateTime? pickedDate;
  TimeOfDay? pickedTime;

  String? token;
  bool isSubmitting = false;

  /// Flag to indicate whether we have finished all of the async initialization.
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    
    // Configurar animaciones
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Inicialización síncrona inmediata
    userData = widget.userData;
    pickedDate = widget.selectedDate;
    
    // Parse selectedTime (which came as a String). If parse fails, keep null.
    try {
      final parsed = DateTime.parse(widget.selectedTime).toLocal();
      pickedTime = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
    } catch (_) {
      pickedTime = null;
    }

    // Crear los wizards inmediatamente
    dataWizard = ServiceDataWizard(
      selectedServiceTitle: widget.selectedServiceTitle,
      serviceRequest: widget.serviceRequest,
      onImageSelected: (image) {
        if (image != null && widget.serviceRequest.images.length < 5) {
          setState(() => widget.serviceRequest.images.add(image.path));
        }
      },
      onPriceSelected: (price) {
        widget.serviceRequest.offeredPrice = price as double;
      },
      onNextStep: () {},
      services: widget.serviceRequests,
      maxImageCount: 5,
    );

    locationAndFavoritesWizard = LocationAndFavoritesWizard(
      location: widget.serviceRequest.location,
      onLocationSelected: (loc) => setState(() {
        widget.serviceRequest.location = {
          'lat': loc.latitude,
          'lng': loc.longitude,
        };
      }),
      onFavoritesSelected: (fav) =>
          setState(() => widget.serviceRequest.isFavorite = fav),
      onNextStep: () {},
    );

    termsWizard = TermsAndConditionsWizard(
      isChecked: false,
      onAcceptTerms: (accepted) =>
      widget.serviceRequest.acceptedTerms = accepted,
      onNextStep: () {},
    );

    // Marcar como inicializado
    _initialized = true;
    
    // Iniciar animación
    _animationController.forward();
    
    // Cargar datos asíncronos después
    _loadAsyncData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAsyncData() async {
    try {
      // Solo obtenemos el token de AuthUtils
      final t = await AuthUtils.getToken();
      if (mounted) {
        setState(() {
          token = t;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Error al cargar datos: $e');
      }
    }
  }

  void _nextStep() {
    if (currentStep < 2) {
      setState(() => currentStep++);
      _animationController.reset();
      _animationController.forward();
    } else {
      onSubmit();
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() => currentStep--);
      _animationController.reset();
      _animationController.forward();
    }
  }

  void onSubmit() async {
    if (!widget.acceptTerms || token == null || isSubmitting) {
      _showError('Términos no aceptados o token nulo.');
      return;
    }

    if (pickedDate == null || pickedTime == null) {
      _showError('Por favor selecciona fecha y hora.');
      return;
    }

    final dateOnly = DateFormat('yyyy-MM-dd').format(pickedDate!);
    final timeOnly = pickedTime!.format(context);

    setState(() => isSubmitting = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A819A), Color(0xFF0D4A5A)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Enviando datos...',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A819A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Por favor espera un momento',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) throw 'Usuario no autenticado.';
      widget.serviceRequest
        ..userId = firebaseUser.uid
        ..status = StatusUtils.getStatusById('available');

      // Convertir expertises a JSON
      final expertisesJson = jsonEncode(
        widget.serviceRequest.expertises.map((e) => e.toMap()).toList(),
      );

      // Subir imágenes y obtener URLs
      List<String> imageUrls = [];
      for (final path in widget.serviceRequest.images) {
        if (path.isEmpty) continue;
        final file = File(path);
        final compressed = await compressAndResizeImage(file);
        final url = await ApiService()
            .uploadImageToFirebaseStorage(compressed, firebaseUser.uid);
        imageUrls.add(url);
      }

      // Obtener deviceId y authToken
      final devicesId = await AuthUtils.getDeviceId();
      final authToken = await AuthUtils.getToken();

      // Enviar datos al backend
      final response = await ApiService().sendDataToBackend(
        widget.serviceRequest,
        authToken!,
        widget.serviceRequest.status.id,
        expertisesJson,
        widget.categoryId,
        widget.expertiseId,
        widget.serviceRequest.status,
        widget.expertiseName,
        imageUrls,
        devicesId,
        null, // Si el parámetro es obligatorio, enviamos null
        dateOnly,
        timeOnly,
      );

      Navigator.of(context).pop(); // Cerrar diálogo de progreso

      if (response.statusCode == 201) {
        _showSuccess();
      } else {
        _showError('Código: ${response.statusCode}');
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showError(e.toString());
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _showSuccess() async {
    // Reproducir sonido de éxito
    final player = AudioPlayer();
    await player.play(AssetSource('sounds/success.wav'));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                  ),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '¡Éxito!',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Servicio creado correctamente',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeScreen(
                        initialPageIndex: 2,
                        userData: userData,
                      ),
                    ),
                    (_) => false,
                  ),
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
                    'Ir a Historial',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF44336),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF44336),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                msg,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A819A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Cerrar',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index == currentStep;
          final isCompleted = index < currentStep;
          
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: isActive || isCompleted
                          ? const LinearGradient(
                              colors: [Color(0xFF1A819A), Color(0xFF0D4A5A)],
                            )
                          : null,
                      color: isActive || isCompleted ? null : Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                      border: isActive
                          ? Border.all(color: const Color(0xFF1A819A), width: 2)
                          : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : Text(
                              '${index + 1}',
                              style: GoogleFonts.poppins(
                                color: isActive || isCompleted
                                    ? Colors.white
                                    : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStepTitle(index),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive
                          ? const Color(0xFF1A819A)
                          : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  String _getStepTitle(int index) {
    switch (index) {
      case 0:
        return 'Datos del\nServicio';
      case 1:
        return 'Fecha y\nHora';
      case 2:
        return 'Ubicación';
      default:
        return '';
    }
  }

  Widget _buildStepContent() {
    Widget content;
    
    switch (currentStep) {
      case 0:
        content = dataWizard!;
        break;
      case 1:
        content = DateTimeSelectionWizard(
          selectedDate: pickedDate,
          selectedTime: pickedTime,
          onDateSelected: (date) => setState(() => pickedDate = date),
          onTimeSelected: (time) => setState(() => pickedTime = time),
          onNextStep: () {},
        );
        break;
      case 2:
        content = locationAndFavoritesWizard!;
        break;
      default:
        content = const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: content,
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A819A),
                  side: const BorderSide(color: Color(0xFF1A819A)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_back, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Anterior',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A819A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currentStep == 2 ? 'Crear Servicio' : 'Siguiente',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          currentStep == 2 ? Icons.send : Icons.arrow_forward,
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A819A), Color(0xFF0D4A5A)],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
                SizedBox(height: 20),
                Text(
                  'Preparando formulario...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF1A819A)),
        title: Text(
          'Nuevo Servicio',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1A819A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF0F8FF)],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildStepContent(),
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }
}