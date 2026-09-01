import 'package:eira/core/storage/local_storage.dart';
import 'package:eira/core/storage/storage_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Verificación de los métodos genéricos de [LocalStorage] (T-008).
///
/// Cubre los cuatro casos del criterio de aceptación del backlog —vacío,
/// completo, campo faltante y JSON malformado— y los extiende a los estados
/// que el `PLAN_MAESTRO` §27 exige para persistencia: primera instalación,
/// escritura y relectura tras cierre, y dato de tipo inesperado.
///
/// Es el test de la lección **L1** del plan: *el usuario cree que guardó y no
/// guardó*. Por eso casi ningún caso se conforma con mirar lo que devolvió un
/// método: comprueba lo que quedó en el almacén.
///
/// ## Qué NO prueba este archivo
///
/// - **Las seis ramas de la migración de esquema.** Son de T-007 y ya están en
///   `schema_migration_test.dart`. Aquí solo se prueban `readInt` y `writeInt`
///   como lo que son a este nivel: acceso a un entero.
/// - **`storage_keys.dart`.** Es un catálogo de constantes sin comportamiento.
///   Un test que afirme que una constante vale lo que vale solo duplica el
///   archivo y hay que cambiarlo dos veces.
/// - **La rama de escritura fallida.** El almacén en memoria del paquete nunca
///   falla una escritura; ya está anotada como límite conocido desde T-006.
/// - **`writeJsonObject` con un objeto no serializable.** Lanza
///   `JsonUnsupportedObjectError` desde `dart:convert`: sería probar la
///   librería estándar, no nuestro código. Que ese error suba sin envolver es
///   deliberado —es un defecto del `toJson()` del modelo y debe verse—.
///
/// ## Por qué este archivo importa `shared_preferences`
///
/// Por dos llamadas de andamiaje: `setMockInitialValues`, que instala el
/// almacén en memoria sin el cual no hay implementación de plataforma en un
/// test, y `resetStatic`, que sostiene la simulación de cierre forzado
/// explicada más abajo. Todo lo demás pasa por [LocalStorage], que es el punto
/// de acceso que fija la regla **E4**. La regla gobierna `lib/`; aquí el
/// paquete entra como herramienta de prueba, igual que en T-007.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Todas las claves del catálogo. Se enumeran a mano porque [StorageKeys] es
  /// un contenedor de constantes y no expone una lista: exponerla solo para el
  /// test agregaría superficie pública que la app no necesita.
  const List<String> catalogoCompleto = <String>[
    StorageKeys.schemaVersion,
    StorageKeys.profile,
    StorageKeys.habitsCompletions,
    StorageKeys.habitsStreak,
    StorageKeys.metricsGlucose,
    StorageKeys.metricsBloodPressure,
    StorageKeys.metricsWeight,
    StorageKeys.favoriteRecipes,
    StorageKeys.favoriteRoutines,
    StorageKeys.appLastOpened,
    StorageKeys.notificationsEnabled,
  ];

  /// Clave de otro origen, deliberadamente **sin** el prefijo `eira.`.
  ///
  /// Es un literal a propósito y no vive en `storage_keys.dart`: representa
  /// justo lo que EIRA no escribió y no le pertenece. Sirve para probar que
  /// `deleteAll()` no la toca.
  const String claveAjena = 'otro_plugin.token';

  late LocalStorage storage;

  setUp(() async {
    // Almacén vacío y singleton reiniciado antes de cada test: ninguna prueba
    // hereda lo que escribió la anterior.
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    storage = await LocalStorage.open();
  });

  /// Simula el arranque en frío tras un cierre forzado (`PLAN_MAESTRO` §27).
  ///
  /// El paquete mantiene dos cosas separadas: el **almacén**
  /// (`SharedPreferencesStorePlatform.instance`, que en un test es el mapa en
  /// memoria y hace de disco) y la **caché** del proceso, que muere con él.
  /// `resetStatic()` anula solo lo segundo —descarta la instancia cacheada— y
  /// no toca el almacén, así que el siguiente `LocalStorage.open()` reconstruye
  /// la caché leyendo el almacén desde cero.
  ///
  /// Es lo más parecido a matar el proceso que se puede observar desde Dart.
  /// Lo que sigue sin probarse aquí es que Android complete el volcado a disco
  /// antes de un cierre abrupto: eso depende del plugin nativo y le toca a la
  /// prueba en dispositivo físico. Lo que sí queda demostrado es la mitad que
  /// nos corresponde —que el dato salió de la caché y llegó al almacén—, que es
  /// exactamente donde falló el proyecto anterior.
  ///
  /// No se usa `setMockInitialValues` para esto: ese método **reemplaza** el
  /// almacén, o sea que borraría el disco y probaría lo contrario.
  Future<LocalStorage> reabrirEnFrio() async {
    SharedPreferences.resetStatic();
    return LocalStorage.open();
  }

  // =======================================================================
  // A. Arranque
  // =======================================================================

  group('Arranque', () {
    test('abrir un almacén vacío no lanza y deja una instancia usable',
        () async {
      final LocalStorage recienAbierto = await LocalStorage.open();

      expect(
        recienAbierto.readString(StorageKeys.profile, defaultValue: 'sin dato'),
        'sin dato',
      );
    });
  });

  // =======================================================================
  // B. Instalación nueva — sin claves, valores por defecto (§27)
  //
  // La regla del §22 es «prohibido asumir que un dato existe». Estos casos son
  // esa regla comprobada método por método: ninguna lectura lanza por ausencia,
  // porque una instalación nueva no es un error.
  // =======================================================================

  group('Instalación nueva', () {
    test('readString devuelve el valor por defecto si la clave no existe', () {
      expect(
        storage.readString(StorageKeys.appLastOpened, defaultValue: 'nunca'),
        'nunca',
      );
    });

    test('readBool devuelve el valor por defecto si la clave no existe', () {
      expect(
        storage.readBool(
          StorageKeys.notificationsEnabled,
          defaultValue: false,
        ),
        isFalse,
      );
    });

    test('readInt devuelve el valor por defecto si la clave no existe', () {
      expect(storage.readInt(StorageKeys.schemaVersion, defaultValue: -1), -1);
    });

    test('readStringList devuelve lista vacía si la clave no existe', () {
      expect(storage.readStringList(StorageKeys.favoriteRecipes), isEmpty);
    });

    test('readJsonObject devuelve null si la clave no existe', () {
      // `null` significa «nunca se guardó». Es lo que distingue a quien no
      // completó el onboarding de quien lo completó sin responder nada.
      expect(storage.readJsonObject(StorageKeys.profile), isNull);
    });

    test('readJsonObjectList devuelve lista vacía si la clave no existe', () {
      expect(storage.readJsonObjectList(StorageKeys.metricsGlucose), isEmpty);
    });

    test('ninguna clave del catálogo existe en una instalación nueva', () {
      for (final String clave in catalogoCompleto) {
        expect(
          storage.contains(clave),
          isFalse,
          reason: 'la clave "$clave" no debería existir todavía',
        );
      }
    });
  });

  // =======================================================================
  // C. Ida y vuelta — el caso «completo»
  // =======================================================================

  group('Ida y vuelta', () {
    test('un texto vuelve idéntico', () async {
      await storage.writeString(StorageKeys.appLastOpened, '2026-09-01');

      expect(
        storage.readString(StorageKeys.appLastOpened, defaultValue: ''),
        '2026-09-01',
      );
    });

    test('una cadena vacía guardada se lee vacía, no como el defecto',
        () async {
      // Es la razón de que `defaultValue` sea obligatorio: si el defecto fuera
      // `''` por omisión, guardar «nada» y no haber guardado nunca serían
      // indistinguibles.
      await storage.writeString(StorageKeys.appLastOpened, '');

      expect(
        storage.readString(StorageKeys.appLastOpened, defaultValue: 'defecto'),
        '',
      );
    });

    test('los acentos y los emoji sobreviven el viaje', () async {
      const String texto = 'Presión arterial · medición matutina 🩺';
      await storage.writeString(StorageKeys.appLastOpened, texto);

      expect(
        storage.readString(StorageKeys.appLastOpened, defaultValue: ''),
        texto,
      );
    });

    test('un booleano verdadero vuelve verdadero', () async {
      await storage.writeBool(StorageKeys.notificationsEnabled, value: true);

      expect(
        storage.readBool(
          StorageKeys.notificationsEnabled,
          defaultValue: false,
        ),
        isTrue,
      );
    });

    test('un booleano falso guardado se lee falso, no como el defecto',
        () async {
      // Con `defaultValue: true`, si el `false` se perdiera, la lectura
      // devolvería `true` y el test lo vería. Es el caso que apaga un
      // recordatorio y lo encuentra encendido al día siguiente.
      await storage.writeBool(StorageKeys.notificationsEnabled, value: false);

      expect(
        storage.readBool(StorageKeys.notificationsEnabled, defaultValue: true),
        isFalse,
      );
    });

    test('un entero vuelve idéntico, incluidos el cero y los negativos',
        () async {
      await storage.writeInt(StorageKeys.schemaVersion, 7);
      expect(storage.readInt(StorageKeys.schemaVersion, defaultValue: -1), 7);

      await storage.writeInt(StorageKeys.schemaVersion, 0);
      expect(storage.readInt(StorageKeys.schemaVersion, defaultValue: -1), 0);

      await storage.writeInt(StorageKeys.schemaVersion, -3);
      expect(storage.readInt(StorageKeys.schemaVersion, defaultValue: 0), -3);
    });

    test('una lista de textos conserva orden y duplicados', () async {
      const List<String> favoritas = <String>[
        'receta-03',
        'receta-01',
        'receta-03',
      ];
      await storage.writeStringList(StorageKeys.favoriteRecipes, favoritas);

      // El orden es dato: es el que ve la persona en su lista de favoritos.
      expect(storage.readStringList(StorageKeys.favoriteRecipes), favoritas);
    });

    test('una lista de textos vacía guardada se lee vacía', () async {
      await storage.writeStringList(
        StorageKeys.favoriteRecipes,
        const <String>[],
      );

      expect(storage.readStringList(StorageKeys.favoriteRecipes), isEmpty);
    });

    test('un objeto JSON vuelve igual al que se escribió', () async {
      const Map<String, Object?> perfil = <String, Object?>{
        'condicion': 'both',
        'anioNacimiento': 1968,
        'avisoAceptado': true,
      };
      await storage.writeJsonObject(StorageKeys.profile, perfil);

      expect(storage.readJsonObject(StorageKeys.profile), perfil);
    });

    test('un objeto JSON vacío se lee como vacío, nunca como null', () async {
      // Vacío no es ausente. Si `{}` volviera como `null`, el repositorio
      // concluiría que no hay perfil y mandaría al onboarding a alguien que ya
      // lo hizo.
      await storage.writeJsonObject(
        StorageKeys.profile,
        const <String, Object?>{},
      );

      final Map<String, Object?>? leido =
          storage.readJsonObject(StorageKeys.profile);

      expect(leido, isNotNull);
      expect(leido, isEmpty);
    });

    test('un objeto anidado sobrevive con todos sus tipos', () async {
      const Map<String, Object?> anidado = <String, Object?>{
        'texto': 'glucosa',
        'entero': 118,
        'decimal': 72.5,
        'booleano': false,
        'nulo': null,
        'lista': <Object?>[1, 'dos', true],
        'mapa': <String, Object?>{'unidad': 'mg/dL'},
      };
      await storage.writeJsonObject(StorageKeys.habitsStreak, anidado);

      expect(storage.readJsonObject(StorageKeys.habitsStreak), anidado);
    });

    test('un arreglo de objetos conserva orden y cantidad', () async {
      const List<Map<String, Object?>> registros = <Map<String, Object?>>[
        <String, Object?>{'fecha': '2026-08-30', 'valor': 112},
        <String, Object?>{'fecha': '2026-08-31', 'valor': 98},
        <String, Object?>{'fecha': '2026-09-01', 'valor': 105},
      ];
      await storage.writeJsonObjectList(
        StorageKeys.metricsGlucose,
        registros,
      );

      final List<Map<String, Object?>> leidos =
          storage.readJsonObjectList(StorageKeys.metricsGlucose);

      expect(leidos, hasLength(3));
      expect(leidos, registros);
    });

    test('un arreglo vacío guardado se lee vacío', () async {
      await storage.writeJsonObjectList(
        StorageKeys.metricsWeight,
        const <Map<String, Object?>>[],
      );

      expect(storage.readJsonObjectList(StorageKeys.metricsWeight), isEmpty);
    });

    test('toda escritura confirma que persistió', () async {
      // Lección L1 en una línea por método: el booleano devuelto es lo único
      // que autoriza a decirle a la persona que su dato quedó guardado.
      expect(
        await storage.writeString(StorageKeys.appLastOpened, '2026-09-01'),
        isTrue,
      );
      expect(
        await storage.writeBool(
          StorageKeys.notificationsEnabled,
          value: true,
        ),
        isTrue,
      );
      expect(await storage.writeInt(StorageKeys.schemaVersion, 1), isTrue);
      expect(
        await storage.writeStringList(
          StorageKeys.favoriteRoutines,
          const <String>['rutina-01'],
        ),
        isTrue,
      );
      expect(
        await storage.writeJsonObject(
          StorageKeys.profile,
          const <String, Object?>{'condicion': 'diabetes'},
        ),
        isTrue,
      );
      expect(
        await storage.writeJsonObjectList(
          StorageKeys.metricsWeight,
          const <Map<String, Object?>>[
            <String, Object?>{'valor': 81.4},
          ],
        ),
        isTrue,
      );
    });
  });

  // =======================================================================
  // D. Campo faltante
  //
  // El §22 pide un `fromJson` **tolerante**: campo faltante → valor por
  // defecto. Esa tolerancia vive en el modelo, no aquí. Lo que a esta capa le
  // toca es entregar el mapa tal como está, sin inventar ni filtrar, y sobre
  // todo sin confundir «ausente» con «presente y nulo»: si las colapsara, el
  // modelo de arriba no podría distinguirlas aunque quisiera.
  // =======================================================================

  group('Campo faltante', () {
    test('un objeto al que le falta un campo se lee tal cual', () async {
      await storage.writeJsonObject(
        StorageKeys.profile,
        const <String, Object?>{'condicion': 'hypertension'},
      );

      final Map<String, Object?> perfil =
          storage.readJsonObject(StorageKeys.profile)!;

      expect(perfil['condicion'], 'hypertension');
      expect(perfil.containsKey('anioNacimiento'), isFalse);
      expect(perfil['anioNacimiento'], isNull);
    });

    test('un campo presente con valor nulo se distingue de uno ausente',
        () async {
      await storage.writeJsonObject(
        StorageKeys.profile,
        const <String, Object?>{'anioNacimiento': null},
      );

      final Map<String, Object?> perfil =
          storage.readJsonObject(StorageKeys.profile)!;

      // Ambos leen `null`, pero solo uno existe. Un `fromJson` tolerante que
      // quiera diferenciar «prefirió no responder» de «esta versión de la app
      // todavía no preguntaba» necesita esta distinción intacta.
      expect(perfil.containsKey('anioNacimiento'), isTrue);
      expect(perfil['anioNacimiento'], isNull);
      expect(perfil.containsKey('condicion'), isFalse);
    });

    test('un objeto con campos de más se lee completo, sin filtrar', () async {
      // LocalStorage no valida esquema: descartar un campo desconocido sería
      // perder en silencio el dato de una versión más nueva.
      await storage.writeJsonObject(
        StorageKeys.profile,
        const <String, Object?>{
          'condicion': 'diabetes',
          'campoDeUnaVersionFutura': 'valor',
        },
      );

      final Map<String, Object?> perfil =
          storage.readJsonObject(StorageKeys.profile)!;

      expect(perfil, hasLength(2));
      expect(perfil['campoDeUnaVersionFutura'], 'valor');
    });
  });

  // =======================================================================
  // E. JSON malformado
  //
  // El §27 lo pide así: «no crashea, devuelve error explícito». Lanzar una
  // StorageException con nombre ES el error explícito; el repositorio la
  // traduce a estado `error` y la UI dice «no pudimos cargar tus registros»,
  // que no es «aún no tienes registros». Devolver vacío aquí sería pérdida de
  // datos silenciosa, razonado en el ADR-009.
  // =======================================================================

  group('JSON malformado', () {
    test('un texto que no es JSON lanza StorageException', () async {
      await storage.writeString(StorageKeys.profile, '{no soy json');

      expect(
        () => storage.readJsonObject(StorageKeys.profile),
        throwsA(isA<StorageException>()),
      );
    });

    test('un JSON truncado lanza StorageException', () async {
      // El caso realista: la app murió a mitad de una escritura.
      await storage.writeString(StorageKeys.profile, '{"condicion":"both"');

      expect(
        () => storage.readJsonObject(StorageKeys.profile),
        throwsA(isA<StorageException>()),
      );
    });

    test('un arreglo leído como objeto lanza StorageException', () async {
      await storage.writeString(StorageKeys.profile, '[1,2]');

      expect(
        () => storage.readJsonObject(StorageKeys.profile),
        throwsA(isA<StorageException>()),
      );
    });

    test('un escalar leído como objeto lanza StorageException', () async {
      await storage.writeString(StorageKeys.profile, '42');

      expect(
        () => storage.readJsonObject(StorageKeys.profile),
        throwsA(isA<StorageException>()),
      );
    });

    test('el literal null guardado lanza, no se confunde con clave ausente',
        () async {
      // Son dos nulos distintos: «no hay clave» devuelve null y es normal;
      // «hay una clave que contiene la palabra null» es dato corrupto. Si se
      // colapsaran, un archivo dañado se leería como una instalación nueva y
      // el siguiente guardado lo sobrescribiría.
      await storage.writeString(StorageKeys.profile, 'null');

      expect(
        () => storage.readJsonObject(StorageKeys.profile),
        throwsA(isA<StorageException>()),
      );
    });

    test('un texto que no es JSON lanza al leer un arreglo', () async {
      await storage.writeString(StorageKeys.metricsGlucose, 'glucosa: 110');

      expect(
        () => storage.readJsonObjectList(StorageKeys.metricsGlucose),
        throwsA(isA<StorageException>()),
      );
    });

    test('un objeto leído como arreglo lanza StorageException', () async {
      await storage.writeString(StorageKeys.metricsGlucose, '{"valor":110}');

      expect(
        () => storage.readJsonObjectList(StorageKeys.metricsGlucose),
        throwsA(isA<StorageException>()),
      );
    });

    test('un arreglo con un elemento que no es objeto lanza', () async {
      await storage.writeString(StorageKeys.metricsGlucose, '[{"valor":110},7]');

      expect(
        () => storage.readJsonObjectList(StorageKeys.metricsGlucose),
        throwsA(
          isA<StorageException>().having(
            (StorageException e) => e.reason,
            'razón',
            contains('no es un objeto JSON'),
          ),
        ),
      );
    });

    test('la excepción nombra la clave culpable, la razón y la causa',
        () async {
      await storage.writeString(StorageKeys.habitsStreak, '{roto');

      expect(
        () => storage.readJsonObject(StorageKeys.habitsStreak),
        throwsA(
          isA<StorageException>()
              .having(
                (StorageException e) => e.key,
                'clave',
                StorageKeys.habitsStreak,
              )
              .having(
                (StorageException e) => e.cause,
                'causa',
                isA<FormatException>(),
              )
              .having(
                (StorageException e) => e.toString(),
                'toString',
                allOf(
                  // Sin la clave, un log de tres fallos no dice cuál de las
                  // once claves hay que mirar.
                  contains(StorageKeys.habitsStreak),
                  contains('no es JSON válido'),
                  contains('causa:'),
                ),
              ),
        ),
      );
    });

    test('un JSON roto en una clave no contamina a las demás', () async {
      await storage.writeString(StorageKeys.profile, '{roto');
      await storage.writeJsonObjectList(
        StorageKeys.metricsGlucose,
        const <Map<String, Object?>>[
          <String, Object?>{'valor': 110},
        ],
      );

      // Las métricas separadas por tipo (§22) sirven justo para esto: un dato
      // dañado se lleva su clave, no el historial completo.
      expect(
        () => storage.readJsonObject(StorageKeys.profile),
        throwsA(isA<StorageException>()),
      );
      expect(
        storage.readJsonObjectList(StorageKeys.metricsGlucose),
        hasLength(1),
      );
    });
  });

  // =======================================================================
  // F. Dato de otro tipo
  //
  // Distinto del JSON roto: aquí el dato está sano, pero es de otro tipo. Los
  // métodos tipados del paquete harían un cast interno que revienta con un
  // error sin contexto; leer con `get` y comprobar aquí es lo que permite que
  // el fallo tenga nombre y clave.
  // =======================================================================

  group('Dato de otro tipo', () {
    test('readString sobre un entero lanza StorageException', () async {
      await storage.writeInt(StorageKeys.appLastOpened, 20260901);

      expect(
        () => storage.readString(StorageKeys.appLastOpened, defaultValue: ''),
        throwsA(isA<StorageException>()),
      );
    });

    test('readBool sobre un texto lanza StorageException', () async {
      await storage.writeString(StorageKeys.notificationsEnabled, 'true');

      expect(
        () => storage.readBool(
          StorageKeys.notificationsEnabled,
          defaultValue: false,
        ),
        throwsA(isA<StorageException>()),
      );
    });

    test('readInt sobre un texto lanza StorageException', () async {
      await storage.writeString(StorageKeys.schemaVersion, 'dos');

      expect(
        () => storage.readInt(StorageKeys.schemaVersion, defaultValue: -1),
        throwsA(isA<StorageException>()),
      );
    });

    test('readInt sobre un booleano lanza: true no es 1', () async {
      await storage.writeBool(StorageKeys.schemaVersion, value: true);

      expect(
        () => storage.readInt(StorageKeys.schemaVersion, defaultValue: -1),
        throwsA(isA<StorageException>()),
      );
    });

    test('readStringList sobre un texto lanza StorageException', () async {
      await storage.writeString(StorageKeys.favoriteRecipes, 'receta-01');

      expect(
        () => storage.readStringList(StorageKeys.favoriteRecipes),
        throwsA(isA<StorageException>()),
      );
    });

    test('readStringList sobre una lista con un elemento no textual lanza',
        () async {
      // Esta forma solo puede llegar de un almacén escrito por otra versión o
      // dañado, así que se siembra directamente. `writeStringList` no permite
      // construirla, y por eso mismo la rama necesita este test: es la única
      // manera de alcanzarla.
      SharedPreferences.setMockInitialValues(const <String, Object>{
        StorageKeys.favoriteRecipes: <Object>['receta-01', 7],
      });
      final LocalStorage sembrado = await LocalStorage.open();

      expect(
        () => sembrado.readStringList(StorageKeys.favoriteRecipes),
        throwsA(
          isA<StorageException>().having(
            (StorageException e) => e.reason,
            'razón',
            contains('no es texto'),
          ),
        ),
      );
    });

    test('readJsonObject sobre un entero lanza StorageException', () async {
      await storage.writeInt(StorageKeys.profile, 3);

      expect(
        () => storage.readJsonObject(StorageKeys.profile),
        throwsA(
          isA<StorageException>().having(
            (StorageException e) => e.reason,
            'razón',
            contains('un texto con JSON'),
          ),
        ),
      );
    });

    test('una lectura fallida no daña el dato guardado', () async {
      await storage.writeInt(StorageKeys.schemaVersion, 4);

      expect(
        () => storage.readString(StorageKeys.schemaVersion, defaultValue: ''),
        throwsA(isA<StorageException>()),
      );
      // La excepción informa; no consume ni corrompe nada.
      expect(storage.readInt(StorageKeys.schemaVersion, defaultValue: -1), 4);
    });
  });

  // =======================================================================
  // G. Sobrescritura, existencia y borrado
  // =======================================================================

  group('Sobrescritura, existencia y borrado', () {
    test('escribir dos veces deja el último valor, no acumula', () async {
      await storage.writeString(StorageKeys.appLastOpened, '2026-08-31');
      await storage.writeString(StorageKeys.appLastOpened, '2026-09-01');

      expect(
        storage.readString(StorageKeys.appLastOpened, defaultValue: ''),
        '2026-09-01',
      );
    });

    test('sobrescribir con otro tipo cambia el tipo efectivo de la clave',
        () async {
      await storage.writeInt(StorageKeys.schemaVersion, 1);
      await storage.writeString(StorageKeys.schemaVersion, 'uno');

      // Así es como una clave se corrompe en la vida real: no por un JSON
      // roto, sino por código que escribe donde no debe. El almacén acepta el
      // cambio; el que lo detecta es el lector.
      expect(
        () => storage.readInt(StorageKeys.schemaVersion, defaultValue: -1),
        throwsA(isA<StorageException>()),
      );
      expect(
        storage.readString(StorageKeys.schemaVersion, defaultValue: ''),
        'uno',
      );
    });

    test('contains responde true tras escribir y false tras borrar', () async {
      expect(storage.contains(StorageKeys.profile), isFalse);

      await storage.writeJsonObject(
        StorageKeys.profile,
        const <String, Object?>{'condicion': 'both'},
      );
      expect(storage.contains(StorageKeys.profile), isTrue);

      await storage.remove(StorageKeys.profile);
      expect(storage.contains(StorageKeys.profile), isFalse);
    });

    test('borrar una clave inexistente no lanza', () async {
      expect(storage.remove(StorageKeys.profile), completes);
    });

    test('tras borrar, la lectura vuelve al valor por defecto', () async {
      await storage.writeString(StorageKeys.appLastOpened, '2026-09-01');
      await storage.remove(StorageKeys.appLastOpened);

      // No al valor anterior ni a un residuo en caché: al defecto.
      expect(
        storage.readString(StorageKeys.appLastOpened, defaultValue: 'nunca'),
        'nunca',
      );
    });

    test('deleteAll borra todas las claves de EIRA y lo confirma', () async {
      await storage.writeString(StorageKeys.appLastOpened, '2026-09-01');
      await storage.writeInt(StorageKeys.schemaVersion, 1);
      await storage.writeJsonObject(
        StorageKeys.profile,
        const <String, Object?>{'condicion': 'both'},
      );

      expect(await storage.deleteAll(), isTrue);

      for (final String clave in catalogoCompleto) {
        expect(
          storage.contains(clave),
          isFalse,
          reason: 'la clave "$clave" sobrevivió al borrado total',
        );
      }
    });

    test('deleteAll no toca claves ajenas sin el prefijo eira.', () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{
        claveAjena: 'valor de otro plugin',
      });
      final LocalStorage conVecinos = await LocalStorage.open();
      await conVecinos.writeString(StorageKeys.appLastOpened, '2026-09-01');

      await conVecinos.deleteAll();

      // La promesa del §26 es borrar los datos de la persona, no vaciar el
      // almacén del proceso. `clear()` habría borrado también esta clave, que
      // EIRA nunca escribió.
      expect(conVecinos.contains(StorageKeys.appLastOpened), isFalse);
      expect(
        conVecinos.readString(claveAjena, defaultValue: ''),
        'valor de otro plugin',
      );
    });

    test('deleteAll sobre un almacén vacío devuelve true y no lanza', () async {
      expect(await storage.deleteAll(), isTrue);
    });

    test('tras deleteAll el estado es indistinguible de una instalación nueva',
        () async {
      await storage.writeString(StorageKeys.appLastOpened, '2026-09-01');
      await storage.writeBool(StorageKeys.notificationsEnabled, value: true);
      await storage.writeStringList(
        StorageKeys.favoriteRecipes,
        const <String>['receta-01'],
      );
      await storage.writeJsonObject(
        StorageKeys.profile,
        const <String, Object?>{'condicion': 'both'},
      );
      await storage.writeJsonObjectList(
        StorageKeys.metricsGlucose,
        const <Map<String, Object?>>[
          <String, Object?>{'valor': 110},
        ],
      );

      await storage.deleteAll();

      expect(
        storage.readString(StorageKeys.appLastOpened, defaultValue: 'nunca'),
        'nunca',
      );
      expect(
        storage.readBool(
          StorageKeys.notificationsEnabled,
          defaultValue: false,
        ),
        isFalse,
      );
      expect(storage.readStringList(StorageKeys.favoriteRecipes), isEmpty);
      expect(storage.readJsonObject(StorageKeys.profile), isNull);
      expect(storage.readJsonObjectList(StorageKeys.metricsGlucose), isEmpty);
    });
  });

  // =======================================================================
  // H. Escritura, cierre forzado, relectura (§27)
  // =======================================================================

  group('Escritura, cierre forzado, relectura', () {
    test('un texto escrito sobrevive al arranque en frío', () async {
      await storage.writeString(StorageKeys.appLastOpened, '2026-09-01');

      final LocalStorage enFrio = await reabrirEnFrio();

      expect(
        enFrio.readString(StorageKeys.appLastOpened, defaultValue: 'nunca'),
        '2026-09-01',
      );
    });

    test('un objeto JSON escrito sobrevive completo al arranque en frío',
        () async {
      const Map<String, Object?> perfil = <String, Object?>{
        'condicion': 'both',
        'anioNacimiento': 1968,
        'avisoAceptado': true,
      };
      await storage.writeJsonObject(StorageKeys.profile, perfil);

      final LocalStorage enFrio = await reabrirEnFrio();

      // Si el dato solo hubiera quedado en la caché del proceso anterior, esta
      // lectura devolvería null. Es exactamente el fallo de la lección L1.
      expect(enFrio.readJsonObject(StorageKeys.profile), perfil);
    });

    test('lo borrado con deleteAll no reaparece tras el arranque en frío',
        () async {
      await storage.writeJsonObject(
        StorageKeys.profile,
        const <String, Object?>{'condicion': 'both'},
      );
      await storage.deleteAll();

      final LocalStorage enFrio = await reabrirEnFrio();

      // Prueba que el borrado llegó al almacén y no solo a la caché. Es un
      // requisito legal (§26), no una comodidad: si el dato volviera al
      // reiniciar, la app habría mentido al decir que borró todo.
      expect(enFrio.readJsonObject(StorageKeys.profile), isNull);
      expect(enFrio.contains(StorageKeys.profile), isFalse);
    });
  });
}
