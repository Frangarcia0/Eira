import 'package:eira/core/storage/local_storage.dart';
import 'package:eira/core/storage/schema_migration.dart';
import 'package:eira/core/storage/storage_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Verificación del mecanismo de migración de esquema (T-007).
///
/// Cubre las seis ramas del arranque descritas en [SchemaMigration], más el
/// catálogo de migraciones. El criterio de aceptación del backlog —«instalación
/// nueva y versión antigua manejadas correctamente»— son los dos primeros
/// grupos; los otros cuatro son los estados en los que **no hay que tocar
/// nada**, que es donde se pierden los datos de la gente.
///
/// ## Por qué este archivo importa `shared_preferences`
///
/// Para una sola llamada: `setMockInitialValues`, que instala el almacén en
/// memoria del paquete. Sin ella no existe implementación de plataforma en un
/// test y `LocalStorage.open()` falla. Todo lo demás —sembrar una versión
/// antigua, un texto corrupto, comprobar qué quedó guardado— pasa por
/// [LocalStorage], que es el punto de acceso que fija la regla E4. La regla
/// gobierna `lib/`; aquí el paquete entra solo como andamio de prueba.
///
/// ## Lo que no se prueba, y por qué
///
/// La rama de «se aplicó el paso pero no se pudo sellar la versión»
/// (`writeInt` devolviendo `false`) no tiene test: el almacén en memoria del
/// paquete nunca falla una escritura, y fabricar un `LocalStorage` que falle
/// exigiría convertirlo en interfaz solo para esto. Es código defensivo con
/// una salida honesta —[MigrationOutcome.failed] sin sellar—, anotado como
/// límite conocido en la bitácora del día.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;

  setUp(() async {
    // Almacén vacío y singleton reiniciado antes de cada test: ninguna prueba
    // hereda la versión que selló la anterior.
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    storage = await LocalStorage.open();
  });

  group('Instalación nueva — la clave no existe', () {
    test('sella la versión actual y declara los datos utilizables', () async {
      final MigrationResult resultado =
          await const SchemaMigration().run(storage);

      expect(resultado.outcome, MigrationOutcome.freshInstall);
      expect(resultado.fromVersion, isNull);
      expect(resultado.toVersion, SchemaMigration.currentVersion);
      expect(resultado.dataIsUsable, isTrue);
    });

    test('la versión queda persistida, no solo informada', () async {
      await const SchemaMigration().run(storage);

      // Lo que importa no es lo que devolvió el método, sino lo que quedó en
      // el almacén: es la lección L1 aplicada a la propia migración.
      expect(storage.contains(StorageKeys.schemaVersion), isTrue);
      expect(
        storage.readInt(StorageKeys.schemaVersion, defaultValue: -1),
        SchemaMigration.currentVersion,
      );
    });

    test('el segundo arranque ya no es una instalación nueva', () async {
      await const SchemaMigration().run(storage);

      final MigrationResult segundo =
          await const SchemaMigration().run(storage);

      expect(segundo.outcome, MigrationOutcome.upToDate);
    });
  });

  group('Versión al día', () {
    test('no cambia nada cuando la guardada ya es la actual', () async {
      await storage.writeInt(
        StorageKeys.schemaVersion,
        SchemaMigration.currentVersion,
      );

      final MigrationResult resultado =
          await const SchemaMigration().run(storage);

      expect(resultado.outcome, MigrationOutcome.upToDate);
      expect(resultado.fromVersion, SchemaMigration.currentVersion);
      expect(resultado.toVersion, SchemaMigration.currentVersion);
      expect(resultado.dataIsUsable, isTrue);
    });
  });

  group('Versión antigua — se migra en cadena', () {
    test('aplica todos los pasos, en orden de versión, y sella el destino',
        () async {
      final List<int> aplicadas = <int>[];
      await storage.writeInt(StorageKeys.schemaVersion, 1);

      // El registro va deliberadamente desordenado: el motor encadena por
      // número de versión, no por la posición en la lista.
      final MigrationResult resultado = await SchemaMigration.withRegistry(
        registry: <Migration>[
          _MigracionDeMentira(target: 3, aplicadas: aplicadas),
          _MigracionDeMentira(target: 2, aplicadas: aplicadas),
        ],
        targetVersion: 3,
      ).run(storage);

      expect(resultado.outcome, MigrationOutcome.migrated);
      expect(resultado.fromVersion, 1);
      expect(resultado.toVersion, 3);
      expect(resultado.dataIsUsable, isTrue);
      expect(aplicadas, <int>[2, 3]);
      expect(storage.readInt(StorageKeys.schemaVersion, defaultValue: -1), 3);
    });

    test('un solo paso pendiente también se aplica', () async {
      final List<int> aplicadas = <int>[];
      await storage.writeInt(StorageKeys.schemaVersion, 1);

      final MigrationResult resultado = await SchemaMigration.withRegistry(
        registry: <Migration>[
          _MigracionDeMentira(target: 2, aplicadas: aplicadas),
        ],
        targetVersion: 2,
      ).run(storage);

      expect(resultado.outcome, MigrationOutcome.migrated);
      expect(aplicadas, <int>[2]);
      expect(storage.readInt(StorageKeys.schemaVersion, defaultValue: -1), 2);
    });
  });

  group('Versión futura — datos de una app más nueva', () {
    test('no ejecuta ninguna migración ni toca el almacén', () async {
      final List<int> aplicadas = <int>[];
      await storage.writeInt(StorageKeys.schemaVersion, 5);
      await storage.writeString(StorageKeys.profile, '{"intacto":true}');

      final MigrationResult resultado = await SchemaMigration.withRegistry(
        registry: <Migration>[
          _MigracionDeMentira(target: 2, aplicadas: aplicadas),
        ],
        targetVersion: 2,
      ).run(storage);

      expect(resultado.outcome, MigrationOutcome.futureVersion);
      expect(resultado.fromVersion, 5);
      expect(resultado.dataIsUsable, isFalse);
      expect(aplicadas, isEmpty);
      expect(storage.readInt(StorageKeys.schemaVersion, defaultValue: -1), 5);
      expect(
        storage.readString(StorageKeys.profile, defaultValue: ''),
        '{"intacto":true}',
      );
    });
  });

  group('Versión ilegible — el dato no es una versión', () {
    test('un texto donde va la versión no se pisa', () async {
      await storage.writeString(StorageKeys.schemaVersion, 'dos');

      final MigrationResult resultado =
          await const SchemaMigration().run(storage);

      expect(resultado.outcome, MigrationOutcome.unreadableVersion);
      expect(resultado.fromVersion, isNull);
      expect(resultado.dataIsUsable, isFalse);
      // Sigue siendo texto: nadie lo sobrescribió con un entero.
      expect(
        storage.readString(StorageKeys.schemaVersion, defaultValue: ''),
        'dos',
      );
    });

    for (final int invalida in <int>[0, -3]) {
      test('$invalida está por debajo de la primera versión y no se toca',
          () async {
        await storage.writeInt(StorageKeys.schemaVersion, invalida);

        final MigrationResult resultado =
            await const SchemaMigration().run(storage);

        expect(resultado.outcome, MigrationOutcome.unreadableVersion);
        expect(resultado.dataIsUsable, isFalse);
        expect(
          storage.readInt(StorageKeys.schemaVersion, defaultValue: -99),
          invalida,
        );
      });
    }
  });

  group('Cadena fallida', () {
    test('un paso incompleto detiene la cadena y sella hasta donde llegó',
        () async {
      final List<int> aplicadas = <int>[];
      await storage.writeInt(StorageKeys.schemaVersion, 1);

      final MigrationResult resultado = await SchemaMigration.withRegistry(
        registry: <Migration>[
          _MigracionDeMentira(target: 2, aplicadas: aplicadas),
          _MigracionDeMentira(
            target: 3,
            aplicadas: aplicadas,
            completa: false,
          ),
          _MigracionDeMentira(target: 4, aplicadas: aplicadas),
        ],
        targetVersion: 4,
      ).run(storage);

      expect(resultado.outcome, MigrationOutcome.failed);
      expect(resultado.fromVersion, 1);
      expect(resultado.dataIsUsable, isFalse);
      // El paso 2 sí se selló; el 3 falló y el 4 nunca corrió. Esto es lo que
      // permite que el próximo arranque retome en el 3 y no desde el 2.
      expect(resultado.toVersion, 2);
      expect(aplicadas, <int>[2, 3]);
      expect(storage.readInt(StorageKeys.schemaVersion, defaultValue: -1), 2);
    });

    test('una versión sin migración registrada no se sella', () async {
      await storage.writeInt(StorageKeys.schemaVersion, 1);

      final MigrationResult resultado = await const SchemaMigration
          .withRegistry(registry: <Migration>[], targetVersion: 2)
          .run(storage);

      expect(resultado.outcome, MigrationOutcome.failed);
      expect(resultado.toVersion, 1);
      expect(resultado.dataIsUsable, isFalse);
      expect(storage.readInt(StorageKeys.schemaVersion, defaultValue: -1), 1);
    });
  });

  group('Catálogo de migraciones', () {
    // Estos dos tests pasan hoy sin recorrer nada: el registro está vacío y
    // `currentVersion` es 1. Están escritos igual porque el día que alguien
    // suba `currentVersion` sin registrar la migración, este archivo es lo
    // único que lo detiene antes de que la app llegue a un dispositivo.
    test('hay exactamente una migración por cada versión del rango', () {
      for (int version = SchemaMigration.firstVersion + 1;
          version <= SchemaMigration.currentVersion;
          version++) {
        expect(
          SchemaMigration.migrations
              .where((Migration paso) => paso.target == version)
              .length,
          1,
          reason: 'la versión $version no tiene exactamente una migración en '
              'SchemaMigration.migrations. Subir currentVersion exige '
              'registrar el paso que la produce.',
        );
      }
    });

    test('ninguna migración apunta fuera del rango', () {
      for (final Migration paso in SchemaMigration.migrations) {
        expect(paso.target, greaterThan(SchemaMigration.firstVersion));
        expect(paso.target, lessThanOrEqualTo(SchemaMigration.currentVersion));
      }
    });
  });
}

/// Migración de prueba: no transforma nada, solo deja constancia de que se
/// aplicó y de en qué orden.
///
/// Existe porque el registro real está vacío —hoy no hay ninguna versión
/// anterior de qué migrar— y el motor de encadenado necesita probarse igual.
class _MigracionDeMentira extends Migration {
  _MigracionDeMentira({
    required this.target,
    required this.aplicadas,
    this.completa = true,
  });

  @override
  final int target;

  /// Bitácora compartida por todos los pasos de un mismo test: el orden de
  /// esta lista es el orden real en que se aplicaron.
  final List<int> aplicadas;

  /// Si el paso se completa. `false` simula la migración que no termina.
  final bool completa;

  @override
  Future<bool> apply(LocalStorage storage) async {
    aplicadas.add(target);
    return completa;
  }
}
