import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Destino vecino que una [RoutePlaceholderPage] ofrece como botón.
///
/// Es un registro y no una clase porque el archivo completo es temporal: se
/// borra entero cuando la última pantalla real ocupe su lugar.
typedef PlaceholderDestination = ({String label, String location});

/// Pantalla vacía temporal que ocupa el lugar de una pantalla real todavía no
/// construida.
///
/// ## Por qué existe
///
/// T-010 monta el enrutado —el shell de cinco pestañas y el mapa de rutas del
/// `PLAN_MAESTRO` §23— **antes** de que exista ninguna pantalla: las reales
/// entran de T-015 en adelante. Sin algo que dibujar, el shell no se puede
/// probar, y la Definition of Done exige probar en dispositivo físico.
///
/// ## Por qué vive en `core/router/` y no en `features/`
///
/// Un archivo desechable no debe ocupar el nombre definitivo de una pantalla
/// real. Si esto fueran diez `features/*/pages/*_page.dart` vacíos, cada tarea
/// de T-015 en adelante tendría que sobrescribir un archivo en vez de crearlo,
/// los nombres quedarían decididos antes de diseñar la pantalla y, si alguna
/// pestaña cambiara, quedarían archivos sin referencias (regla E7). Con un
/// archivo y una clase, la limpieza es borrar el archivo, y el día que deje de
/// estar referenciado lo dice `tool/check_architecture.dart` sin que nadie lo
/// recuerde.
///
/// ## Los botones no son decoración
///
/// [destinations] es lo que hace demostrable el criterio de aceptación de
/// T-010 —«navegación entre pantallas vacías»— en el flujo de onboarding, que
/// queda fuera del shell y por lo tanto no tiene barra de pestañas que lo
/// recorra. Dentro del shell no hacen falta: la barra de navegación ya
/// comunica las cinco pestañas entre sí.
class RoutePlaceholderPage extends StatelessWidget {
  const RoutePlaceholderPage({
    required this.title,
    required this.location,
    this.pendingTask,
    this.destinations = const <PlaceholderDestination>[],
    super.key,
  });

  /// Nombre de la pantalla que ocupará este lugar. Se muestra en la barra
  /// superior.
  final String title;

  /// Ruta que atiende esta pantalla, tal como la declara [Routes]. Se muestra
  /// en pantalla para poder verificar el mapa del §23 recorriendo la app.
  final String location;

  /// Identificador de la tarea del backlog que construirá la pantalla real.
  ///
  /// Se muestra para que quien recorra la app sepa que la pantalla está
  /// pendiente por planificación y no por un fallo.
  final String? pendingTask;

  /// Rutas vecinas alcanzables desde aquí, en el orden en que se ofrecen.
  final List<PlaceholderDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Pantalla en construcción',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                pendingTask == null
                    ? 'Aquí va $title.'
                    : 'Aquí va $title. Se construye en la tarea $pendingTask.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Text(
                location,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              for (final PlaceholderDestination destination in destinations)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: FilledButton(
                    // 56 dp: área táctil de acción primaria (§24).
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                    onPressed: () => context.go(destination.location),
                    child: Text(destination.label),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
