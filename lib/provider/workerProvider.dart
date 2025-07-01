import 'package:flutter/cupertino.dart';

import '../request/requestWoker.dart';

class WorkerProvider extends ChangeNotifier {
  WorkerDetails? _worker;

  /// Obtiene toda la info
  WorkerDetails? get worker => _worker;

  /// Obtiene sólo el ID
  String get workerId => _worker?.id ?? '';

  /// Asigna la info y notifica listeners
  void setWorker(WorkerDetails workerDetails) {
    _worker = workerDetails;
    notifyListeners();
  }

  /// Limpia (opcional al hacer logout)
  void clear() {
    _worker = null;
    notifyListeners();
    }
}