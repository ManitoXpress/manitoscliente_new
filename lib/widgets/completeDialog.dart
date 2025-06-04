import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
class PaymentDetailsDialog extends StatelessWidget {
  final double offeredPrice;
  final String? completionImageUrl;

  const PaymentDetailsDialog({
    Key? key,
    required this.offeredPrice,
    this.completionImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Detalle de Pago'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Precio a pagar: Bs ${offeredPrice.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (completionImageUrl != null && completionImageUrl!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Comprobante de pago:'),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    completionImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.broken_image),
                  ),
                ),
              ],
            )
          else
            Text('No se encontró imagen de comprobante.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cerrar'),
        ),
      ],
    );
  }
}