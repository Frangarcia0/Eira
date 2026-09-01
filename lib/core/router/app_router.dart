import 'package:eira/core/router/eira_shell.dart';
import 'package:eira/core/router/route_placeholder_page.dart';
import 'package:eira/core/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Construye el enrutador de EIRA: el mapa de rutas del `PLAN_MAESTRO` §23.
///
/// Es una función y no una variable global para que cada prueba trabaje con un
/// enrutador propio. Un `GoRouter` compartido entre pruebas arrastra la
/// ubicación de la anterior y produce fallos que dependen del orden.
///
/// ## Estructura
///
/// Tres bloques, en el orden del §23:
///
/// 1. `/` — sin pantalla, solo redirige.
/// 2. Onboarding — cuatro pantallas **fuera** del shell: durante el primer
///    inicio no hay barra de pestañas que distraiga ni que permita saltarse el
///    aviso legal.
/// 3. `StatefulShellRoute.indexedStack` — las cinco pestañas.
///
/// ## Por qué `StatefulShellRoute` y no `ShellRoute`
///
/// El §23 nombra `ShellRoute`. Se usa `StatefulShellRoute.indexedStack`, que es
/// del mismo paquete y de la misma familia (`ShellRouteBase`), porque da un
/// `Navigator` por pestaña y conserva la pila y el desplazamiento de cada una
/// al cambiar de pestaña. Cuatro de las cinco pestañas del propio mapa del §23
/// tienen subárbol de rutas. La desviación, con sus consecuencias negativas,
/// está en `docs/decisions/ADR-010`.
///
/// ## Por qué `builder:` y nunca `pageBuilder:`
///
/// `go_router` 18 movió sus transiciones y su pantalla de error internas a los
/// paquetes `material_ui` y `cupertino_ui`, que traen **su propia copia** de la
/// biblioteca Material: el `MaterialPage` de `material_ui` no es la misma clase
/// que el de `package:flutter/material.dart`. Con `builder:` la configuración
/// no nombra ningún tipo de Material y esa duplicación no nos alcanza. Por la
/// misma razón se define [_pantallaDeError]: la pantalla de error interna de
/// `go_router` se construye sobre el `Theme` de `material_ui`, que es un
/// `InheritedWidget` distinto del nuestro, así que saldría sin el tema de la
/// app y en inglés.
GoRouter createAppRouter() {
  return GoRouter(
    // `initialLocation` se deja sin declarar a propósito: sin él, `go_router`
    // arranca en la ubicación que reporta la plataforma, que es `/`, y `/`
    // redirige. Fijarlo aquí duplicaría la misma decisión en dos sitios.
    routes: _rutas,
    errorBuilder: _pantallaDeError,
  );
}

// ---------------------------------------------------------------------------
// Redirección inicial
// ---------------------------------------------------------------------------

/// Decide por dónde entra la app: por el onboarding o por la pestaña «Hoy».
///
/// ## Cumple la regla N6 por su forma, no por su velocidad
///
/// N6 pide que la redirección inicial no muestre un indicador de carga si
/// resuelve en menos de 300 ms. Lo que obliga a mostrar uno es una redirección
/// que tiene que **esperar** algo antes de poder decidir; si no espera, no hay
/// estado intermedio que dibujar y no hay parpadeo que suprimir.
///
/// Por eso esta función devuelve `String?` y no `Future<String?>`, aunque
/// `GoRouterRedirect` admita las dos formas: una redirección síncrona se
/// resuelve dentro de la resolución del primer fotograma. Son cero
/// milisegundos, no «menos de 300».
///
/// **Lo que no puede cambiar en T-019 es el tipo de retorno.** Allí se
/// sustituye el cuerpo de [_onboardingCompletado], no la firma de nadie.
String? _redirigirDesdeLaRaiz(BuildContext context, GoRouterState state) {
  return _onboardingCompletado() ? Routes.today : Routes.onboardingWelcome;
}

