import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:manitoscliente_new/Styles/stilo.dart';
import 'package:manitoscliente_new/home.dart';

class ServiceCompletionDialog extends StatefulWidget {
  final String serviceId;

  ServiceCompletionDialog({required this.serviceId});

  @override
  _ServiceCompletionDialogState createState() => _ServiceCompletionDialogState();
}

class _ServiceCompletionDialogState extends State<ServiceCompletionDialog> {
  String? _imageUrl;
  bool _isLoading = true;
  bool _isProcessingPayment = false;
  bool _paymentCompleted = false;

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
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Actualizar el estado del servicio a 'pending_confirmation2'
      await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceId)
          .update({'status': 'pending_confirmation2'});

      // Monitorear el cambio de estado del servicio
      FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          if (data['status'] == 'completed') {
            setState(() {
              _paymentCompleted = true;
              _isProcessingPayment = false;
            });
            // Cerrar el diálogo después de mostrar el mensaje de éxito
            Future.delayed(Duration(seconds: 1), () {
              Navigator.of(context).pop(true);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => HomeScreen(initialPageIndex: 2),
                ),
              );
            });
          }
        }
      });
    } catch (e) {
      print('Error al confirmar la finalización: $e');
      setState(() {
        _isProcessingPayment = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al confirmar la finalización. Por favor, intenta de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Confirmar Finalización',
      style: MyTextStyles.notification,
      ),
      content: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _isProcessingPayment
              ? Center(child: Text('Esperando el pago...'))
              : _paymentCompleted
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 60),
                        SizedBox(height: 16),
                        Text('¡El pago se realizó con éxito!'),
                      ],
                    )
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
                        Text('Por favor, culmine el pago acordado con el trabajador para finalizar el trabajo'),
                      ],
                    ),
      actions: [
        TextButton.icon(
        onPressed: () => Navigator.of(context).pop(false),
        icon: Icon(Icons.dangerous, color: Color(0xFF1A819A)),
        label: Text(
          'Cancelar',
          style: GoogleFonts.karla(
            color: Color(0xFF1A819A),
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          backgroundColor: Colors.white, // Fondo blanco del botón
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
            side: BorderSide(
              color: Color(0xFF1A819A), // Borde del botón
            ),
          ),
        ),
      ),
      if (!_isProcessingPayment)
        ElevatedButton.icon(
          onPressed: _confirmCompletion,
          icon: Icon(Icons.check_circle, color: Color(0xFF1A819A)),
          label: Text(
            'Hacer el pago',
            style: GoogleFonts.karla(
              color: Color(0xFF1A819A),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            backgroundColor: Colors.white, // Fondo blanco del botón
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
              side: BorderSide(
                color: Color(0xFF1A819A), // Borde del botón
              ),
            ),
          ),
        ),

      ],
    );
 }
}
