import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manitoscliente_new/request/ResponsePost.dart';
import 'package:manitoscliente_new/Styles/stilo.dart';
import 'package:manitoscliente_new/request/requestServiceType.dart';
import 'package:manitoscliente_new/request/resquest.dart';

class ServiceDataWizard extends StatefulWidget {
  final ServiceRequest serviceRequest;
  final Function(File?) onImageSelected;
  final Function(String?) onPriceSelected;
  final Function()? onNextStep; // Cambio en el tipo de la función
  final int maxImageCount; // Nuevo atributo para definir la cantidad máxima de imágenes
  final String selectedServiceTitle;
  final List<ServiceRequest> services; // Agregado el parámetro services

  const ServiceDataWizard({
    Key? key,
    required this.serviceRequest,
    required this.onImageSelected,
    required this.onPriceSelected,
    required this.onNextStep,
    required this.selectedServiceTitle,
    required this.services, // Agregado el parámetro services
    required this.maxImageCount, // Define la cantidad máxima de imágenes
  }) : super(key: key);

  @override
  _ServiceDataWizardState createState() => _ServiceDataWizardState();
}
class _ServiceDataWizardState extends State<ServiceDataWizard> {
  final List<File?> _images = List.generate(3, (index) => null); // Lista para almacenar las imágenes
  final List<File?> _image = []; // Lista para almacenar las imágenes
  late ServiceType selectedServiceType;
  TextEditingController detailController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  ApiService apiService = ApiService(); // Create an instance of ApiService


  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();

    // Muestra un cuadro de diálogo con las opciones para tomar una foto o seleccionar desde la galería
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Selecciona la fuente de la imagen',
           style: MyTextStyles.drawerButtonTextStyle4,
           ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Cierra el cuadro de diálogo
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  _processImage(image);
                },
                child: Text('Seleccionar desde Galería'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Cierra el cuadro de diálogo
                  final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                  _processImage(image);
                },
                child: Text('Tomar Foto'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _processImage(XFile? image) {
    if (image != null) {
      // Encuentra el primer espacio nulo en la lista y asigna la imagen allí
      for (int i = 0; i < _images.length; i++) {
        if (_images[i] == null) {
          final File imageFile = File(image.path); // Convierte XFile a File
          setState(() {
            _images[i] = imageFile;
          });

          // Actualiza las imágenes en widget.serviceRequest
          widget.serviceRequest.images = _images.map((image) => image?.path ?? "").toList();

          // Llama a la función para subir la imagen al backend

          break;
        }
      }
    }
  }




  Future<void> _showImagePreview(int index) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mostrar la imagen
              Image.file(_image[index]!),
              SizedBox(height: 10),

              // Mostrar el precio ofrecido
              Text(
                'Precio Ofrecido: ${widget.serviceRequest.offeredPrice?.toStringAsFixed(2)}', // Puedes personalizar el formato del precio ofrecido
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _image.removeAt(index);
                  });
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
  void initState() {
    super.initState();
    selectedServiceType = widget.serviceRequest.serviceType as ServiceType;

    detailController.text = widget.serviceRequest.description;
    priceController.text = widget.serviceRequest.offeredPrice.toString();
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título del servicio seleccionado
        Text(
          widget.selectedServiceTitle, // Utiliza el título proporcionado
          style: MyTextStyles.formServiceTextStyle,
        ),
        const SizedBox(height: 2.0),

        // Mostrar la imagen deseada
        AspectRatio(
          aspectRatio: 4 / 3,
          child: Image.network(
            'https://i.imgur.com/1qPhnSi.png',
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 2.0),

        // Título para detalles del servicio
        Text(
          "Escribe tu problema",
          style: MyTextStyles.formServiceTextStyle,
        ),
        const SizedBox(height: 2.0),

        // Cuadro de texto para ingresar detalles del servicio
        TextFormField(
          controller: detailController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Detalles del servicio',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xA3C9D2D2)),
              borderRadius: BorderRadius.circular(20.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF1A819A)),
              borderRadius: BorderRadius.circular(20.0),
            ),
            labelStyle: MyTextStyles.formsdetails,
          ),
          onChanged: (value) {
            widget.serviceRequest.description = value;
          },
        ),
        const SizedBox(height: 4.0),

        // Título para cargar imagen
        Text(
          "Carga una foto de tu problema",
          style: MyTextStyles.formServiceTextStyle,
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
                if (_images.every((image) => image == null))
                  Center(
                    child: Icon(
                      Icons.cloud_upload,
                      size: 48,
                      color: Color(0xA3C9D2D2),
                    ),
                  ),
                ..._images
                    .asMap()
                    .entries
                    .map((entry) {
                  int idx = entry.key;
                  File? imageFile = entry.value;
                  double imageWidth = 200 / widget.maxImageCount; // Distribuye en base al máximo de imágenes
                  return Positioned(
                    left: imageWidth * idx,
                    child: GestureDetector(
                      onTap: () {
                        if (imageFile != null) {
                          _showImagePreview(imageFile as int);
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
                })
                    .toList(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4.0),
      ],
    );
  }
}