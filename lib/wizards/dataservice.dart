import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manitoscliente_new/provider/data_provider.dart';

import 'package:provider/provider.dart';

import '../Styles/stilo.dart';
import '../request/ResponsePost.dart';
import '../request/requestServiceType.dart';
import '../request/resquest.dart';
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

class _ServiceDataWizardState extends State<ServiceDataWizard> {
  TextEditingController detailController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();

    // Inicializa el Provider con los datos del serviceRequest
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ServiceDataProvider>(context, listen: false);
      provider.loadFromServiceRequest(widget.serviceRequest, widget.selectedServiceTitle);

      // Inicializa los controladores con los datos del provider
      detailController.text = provider.description;
      if (provider.offeredPrice != null) {
        priceController.text = provider.offeredPrice.toString();
      }
    });
  }

  Future<void> _pickImage() async {
    // Guarda el estado actual antes de abrir el selector de imágenes
    final currentState = {
      'description': detailController.text,
      'price': priceController.text,
    };

    final ImagePicker _picker = ImagePicker();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Selecciona la fuente de la imagen',
            style: MyTextStyles.linkTextStyle,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                    _processImage(image);
                  } catch (e) {
                    print("Error al seleccionar imagen: $e");
                    // Restaurar estado si hay error
                    _restoreState(currentState);
                  }
                },
                child: Text(
                  'Seleccionar desde Galería',
                  style: MyTextStyles.ButtonTextStyle,
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                    _processImage(image);
                  } catch (e) {
                    print("Error al tomar foto: $e");
                    // Restaurar estado si hay error
                    _restoreState(currentState);
                  }
                },
                child: Text(
                  'Tomar Foto',
                  style: MyTextStyles.ButtonTextStyle,
                ),
              ),
            ],
          ),
        );
      },
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

  void _processImage(XFile? image) {
    if (image != null) {
      final provider = Provider.of<ServiceDataProvider>(context, listen: false);
      final File imageFile = File(image.path);

      // Encuentra el primer espacio disponible
      for (int i = 0; i < provider.images.length; i++) {
        if (provider.images[i] == null) {
          provider.updateImage(i, imageFile);

          // Actualiza el ServiceRequest con los nuevos datos
          provider.updateServiceRequest(widget.serviceRequest);

          // Llama a la función onImageSelected si es necesario
          widget.onImageSelected(imageFile);

          break;
        }
      }
    }
  }

  Future<void> _showImagePreview(int index) async {
    final provider = Provider.of<ServiceDataProvider>(context, listen: false);
    if (provider.images[index] == null) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.file(provider.images[index]!),
              SizedBox(height: 10),
              Text(
                'Precio Ofrecido: ${provider.offeredPrice?.toStringAsFixed(2) ?? "No definido"}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: () {
                  provider.removeImage(index);
                  provider.updateServiceRequest(widget.serviceRequest);
                  Navigator.pop(context);
                },
                child: Text("Eliminar imagen"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServiceDataProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider.selectedServiceTitle,
              style: MyTextStyles.formServiceTextStyle,
            ),
            const SizedBox(height: 0.5),

            Center(
              child: Image.asset(
                'assets/animations/manito.png',
                width: 160,
                height: 160,
              ),
            ),
            const SizedBox(height: 2.0),

            Text(
              "Escribe tu problema",
              style: MyTextStyles.formServiceTextStyle2,
            ),
            const SizedBox(height: 2.0),

            TextFormField(
              controller: detailController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Detalles del servicio',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: const Color(0xFF9E9E9E)),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF9E9E9E)),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                labelStyle: TextStyle(color: Colors.grey),
                floatingLabelStyle: TextStyle(color: Color(0xFF9E9E9E)),
              ),
              onChanged: (value) {
                provider.updateDescription(value);
                provider.updateServiceRequest(widget.serviceRequest);
              },
            ),
            const SizedBox(height: 4.0),

            Text(
              "Carga una foto de tu problema",
              style: MyTextStyles.formServiceTextStyle2,
            ),
            const SizedBox(height: 4.0),

            GestureDetector(
              onTap: () => _pickImage(),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xA3C9D2D2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    if (provider.images.every((image) => image == null))
                      Center(
                        child: Icon(
                          Icons.cloud_upload,
                          size: 48,
                          color: Color(0xA3C9D2D2),
                        ),
                      ),
                    ...provider.images.asMap().entries.map((entry) {
                      int idx = entry.key;
                      File? imageFile = entry.value;
                      double imageWidth = 200 / widget.maxImageCount;
                      return Positioned(
                        left: imageWidth * idx,
                        child: GestureDetector(
                          onTap: () {
                            if (imageFile != null) {
                              _showImagePreview(idx);
                            }
                          },
                          child: imageFile != null
                              ? Image.file(
                            imageFile,
                            width: imageWidth,
                            height: 200,
                            fit: BoxFit.cover,
                          )
                              : Container(
                            width: imageWidth,
                            height: 200,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4.0),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    detailController.dispose();
    priceController.dispose();
    super.dispose();
  }
}