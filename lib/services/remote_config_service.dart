import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  // ─── Claves de Remote Config ───────────────────────────────────────────────
  static const String _keyMaintenanceEnabled  = 'maintenance_enabled';
  static const String _keyMaintenanceTitle    = 'maintenance_title';
  static const String _keyMaintenanceBody1    = 'maintenance_body1';
  static const String _keyMaintenanceBody2    = 'maintenance_body2';
  static const String _keyMaintenanceFooter   = 'maintenance_footer';
  static const String _keyMaintenanceBadge    = 'maintenance_badge';
  static const String _keyMaintenanceButton   = 'maintenance_button';

  // ─── Valores por defecto (los que se usan si no hay internet) ─────────────
  static const Map<String, dynamic> _defaults = {
    _keyMaintenanceEnabled : false,
    _keyMaintenanceTitle   : 'Aviso importante',
    _keyMaintenanceBody1   :
        'Estimado usuario, estamos realizando trabajos de mantenimiento y '
        'actualización para mejorar su experiencia.',
    _keyMaintenanceBody2   :
        'La aplicación estará temporalmente fuera de servicio.',
    _keyMaintenanceFooter  : 'Agradecemos su comprensión.',
    _keyMaintenanceBadge   : 'En mantenimiento',
    _keyMaintenanceButton  : 'Entendido',
  };

  /// Inicializa Remote Config. Llamar una vez en main.dart o antes de usarlo.
  Future<void> initialize() async {
    await _remoteConfig.setDefaults(_defaults);

    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      // En producción: 1 hora. Para pruebas puedes bajar a 0.
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ));

    // Fetcha y activa en background; si falla usa los defaults.
    await _remoteConfig.fetchAndActivate();
  }

  // ─── Getters ──────────────────────────────────────────────────────────────

  /// Si `true`, muestra el diálogo de mantenimiento al presionar "Empezar".
  bool get maintenanceEnabled =>
      _remoteConfig.getBool(_keyMaintenanceEnabled);

  String get maintenanceTitle =>
      _remoteConfig.getString(_keyMaintenanceTitle);

  String get maintenanceBody1 =>
      _remoteConfig.getString(_keyMaintenanceBody1);

  String get maintenanceBody2 =>
      _remoteConfig.getString(_keyMaintenanceBody2);

  String get maintenanceFooter =>
      _remoteConfig.getString(_keyMaintenanceFooter);

  String get maintenanceBadge =>
      _remoteConfig.getString(_keyMaintenanceBadge);

  String get maintenanceButton =>
      _remoteConfig.getString(_keyMaintenanceButton);
}
