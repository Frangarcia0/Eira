import 'dart:math' as math;
import 'dart:ui';

import 'package:eira/core/theme/app_colors.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verificación automática del contraste de la paleta (T-004).
///
/// Los ratios se calculan aquí desde las constantes reales de [AppColors], no
/// desde copias de los hexadecimales. Así, oscurecer o aclarar un token sin
/// revisar `docs/accessibility/contrast-verification.md` hace fallar el build
/// en lugar de degradar la accesibilidad en silencio.
///
/// Este archivo **no declara ningún literal de color propio** a propósito: la
/// regla E5 reserva esa potestad a `lib/core/theme/`, y duplicar aquí los
/// hexadecimales permitiría que el test siguiera pasando con la paleta ya
/// cambiada.
void main() {
  // Umbrales de la WCAG 2.1 SC 1.4.3 y SC 1.4.11, según el PLAN_MAESTRO §24.
  const double minimoTextoNormal = 4.5;
  const double minimoInteractivo = 3.0;

  group('Texto normal (>= 4.5:1)', () {
    test('blanco sobre el primario — texto del botón principal', () {
      // 5.62
      expect(
        _ratio(AppColors.textOnPrimary, AppColors.sage600),
        greaterThanOrEqualTo(minimoTextoNormal),
      );
    });

    test('blanco sobre el primario presionado', () {
      // 8.02
      expect(
        _ratio(AppColors.textOnPrimary, AppColors.sage700),
        greaterThanOrEqualTo(minimoTextoNormal),
      );
    });

    test('primario sobre el fondo — texto e iconos salvia', () {
      // 5.42
      expect(
        _ratio(AppColors.sage600, AppColors.background),
        greaterThanOrEqualTo(minimoTextoNormal),
      );
    });

    test('primario sobre la superficie suave', () {
      // 5.07
      expect(
        _ratio(AppColors.sage600, AppColors.sage50),
        greaterThanOrEqualTo(minimoTextoNormal),
      );
    });

    test('texto principal sobre el fondo', () {
      // 16.39
      expect(
        _ratio(AppColors.textPrimary, AppColors.background),
        greaterThanOrEqualTo(minimoTextoNormal),
      );
    });

    test('texto principal sobre la tarjeta', () {
      // 17.00
      expect(
        _ratio(AppColors.textPrimary, AppColors.surface),
        greaterThanOrEqualTo(minimoTextoNormal),
      );
    });

    test('texto principal sobre el contenedor primario', () {
      // 13.64
      expect(
        _ratio(AppColors.textPrimary, AppColors.sage100),
        greaterThanOrEqualTo(minimoTextoNormal),
      );
    });

    test('texto principal sobre la superficie salvia media', () {
      // 10.91
      expect(
        _ratio(AppColors.textPrimary, AppColors.sage200),
        greaterThanOrEqualTo(minimoTextoNormal),
      );
    });

    test('texto secundario sobre el fondo', () {
      // 8.13
      expect(
        _ratio(AppColors.textSecondary, AppColors.background),
        greaterThanOrEqualTo(minimoTextoNormal),
      );
    });

    test('texto terciario sobre el fondo — el par más ajustado', () {
      // 4.86, contra un mínimo de 4.5. Es el margen más estrecho de toda la
      // paleta y la razón de que textTertiary solo se use en 14 sp o más.
      expect(
        _ratio(AppColors.textTertiary, AppColors.background),
        greaterThanOrEqualTo(minimoTextoNormal),
      );
    });

    test('error sobre la tarjeta', () {
      // 7.12
      expect(
        _ratio(AppColors.error, AppColors.surface),
        greaterThanOrEqualTo(minimoTextoNormal),
      );
    });

    test('error sobre su propia superficie', () {
      // 6.16
      expect(
        _ratio(AppColors.error, AppColors.errorSurface),
        greaterThanOrEqualTo(minimoTextoNormal),
      );
    });

    test('blanco sobre el relleno de error', () {
      // 7.12
      expect(
        _ratio(AppColors.textOnPrimary, AppColors.error),
        greaterThanOrEqualTo(minimoTextoNormal),
      );
    });

    test('confirmación sobre la tarjeta', () {
      // 6.29
      expect(
        _ratio(AppColors.success, AppColors.surface),
        greaterThanOrEqualTo(minimoTextoNormal),
      );
    });

    test('confirmación sobre su propia superficie', () {
      // 5.50
      expect(
        _ratio(AppColors.success, AppColors.successSurface),
        greaterThanOrEqualTo(minimoTextoNormal),
      );
    });

    test('informativo sobre la tarjeta', () {
      // 7.21
      expect(
        _ratio(AppColors.info, AppColors.surface),
        greaterThanOrEqualTo(minimoTextoNormal),
      );
    });
  });

  group('Interactivo y texto grande (>= 3:1)', () {
    test('borde de campo sobre la tarjeta', () {
      // 3.29
      expect(
        _ratio(AppColors.outline, AppColors.surface),
        greaterThanOrEqualTo(minimoInteractivo),
      );
    });

    test('borde de campo sobre el fondo', () {
      // 3.17
      expect(
        _ratio(AppColors.outline, AppColors.background),
        greaterThanOrEqualTo(minimoInteractivo),
      );
    });
  });

  group('Excepciones documentadas', () {
    test('el salvia de marca NO alcanza 4.5:1 contra blanco', () {
      // Intencional, no es un defecto pendiente de arreglar.
      //
      // sage400 es el color de marca exacto (#979F80) y da 2.77:1 con texto
      // blanco encima. Por eso NO es color de texto ni relleno de botón: su
      // lugar es la decoración y las superficies grandes sin texto.
      //
      // Este test existe para que la excepción quede afirmada y no supuesta.
      // Si alguien aclarara sage400 hasta hacerlo apto para texto, este test
      // fallaría y obligaría a revisar la decisión completa (ADR-008) en vez
      // de dejar que el cambio pase inadvertido.
      expect(_ratio(AppColors.textOnPrimary, AppColors.sage400), lessThan(4.5));
    });

    test('el divisor es decorativo y NO alcanza 3:1 contra la tarjeta', () {
      // 1.44. Permitido porque no porta información: nunca es el único
      // elemento que comunica una separación, un estado o un límite.
      expect(_ratio(AppColors.divider, AppColors.surface), lessThan(3.0));
    });
  });

  group('La tabla documentada coincide con los tokens', () {
    // Los umbrales de arriba impiden bajar de AA, pero no detectan que un token
    // cambie y siga aprobando: en ese caso los ratios publicados en
    // docs/accessibility/contrast-verification.md quedarían obsoletos sin que
    // nada avisara. Este bloque ancla cada valor de la tabla.
    const Map<String, double> tabla = <String, double>{
      'textOnPrimary/sage600': 5.62,
      'textOnPrimary/sage700': 8.02,
      'sage600/background': 5.42,
      'sage600/sage50': 5.07,
      'textPrimary/background': 16.39,
      'textPrimary/surface': 17.00,
      'textPrimary/sage100': 13.64,
      'textPrimary/sage200': 10.91,
      'textSecondary/background': 8.13,
      'textTertiary/background': 4.86,
      'outline/surface': 3.29,
      'outline/background': 3.17,
      'error/surface': 7.12,
      'error/errorSurface': 6.16,
      'textOnPrimary/error': 7.12,
      'success/surface': 6.29,
      'success/successSurface': 5.50,
      'info/surface': 7.21,
      'textOnPrimary/sage400': 2.77,
      'divider/surface': 1.44,
    };

    final Map<String, Color> tokens = <String, Color>{
      'sage50': AppColors.sage50,
      'sage100': AppColors.sage100,
      'sage200': AppColors.sage200,
      'sage400': AppColors.sage400,
      'sage600': AppColors.sage600,
      'sage700': AppColors.sage700,
      'textPrimary': AppColors.textPrimary,
      'textSecondary': AppColors.textSecondary,
      'textTertiary': AppColors.textTertiary,
      'textOnPrimary': AppColors.textOnPrimary,
      'background': AppColors.background,
      'surface': AppColors.surface,
      'outline': AppColors.outline,
      'divider': AppColors.divider,
      'error': AppColors.error,
      'errorSurface': AppColors.errorSurface,
      'success': AppColors.success,
      'successSurface': AppColors.successSurface,
      'info': AppColors.info,
      'infoSurface': AppColors.infoSurface,
    };

    for (final MapEntry<String, double> fila in tabla.entries) {
      test('${fila.key} = ${fila.value.toStringAsFixed(2)}:1', () {
        final List<String> partes = fila.key.split('/');
        final Color frente = tokens[partes[0]]!;
        final Color fondo = tokens[partes[1]]!;
        expect(
          _ratio(frente, fondo),
          closeTo(fila.value, 0.005),
          reason:
              'El ratio dejó de coincidir con la tabla de '
              'docs/accessibility/contrast-verification.md. Vuelve a medir y '
              'actualiza el documento antes de tocar el token.',
        );
      });
    }
  });
}

/// Linealiza un canal sRGB ya normalizado a `[0, 1]` (WCAG 2.1).
double _linealizar(double canal) {
  return canal <= 0.03928
      ? canal / 12.92
      : math.pow((canal + 0.055) / 1.055, 2.4).toDouble();
}

/// Luminancia relativa de [color] según la WCAG 2.1.
///
/// Usa `r`, `g` y `b`, que en Flutter entregan el canal ya normalizado a
/// `[0, 1]`. La paleta es opaca, así que el canal alfa no interviene.
double _luminancia(Color color) {
  return 0.2126 * _linealizar(color.r) +
      0.7152 * _linealizar(color.g) +
      0.0722 * _linealizar(color.b);
}

/// Ratio de contraste entre [frente] y [fondo]: `(Lclaro + 0.05) / (Loscuro + 0.05)`.
///
/// El orden de los argumentos no altera el resultado; se conserva por
/// legibilidad de cada caso de prueba.
double _ratio(Color frente, Color fondo) {
  final double a = _luminancia(frente);
  final double b = _luminancia(fondo);
  final double claro = a > b ? a : b;
  final double oscuro = a > b ? b : a;
  return (claro + 0.05) / (oscuro + 0.05);
}
