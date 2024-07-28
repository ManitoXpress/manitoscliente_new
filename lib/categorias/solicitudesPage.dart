import 'dart:math';
import 'package:flutter/material.dart';

import 'package:manitoscliente_new/categorias/solicitudesPage.dart';
import 'package:manitoscliente_new/chatscreen.dart';

class ClientPage extends StatelessWidget {
  final int clientId;
  final bool clientStatus;
  final Function onStatusChanged;

  ClientPage(
      {required this.clientId,
      required this.clientStatus,
      required this.onStatusChanged});

  String _generateRandomPrice() {
    final random = Random();
    final double minPrice = 100.0;
    final double maxPrice = 1000.0;
    final double price = minPrice + random.nextDouble() * (maxPrice - minPrice);
    return price.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController nombreController = TextEditingController();
    final TextEditingController tipoServicioController =
        TextEditingController();
    final TextEditingController precioController = TextEditingController();
    final TextEditingController descripcionController = TextEditingController();

    nombreController.text = 'Trabajador $clientId';
    tipoServicioController.text = 'Plomero';
    precioController.text = 'Precio Final: ${_generateRandomPrice()} Bs.';
    descripcionController.text =
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Trabajador $clientId',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          textAlign: TextAlign.left,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: nombreController,
              style: TextStyle(
                  fontFamily: 'Xpress Heavy',
                  fontWeight: FontWeight.normal,
                  fontStyle: FontStyle.italic,
                  fontSize: 15),
              decoration: InputDecoration(labelText: 'Nombre del Trabajador'),
            ),
            SizedBox(height: 10.0),
            TextFormField(
              controller: tipoServicioController,
              style: TextStyle(
                  fontFamily: 'Xpress Heavy',
                  fontWeight: FontWeight.normal,
                  fontStyle: FontStyle.italic,
                  fontSize: 15),
              decoration: InputDecoration(labelText: 'Tipo de Servicio'),
            ),
            SizedBox(height: 10.0),
            TextFormField(
              controller: precioController,
              style: TextStyle(
                  fontFamily: 'Xpress Heavy',
                  fontWeight: FontWeight.normal,
                  fontStyle: FontStyle.italic,
                  fontSize: 15),
              decoration: InputDecoration(labelText: 'Precio'),
            ),
            SizedBox(height: 10.0), // Ajusta este valor según sea necesario
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                Image.network(
                  'https://i.imgur.com/EcmcVKO.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
                Image.network(
                  'https://i.imgur.com/BqQE7bA.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
                Image.network(
                  'https://i.imgur.com/kYR0V6J.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ],
            ),
            SizedBox(height: 20.0),
            TextFormField(
              controller: descripcionController,
              style: TextStyle(
                  fontFamily: 'Xpress Heavy',
                  fontWeight: FontWeight.normal,
                  fontStyle: FontStyle.italic,
                  fontSize: 14),
              maxLines: 4,
              decoration: InputDecoration(labelText: 'Descripción'),
            ),
            SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    onStatusChanged();
                    Navigator.pop(context);
                  },
                  child: Text(
                    clientStatus
                        ? 'Marcar como en espera'
                        : 'Marcar como completado',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancelar',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: Draggable(
        feedback: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF1A819A), // Color de fondo del botón
          ),
          child: FloatingActionButton(
            onPressed: () {},
            child: Icon(
              Icons.chat,
              color: Colors.white, // Color del icono del chat
            ),
          ),
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChatScreen()),
            );
          },
          backgroundColor: Color(0xFF1A819A), // Color de fondo del botón
          child: Icon(
            Icons.chat,
            color: Colors.white, // Color del icono del chat
          ),
        ),
      ),
    );
  }
}
