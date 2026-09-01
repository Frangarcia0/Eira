import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Una pestaña de la barra de navegación.
///
/// Es privada a propósito: el orden de esta lista y el orden de las ramas de
/// `StatefulShellRoute` tienen que coincidir, y la única forma de que no se
/// separen es que nadie más pueda construir pestañas desde fuera.
@immutable
class _Pestana {
  const _Pestana({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;

  /// Icono en reposo, de contorno.
  final IconData icon;

  /// Icono de la pestaña activa, relleno.
  ///
  /// El cambio de relleno importa: junto con el resaltado de la etiqueta hace
  /// que la pestaña seleccionada se distinga por **forma** y no solo por
  /// color, que es la regla del §24 «el color nunca es el único portador de
  /// información».
  final IconData selectedIcon;
}

/// Las cinco pestañas del §23, en el orden del plan.
///
/// `Hoy · Hábitos · Métricas · Descubre · Perfil`
///
/// Las etiquetas son cortas por accesibilidad: cinco destinos tienen que caber
/// con el texto visible y con el escalado del sistema al 130 % (§24).
const List<_Pestana> _pestanas = <_Pestana>[
  _Pestana(
    label: 'Hoy',
    icon: Icons.wb_sunny_outlined,
    selectedIcon: Icons.wb_sunny,
  ),
  _Pestana(
    label: 'Hábitos',
    icon: Icons.check_circle_outline,
    selectedIcon: Icons.check_circle,
  ),
  _Pestana(
    label: 'Métricas',
    icon: Icons.show_chart_outlined,
    selectedIcon: Icons.show_chart,
  ),
  _Pestana(
    label: 'Descubre',
    icon: Icons.explore_outlined,
    selectedIcon: Icons.explore,
  ),
  _Pestana(
    label: 'Perfil',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
];

/// Armazón de la aplicación: el contenido de la pestaña activa con la barra de
/// navegación de cinco pestañas debajo.
///
/// Es el `builder` de `StatefulShellRoute.indexedStack` en
/// `app_router.dart`. Recibe [navigationShell], que es a la vez el widget que
/// dibuja la pestaña activa —un `IndexedStack` con un `Navigator` por rama— y
/// el objeto que sabe cuál está activa y cómo cambiar de una a otra.
///
/// ## Lo que esta clase no hace
///
/// No navega con `context.go()`. Cambiar de pestaña con `go()` reemplazaría la
/// pila entera y tiraría el estado de las otras cuatro, que es justo lo que
/// `StatefulShellRoute` existe para evitar. Se usa
/// `StatefulNavigationShell.goBranch`, que cambia de rama conservando la pila
/// de cada una. La decisión, y por qué se aparta de la letra del §23, está en
/// `docs/decisions/ADR-010`.
class EiraShell extends StatelessWidget {
  const EiraShell({required this.navigationShell, super.key});

  /// Pestaña activa y control de cambio de pestaña, provisto por `go_router`.
  final StatefulNavigationShell navigationShell;

  /// Cambia a la pestaña [index].
  ///
  /// Tocar la pestaña que ya está activa devuelve a la raíz de esa pestaña, en
  /// vez de no hacer nada: es el gesto que Material define para salir de una
  /// pantalla de detalle sin buscar el botón de retorno, y con el mapa del §23
  /// —donde cuatro de las cinco pestañas tienen subárbol— va a hacer falta.
  void _irAPestana(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(
      _pestanas.length == navigationShell.route.branches.length,
      'La barra tiene ${_pestanas.length} pestañas y el shell '
      '${navigationShell.route.branches.length} ramas. Los dos órdenes son el '
      'mismo: agregar o quitar una pestaña se hace en los dos sitios.',
    );

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _irAPestana,
        // §24: la etiqueta de texto está siempre visible. Nunca solo icono.
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: <Widget>[
          for (final _Pestana pestana in _pestanas)
            NavigationDestination(
              icon: Icon(pestana.icon),
              selectedIcon: Icon(pestana.selectedIcon),
              label: pestana.label,
            ),
        ],
      ),
    );
  }
}