/// Marcador de posición: hoy la app siempre entra por el onboarding.
///
/// ## Pendiente de conectar en T-019
///
/// La respuesta real vive en `UserProfile` (**T-013**), que se lee a través del
/// repositorio de perfil y de `UserProvider` (**T-020**). Ninguno de los tres
/// existe todavía, así que aquí hay una constante y no una lectura.
///
/// Cuando exista, la lectura tiene que seguir siendo **síncrona**, y podrá
/// serlo: `LocalStorage` usa la API cacheada de `SharedPreferences`
/// (`ADR-009`), de modo que `main()` hará `await LocalStorage.open()` una sola
/// vez antes de `runApp` —dentro de la pantalla de arranque nativa, donde
/// todavía no hay fotograma de Flutter y por lo tanto no hay nada que pueda
/// parpadear— y toda lectura posterior es inmediata.
///
/// Lo que **no** se hace hoy «para dejarlo listo» es introducir un
/// `FutureBuilder` o una ruta de carga. Eso es exactamente lo que N6 prohíbe, y
/// en T-019 sería la pieza a borrar.
bool _onboardingCompletado() => false;

/// Redirección del contenedor `/onboarding`, que no tiene pantalla propia.
String? _redirigirAlPrimerPaso(BuildContext context, GoRouterState state) {
  return Routes.onboardingWelcome;
}

// ---------------------------------------------------------------------------
// Mapa de rutas
// ---------------------------------------------------------------------------

