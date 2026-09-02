import 'package:eira/core/router/routes.dart';
import 'package:eira/core/theme/app_colors.dart';
import 'package:eira/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Primera pantalla del onboarding: qué es EIRA y para qué sirve (RF-01).
///
/// ## Qué entrega y qué no
///
/// RF-01 pide una sola cosa —«pantalla de bienvenida con propósito de la
/// app»—, así que aquí no se pide ningún dato, no se elige condición y no se
/// acepta nada. Eso es T-016, T-017 y T-018, en ese orden. Una decisión
/// principal por pantalla (`PLAN_MAESTRO` §24, carga cognitiva).
///
/// **Esta pantalla no decide si debe mostrarse.** El criterio de aceptación de
/// RF-01 —«solo en el primer inicio»— lo resuelve la redirección de `/` en
/// `app_router.dart` cuando T-019 la conecte al perfil persistido. Si esta
/// pantalla se está dibujando, es porque ya se decidió que corresponde. Poner
/// aquí una segunda comprobación crearía dos sitios que responden la misma
/// pregunta, y el día que discrepen gana el que se ejecute último.
///
/// ## Precedente: la primera pantalla que usa los tokens sin `ThemeData`
///
/// `app_theme.dart` todavía no existe —es posterior a T-005— y `EiraApp` monta
/// `MaterialApp.router` sin `theme:`, de modo que el `ThemeData` vigente es el
/// de fábrica de Material 3. Por eso esta pantalla **no lee
/// `Theme.of(context)` en ninguna línea**: cada color sale de [AppColors] y
/// cada tamaño de [AppTypography], puestos en el sitio de uso.
///
/// Es la regla que documenta la cabecera de `app_typography.dart`: el estilo
/// trae tamaño, peso e interlineado; **el color lo pone quien lo usa**. Sin
/// eso, un `FilledButton` saldría con el morado por defecto del `ColorScheme`
/// de Material y un `AppBar` con su superficie.
///
/// T-016, T-017 y T-018 copian esta forma. Cuando `app_theme.dart` entre, esta
/// pantalla no cambia de aspecto: a lo sumo se le podrán borrar los `copyWith`
/// de color, que pasarán a ser redundantes.
///
/// ## Por qué no hay `AppBar`
///
/// No hay pantalla anterior a la que volver —es el primer destino del primer
/// inicio—, así que una barra superior solo aportaría un espacio vacío. Y sin
/// tema propio se dibujaría con el `ColorScheme` de fábrica: sería el único
/// elemento de la pantalla fuera de la paleta.
///
/// ## Por qué no hay imagen
///
/// Toda imagen del proyecto debe ser WebP de 80 KB o menos y llevar su
/// licencia registrada en `docs/content/image-credits.md` (`CLAUDE.md`, DoD).
/// Ese asset no existe todavía y crearlo no es de esta tarea. La pantalla se
/// sostiene con tipografía y espacio.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  // ---------------------------------------------------------------------
  // Textos
  //
  // Viven en este archivo y NO en assets/content/*.json a propósito. La regla
  // de contenido de salud —CLAUDE.md y §25— cubre «todo texto que afirme algo
  // sobre la salud del usuario», y por eso exige fuente, fecha de revisión y
  // estado de validación. Ninguna de estas siete líneas afirma nada sobre la
  // salud de nadie: describen lo que la aplicación hace. No dicen que EIRA
  // mejore, controle ni prevenga nada, y ninguna clasifica un valor clínico.
  // Esa frontera es la razón de que la línea de las métricas diga «ves cómo
  // cambian» y no «ves si están bien»: lo segundo sería interpretación
  // clínica, que es lo que el ADR-003 prohíbe.
  //
  // Reglas de lenguaje del §24 aplicadas aquí: segunda persona, ninguna frase
  // sobre 20 palabras —la más larga tiene 13—, sin jerga sin explicar («tu
  // diabetes o tu presión», no «DM2» ni «HTA») y sin género gramatical sobre
  // la persona («te damos la bienvenida», no «bienvenido/a»): el perfil de
  // T-013 no guarda género y no va a guardarlo.
  // ---------------------------------------------------------------------

  /// Título de la pantalla. Uno solo, en el rol `headline` del §24.
  static const String _titulo = 'Te damos la bienvenida a EIRA';

  /// El propósito de la app, que es lo que RF-01 pide por escrito.
  static const String _proposito =
      'EIRA te acompaña día a día en el cuidado de tu diabetes o tu presión.';

  /// Lo que la persona va a poder hacer, en el orden de las pestañas del §23:
  /// hábitos, métricas y el catálogo de «Descubre». La cuarta línea es la
  /// promesa de privacidad del §26, dicha sin tecnicismos.
  static const List<String> _loQueHace = <String>[
    'Marcas tus hábitos del día y ves tu racha.',
    'Anotas tu glucosa, tu presión y tu peso, y ves cómo cambian.',
    'Encuentras recetas y ejercicio pensados para tu condición.',
    'Todo se guarda en tu teléfono. Sin cuenta y sin internet.',
  ];

  /// Límite de la app, dicho una vez y sin ceremonia.
  ///
  /// **No es el aviso legal de RF-04.** Aquel exige acción explícita, no se
  /// puede omitir y su aceptación se persiste con fecha; es T-018 y es una
  /// pantalla propia. Esta línea solo fija la expectativa desde el principio,
  /// para que el aviso del cuarto paso no llegue de sorpresa.
  static const String _cierre =
      'EIRA te acompaña entre tus controles. '
      'No reemplaza a tu equipo de salud.';

  /// Texto del botón que lleva al paso siguiente.
  static const String _continuar = 'Continuar';

  // ---------------------------------------------------------------------
  // Medidas
  // ---------------------------------------------------------------------

  /// Margen de la pantalla.
  static const double _margen = 24;

  /// Separación entre bloques distintos: antes de [_cierre] y antes del botón.
  /// Un solo valor para que la pantalla tenga un único ritmo vertical.
  static const double _espacioEntreBloques = 24;

  /// Separación entre el título y el propósito. Menor que la de bloques porque
  /// el propósito continúa el título en vez de abrir un bloque nuevo.
  static const double _espacioTrasTitulo = 20;

  /// Separación entre las líneas de [_loQueHace]. Supera los 8 dp mínimos del
  /// §24 y hace que cada línea se lea como un ítem y no como texto corrido.
  static const double _espacioEntreLineas = 12;

  /// Alto mínimo del botón: área táctil de **acción primaria** del §24.
  ///
  /// 56 dp y no 48: 48 es el mínimo de cualquier control; 56 es el que el §24
  /// exige a la acción principal de la pantalla.
  static const double _altoDeAccionPrimaria = 56;

  /// Relleno interno del botón. El vertical se queda en 12 dp para que, al
  /// 130 % de escala del sistema, el botón crezca en vez de recortar su
  /// etiqueta.
  static const double _rellenoHorizontalDelBoton = 24;
  static const double _rellenoVerticalDelBoton = 12;

  // ---------------------------------------------------------------------
  // Estilos
  //
  // Se componen una vez, como constantes de clase, y no dentro de `build`:
  // `copyWith` crea un TextStyle nuevo en cada llamada y aquí hay siete
  // textos. Son `static final` y no `const` porque `copyWith` no es constante.
  //
  // Los contrastes están medidos en
  // docs/accessibility/contrast-verification.md; se citan aquí para que la
  // revisión de la pantalla no tenga que volver a calcularlos.
  // ---------------------------------------------------------------------

  /// 26 sp Bold. `textPrimary` contra `background`: **16.39:1**.
  static final TextStyle _estiloTitulo = AppTypography.headline.copyWith(
    color: AppColors.textPrimary,
  );

  /// 18 sp Regular, el cuerpo por defecto de la app. Mismo par: **16.39:1**.
  static final TextStyle _estiloCuerpo = AppTypography.body.copyWith(
    color: AppColors.textPrimary,
  );

  /// 16 sp Regular para [_cierre]. `textSecondary` contra `background`:
  /// **8.13:1**.
  ///
  /// No se usa `textTertiary`: son 4.86:1, el par más ajustado del sistema, y
  /// esta línea es la que acota lo que la app puede hacer por alguien. No es
  /// texto que convenga apagar.
  static final TextStyle _estiloCierre = AppTypography.bodySecondary.copyWith(
    color: AppColors.textSecondary,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(_margen),
          // El texto se desplaza dentro de `Expanded`; el botón queda fuera del
          // desplazamiento, siempre visible al pie. Envolver la pantalla entera
          // en un `SingleChildScrollView` habría sido más corto —es lo que hace
          // RoutePlaceholderPage—, pero al 130 % de escala del sistema, que el
          // §24 exige soportar, empujaría el botón bajo el pliegue: la única
          // acción de la pantalla dejaría de verse.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: _textos()),
              const SizedBox(height: _espacioEntreBloques),
              _botonContinuar(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Bloque de texto desplazable: título, propósito, lo que hace y el cierre.
  Widget _textos() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // `header: true` hace que el lector de pantalla anuncie el título
          // como encabezado y permita saltar a él. Sin tema propio no hay nada
          // que lo declare por nosotros.
          Semantics(
            header: true,
            child: Text(_titulo, style: _estiloTitulo),
          ),
          const SizedBox(height: _espacioTrasTitulo),
          Text(_proposito, style: _estiloCuerpo),
          for (final String linea in _loQueHace) ...<Widget>[
            const SizedBox(height: _espacioEntreLineas),
            Text(linea, style: _estiloCuerpo),
          ],
          const SizedBox(height: _espacioEntreBloques),
          Text(_cierre, style: _estiloCierre),
        ],
      ),
    );
  }

  /// Única acción de la pantalla. El §24 permite hasta cinco; aquí hay una.
  ///
  /// Es `FilledButton.icon` y no `FilledButton` porque el §24 pide icono **y**
  /// texto en toda acción primaria. El icono va después de la etiqueta: indica
  /// avance dentro del flujo, y leído antes del texto sugeriría un retorno.
  ///
  /// El destino es fijo. No hay lógica de «a dónde toca ir ahora» aquí: el
  /// orden del onboarding lo define el mapa del §23, no cada pantalla.
  Widget _botonContinuar(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        // Colores explícitos, obligatorios mientras no exista
        // `app_theme.dart`: sin ellos el botón toma `colorScheme.primary`, que
        // hoy es el morado por defecto de Material 3.
        //
        // `sage600` y no `sage400`: el color de marca da 2.77:1 con texto
        // blanco encima y reprueba AA (ADR-008). Este par da 5.62:1, y el
        // relleno contra el fondo, 5.42:1 —umbral de 3:1 para elementos
        // interactivos—.
        backgroundColor: AppColors.sage600,
        foregroundColor: AppColors.textOnPrimary,
        // Fija el alto de acción primaria y, de paso, el ancho completo.
        minimumSize: const Size.fromHeight(_altoDeAccionPrimaria),
        padding: const EdgeInsets.symmetric(
          horizontal: _rellenoHorizontalDelBoton,
          vertical: _rellenoVerticalDelBoton,
        ),
        // El cuerpo de 18 sp, sin inventar un séptimo rol tipográfico.
        textStyle: AppTypography.body,
      ),
      onPressed: () => context.go(Routes.onboardingProfileSetup),
      iconAlignment: IconAlignment.end,
      // Sin `semanticLabel`: el icono es decorativo y el botón ya tiene texto.
      // Etiquetarlo haría que el lector de pantalla anunciara dos veces la
      // misma acción.
      icon: const Icon(Icons.arrow_forward),
      label: const Text(_continuar),
    );
  }
}
