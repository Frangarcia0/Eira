import 'package:flutter/material.dart';

/// Paleta cerrada de EIRA: el **único** origen de color de la aplicación.
///
/// Este archivo es el único del proyecto autorizado a contener literales
/// `Color(0xFF…)` (regla estructural E5, PLAN_MAESTRO §20). El verificador
/// `tool/check_architecture.dart` falla si aparece un literal de color, un
/// `Color.fromARGB` o un `Colors.*` fuera de `lib/core/theme/`.
///
/// **Para agregar un color nuevo no basta con escribirlo aquí.** Hay que medir
/// su contraste contra cada superficie sobre la que se vaya a usar, con la
/// fórmula de luminancia relativa de la WCAG 2.1, y registrar el resultado en
/// `docs/accessibility/contrast-verification.md`. El test
/// `test/core/theme/app_colors_contrast_test.dart` verifica cada par de la
/// tabla en cada ejecución de `flutter test`.
///
/// Umbrales aplicables (PLAN_MAESTRO §24): 4.5:1 para texto normal, 3:1 para
/// texto de 24 sp o más y para elementos interactivos.
///
/// La escala salvia nace del color de marca `#979F80`, que **reprueba AA**
/// como color de texto. Ver [sage400] y `docs/decisions/ADR-008`.
@immutable
class AppColors {
  /// Constructor privado: [AppColors] es un contenedor de constantes y no se
  /// instancia nunca.
  const AppColors._();

  // ---------------------------------------------------------------------
  // Escala salvia — identidad de marca
  // ---------------------------------------------------------------------

  /// Fondo de sección suave, para separar bloques sin dibujar un borde.
  static const Color sage50 = Color(0xFFF2F4EC);

  /// Contenedor primario: chips, tarjetas destacadas, fondos de estado activo.
  static const Color sage100 = Color(0xFFE4E8DA);

  /// Borde sobre superficie salvia, donde [outline] resultaría demasiado duro.
  static const Color sage200 = Color(0xFFCBD2BB);

  /// Color de marca exacto. Identidad visual: decoración, ilustración y
  /// superficies grandes.
  ///
  /// **PROHIBIDO usarlo como color de texto o como relleno de un botón que
  /// lleve texto encima.** Contra blanco da **2.77:1** y reprueba el mínimo
  /// AA de 4.5:1 (medición en `docs/accessibility/contrast-verification.md`).
  /// Es la corrección obligatoria que el PLAN_MAESTRO §24 declara no
  /// negociable y que el anexo A.10 documenta como defecto heredado.
  ///
  /// Para texto, iconos y rellenos de botón, usa [sage600].
  static const Color sage400 = Color(0xFF979F80);

  /// **Primario de la aplicación.** Relleno de botón, texto e iconos salvia.
  ///
  /// Es la variante oscurecida de [sage400] que sí aprueba AA: 5.62:1 contra
  /// blanco y 5.42:1 sobre [background].
  static const Color sage600 = Color(0xFF626B4F);

  /// Primario en estado presionado y énfasis sobre superficies claras.
  static const Color sage700 = Color(0xFF4C5340);

  // ---------------------------------------------------------------------
  // Texto
  // ---------------------------------------------------------------------

  /// Texto principal: cuerpo, títulos y cifras de métricas.
  static const Color textPrimary = Color(0xFF1B1D18);

  /// Texto de apoyo: subtítulos, descripciones, unidades.
  static const Color textSecondary = Color(0xFF4A4F44);

  /// Texto terciario. **4.86:1 sobre [background]: el mínimo aceptable.**
  ///
  /// Solo para texto de cuerpo de 14 sp o más. No usarlo para texto pequeño,
  /// para marcas de agua ni para representar un control deshabilitado: no
  /// queda margen alguno sobre el umbral de 4.5:1.
  static const Color textTertiary = Color(0xFF6B7163);

  /// Texto e iconos sobre relleno primario ([sage600] o [sage700]).
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------
  // Superficie
  // ---------------------------------------------------------------------

  /// Fondo de pantalla.
  static const Color background = Color(0xFFFBFBF8);

  /// Superficie elevada: tarjetas, hojas inferiores, diálogos.
  static const Color surface = Color(0xFFFFFFFF);

  /// Borde de campos de formulario y de controles no rellenos.
  ///
  /// Aprueba el umbral de 3:1 para elementos interactivos: 3.29:1 sobre
  /// [surface] y 3.17:1 sobre [background].
  static const Color outline = Color(0xFF8A9081);

  /// Divisor **decorativo**: 1.44:1 contra [surface], reprueba cualquier
  /// umbral.
  ///
  /// Por eso no puede ser nunca el único elemento que comunique una
  /// separación, un estado o un límite. Siempre acompañado de espaciado,
  /// texto o forma (PLAN_MAESTRO §24: el color nunca es el único portador de
  /// información).
  static const Color divider = Color(0xFFD6D8CE);

  // ---------------------------------------------------------------------
  // Semánticos de interfaz
  //
  // ⚠ ADVERTENCIA — LÍMITE CLÍNICO
  //
  // `error`, `success` e `info` describen estados de la INTERFAZ: un guardado
  // correcto, un error de validación, un aviso informativo.
  //
  // Está PROHIBIDO usarlos para clasificar valores clínicos —glucosa,
  // presión arterial, peso— ni directa ni indirectamente. Pintar de rojo una
  // glucosa alta o de verde una presión "normal" es emitir un juicio clínico
  // sin decirlo, y EIRA no diagnostica: registra y grafica.
  //
  // Un gráfico de tendencia se dibuja con la escala salvia y con
  // `textSecondary`, nunca con estos tres colores.
  //
  // CLAUDE.md regla 5 · ADR-003 · PLAN_MAESTRO §14.
  // ---------------------------------------------------------------------

  /// Error de interfaz: validación fallida, acción que no se pudo completar.
  static const Color error = Color(0xFFA03028);

  /// Superficie de un bloque de error. Texto encima: [error].
  static const Color errorSurface = Color(0xFFFBEBE9);

  /// Confirmación de interfaz: el dato se guardó de verdad.
  static const Color success = Color(0xFF2F6B4F);

  /// Superficie de un bloque de confirmación. Texto encima: [success].
  static const Color successSurface = Color(0xFFE8F2EC);

  /// Aviso informativo de interfaz: nota, ayuda contextual, fuente del
  /// contenido.
  static const Color info = Color(0xFF2B5C7A);

  /// Superficie de un bloque informativo. Texto encima: [info].
  static const Color infoSurface = Color(0xFFE7F0F5);
}
