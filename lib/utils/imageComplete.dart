import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:manitoscliente_new/ServicesResponse/resquest.dart';
import 'package:manitoscliente_new/Styles/stilo.dart';
import 'package:manitoscliente_new/home.dart';

class ServiceCompletionDialog extends StatefulWidget {
  final String serviceId;
  final WorkerDetails? workerDetails;
  final double? fetchedOfferedPrice;

  ServiceCompletionDialog({
    required this.serviceId,
    required this.workerDetails,
    required this.fetchedOfferedPrice,
  });


  @override
  _ServiceCompletionDialogState createState() =>
      _ServiceCompletionDialogState();
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
          // Cerrar el diálogo después de que el estado sea 'completed'
          Future.delayed(Duration(seconds: 1), () {
            Navigator.of(context).pop(true);  // Cerrar el cuadro de diálogo
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => HomeScreen(initialPageIndex: 1),
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
      SnackBar(
        content: Text('Error al confirmar la finalización. Por favor, intenta de nuevo.'),
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
          title: Text('Confirmación de la Oferta',
            style: MyTextStyles.notification,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Oferta del servicio:',
                  style: MyTextStyles.ButtonTextStyle,
                  textAlign: TextAlign.start,
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    text: 'Precio ofertado: ',
                    style: MyTextStyles.formServiceTextStyle,
                    children: [
                      TextSpan(
                        text: '${widget.fetchedOfferedPrice ?? 'No ofertado'}',
                        style: MyTextStyles.formServiceTextStyle,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
              SizedBox(height: 16.0),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Se agregarán 3 Bs en gastos informáticos.',
                  style: MyTextStyles.drawerButtonTextStyle5,
                  textAlign: TextAlign.start,
                ),
              ),
              SizedBox(height: 16.0),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Nuevo precio total: Bs ${(widget.fetchedOfferedPrice! + 3.0).toStringAsFixed(2)}',
                  style: MyTextStyles.formServiceTextStyle,
                  textAlign: TextAlign.start,
                ),
              ),
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
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(
                      color: Color(0xFF1A819A),
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
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: BorderSide(
                        color: Color(0xFF1A819A),
                      ),
                    ),
                  ),
                ),
            ],
          );
    }   
 }
