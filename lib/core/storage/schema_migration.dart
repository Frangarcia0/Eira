import 'package:eira/core/storage/local_storage.dart';
import 'package:eira/core/storage/storage_keys.dart';
import 'package:flutter/foundation.dart' show immutable, visibleForTesting;

/// Cómo terminó [SchemaMigration.run].
///
/// El valor es lo único que la capa de arriba necesita mirar para decidir qué
/// hacer: los tres primeros dejan el almacén en un estado legible, los tres
/// últimos no. Esa distinción está en [dataIsUsable] para que nadie tenga que
/// recordar de memoria cuáles son cuáles.
enum MigrationOutcome {
  /// No existía [StorageKeys.schemaVersion]: instalación nueva. No había nada
  /// que migrar y se selló la versión actual.
  freshInstall(dataIsUsable: true),

  /// La versión guardada ya era la actual. No se escribió nada.
  upToDate(dataIsUsable: true),

  /// La versión guardada era anterior y la cadena de migraciones se completó.
  migrated(dataIsUsable: true),

  /// Los datos son de una versión **más nueva** que esta app: alguien instaló
  /// un APK anterior sobre sus datos, o restauró un respaldo posterior.
  ///
  /// No existe migración hacia atrás, así que no se tocó ni un byte. La app no
  /// debe leer estos datos: no sabe qué forma tienen.
  futureVersion(dataIsUsable: false),

  /// La clave existía pero su contenido no es un número de versión: hay un
  /// texto donde va un entero, o un valor menor a
  /// [SchemaMigration.firstVersion].
  ///
  /// Tampoco se tocó nada. Pisar esa clave con la versión actual declararía
  /// migrados unos datos que nadie miró.
  unreadableVersion(dataIsUsable: false),

  /// Un paso de la cadena no se completó, faltaba una migración en el
  /// registro, o no se pudo escribir la versión.
  ///
  /// La versión sellada refleja hasta dónde se llegó de verdad, así que el
  /// próximo arranque retoma en el paso correcto.
  failed(dataIsUsable: false);

  const MigrationOutcome({required this.dataIsUsable});

  /// Si el almacén quedó en un estado que la app puede leer.
  ///
  /// Cuando es `false`, la app **no debe continuar hacia el contenido normal**:
  /// tiene que mostrar una pantalla que explique qué pasó, sin escribir nada
  /// encima. Escribir sobre datos que no se entienden es la forma más rápida
  /// de perderlos.
  final bool dataIsUsable;
}

/// Resultado de [SchemaMigration.run]: qué pasó y entre qué versiones.
///
/// [SchemaMigration.run] **no lanza**. Devuelve siempre uno de estos, incluso
/// cuando falla, porque corre en el arranque —antes de que exista una sola
/// pantalla— y una excepción ahí es la app que no abre.
@immutable
class MigrationResult {
  const MigrationResult._({
    required this.outcome,
    this.fromVersion,
    this.toVersion,
    this.detail,
  });

  /// Qué pasó.
  final MigrationOutcome outcome;

  /// Versión que había guardada al arrancar.
  ///
  /// `null` en [MigrationOutcome.freshInstall] —no había ninguna— y en
  /// [MigrationOutcome.unreadableVersion] —había algo, pero no era una
  /// versión—.
  final int? fromVersion;

  /// Versión que quedó sellada en el almacén al terminar.
  ///
  /// En [MigrationOutcome.failed] es hasta dónde llegó la cadena de verdad, no
  /// hasta dónde se pretendía llegar. `null` si no se selló ninguna.
  final int? toVersion;

  /// Descripción del fallo, para la bitácora de desarrollo.
  ///
  /// **No es un mensaje para la persona usuaria.** Habla de versiones y de
  /// claves; el texto visible lo decide la capa de arriba, en los términos del
  /// §24: qué pasó y qué hacer, sin códigos técnicos.
  final String? detail;

  /// Atajo de [MigrationOutcome.dataIsUsable].
  bool get dataIsUsable => outcome.dataIsUsable;

  @override
  String toString() {
    final String causa = detail == null ? '' : ' — $detail';
    return 'MigrationResult(${outcome.name}, de: $fromVersion, '
        'a: $toVersion)$causa';
  }
}

/// Un paso de migración: transforma los datos de la versión [target] menos uno
/// a la versión [target].
///
/// Los pasos son siempre de **uno en uno**. Una migración que saltara de la 1
/// a la 3 obligaría a que cada versión futura conociera todas las anteriores;
/// con saltos de uno, [SchemaMigration] solo tiene que encadenarlos.
///
/// ## Dos exigencias para quien escriba una
///
/// **1. Tiene que ser idempotente.** [SchemaMigration] sella la versión
/// después de cada paso, pero entre aplicar el paso y sellarlo el proceso
/// puede morir. Si eso ocurre, el próximo arranque vuelve a aplicar ese mismo
/// paso sobre datos ya migrados, y el resultado tiene que ser el mismo.
///
/// **2. Escribe lo nuevo antes de borrar lo viejo.** La convención de claves
/// `eira.v1.<dominio>` existe justamente para poder escribir `eira.v2.profile`
/// **junto a** `eira.v1.profile` y borrar el viejo solo cuando el nuevo está
/// confirmado. Destruir primero y escribir después es pérdida de datos con un
/// corte de luz de por medio.
///
/// [apply] devuelve `true` solo si el paso quedó completo. Un `false` detiene
/// la cadena sin sellar la versión, y el próximo arranque lo reintenta.
abstract class Migration {
  const Migration();

