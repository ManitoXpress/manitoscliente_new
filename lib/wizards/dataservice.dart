import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../Styles/stilo.dart';
import '../provider/providerController.dart';
import '../request/ResponsePost.dart';
import '../request/requestServiceType.dart';
import '../request/resquest.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:provider/provider.dart';

class ServiceDataWizard extends StatefulWidget {
  final ServiceRequest serviceRequest;
  final Function(File?) onImageSelected;
  final Function(String?) onPriceSelected;
  final Function()? onNextStep;
  final int maxImageCount;
  final String selectedServiceTitle;
  final List<ServiceRequest> services;

  const ServiceDataWizard({
    Key? key,
    required this.serviceRequest,
    required this.onImageSelected,
    required this.onPriceSelected,
    required this.onNextStep,
    required this.selectedServiceTitle,
    required this.services,
    required this.maxImageCount,
  }) : super(key: key);

  @override
  _ServiceDataWizardState createState() => _ServiceDataWizardState();
}

class _ServiceDataWizardState extends State<ServiceDataWizard>
    with TickerProviderStateMixin {
  TextEditingController detailController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ServiceDataProvider>(context, listen: false);
      provider.loadFromServiceRequest(
          widget.serviceRequest, widget.selectedServiceTitle);

      detailController.text = provider.description;
      if (provider.offeredPrice != null) {
        priceController.text = provider.offeredPrice.toString();
      }

      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    detailController.dispose();
    priceController.dispose();
    super.dispose();
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isIOS) {
      // Verifica el estado actual
      PermissionStatus cameraStatus = await Permission.camera.status;
      PermissionStatus photosStatus = await Permission.photos.status;

      // Si están denegados permanentemente, abre configuración
      if (cameraStatus.isPermanentlyDenied ||
          photosStatus.isPermanentlyDenied) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Permisos requeridos'),
            content: Text(
                'Debes habilitar los permisos de cámara y fotos en Configuración para poder adjuntar imágenes.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancelar'),
              ),
            ],
          ),
        );
        return false;
      }

      // Si no están concedidos, solicítalos
      if (!cameraStatus.isGranted)
        cameraStatus = await Permission.camera.request();
      if (!photosStatus.isGranted)
        photosStatus = await Permission.photos.request();

      return cameraStatus.isGranted && photosStatus.isGranted;
    } else {
      // Android
      final statuses = await [
        Permission.camera,
        Permission.storage,
      ].request();
      return statuses.values.every((status) => status.isGranted);
    }
  }

  Future<void> _pickImage() async {
    // Verificar si el widget está montado
    if (!mounted) return;

    // Guardamos estado antes de abrir diálogo
    final currentState = {
      'description': detailController.text,
      'price': priceController.text,
    };

    try {
      // Solicitamos permisos

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.transparent,
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
                Text(
                  'Selecciona la fuente de la imagen',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A819A),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildImageSourceButton(
                        icon: Icons.photo_library,
                        label: 'Galería',
                        onTap: () async {
                          Navigator.of(context).pop();
                          await _selectImageFromGallery(currentState);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildImageSourceButton(
                        icon: Icons.camera_alt,
                        label: 'Cámara',
                        onTap: () async {
                          Navigator.of(context).pop();
                          await _selectImageFromCamera(currentState);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Error en _pickImage: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al abrir selector de imágenes: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFFF44336),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _selectImageFromGallery(Map<String, String> currentState) async {
    try {
      if (!mounted) return;

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (!mounted) return;

      if (image != null) {
        await _processImageSafely(image);
      }
    } catch (e, stackTrace) {
      debugPrint('Error al seleccionar imagen de galería: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al seleccionar imagen: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFFF44336),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _restoreState(currentState);
      }
    }
  }

  Future<void> _selectImageFromCamera(Map<String, String> currentState) async {
    try {
      if (!mounted) return;

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (!mounted) return;

      if (image != null) {
        await _processImageSafely(image);
      }
    } catch (e, stackTrace) {
      debugPrint('Error al tomar foto: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al tomar foto: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFFF44336),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _restoreState(currentState);
      }
    }
  }

  Future<void> _processImageSafely(XFile image) async {
    try {
      if (!mounted) return;

      // Verificar que el archivo existe
      final File imageFile = File(image.path);
      if (!await imageFile.exists()) {
        throw Exception('El archivo de imagen no existe');
      }

      // Verificar el tamaño del archivo (máximo 10MB)
      final int fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        // 10MB
        throw Exception('La imagen es demasiado grande. Máximo 10MB');
      }

      // Verificar que el provider está disponible
      if (!mounted) return;
      final provider = Provider.of<ServiceDataProvider>(context, listen: false);

      // Verificar si hay espacio disponible
      bool spaceFound = false;
      for (int i = 0; i < provider.images.length; i++) {
        if (provider.images[i] == null) {
          spaceFound = true;
          break;
        }
      }

      if (!spaceFound) {
        throw Exception('Ya has alcanzado el límite de imágenes');
      }

      // Procesar la imagen
      _processImage(image);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Imagen agregada correctamente',
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
      }
    } catch (e, stackTrace) {
      debugPrint('Error al procesar imagen: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al procesar imagen: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFFF44336),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _processImage(XFile? image) {
    if (image == null || !mounted) return;

    try {
      final provider = Provider.of<ServiceDataProvider>(context, listen: false);
      final File imageFile = File(image.path);

      // Buscar espacio disponible
      for (int i = 0; i < provider.images.length; i++) {
        if (provider.images[i] == null) {
          provider.updateImage(i, imageFile);
          provider.updateServiceRequest(widget.serviceRequest);
          widget.onImageSelected(imageFile);
          break;
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error en _processImage: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al agregar imagen: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFFF44336),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A819A), Color(0xFF0D4A5A)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A819A).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _restoreState(Map<String, String> state) {
    if (detailController.text.isEmpty && state['description'] != null) {
      detailController.text = state['description']!;
    }
    if (priceController.text.isEmpty && state['price'] != null) {
      priceController.text = state['price']!;
    }
  }

  Future<void> _showImagePreview(int index) async {
    try {
      if (!mounted) return;

      final provider = Provider.of<ServiceDataProvider>(context, listen: false);
      if (provider.images[index] == null) return;

      // Verificar que el archivo existe
      final File imageFile = provider.images[index]!;
      if (!await imageFile.exists()) {
        throw Exception('La imagen ya no existe en el dispositivo');
      }

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    imageFile,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Error al cargar imagen',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Precio Ofrecido: \$${provider.offeredPrice?.toStringAsFixed(2) ?? "No definido"}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A819A),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      try {
                        provider.removeImage(index);
                        provider.updateServiceRequest(widget.serviceRequest);
                        Navigator.of(context).pop();

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.delete, color: Colors.white),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Imagen eliminada',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFFF44336),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('Error al eliminar imagen: $e');
                        Navigator.of(context).pop();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error al eliminar imagen: $e',
                                style: GoogleFonts.poppins(),
                              ),
                              backgroundColor: const Color(0xFFF44336),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.delete, color: Colors.white),
                    label: Text(
                      "Eliminar imagen",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF44336),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Error en _showImagePreview: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al mostrar imagen: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFFF44336),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Consumer<ServiceDataProvider>(
          builder: (context, provider, child) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con título y descripción
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: Image.asset(
                            'assets/animations/manito.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        provider.selectedServiceTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Describe tu problema y adjunta imágenes',
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

                // Campo de descripción
                Text(
                  "Describe tu problema",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A819A),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: detailController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Explica detalladamente qué necesitas...',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                    onChanged: (value) {
                      provider.updateDescription(value);
                      provider.updateServiceRequest(widget.serviceRequest);
                    },
                  ),
                ),

                const SizedBox(height: 32),

                // Sección de imágenes
                Text(
                  "Adjunta fotos de tu problema",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A819A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Puedes agregar hasta ${widget.maxImageCount} imágenes",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),

                // Contenedor de imágenes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(3, (idx) {
                    final imageFile = idx < provider.images.length
                        ? provider.images[idx]
                        : null;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (imageFile != null) {
                            _showImagePreview(idx);
                          } else {
                            _pickImage();
                          }
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: imageFile != null
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        imageFile,
                                        width: double.infinity,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[200],
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.broken_image,
                                                  size: 24,
                                                  color: Colors.grey[400],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Error',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.grey[600],
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.remove_red_eye,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                    // Botón de eliminar
                                    Positioned(
                                      top: 4,
                                      left: 4,
                                      child: GestureDetector(
                                        onTap: () {
                                          try {
                                            provider.removeImage(idx);
                                            provider.updateServiceRequest(
                                                widget.serviceRequest);
                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      const Icon(Icons.delete,
                                                          color: Colors.white),
                                                      const SizedBox(width: 12),
                                                      const Expanded(
                                                        child: Text(
                                                          'Imagen eliminada',
                                                          style: TextStyle(
                                                              fontSize: 14),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  backgroundColor:
                                                      const Color(0xFFF44336),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  duration: const Duration(
                                                      seconds: 2),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            debugPrint(
                                                'Error al eliminar imagen: $e');
                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Error al eliminar imagen: $e',
                                                    style:
                                                        GoogleFonts.poppins(),
                                                  ),
                                                  backgroundColor:
                                                      const Color(0xFFF44336),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF44336),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Center(
                                  child: Icon(
                                    Icons.add_photo_alternate,
                                    color: Color(0xFF1A819A),
                                    size: 32,
                                  ),
                                ),
                        ),
                      ),
                    );
                  }),
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
                        child: Text(
                          'Las imágenes ayudan a los profesionales a entender mejor tu problema y ofrecer una solución más precisa.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF1A819A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
