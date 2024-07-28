
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ModifyServiceScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;

  ModifyServiceScreen({required this.initialData});

  @override
  _ModifyServiceScreenState createState() => _ModifyServiceScreenState();
}

class _ModifyServiceScreenState extends State<ModifyServiceScreen> {
  late TextEditingController offeredPriceController;

  @override
  void initState() {
    super.initState();
    offeredPriceController = TextEditingController(
      text: widget.initialData['offeredPrice'].toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Modificar Servicio"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Copia y pega el código de los otros campos que deseas mostrar

            // Cuadro de texto para editar el precio
            TextFormField(
              controller: offeredPriceController,
              decoration: InputDecoration(labelText: 'Precio ofrecido'),
            ),
            SizedBox(height: 16.0),

            // Botón para guardar los cambios
            ElevatedButton(
              onPressed: () {
                // Lógica para guardar los cambios en el precio
                // Puedes acceder a offeredPriceController.text para obtener el nuevo precio
                Navigator.of(context).pop();
              },
              child: Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }
}