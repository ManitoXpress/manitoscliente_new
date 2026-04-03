import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Styles/stilo.dart';
import '../home.dart';
import '../request/dataprofile.dart';
import '../request/requestWoker.dart';
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
  late UserData userData;
  bool _isProcessingPayment = false;
  bool _paymentCompleted = false;
  final TextEditingController _nitController = TextEditingController();


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
        null;
        setState(() => _isLoading = false);
      }
    } catch (e) {
      null;
      setState(() => _isLoading = false);
    }
  }

  void _confirmCompletion() async {
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Actualizar el estado del servicio
      await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceId)
          .update({'status': 'pending_confirmation2'});

      // Buscar la oferta asociada al servicio
      final querySnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('serviceId', isEqualTo: widget.serviceId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final offerDoc = querySnapshot.docs.first;
        final offerId = offerDoc.id;

        // Actualizar el estado y el NIT (si está presente)
        await FirebaseFirestore.instance
            .collection('offers')
            .doc(offerId)
            .update({
          'status': 'pending_confirmation2',
          'clientNIT': _nitController.text.trim().isNotEmpty
              ? _nitController.text.trim()
              : null,
        });

        null;
      } else {
        null;
      }

      // Escuchar cambios al servicio
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
            Future.delayed(Duration(seconds: 1), () {
              Navigator.of(context).pop(true);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => HomeScreen(initialPageIndex: 1,userData: userData!, ),
                ),
              );
            });
          }
        }
      });
    } catch (e) {
      null;
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
    final double offeredPrice = widget.fetchedOfferedPrice ?? 0.0;
    final double extraCosts = 3.0; // Gastos informáticos fijos
    final double totalPrice = offeredPrice + extraCosts;
    
    return AlertDialog(
      backgroundColor: Colors.transparent,
      content: Container(
        padding: const EdgeInsets.all(24),
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
            // Header con ícono y título
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A819A), Color(0xFF0D4A5A)],
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.payment,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Detalle de Pago',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A819A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Revisa el desglose de costos',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            // Desglose de costos
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey[200]!,
                ),
              ),
              child: Column(
                children: [
                  // Precio ofertado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.attach_money,
                              color: Color(0xFF4CAF50),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Precio ofertado',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                'Servicio del profesional',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        'Bs ${offeredPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Gastos informáticos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.computer,
                              color: Color(0xFFFF9800),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gastos informáticos',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                'Costo de plataforma',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        'Bs ${extraCosts.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Línea divisoria
                  Container(
                    height: 1,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  
                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total a pagar',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A819A),
                        ),
                      ),
                      Text(
                        'Bs ${totalPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A819A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
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
                      'Realiza el pago directamente al trabajador para confirmar la finalización del servicio.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF1A819A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Campo NIT
            TextFormField(
              controller: _nitController,
              decoration: InputDecoration(
                labelText: '¿Necesita factura con NIT?',
                hintText: 'Ingrese su número de NIT (opcional)',
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1A819A), width: 2),
                ),
                prefixIcon: const Icon(Icons.receipt, color: Color(0xFF1A819A)),
              ),
              style: GoogleFonts.poppins(fontSize: 14),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
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
                        const Icon(Icons.cancel, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Cancelar',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isProcessingPayment ? null : _confirmCompletion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A819A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isProcessingPayment
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
                              const Icon(Icons.payment, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Confirmar Pago',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}