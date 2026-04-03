/// Constantes para la configuración de caché y optimización del historial
class CacheConstants {
  // 🚀 OPTIMIZADO: Tiempo de validez del caché aumentado para reducir carga constante
  static const int historialCacheValidMinutes = 15;
  
  // 🚀 OPTIMIZADO: Intervalo de actualización automática menos frecuente
  static const int historialAutoRefreshMinutes = 10;
  
  // 🚀 OPTIMIZADO: Intervalo de actualización inteligente menos agresivo
  static const int historialSmartRefreshSeconds = 60;
  
  // 🚀 OPTIMIZADO: Timeout de red aumentado para evitar timeouts
  static const int networkTimeoutSeconds = 30;
  
  // Tiempo máximo para limpiar caché obsoleto (en horas)
  static const int maxCacheAgeHours = 2;
  
  // 🚀 OPTIMIZADO: Elementos en caché optimizados
  static const int maxCacheItemsPerStatus = 100;
  
  // Tiempo de debounce para operaciones de scroll (en milisegundos)
  static const int scrollDebounceMs = 300;
  
  // Distancia desde el final para activar carga infinita
  static const double infiniteScrollThreshold = 200.0;
  
  // Tiempo mínimo entre refrescos manuales (en segundos)
  static const int minRefreshIntervalSeconds = 3;
  
  // 🚀 NUEVO: Tiempo de precarga después del login (en milisegundos)
  static const int preloadDelayMs = 1000;
  
  // 🚀 NUEVO: Tiempo de validez del caché para datos críticos (en minutos)
  static const int criticalDataCacheMinutes = 5;
  
  // 🚀 NUEVO: Tiempo de validez del caché para datos normales (en minutos)
  static const int normalDataCacheMinutes = 15;
}

/// Configuración de paginación
class PaginationConstants {
  // Tamaño de página por defecto
  static const int defaultPageSize = 20;
  
  // Tamaño máximo de página
  static const int maxPageSize = 50;
  
  // Número máximo de páginas en caché
  static const int maxCachedPages = 5;
}

/// Configuración de indicadores visuales
class UIConstants {
  // Opacidad para datos obsoletos durante actualización
  static const double staleDataOpacity = 0.3;
  
  // Duración de las animaciones de transición
  static const Duration transitionDuration = Duration(milliseconds: 300);
  
  // Tamaño del indicador de carga
  static const double loadingIndicatorSize = 20.0;
  
  // Grosor del indicador de carga
  static const double loadingIndicatorStrokeWidth = 2.0;
}
