import 'package:manitoscliente_new/metodos/workers.dart';
import 'package:flutter/material.dart';

import 'Styles/stilo.dart';

class FavoriteScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<Worker> favoriteWorkers = getFavoriteWorkers();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Trabajadores Favoritos',
          style: MyTextStyles.buttonTextStyle,
        ),
      ),
      body: ListView.builder(
        itemCount: favoriteWorkers.length,
        itemBuilder: (context, index) {
          Worker worker = favoriteWorkers[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage(worker.profileImage),
            ),
            title: Text(worker.name),
            subtitle: Text(worker.specialty),
            trailing: IconButton(
              icon: Icon(Icons.favorite),
              color: Colors.red,
              onPressed: () {
                removeFromFavorites(worker);
              },
            ),
          );
        },
      ),
    );
  }

  List<Worker> getFavoriteWorkers() {
    return [
      Worker('Juan Pérez', 'Plomero', 'images/plomero.jpg'),
      Worker('María Rodríguez', 'Electricista', 'images/electricista.jpg'),
      Worker('Carlos Gutiérrez', 'Jardinería', 'images/jardinero.jpg'),
      Worker('Laura Martínez', 'Diseñador Gráfico', 'images/designer.jpg'),
      Worker('Luis Sánchez', 'Programador', 'images/programmer.jpg'),
      Worker('Ana López', 'Nutricionista', 'images/nutritionist.jpg'),
      Worker('José González', 'Plomero', 'images/plomero2.jpg'),
      Worker('Elena Fernández', 'Electricista', 'images/electricista2.jpg'),
      Worker('Pedro Ramírez', 'Jardinería', 'images/jardinero2.jpg'),
      Worker('Sofía Torres', 'Diseñador Gráfico', 'images/designer2.jpg'),
    ];
  }

  void removeFromFavorites(Worker worker) {
    // Implementa la lógica para eliminar a un trabajador de favoritos aquí
    // Esto podría incluir actualizar una base de datos o una lista en memoria.
  }
}