  /// Versión que produce este paso. Migra desde [target] menos uno.
  int get target;

  /// Aplica la transformación. `true` solo si quedó completa.
  Future<bool> apply(LocalStorage storage);
}

/// Mecanismo de migración del esquema de datos guardado en el dispositivo
/// (`PLAN_MAESTRO` §22, «Estrategia de migración»).
///
/// Corre una vez al arrancar, después de `LocalStorage.open()` y **antes de
/// que ningún repositorio lea un solo dato**. Ese orden es el punto entero:
/// migrar después de la primera lectura es leer con la forma equivocada.
///
/// ## Las seis ramas del arranque
///
/// | Estado del almacén | Qué hace | Resultado |
/// |---|---|---|
/// | La clave no existe | Sella [currentVersion] | [MigrationOutcome.freshInstall] |
/// | Guardada igual a la actual | Nada. Ni una escritura | [MigrationOutcome.upToDate] |
/// | Guardada menor a la actual | Encadena migraciones y sella | [MigrationOutcome.migrated] |
/// | Guardada mayor a la actual | **No toca nada** | [MigrationOutcome.futureVersion] |
/// | Guardada ilegible | **No toca nada** | [MigrationOutcome.unreadableVersion] |
/// | Falló un paso | Se detiene donde llegó | [MigrationOutcome.failed] |
///
/// La primera rama se decide con `LocalStorage.contains`, que es exactamente
/// la pregunta que ese método documenta: «¿es la primera vez que se abre la
/// app?». La ausencia de la clave no es un error, es una instalación nueva
/// —§22: «prohibido asumir que un dato existe»—.
///
/// ## Agregar una migración
///
/// Tres cosas, y el motor no se toca:
///
/// 1. Una clase que extienda [Migration] con `target` igual a la versión nueva.
/// 2. Esa clase agregada a [migrations].
/// 3. [currentVersion] subida a esa misma versión.
///
/// `test/core/storage/schema_migration_test.dart` verifica que el registro
/// cubra todo el rango: si alguien sube [currentVersion] y olvida el paso 2,
/// falla el build, no la app de alguien.
///
/// ## Por qué la versión se sella después de cada paso
///
/// Si la app muere a mitad de la cadena, el próximo arranque lee la última
/// versión sellada y retoma en el paso siguiente, en vez de repetir la cadena
/// completa sobre datos ya a medio migrar. El precio es que cada [Migration]
/// debe ser idempotente, y está escrito en su contrato.
///
/// ## Uso
///
/// ```dart
/// final LocalStorage storage = await LocalStorage.open();
/// final MigrationResult resultado = await const SchemaMigration().run(storage);
/// if (!resultado.dataIsUsable) {
///   // No leer nada. Explicar qué pasó.
/// }
/// ```
class SchemaMigration {
  /// Configuración real de la app: el registro [migrations] hasta
  /// [currentVersion].
  const SchemaMigration() : this._(migrations, currentVersion);

  /// Motor con un registro y una versión de destino inventados.
  ///
  /// Existe para poder probar la cadena, el fallo a media cadena y el paso que
  /// falta sin inventar una migración real en producción: hoy [migrations]
  /// está vacío a propósito, porque no existe ninguna versión anterior de qué
  /// migrar y una migración de mentira sería código muerto.
  @visibleForTesting
  const SchemaMigration.withRegistry({
    required List<Migration> registry,
    required int targetVersion,
  }) : this._(registry, targetVersion);

  /// Constructor real. Los dos públicos redirigen aquí; es lo que permite que
  /// los campos sean privados sin que un parámetro con nombre tenga que
  /// llamarse `_registry`.
  const SchemaMigration._(this._registry, this._targetVersion);

  /// Versión del esquema que entiende esta compilación de la app.
  ///
  /// Sube **junto con** la migración que la produce, nunca sola.
  static const int currentVersion = 1;

  /// Primera versión posible. La numeración empieza en 1, así que un valor
  /// guardado por debajo no es una versión antigua: es un dato corrupto.
  static const int firstVersion = 1;

  /// Registro de migraciones conocidas: una por versión, desde [firstVersion]
  /// más uno hasta [currentVersion].
  ///
  /// Vacío hoy. La app está en su primera versión y no hay nada anterior de
  /// qué migrar.
  @visibleForTesting
  static const List<Migration> migrations = <Migration>[];

