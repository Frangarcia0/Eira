/// Fallo al cargar contenido de solo lectura desde su fuente.
///
/// ## Por qué existe una excepción distinta de `StorageException`
///
/// No son el mismo tipo de fallo porque no son el mismo tipo de dato
/// (`PLAN_MAESTRO` §19, tabla «separación conceptual clave»). El contenido es
/// de solo lectura, público, y **viaja dentro del APK**; los datos del usuario
/// se generan en el dispositivo, son sensibles y empiezan vacíos.
///
/// De ahí la asimetría más importante entre las dos capas:
///
/// | Situación | `LocalStorage` | `ContentRepository` |
/// |---|---|---|
/// | El dato no está | Instalación nueva. Devuelve el valor por defecto | **Siempre lanza** |
/// | El dato está corrupto | Lanza `StorageException` | Lanza [ContentException] |
///
/// Que una clave de almacenamiento no exista es un estado legítimo: nadie ha
/// registrado nada todavía. Que un archivo de contenido no exista **no lo es
/// nunca**: o la curación no lo produjo o falta declararlo en `pubspec.yaml`.
/// En ambos casos es un defecto de construcción. Devolver una lista vacía
/// pintaría *«aún no hay recetas»* cuando lo cierto es *«esta app se empaquetó
/// mal»*, y `CLAUDE.md` exige que el estado vacío y el estado de error sean
/// cosas distintas.
///
/// ## Por qué implementa `Exception` y no extiende `Error`
///
/// Verificado en Flutter 3.47.2: `AssetBundle.loadString` sobre un asset
/// ausente lanza un `FlutterError`, que es un **`Error`** (extiende
/// `AssertionError`), no un `Exception`. Un `on Exception catch` en un provider
/// no lo atraparía y el fallo llegaría a la interfaz como un crash.
///
/// Traducirlo a esta excepción no es cosmética: convierte un `Error` —que por
/// convención de Dart señala un defecto no recuperable— en un `Exception` con
/// nombre, que es lo que un repositorio puede capturar para producir el estado
/// `error` explícito que exige el §22. El `FlutterError` original se conserva
/// en [cause] y no se pierde.
///
/// Esta excepción **no se le muestra nunca a la persona usuaria**: es
/// información para el repositorio. El mensaje visible lo decide la capa de
/// arriba.
class ContentException implements Exception {
  const ContentException({
    required this.contentId,
    required this.reason,
    this.cause,
  });

  /// Identificador lógico del contenido que no se pudo cargar (`recipes`,
  /// `habits`), **no una ruta de archivo**: quien lanza esto puede ser una
  /// implementación que no lea archivos.
  final String contentId;

  /// Qué se esperaba y qué se encontró, en términos de datos.
  final String reason;

  /// Excepción original, cuando el fallo viene del bundle o de `json.decode`.
  final Object? cause;

  @override
  String toString() {
    final String origen = cause == null ? '' : ' (causa: $cause)';
    return 'ContentException: no se pudo cargar el contenido "$contentId". '
        '$reason$origen';
  }
}
