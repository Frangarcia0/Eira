/// Catálogo cerrado de las rutas de EIRA.
///
/// Es el mapa de rutas del `PLAN_MAESTRO` §23 escrito en Dart, con las mismas
/// secciones y en el mismo orden, para que la comparación entre el plan y el
/// código sea visual. Ninguna ruta se escribe como literal fuera de este
/// archivo, por la misma razón que ninguna clave se escribe fuera de
/// `StorageKeys`: un literal suelto con una letra de menos compila, no
/// coincide con nada y llega a la persona como una pantalla de error.
///
/// ## Las dos formas de una ruta
///
/// `go_router` recibe las subrutas en forma **relativa** —`':type/history'`,
/// sin barra inicial, porque cuelgan de la ruta padre— mientras que
/// `context.go()` exige la **absoluta** —`/metrics/glucose/history`—. Un
/// catálogo que guardara solo una de las dos formas obligaría a recalcular la
/// otra a mano en cada subruta nueva, que es exactamente el trabajo que este
/// archivo existe para evitar.
///
/// Por eso, al agregar una subruta (T-015 en adelante) se agregan **dos
/// líneas**, una por forma, junto a la constante de su pestaña:
///
/// ```dart
/// // Segmento relativo: lo que recibe GoRoute.path.
/// static const String metricsHistorySegment = ':type/history';
/// // Destino absoluto: lo que recibe context.go().
/// static String metricsHistory(String type) => '$metrics/$type/history';
/// ```
///
/// **Ruta con parámetro → función. Ruta fija → constante.** La función existe
/// para que quien navega nunca concatene: `'$metrics/$type/history'` escrito en
/// una pantalla es el mismo error de tipeo silencioso, solo que repartido por
/// toda la app.
///
/// ## Sin nombres de ruta
///
/// Ninguna ruta usa el parámetro `name` de `go_router`. Los nombres crearían un
/// segundo catálogo de identificadores en paralelo a los caminos, sin nada que
/// mantenga los dos sincronizados: dos caminos válidos para el mismo dato, que
/// es como empezó la deuda técnica del repositorio anterior (§3). Solo caminos.
///
/// ## Este archivo solo declara lo que existe
///
/// Las subrutas profundas del §23 —`/discover/recipes/:id`,
/// `/metrics/:type/add` y las demás— **no están aquí**, porque no existe la
/// pantalla que las atiende. Entran con la tarea que construye esa pantalla,
/// no antes: una constante que no lleva a ninguna parte es la versión de una
/// pantalla huérfana que la regla E7 no puede detectar.
class Routes {
  /// Constructor privado: [Routes] es un contenedor de constantes y no se
  /// instancia nunca.
  const Routes._();

  // ---------------------------------------------------------------------
  // Raíz
  // ---------------------------------------------------------------------

  /// Punto de entrada de la aplicación.
  ///
  /// No tiene pantalla: solo redirige, según haya terminado o no el
  /// onboarding, a [onboardingWelcome] o a [today] (§23, «¿onboarding
  /// completo?»).
  static const String root = '/';

  // ---------------------------------------------------------------------
  // Onboarding — fuera del shell, sin barra de pestañas
  // ---------------------------------------------------------------------

  /// Contenedor del onboarding. No tiene pantalla propia: redirige a
  /// [onboardingWelcome], que es el primer paso del flujo.
  static const String onboarding = '/onboarding';

  /// Bienvenida. Solo en el primer inicio (T-015).
  static const String onboardingWelcome = '/onboarding/welcome';

  /// Datos básicos: máximo tres campos, con año de nacimiento y no fecha
  /// completa (T-016).
  static const String onboardingProfileSetup = '/onboarding/profile-setup';

  /// Selección de condición: diabetes, hipertensión o ambas (T-017).
  static const String onboardingCondition = '/onboarding/condition';

  /// Aviso legal. Aceptación obligatoria y registrada; no se puede omitir
  /// (T-018).
  static const String onboardingDisclaimer = '/onboarding/disclaimer';

  // ---------------------------------------------------------------------
  // Pestaña 1 — Hoy
  // ---------------------------------------------------------------------

  /// Pantalla de inicio. Es también el destino de la redirección inicial
  /// cuando el onboarding ya terminó.
  ///
  /// Subrutas futuras del §23: `/today/recipe/:id`, `/today/routine/:id`.
  static const String today = '/today';

  // ---------------------------------------------------------------------
  // Pestaña 2 — Hábitos
  // ---------------------------------------------------------------------

  /// Hábitos del día y racha. Sin subrutas en el mapa del §23.
  static const String habits = '/habits';

  // ---------------------------------------------------------------------
  // Pestaña 3 — Métricas
  // ---------------------------------------------------------------------

  /// Métricas de salud.
  ///
  /// Subrutas futuras del §23: `/metrics/:type/history`, `/metrics/:type/add`.
  static const String metrics = '/metrics';

  // ---------------------------------------------------------------------
  // Pestaña 4 — Descubre
  // ---------------------------------------------------------------------

  /// Catálogo explorable de recetas, ejercicio, educación y recomendaciones.
  ///
  /// Subrutas futuras del §23: `/discover/recipes` → `/discover/recipes/:id`,
  /// `/discover/exercise` → `/discover/routines/:id` y
  /// `/discover/exercises/:id`, `/discover/education` →
  /// `/discover/education/:id`, y `/discover/recommendations`.
  static const String discover = '/discover';

  // ---------------------------------------------------------------------
  // Pestaña 5 — Perfil
  // ---------------------------------------------------------------------

  /// Perfil de la persona y configuración.
  ///
  /// Subrutas futuras del §23: `/profile/edit`, `/profile/notifications`,
  /// `/profile/data` («Sobre tus datos»), `/profile/backup` y
  /// `/profile/about`.
  static const String profile = '/profile';
}