/// El mapa del §23. Las pantallas son [RoutePlaceholderPage] hasta que T-015 y
/// siguientes las reemplacen, una por una, sin tocar esta estructura.
final List<RouteBase> _rutas = <RouteBase>[
  // La única redirección de la app. Solo reescribe `/`: bloquear además el
  // shell mientras el onboarding esté incompleto es trabajo de T-018 y T-019,
  // que es donde existe el dato de la aceptación del aviso legal. Hacerlo hoy,
  // con el marcador de posición devolviendo `false`, dejaría la app entera
  // inalcanzable y el criterio de aceptación de T-010 sin forma de demostrarse.
  GoRoute(path: Routes.root, redirect: _redirigirDesdeLaRaiz),

  // ── Onboarding — fuera del shell ─────────────────────────────────────────
  GoRoute(path: Routes.onboarding, redirect: _redirigirAlPrimerPaso),
  GoRoute(
    path: Routes.onboardingWelcome,
    builder: (BuildContext context, GoRouterState state) =>
        const RoutePlaceholderPage(
          title: 'Bienvenida',
          location: Routes.onboardingWelcome,
          pendingTask: 'T-015',
          destinations: <PlaceholderDestination>[
            (label: 'Continuar', location: Routes.onboardingProfileSetup),
          ],
        ),
  ),
  GoRoute(
    path: Routes.onboardingProfileSetup,
    builder: (BuildContext context, GoRouterState state) =>
        const RoutePlaceholderPage(
          title: 'Tus datos',
          location: Routes.onboardingProfileSetup,
          pendingTask: 'T-016',
          destinations: <PlaceholderDestination>[
            (label: 'Continuar', location: Routes.onboardingCondition),
          ],
        ),
  ),
  GoRoute(
    path: Routes.onboardingCondition,
    builder: (BuildContext context, GoRouterState state) =>
        const RoutePlaceholderPage(
          title: 'Tu condición',
          location: Routes.onboardingCondition,
          pendingTask: 'T-017',
          destinations: <PlaceholderDestination>[
            (label: 'Continuar', location: Routes.onboardingDisclaimer),
          ],
        ),
  ),
  GoRoute(
    path: Routes.onboardingDisclaimer,
    builder: (BuildContext context, GoRouterState state) =>
        const RoutePlaceholderPage(
          title: 'Aviso importante',
          location: Routes.onboardingDisclaimer,
          pendingTask: 'T-018',
          destinations: <PlaceholderDestination>[
            // Temporal: hasta T-018 nada persiste la aceptación y hasta T-019
            // la redirección no la consulta, así que este botón es la única
            // forma de llegar al shell en el dispositivo.
            (label: 'Entrar a EIRA', location: Routes.today),
          ],
        ),
  ),

  // ── Shell de 5 pestañas ──────────────────────────────────────────────────
  // El orden de las ramas es el orden de la barra de `eira_shell.dart`, y hay
  // un `assert` allí que comprueba que sigan siendo el mismo.
  StatefulShellRoute.indexedStack(
    builder:
        (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) => EiraShell(navigationShell: navigationShell),
    branches: <StatefulShellBranch>[
      // 1 — Hoy
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            path: Routes.today,
            builder: (BuildContext context, GoRouterState state) =>
                const RoutePlaceholderPage(
                  title: 'Hoy',
                  location: Routes.today,
                  pendingTask: 'T-065',
                ),
            // Subrutas de «Hoy» (§23): `recipe/:id` y `routine/:id`.
            // T-046 y T-055 en adelante agregan aquí `routes: <RouteBase>[…]`.
          ),
        ],
      ),

      // 2 — Hábitos
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            path: Routes.habits,
            builder: (BuildContext context, GoRouterState state) =>
                const RoutePlaceholderPage(
                  title: 'Hábitos',
                  location: Routes.habits,
                  pendingTask: 'T-026',
                ),
            // Sin subrutas en el mapa del §23.
          ),
        ],
      ),

      // 3 — Métricas
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            path: Routes.metrics,
            builder: (BuildContext context, GoRouterState state) =>
                const RoutePlaceholderPage(
                  title: 'Métricas',
                  location: Routes.metrics,
                  pendingTask: 'T-038',
                ),
            // Subrutas de «Métricas» (§23): `:type/history` y `:type/add`.
            // T-034 y T-038 agregan aquí `routes: <RouteBase>[…]`.
          ),
        ],
      ),

      // 4 — Descubre
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            path: Routes.discover,
            builder: (BuildContext context, GoRouterState state) =>
                const RoutePlaceholderPage(
                  title: 'Descubre',
                  location: Routes.discover,
                  pendingTask: 'T-043',
                ),
            // Subrutas de «Descubre» (§23): `recipes`, `exercise`, `education`
            // y `recommendations`, cada una con su pantalla de detalle.
            // T-043 en adelante agregan aquí `routes: <RouteBase>[…]`.
          ),
        ],
      ),

      // 5 — Perfil
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            path: Routes.profile,
            builder: (BuildContext context, GoRouterState state) =>
                const RoutePlaceholderPage(
                  title: 'Perfil',
                  location: Routes.profile,
                  pendingTask: 'T-021',
                ),
            // Subrutas de «Perfil» (§23): `edit`, `notifications`, `data`
            // —«Sobre tus datos»—, `backup` y `about`.
            // T-021 en adelante agregan aquí `routes: <RouteBase>[…]`.
          ),
        ],
      ),
    ],
  ),
];

// ---------------------------------------------------------------------------
// Ruta no encontrada
// ---------------------------------------------------------------------------

/// Pantalla de una ruta que no existe.
///
/// Sustituye a la pantalla de error interna de `go_router`, que muestra la
/// excepción en inglés y sobre el tema de `material_ui`. El §24 pide lo
/// contrario: decir qué pasó y qué hacer, en segunda persona y sin códigos
/// técnicos.
Widget _pantallaDeError(BuildContext context, GoRouterState state) {
  return Scaffold(
    appBar: AppBar(title: const Text('No encontramos esa pantalla')),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'La pantalla que buscabas no existe.',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Puedes volver al inicio y seguir usando EIRA con normalidad.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: () => context.go(Routes.root),
              child: const Text('Ir al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
}
