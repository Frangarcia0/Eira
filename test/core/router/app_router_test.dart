import 'package:eira/core/router/app_router.dart';
import 'package:eira/core/router/eira_shell.dart';
import 'package:eira/core/router/routes.dart';
import 'package:eira/features/onboarding/pages/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Pruebas del enrutador de T-010.
///
/// Alcance deliberadamente corto: el §27 no sitúa el enrutado en P0 y todavía
/// no hay ninguna pantalla real que navegar. Se comprueba lo único que T-010
/// entrega —que el mapa del §23 existe y responde— más las dos propiedades que
/// son criterio de aceptación y no se pueden verificar mirando el código: que
/// la redirección inicial es síncrona (N6) y que la barra de cinco pestañas
/// aguanta el escalado de texto del sistema al 130 % (§24).
void main() {
  /// Monta la app real —`MaterialApp.router`— sobre un enrutador recién
  /// construido, en un lienzo del tamaño de un teléfono de gama media.
  Future<void> montarApp(
    WidgetTester tester,
    GoRouter router, {
    double escalaDeTexto = 1,
  }) async {
    tester.view
      ..physicalSize = const Size(1080, 1920)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(escalaDeTexto)),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('createAppRouter', () {
    testWidgets('construye el enrutador y arranca sin excepciones', (
      WidgetTester tester,
    ) async {
      final GoRouter router = createAppRouter();
      addTearDown(router.dispose);

      await montarApp(tester, router);

      expect(tester.takeException(), isNull);
    });

    testWidgets('la raíz redirige al onboarding mientras esté sin completar', (
      WidgetTester tester,
    ) async {
      final GoRouter router = createAppRouter();
      addTearDown(router.dispose);

      await montarApp(tester, router);

      expect(router.state.uri.toString(), Routes.onboardingWelcome);
      expect(find.byType(WelcomePage), findsOneWidget);
      // El onboarding queda fuera del shell: no hay barra de pestañas.
      expect(find.byType(EiraShell), findsNothing);
    });

    testWidgets('la redirección inicial es síncrona — regla N6', (
      WidgetTester tester,
    ) async {
      final GoRouter router = createAppRouter();
      addTearDown(router.dispose);

      tester.view
        ..physicalSize = const Size(1080, 1920)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      // Un solo `pump`: el primer fotograma, sin dejar correr temporizadores ni
      // microtareas pendientes. Si la redirección esperara algo, aquí todavía
      // no habría llegado a destino y haría falta un indicador de carga, que es
      // lo que N6 prohíbe.
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      expect(router.state.uri.toString(), Routes.onboardingWelcome);
      expect(find.byType(WelcomePage), findsOneWidget);
    });

    testWidgets('el contenedor /onboarding lleva al primer paso', (
      WidgetTester tester,
    ) async {
      final GoRouter router = createAppRouter();
      addTearDown(router.dispose);

      await montarApp(tester, router);
      router.go(Routes.onboarding);
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), Routes.onboardingWelcome);
    });

    testWidgets('las cinco pestañas resuelven dentro del shell', (
      WidgetTester tester,
    ) async {
      const Map<String, String> pestanas = <String, String>{
        Routes.today: 'Hoy',
        Routes.habits: 'Hábitos',
        Routes.metrics: 'Métricas',
        Routes.discover: 'Descubre',
        Routes.profile: 'Perfil',
      };

      final GoRouter router = createAppRouter();
      addTearDown(router.dispose);
      await montarApp(tester, router);

      for (final MapEntry<String, String> pestana in pestanas.entries) {
        router.go(pestana.key);
        await tester.pumpAndSettle();

        expect(router.state.uri.toString(), pestana.key);
        expect(find.byType(EiraShell), findsOneWidget);
        expect(find.byType(NavigationBar), findsOneWidget);
        // El título aparece dos veces: en la barra superior de la pantalla y en
        // la etiqueta de su pestaña.
        expect(find.text(pestana.value), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('tocar una pestaña cambia de rama sin salir del shell', (
      WidgetTester tester,
    ) async {
      final GoRouter router = createAppRouter();
      addTearDown(router.dispose);

      await montarApp(tester, router);
      router.go(Routes.today);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Métricas'));
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), Routes.metrics);
      expect(find.byType(EiraShell), findsOneWidget);
    });

    testWidgets('una ruta inexistente muestra la pantalla de error, no un fallo', (
      WidgetTester tester,
    ) async {
      final GoRouter router = createAppRouter();
      addTearDown(router.dispose);

      await montarApp(tester, router);
      router.go('/esta-ruta-no-existe');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('La pantalla que buscabas no existe.'), findsOneWidget);
      // §24: el mensaje dice qué pasó y qué hacer, sin códigos técnicos.
      expect(find.text('Ir al inicio'), findsOneWidget);
    });

    testWidgets('la barra de pestañas aguanta el escalado de texto al 130 %', (
      WidgetTester tester,
    ) async {
      final GoRouter router = createAppRouter();
      addTearDown(router.dispose);

      await montarApp(tester, router, escalaDeTexto: 1.3);
      router.go(Routes.today);
      await tester.pumpAndSettle();

      // Un desbordamiento de la barra se reporta como excepción del fotograma.
      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Descubre'), findsOneWidget);
    });
  });
}
