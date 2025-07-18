# Timeline Refactorizado

Este directorio contiene la nueva estructura modular del timeline de servicios, refactorizada desde el archivo original `lib/utils/timeLines.dart`.

## Estructura de Archivos

### 📁 Archivos Principales

- **`service_timeline.dart`** - Widget principal que orquesta todos los componentes
- **`timeline_exports.dart`** - Archivo de exportaciones para facilitar importaciones

### 📁 Componentes

- **`service_info_section.dart`** - Sección de información del servicio (estado, fecha/hora, descripción, imágenes, expertises)
- **`payment_report_section.dart`** - Sección del informe de pago con desglose de costos
- **`worker_details_section.dart`** - Sección de detalles del trabajador con información personal y profesional
- **`action_buttons_section.dart`** - Sección de botones de acción (aceptar, cancelar, WhatsApp, comentarios)

### 📁 Utilidades

- **`timeline_helpers.dart`** - Funciones auxiliares (obtener precio, mostrar diálogos, modales)

## Uso

### Importación Simple
```dart
import 'package:your_app/timeline/timeline_exports.dart';
```

### Importación Individual
```dart
import 'package:your_app/timeline/service_timeline.dart';
import 'package:your_app/timeline/service_info_section.dart';
// ... etc
```

## Ventajas de la Refactorización

✅ **Mantenibilidad** - Cada archivo tiene una responsabilidad específica  
✅ **Reutilización** - Los componentes pueden usarse en otras pantallas  
✅ **Escalabilidad** - Fácil agregar nuevas secciones o modificar existentes  
✅ **Colaboración** - Múltiples desarrolladores pueden trabajar en diferentes archivos  
✅ **Legibilidad** - Código más organizado y fácil de entender  
✅ **Testing** - Cada componente puede ser testeado independientemente  

## Migración

El archivo original `lib/utils/timeLines.dart` ahora simplemente exporta la nueva estructura, por lo que no se requieren cambios en el código existente que lo importe.

## Componentes Disponibles

### ServiceFormWithTimeline
Widget principal que maneja toda la lógica del timeline.

### ServiceInfoSection
Muestra:
- Estado del servicio
- Fecha y hora
- Descripción
- Carrusel de imágenes
- Tipos de servicio (expertises)

### PaymentReportSection
Muestra:
- Desglose de costos
- Precio ofertado
- Gastos informáticos
- Total a pagar

### WorkerDetailsSection
Muestra:
- Información personal del trabajador
- Información profesional
- Documentos verificados

### ActionButtonsSection
Muestra botones según el estado:
- Aceptar/Cancelar propuesta
- Cancelar trabajo
- WhatsApp
- Comentarios

## Helpers Disponibles

### TimelineHelpers
- `getOfferedPrice()` - Obtiene el precio ofertado desde múltiples fuentes
- `showImageDialog()` - Muestra diálogo con imagen
- `showCommentsModal()` - Muestra modal de comentarios 