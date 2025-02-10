import 'package:flutter/material.dart';


import '../request/ResponseGet.dart'; // Asegúrate de importar correctamente la clase ServiceResponse

class OfferDialog extends StatelessWidget {
  final List<ServiceResponse> offers;

  const OfferDialog({Key? key, required this.offers}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Ofertas Disponibles'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            for (var offer in offers) ...[
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey,
                  backgroundImage: AssetImage('assets/animations/manito.png'),
                ),
                title: Text(offer.name),
              ),
              Divider(), // Separador entre cada oferta
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cerrar'),
        ),
      ],
    );
  }
}