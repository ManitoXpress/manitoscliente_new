import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:manitoscliente_new/ServicesResponse/resquest.dart';

class ServiceDataFetcher {
  Future<WorkerDetails?> fetchWorkerDetails(String workerId) async {
    try {
      final workerSnapshot = await FirebaseFirestore.instance
          .collection('workers')
          .doc(workerId)
          .get();

      if (workerSnapshot.exists) {
        return WorkerDetails.fromMap(workerSnapshot.data()!);
      }
    } catch (e) {
      print('Error al obtener los detalles del trabajador: $e');
    }
    return null;
  }

  Future<double?> fetchOfferedPrice(String serviceId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('serviceId', isEqualTo: serviceId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final offerData = querySnapshot.docs.first.data();
        return double.tryParse(offerData['offeredPrice'].toString());
      }
    } catch (e) {
      print('Error al obtener el precio ofertado: $e');
    }
    return null;
  }
}