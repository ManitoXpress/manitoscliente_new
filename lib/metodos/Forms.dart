import 'dart:convert';
import 'package:manitoscliente_new/widgets/status.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

import 'package:manitoscliente_new/request/ResponseGet.dart';

import '../categorias/modifyServices.dart';

class ServiceForm extends StatefulWidget {
  final Map<String, dynamic> initialData;

  ServiceForm({required this.initialData});

  @override
  _ServiceFormState createState() => _ServiceFormState();
}

class _ServiceFormState extends State<ServiceForm> {
  late TextEditingController serviceTypeController;
  late TextEditingController descriptionController;
  late TextEditingController dateController;
  late List<String> images;
  late TextEditingController offeredPriceController;
  late TextEditingController yourPriceController;
  late TextEditingController addressController;
  late double rating;
  late String imageUrl;
  late bool editingDescription;
  late bool editingPrice;

  @override
  void initState() {
    super.initState();
    super.initState();
    serviceTypeController =
        TextEditingController(text: widget.initialData['serviceType'] ?? '');
    descriptionController =
        TextEditingController(text: widget.initialData['description'] ?? '');
    dateController = TextEditingController(
        text: widget.initialData['dateTime'] ?? 'No disponible');
    images = [];
    offeredPriceController = TextEditingController(
        text: widget.initialData['offeredPrice'].toString());
    yourPriceController = TextEditingController();
    addressController =
        TextEditingController(text: widget.initialData['location'].toString());
    rating = 0.0;
    imageUrl = '';
    editingDescription = false;
    editingPrice = false;
    // Obtén el userId
    getUserIdAutenticado().then((userId) {
      // Llamada al método para cargar imágenes desde el backend
      loadImagesFromBackend(userId);

      // Resto del código...
      // Cargar las imágenes y datos del servicio desde el backend
      loadServiceDetailsFromBackend(userId);
    });
  }

  Future<void> loadServiceDetailsFromBackend(String userId) async {
    try {
      final apiService = ApiService2();

      // Obtener el ID del servicio desde los datos iniciales
      final serviceId = widget.initialData['id'];

      // Llamar al método del servicio para obtener los detalles del servicio
      final response =
          await apiService.fetchServiceDetailsFromBackend(userId, serviceId);

      if (response.statusCode == 200) {
        // Analizar el cuerpo JSON de la respuesta
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Extraer la URL de la imagen del cuerpo de la respuesta
        final imageFromResponse = responseData['imageUrl'];

        // Actualizar el estado con la URL de la imagen y el rating si es necesario
        setState(() {
          imageUrl =
              imageFromResponse ?? ''; // Asegurarse de manejar el caso de nulo
          // Resto del código...
        });
      } else {
        // Manejar el caso en el que la solicitud no fue exitosa
        print('Error: ${response.statusCode}');
        print('Mensaje de error: ${response.body}');
      }
    } catch (e) {
      print('Error al cargar detalles del servicio desde el backend: $e');
    }
  }

  Future<void> loadImagesFromBackend(String userId) async {
    try {
      final apiService = ApiService2();
      // Aquí deberías verificar si userId es nulo y manejarlo apropiadamente
      final imageUrl = await apiService.getImage(userId);

      print('URL de la imagen: $imageUrl'); // Imprimir la URL

      setState(() {
        images;
      });
    } catch (e) {
      print('Error al cargar la imagen desde el backend: $e');
    }
  }

  Future<String> getUserIdAutenticado() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return user.uid;
    } else {
      throw Exception('Usuario no autenticado');
    }
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: PhotoViewGallery.builder(
              itemCount: images.length,
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  // Usa NetworkImage para imágenes en línea (por ejemplo, desde Firebase Storage)
                  imageProvider: NetworkImage(images[index]),
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  maxScale: PhotoViewComputedScale.covered * 2,
                );
              },
              backgroundDecoration: BoxDecoration(
                color: Colors.black,
              ),
              pageController: PageController(),
              scrollPhysics: BouncingScrollPhysics(),
              onPageChanged: (index) {},
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Detalles del Servicio"),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tipo de servicio y estado
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Tipo de servicio: ${serviceTypeController.text}"),
                SizedBox(height: 5),
                buildStatusIndicator("Completado"), // Ejemplo de uso
              ],
            ),

            // Display thumbnail images with a common title
            Column(
              children: [
                Text("Imágenes",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          _showImageDialog(images[index]);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.network(
                            images[index],
                            width: 80,
                            // Set your desired width for thumbnails
                            height: 80,
                            // Set your desired height for thumbnails
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: descriptionController,
              enabled: editingDescription,
              decoration: InputDecoration(labelText: "Descripción"),
            ),
            TextFormField(
              controller: dateController,
              enabled: false, // Hacer que este campo sea de solo lectura
              decoration: InputDecoration(labelText: "Fecha"),
            ),
            TextFormField(
              controller: addressController,
              enabled: false, // Hacer que este campo sea de solo lectura
              decoration: InputDecoration(labelText: "Dirección"),
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: offeredPriceController,
                    enabled: editingPrice,
                    decoration: InputDecoration(labelText: "Precio ofrecido"),
                  ),
                ),
                SizedBox(width: 10),
              ],
            ),
          ],
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navegar a la nueva pantalla para modificar el precio
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ModifyServiceScreen(
                      initialData: widget.initialData,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              child: Text("Modificar", style: TextStyle(color: Colors.white)),
            ),
            SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Lógica para el botón "Cancelar"
                  // Puedes implementar la lógica que necesites al presionar este botón
                  setState(() {
                    editingDescription = false;
                    editingPrice = false;
                  });
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: Text("Cancelar", style: TextStyle(color: Colors.white)),
              ),
            ),
            SizedBox(width: 10),
            // "Cerrar" button on the bottom
          ],
        ),
      ],
    );
  }
}
