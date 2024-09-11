import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceCompletionDialog extends StatefulWidget {
  final String serviceId;

  ServiceCompletionDialog({required this.serviceId});

  @override
  _ServiceCompletionDialogState createState() => _ServiceCompletionDialogState();
}

class _ServiceCompletionDialogState extends State<ServiceCompletionDialog> {
  String? _imageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCompletionImage();
  }

  Future<void> _fetchCompletionImage() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('serviceId', isEqualTo: widget.serviceId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final offerData = querySnapshot.docs.first.data();
        setState(() {
          _imageUrl = offerData['completionImageUrl'] as String?;
          _isLoading = false;
        });
      } else {
        print('No se encontró una oferta para el serviceId proporcionado');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error al obtener la imagen de finalización: $e');
      setState(() => _isLoading = false);
    }
  }

  void _confirmCompletion() async {
    try {
      // Actualizar el estado del servicio a 'completed'
      await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceId)
          .update({'status': 'completed'});

      // Cerrar el diálogo y notificar al widget padre
      Navigator.of(context).pop(true);
    } catch (e) {
      print('Error al confirmar la finalización: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al confirmar la finalización. Por favor, intenta de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Confirmar Finalización'),
      content: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_imageUrl != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    child: Image.network(
                      _imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.error);
                      },
                    ),
                  ),
                SizedBox(height: 16),
                Text('¿Estás seguro de que quieres confirmar la finalización de este trabajo?'),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _confirmCompletion,
          child: Text('Confirmar'),
        ),
      ],
    );
  }
}