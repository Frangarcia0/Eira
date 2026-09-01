import 'package:flutter/material.dart';

/// Escala tipográfica cerrada de EIRA: **seis tamaños y ninguno más**.
///
/// La tabla del PLAN_MAESTRO §24 fija los seis roles y es un criterio de
/// aceptación, no una recomendación:
///
/// | Rol              | Tamaño   | Peso     | Uso                            |
/// |------------------|----------|----------|--------------------------------|
/// | [display]        | 32 sp    | Bold     | Números de métricas, racha     |
/// | [headline]       | 26 sp    | Bold     | Títulos de pantalla            |
/// | [title]          | 21 sp    | SemiBold | Títulos de tarjeta             |
/// | [body]           | **18 sp**| Regular  | Texto principal                |
/// | [bodySecondary]  | 16 sp    | Regular  | Texto de apoyo                 |
/// | [label]          | **14 sp**| Medium   | Etiquetas — mínimo absoluto    |
///
/// El proyecto anterior llegó a 16 tamaños distintos y a 45 usos de 12 sp o
/// menos, con textos de hasta 9 sp. De ahí que esta escala sea cerrada:
/// **cuerpo por defecto 18 sp, mínimo absoluto 14 sp** ([minimumSize]).
/// Si una pantalla parece necesitar un séptimo tamaño, el problema es la
/// pantalla.
///
/// ## Qué NO define este archivo
///
/// **Color.** Los estilos traen tamaño, peso e interlineado; nada más. El color
/// lo pone el tema o el sitio de uso, siempre con un token de `AppColors`:
///
/// ```dart
/// Text('120 mg/dL', style: AppTypography.display.copyWith(color: AppColors.textPrimary))
/// ```
///
/// Embeber el color aquí crearía una segunda fuente de verdad de color y
/// obligaría a anularlo con `copyWith` en cada texto sobre superficie salvia.
///
/// **`TextTheme` de Material.** El armado del tema y su integración en
/// `ThemeData` son trabajo de `app_theme.dart`, no de esta escala.
///
/// **Fuente.** `fontFamily` queda sin declarar a propósito: se usa la fuente
/// del sistema (Roboto en Android). EIRA no incorpora fuentes externas; hacerlo
/// exigiría una dependencia nueva y su ADR.
///
/// ## Sobre las unidades
///
/// Flutter expresa `fontSize` en *logical pixels*, y el escalado de fuente del
/// sistema se aplica encima mediante `TextScaler`. Por eso "18 sp" se escribe
/// aquí como `fontSize: 18`, y el requisito de seguir siendo usable al 130 % de
/// escala (§24) se verifica en las pantallas, no en este archivo.
@immutable
class AppTypography {
  /// Constructor privado: [AppTypography] es un contenedor de constantes y no
  /// se instancia nunca.
  const AppTypography._();

  // ---------------------------------------------------------------------
  // Tamaños
  //
  // Viven como constantes propias, y no solo dentro de cada TextStyle, para
  // que el tema y los tests puedan afirmar "el cuerpo son 18 sp" sin repetir
  // el literal ni abrir un TextStyle.
  // ---------------------------------------------------------------------

  /// 32 sp. Cifras de métricas y contador de racha.
  static const double displaySize = 32;

  /// 26 sp. Título de pantalla.
  static const double headlineSize = 26;

  /// 21 sp. Título de tarjeta.
  static const double titleSize = 21;

  /// 18 sp. **Tamaño de cuerpo por defecto de la aplicación.**
  static const double bodySize = 18;

  /// 16 sp. Texto de apoyo: descripciones, unidades, pies de tarjeta.
  static const double bodySecondarySize = 16;

  /// 14 sp. Etiquetas. Coincide con [minimumSize].
  static const double labelSize = 14;

  /// **Mínimo absoluto: ningún texto de EIRA baja de 14 sp.**
  ///
  /// No es un valor orientativo. Es el piso que el §24 declara criterio de
  /// aceptación y que la checklist de accesibilidad por pantalla verifica.
  static const double minimumSize = labelSize;

