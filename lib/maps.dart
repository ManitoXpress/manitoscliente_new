import 'package:flutter/material.dart';

import 'Styles/stilo.dart';
import 'models/worker_detailsModels.dart';

class FavoriteScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<WorkerDetailsModel> favoriteWorkers = getFavoriteWorkers();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Trabajadores Favoritos',
          style: MyTextStyles.buttonTextStyle,
        ),
      ),
      body: ListView.builder(
        itemCount: favoriteWorkers.length,
        itemBuilder: (context, index) {
          WorkerDetailsModel worker = favoriteWorkers[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage(worker.imagePath.isNotEmpty ? worker.imagePath : 'images/default_worker.jpg'),
            ),
            title: Text(worker.displayName),
            subtitle: Text(worker.expertises.isNotEmpty ? worker.expertises.first.name : 'Sin especialidad'),
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

  List<WorkerDetailsModel> getFavoriteWorkers() {
    return [
      WorkerDetailsModel(
        displayName: 'Juan Pérez',
        email: 'juan@example.com',
        expertises: [],
        imagePath: 'images/plomero.jpg',
        idDocumentImagePath: '',
        phoneNumber: '',
      ),
      WorkerDetailsModel(
        displayName: 'María Rodríguez',
        email: 'maria@example.com',
        expertises: [],
        imagePath: 'images/electricista.jpg',
        idDocumentImagePath: '',
        phoneNumber: '',
      ),
      // Agregar más trabajadores según sea necesario
    ];
  }

  void removeFromFavorites(WorkerDetailsModel worker) {
    // Implementa la lógica para eliminar a un trabajador de favoritos aquí
    // Esto podría incluir actualizar una base de datos o una lista en memoria.
  }
}
