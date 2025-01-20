import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:manitoscliente_new/ServicesResponse/resquest.dart';

class ServiceDataFetcher {
  // Obtener los detalles del trabajador
  Future<WorkerDetails?> fetchWorkerDetails(String? workerId) async {
    if (workerId == null || workerId.isEmpty) {
      print('workerId está vacío o es nulo');
      return null;
    }

    try {
      final workerSnapshot = await FirebaseFirestore.instance
          .collection('workers')
          .doc(workerId)
          .get();

      if (workerSnapshot.exists) {
        return WorkerDetails.fromMap(workerSnapshot.data()!);
      } else {
        print('No se encontró al trabajador con ID: $workerId');
      }
    } catch (e) {
      print('Error al obtener los detalles del trabajador: $e');
    }
    return null;
  }

  // Obtener el precio ofertado para un servicio específico
  Future<double?> fetchOfferedPrice(String? serviceId) async {
    if (serviceId == null || serviceId.isEmpty) {
      print('serviceId está vacío o es nulo');
      return null;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('serviceId', isEqualTo: serviceId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final offerData = querySnapshot.docs.first.data();
        return double.tryParse(offerData['offeredPrice'].toString());
      } else {
        print('No se encontró oferta para el servicio con ID: $serviceId');
      }
    } catch (e) {
      print('Error al obtener el precio ofertado: $e');
    }
    return null;
  }
}