  /// Umbral de "texto grande" de la WCAG: a partir de 24 sp el contraste
  /// mínimo exigible baja de 4.5:1 a 3:1.
  ///
  /// Vive aquí porque depende del tamaño del texto, pero quien lo aplica es la
  /// verificación de contraste de `AppColors`. Solo [display] y [headline] lo
  /// superan.
  static const double largeTextThreshold = 24;

  // ---------------------------------------------------------------------
  // Interlineado
  //
  // DECISIÓN DE ESTA TAREA (T-005), no viene del plan: el §24 no especifica
  // `height` para ningún rol. Se fijan valores estándar de legibilidad —
  // interlineado amplio en texto corrido, ajustado en títulos, donde una línea
  // suelta con demasiado aire se lee como dos bloques distintos. El público de
  // EIRA son personas adultas leyendo texto de salud, así que el cuerpo se
  // trata con holgura.
  //
  // Si el plan llega a fijar interlineado, manda el plan y estos valores se
  // reemplazan.
  // ---------------------------------------------------------------------

  /// Interlineado de [display]: cifra suelta, sin texto corrido alrededor.
  static const double _displayHeight = 1.15;

  /// Interlineado de [headline] y [title].
  static const double _titleHeight = 1.25;

  /// Interlineado de [body]: texto corrido, el más holgado de la escala.
  static const double _bodyHeight = 1.5;

  /// Interlineado de [bodySecondary].
  static const double _bodySecondaryHeight = 1.45;

  /// Interlineado de [label]: una o dos palabras, no necesita aire.
  static const double _labelHeight = 1.3;

  // ---------------------------------------------------------------------
  // Los seis estilos
  // ---------------------------------------------------------------------

  /// 32 sp Bold. Cifras de métricas y contador de racha.
  ///
  /// Supera [largeTextThreshold], de modo que su contraste mínimo exigible es
  /// 3:1. Aun así se usa con `AppColors.textPrimary`, que cumple 4.5:1 de
  /// sobra: la cifra de una métrica es lo primero que el usuario busca.
  static const TextStyle display = TextStyle(
    fontSize: displaySize,
    fontWeight: FontWeight.w700,
    height: _displayHeight,
  );

  /// 26 sp Bold. Título de pantalla. Uno por pantalla.
  ///
  /// También supera [largeTextThreshold].
  static const TextStyle headline = TextStyle(
    fontSize: headlineSize,
    fontWeight: FontWeight.w700,
    height: _titleHeight,
  );

  /// 21 sp SemiBold. Título de tarjeta o de sección dentro de una pantalla.
  static const TextStyle title = TextStyle(
    fontSize: titleSize,
    fontWeight: FontWeight.w600,
    height: _titleHeight,
  );

  /// **18 sp Regular. Texto principal: el estilo por defecto de la app.**
  ///
  /// Ante la duda de qué estilo usar, es este. Los demás son la excepción.
  static const TextStyle body = TextStyle(
    fontSize: bodySize,
    fontWeight: FontWeight.w400,
    height: _bodyHeight,
  );

  /// 16 sp Regular. Texto de apoyo: descripciones, unidades, pies de tarjeta.
  ///
  /// Es texto de apoyo por su tamaño, no por su color: bajarlo además a
  /// `AppColors.textTertiary` deja el contraste en el límite justo de 4.5:1.
  static const TextStyle bodySecondary = TextStyle(
    fontSize: bodySecondarySize,
    fontWeight: FontWeight.w400,
    height: _bodySecondaryHeight,
  );

  /// 14 sp Medium. Etiquetas de campo, de pestaña y de chip.
  ///
  /// **Es el tamaño más pequeño que existe en EIRA** ([minimumSize]). El peso
  /// Medium compensa el tamaño: a 14 sp, Regular pierde legibilidad. Nunca se
  /// reduce con `copyWith(fontSize: …)`.
  static const TextStyle label = TextStyle(
    fontSize: labelSize,
    fontWeight: FontWeight.w500,
    height: _labelHeight,
  );
}
