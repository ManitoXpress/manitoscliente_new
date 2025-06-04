// lib/constants/service_constants.dart

import 'package:flutter/material.dart';

/// Estados válidos de un ServiceRequest (coinciden con Firestore).
class ServiceStatus {
  static const String available = 'available';
  static const String offer = 'offer';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  static const String blocked = 'blocked';
  static const String pendingConfirmation = 'pending_confirmation';
  static const String pendingConfirmation2 = 'pending_confirmation2';
}

/// Etiquetas para mostrar en pantalla según el estado.
const Map<String, String> statusNames = {
  ServiceStatus.available: 'Disponible',
  ServiceStatus.offer: 'Ofertado',
  ServiceStatus.inProgress: 'En curso',
  ServiceStatus.completed: 'Completado',
  ServiceStatus.cancelled: 'Cancelado',
  ServiceStatus.blocked: 'Bloqueado',
  ServiceStatus.pendingConfirmation: 'Esperando confirmación',
  ServiceStatus.pendingConfirmation2: 'Esperando confirmación',
};

/// Colores comunes usados en toda la app.
class AppColors {
  static const Color primary = Color(0xFF830A09);
  static const Color secondary = Color(0xFF1A819A);
  static const Color black = Colors.black;
  static const Color white = Colors.white;
  static const Color whatsappGreen = Color(0xFF25D366);
}

/// Dimensiones y estilos de texto comunes.
class AppTextStyles {
  static const double labelFontSize = 16;
  static const double valueFontSize = 14;
  static const double buttonFontSize = 12;
  static const double smallButtonFontSize = 9;
}
