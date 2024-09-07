import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

Future<File> compressAndResizeImage(File image) async {
  // Leer el archivo de imagen
  final originalImage = img.decodeImage(image.readAsBytesSync());

  // Redimensionar la imagen para reducir aún más su tamaño
  final resizedImage = img.copyResize(originalImage!, width: 800); // Cambia el tamaño según sea necesario

  // Comprimir la imagen redimensionada
  final compressedImage = img.encodeJpg(resizedImage, quality: 60); // Baja la calidad si es necesario

  // Obtener el directorio temporal
  final tempDir = await getTemporaryDirectory();

  // Guardar la imagen comprimida y redimensionada en un archivo temporal
  final compressedFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
  compressedFile.writeAsBytesSync(compressedImage);

  return compressedFile;
}
