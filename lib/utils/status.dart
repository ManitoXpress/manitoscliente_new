import 'package:manitoscliente_new/request/requestStatus.dart';

import '../request/resquest.dart';

class StatusUtils {
  static Status getStatusById(String id) {
    switch (id) {
      case "available":
        return Status(id: "available", name: "Disponible");
      case "assigned":
        return Status(id: "assigned", name: "Asignado");
      case "in_progress":
        return Status(id: "in_progress", name: "En curso");
      case "pending_confirmation":
        return Status(id: "pending_confirmation", name: "Pendiente");
      case "completed":
        return Status(id: "completed", name: "Completado");
      case "cancelled":
        return Status(id: "cancelled", name: "Cancelado");
      default:
        return Status(id: "unknown", name: "Desconocido");
    }
  }
}