  final List<Migration> _registry;
  final int _targetVersion;

  /// Deja el almacén en la versión de destino y cuenta qué pasó.
  ///
  /// Nunca lanza: todo fallo sale como un [MigrationResult] con
  /// `dataIsUsable == false`.
  Future<MigrationResult> run(LocalStorage storage) async {
    // Instalación nueva: la clave no existe. No hay nada que migrar, pero sí
    // que sellar, porque dentro de dos versiones esta instalación tiene que
    // poder decir que empezó aquí y no allá.
    if (!storage.contains(StorageKeys.schemaVersion)) {
      return _sellarInstalacionNueva(storage);
    }

    final int encontrada;
    try {
      // El valor por defecto es inalcanzable: `contains` ya garantizó que la
      // clave existe. Se pasa `_targetVersion` y no `0` porque, si alguna vez
      // se alcanzara, significa «no hagas nada», que es lo inofensivo. Un `0`
      // dispararía la cadena completa sobre datos de forma desconocida.
      encontrada = storage.readInt(
        StorageKeys.schemaVersion,
        defaultValue: _targetVersion,
      );
    } on StorageException catch (error) {
      return MigrationResult._(
        outcome: MigrationOutcome.unreadableVersion,
        detail: 'la versión guardada no es un entero. $error',
      );
    }

    if (encontrada < firstVersion) {
      return MigrationResult._(
        outcome: MigrationOutcome.unreadableVersion,
        detail: 'la versión guardada es $encontrada y la numeración empieza '
            'en $firstVersion.',
      );
    }

    if (encontrada == _targetVersion) {
      return MigrationResult._(
        outcome: MigrationOutcome.upToDate,
        fromVersion: encontrada,
        toVersion: encontrada,
      );
    }

    // Datos de una versión más nueva. No hay camino de vuelta y no se
    // improvisa uno: el almacén queda intacto.
    if (encontrada > _targetVersion) {
      return MigrationResult._(
        outcome: MigrationOutcome.futureVersion,
        fromVersion: encontrada,
        toVersion: encontrada,
        detail: 'los datos son de la versión $encontrada y esta app entiende '
            'hasta la $_targetVersion.',
      );
    }

    return _migrarEnCadena(storage, desde: encontrada);
  }

  Future<MigrationResult> _sellarInstalacionNueva(LocalStorage storage) async {
    final bool sellada = await storage.writeInt(
      StorageKeys.schemaVersion,
      _targetVersion,
    );
    if (!sellada) {
      // No se perdió nada: en una instalación nueva no había datos. El próximo
      // arranque vuelve a intentarlo.
      return MigrationResult._(
        outcome: MigrationOutcome.failed,
        detail: 'no se pudo escribir la versión inicial $_targetVersion.',
      );
    }
    return MigrationResult._(
      outcome: MigrationOutcome.freshInstall,
      toVersion: _targetVersion,
    );
  }

  Future<MigrationResult> _migrarEnCadena(
    LocalStorage storage, {
    required int desde,
  }) async {
    int sellada = desde;

    for (int destino = desde + 1; destino <= _targetVersion; destino++) {
      final Migration? paso = _pasoHacia(destino);
      if (paso == null) {
        // Error de programación, no de datos: alguien subió `currentVersion`
        // sin registrar la migración. Se detiene antes de tocar nada.
        return MigrationResult._(
          outcome: MigrationOutcome.failed,
          fromVersion: desde,
          toVersion: sellada,
          detail: 'no hay ninguna migración registrada para la versión '
              '$destino.',
        );
      }

      final bool aplicada = await paso.apply(storage);
      if (!aplicada) {
        return MigrationResult._(
          outcome: MigrationOutcome.failed,
          fromVersion: desde,
          toVersion: sellada,
          detail: 'la migración a la versión $destino no se completó.',
        );
      }

      final bool escrita = await storage.writeInt(
        StorageKeys.schemaVersion,
        destino,
      );
      if (!escrita) {
        // El paso se aplicó pero la versión quedó en la anterior. Como toda
        // migración es idempotente, el próximo arranque lo repite sin daño.
        return MigrationResult._(
          outcome: MigrationOutcome.failed,
          fromVersion: desde,
          toVersion: sellada,
          detail: 'la migración a la versión $destino se aplicó, pero no se '
              'pudo sellar la versión.',
        );
      }

      sellada = destino;
    }

    return MigrationResult._(
      outcome: MigrationOutcome.migrated,
      fromVersion: desde,
      toVersion: sellada,
    );
  }

  /// Migración registrada que produce [destino], o `null` si no hay ninguna.
  ///
  /// Devuelve la primera coincidencia. Que no haya dos con el mismo `target`
  /// lo garantiza el test de catálogo, no este bucle.
  Migration? _pasoHacia(int destino) {
    for (final Migration paso in _registry) {
      if (paso.target == destino) {
        return paso;
      }
    }
    return null;
  }
}
