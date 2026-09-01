import 'package:eira/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Raíz de la aplicación EIRA.
///
/// Es un `StatefulWidget` por una sola razón: el `GoRouter` tiene que
/// construirse **una vez**. Creado dentro de `build`, cada reconstrucción
/// produciría un enrutador nuevo, y con él una pila de navegación nueva: la
/// persona perdería la pantalla en la que está cada vez que cambie el tamaño de
/// letra del sistema o gire el teléfono.
///
/// El tema propio (T-004 y T-005) todavía no se instala aquí: `app_colors.dart`
/// y `app_typography.dart` existen, pero el `ThemeData` que los une es de una
/// tarea posterior. Hasta entonces se usa el tema por defecto de Material.
class EiraApp extends StatefulWidget {
  const EiraApp({super.key});

  @override
  State<EiraApp> createState() => _EiraAppState();
}

class _EiraAppState extends State<EiraApp> {
  /// `late final` con inicializador: se construye en el primer acceso y no se
  /// vuelve a construir. `dispose()` no lo toca porque el enrutador vive tanto
  /// como la app.
  late final GoRouter _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EIRA',
      routerConfig: _router,
    );
  }
}
