/// Catálogo cerrado de las claves de `SharedPreferences` que usa EIRA.
///
/// Es la tabla del `PLAN_MAESTRO` §22 escrita en Dart, sin una clave de más.
/// Ninguna clave se escribe como literal fuera de este archivo: un literal
/// suelto es un error de tipeo silencioso que devuelve `null` en tiempo de
/// ejecución y se lee, desde la UI, como "el usuario no tiene datos".
///
/// ## Convención
///
/// ```
/// eira.v1.<dominio>.<detalle>
/// ```
///
/// | Parte | Para qué está |
/// |---|---|
/// | `eira.` | Aísla los datos de la app del resto del almacén del proceso, que también contiene claves de plugins. Es lo que permite que [prefix] defina un borrado total exacto |
/// | `v1` | Permite escribir `eira.v2.profile` **junto a** `eira.v1.profile` durante una migración, en vez de destruir el dato viejo antes de saber si el nuevo se escribió bien |
/// | `<dominio>` | Agrupa por área: `habits`, `metrics`, `favorites`, `app`, `notifications` |
/// | `<detalle>` | Distingue dentro del dominio. Se escribe en `snake_case`, como en la tabla del plan |
///
/// ## Por qué las métricas son tres claves y no una
///
/// [metricsGlucose], [metricsBloodPressure] y [metricsWeight] se guardan por
/// separado a propósito (§22). Con una sola clave, registrar un peso obligaría
/// a reescribir el historial completo de glucosa y presión: una escritura
/// fallida a medio camino se llevaría por delante datos que el usuario nunca
/// tocó.
///
/// ## Al agregar una clave
///
/// Actualizar este archivo, evaluar si hace falta migración y **revisar la
/// pantalla "Sobre tus datos"** (`/profile/data`), que debe coincidir
/// exactamente con lo que se almacena. No es opcional: esa pantalla es la
/// declaración de privacidad de la app y una clave no declarada la convierte
/// en falsa.
///
/// La clave `eira.schema_version` todavía no está aquí: la agrega T-007 junto
/// con la lógica de migración que le da sentido.
class StorageKeys {
  /// Constructor privado: [StorageKeys] es un contenedor de constantes y no se
  /// instancia nunca.
  const StorageKeys._();

  /// Prefijo común de todo dato de usuario de EIRA.
  ///
  /// Lo usa `LocalStorage.deleteAll()` para borrar exactamente lo que EIRA
  /// escribió, sin tocar las claves de otros plugins que comparten el mismo
  /// almacén. Toda clave de este archivo empieza por él.
  static const String prefix = 'eira.';

  // ---------------------------------------------------------------------
  // Perfil
  // ---------------------------------------------------------------------

  /// Objeto JSON con el perfil de la persona: condición, año de nacimiento y
  /// aceptación del aviso legal. Uno por instalación.
  static const String profile = 'eira.v1.profile';

  // ---------------------------------------------------------------------
  // Hábitos
  // ---------------------------------------------------------------------

  /// Objeto JSON con las marcas de hábitos completados de los últimos 90 días.
  static const String habitsCompletions = 'eira.v1.habits.completions';

  /// Objeto JSON con el estado de racha en caché: actual, mejor y última
  /// fecha contabilizada.
  ///
  /// Es una caché, no la fuente de verdad. La fuente es
  /// [habitsCompletions], y el recálculo desde el historial debe coincidir
  /// con este valor (§27, casos límite de rachas).
  static const String habitsStreak = 'eira.v1.habits.streak';

  // ---------------------------------------------------------------------
  // Métricas — una clave por tipo
  // ---------------------------------------------------------------------

  /// Arreglo JSON de registros de glucosa.
  static const String metricsGlucose = 'eira.v1.metrics.glucose';

  /// Arreglo JSON de registros de presión arterial.
  static const String metricsBloodPressure = 'eira.v1.metrics.blood_pressure';

  /// Arreglo JSON de registros de peso.
  static const String metricsWeight = 'eira.v1.metrics.weight';

  // ---------------------------------------------------------------------
  // Favoritos — listas de identificadores de contenido
  // ---------------------------------------------------------------------

  /// Identificadores de las recetas marcadas como favoritas.
  ///
  /// Guarda IDs, no las recetas: el contenido vive en `assets/content/` y es
  /// inmutable. Duplicarlo aquí crearía una segunda copia que se desincroniza
  /// en cuanto se corrige un texto.
  static const String favoriteRecipes = 'eira.v1.favorites.recipes';

  /// Identificadores de las rutinas de ejercicio marcadas como favoritas.
  static const String favoriteRoutines = 'eira.v1.favorites.routines';

  // ---------------------------------------------------------------------
  // Estado de la aplicación
  // ---------------------------------------------------------------------

  /// Fecha de la última apertura, en texto ISO-8601.
  ///
  /// Sostiene el reinicio diario del dashboard y la rotación determinista de
  /// contenido. Se guarda como texto porque `SharedPreferences` no almacena
  /// fechas; interpretarla es trabajo de `core/utils/date_utils.dart`, no de
  /// la capa de almacenamiento.
  static const String appLastOpened = 'eira.v1.app.last_opened';

  // ---------------------------------------------------------------------
  // Notificaciones
  // ---------------------------------------------------------------------

  /// Booleano: si la persona activó el recordatorio diario.
  static const String notificationsEnabled = 'eira.v1.notifications.enabled';
}
