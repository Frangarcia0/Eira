import 'package:eira/core/models/health_condition.dart';
import 'package:eira/core/models/user_profile.dart';
import 'package:eira/core/storage/local_storage.dart';
import 'package:eira/core/storage/storage_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Verificación de [UserProfile] y su serialización (T-013).
///
/// Serialización y persistencia son **P0 con cobertura 100 %** (§27), por la
/// lección L1 de la auditoría: el usuario cree que guardó y no guardó. Los
/// casos límite obligatorios del §27 para persistencia están todos aquí —ida y
/// vuelta, campo faltante, tipo inesperado— más el que pidió la revisión:
/// valor de enum desconocido.
///
/// ## Por qué este archivo importa `shared_preferences`
///
/// Para una sola llamada de andamiaje, `setMockInitialValues`, que instala el
/// almacén en memoria del paquete; sin ella no hay implementación de
/// plataforma y `LocalStorage.open()` falla. Todo lo demás pasa por
/// [LocalStorage]. **E4 sigue intacto:** la regla gobierna `lib/`, y
/// `local_storage.dart` sigue siendo el único archivo de la app que importa el
/// paquete. Mismo andamiaje que los tests de T-007 y T-008.
///
/// ## Lo que no se prueba, y por qué
///
/// - **Las rutas de fallo de [LocalStorage].** Ya están, con 55 casos en
///   T-008. Repetirlas haría que dos archivos se pusieran rojos por un solo
///   defecto y ninguno diría cuál. Aquí solo se comprueba **la frontera**: que
///   un almacén dañado salga como `StorageException` y no como fallo del
///   modelo, que es lo que permite a T-020 distinguirlos.
/// - **`storage_keys.dart`.** Catálogo de constantes sin comportamiento;
///   probarlo lo duplica. Precedente de T-008.
/// - **Supervivencia a cierre forzado.** Es **T-022**, y su técnica —reiniciar
///   el singleton sin tocar el almacén— ya está documentada en la bitácora de
///   T-008. Aquí quedaría a medias.
/// - **Rango de `birthYear`, mensajes de error y estados del formulario.** Son
///   **T-016**: el modelo exige presencia y tipo, no plausibilidad.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Ida y vuelta', () {
    test('el perfil vuelve idéntico pasando por JSON', () {
      final UserProfile original = _perfilDePrueba();

      expect(UserProfile.fromJson(original.toJson()), original);
    });

    test('el perfil vuelve idéntico pasando por LocalStorage', () async {
      // El de verdad: el que exige el §27. Recorre el camino real —modelo,
      // JSON, almacén, JSON, modelo— y no solo la aritmética del modelo.
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final LocalStorage storage = await LocalStorage.open();
      final UserProfile original = _perfilDePrueba();

      final bool guardado = await storage.writeJsonObject(
        StorageKeys.profile,
        original.toJson(),
      );
      final Map<String, Object?>? leido = storage.readJsonObject(
        StorageKeys.profile,
      );

      // El booleano es lo único que autoriza a decir que quedó guardado.
      expect(guardado, isTrue);
      expect(leido, isNotNull);
      expect(UserProfile.fromJson(leido!), original);
    });

    test('el JSON usa exactamente los nombres de campo esperados', () {
      // Fija el formato de almacenamiento. Renombrar un campo en Dart no debe
      // poner rojo este test; cambiar la clave del JSON sí, porque invalida
      // los perfiles ya guardados.
      expect(
        _perfilDePrueba().toJson().keys,
        containsAll(<String>[
          'name',
          'birthYear',
          'condition',
          'onboardingCompletedAt',
          'disclaimerAcceptedAt',
        ]),
      );
    });

    test('la condición se guarda con su cadena, no con su índice', () {
      // Si se guardara el índice, `diabetes` valdría 0 y reordenar el enum
      // reinterpretaría los perfiles ya guardados.
      expect(_perfilDePrueba().toJson()['condition'], 'both');
      expect(
        _perfilDePrueba(condition: HealthCondition.diabetes)
            .toJson()['condition'],
        'diabetes',
      );
    });
  });

  group('Sin perfil no es un error', () {
    test('una instalación nueva no tiene la clave y no lanza', () async {
      // La tercera salida del contrato, y la que T-019 tiene que distinguir de
      // las otras dos: no hay perfil, así que va al onboarding. No es error.
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final LocalStorage storage = await LocalStorage.open();

      expect(storage.readJsonObject(StorageKeys.profile), isNull);
    });
  });

  group('Campo obligatorio ausente', () {
    for (final String campo in <String>[
      'name',
      'birthYear',
      'condition',
      'onboardingCompletedAt',
      'disclaimerAcceptedAt',
    ]) {
      test('sin "$campo" el perfil no se puede leer', () {
        final Map<String, Object?> json = _jsonDePrueba()..remove(campo);

        expect(
          () => UserProfile.fromJson(json),
          throwsA(
            isA<UserProfileFormatException>().having(
              (UserProfileFormatException e) => e.field,
              'campo señalado',
              campo,
            ),
          ),
        );
      });
    }
  });

  group('Tipo inesperado', () {
    test('un nombre numérico no se degrada a texto', () {
      final Map<String, Object?> json = _jsonDePrueba()..['name'] = 42;

      expect(
        () => UserProfile.fromJson(json),
        throwsA(isA<UserProfileFormatException>()),
      );
    });

    test('un año escrito como texto no se convierte solo', () {
      // '1980' es un año perfectamente legible para una persona. Convertirlo
      // en silencio abriría la puerta a convertir también lo que no lo es.
      final Map<String, Object?> json = _jsonDePrueba()..['birthYear'] = '1980';

      expect(
        () => UserProfile.fromJson(json),
        throwsA(isA<UserProfileFormatException>()),
      );
    });

    test('una condición numérica no se interpreta como índice', () {
      final Map<String, Object?> json = _jsonDePrueba()..['condition'] = 0;

      expect(
        () => UserProfile.fromJson(json),
        throwsA(isA<UserProfileFormatException>()),
      );
    });

    test('una fecha numérica no se interpreta como epoch', () {
      final Map<String, Object?> json = _jsonDePrueba()
        ..['disclaimerAcceptedAt'] = 1764547200000;

      expect(
        () => UserProfile.fromJson(json),
        throwsA(isA<UserProfileFormatException>()),
      );
    });
  });

  group('Nombre vacío', () {
    test('la cadena vacía no es un nombre', () {
      final Map<String, Object?> json = _jsonDePrueba()..['name'] = '';

      expect(
        () => UserProfile.fromJson(json),
        throwsA(isA<UserProfileFormatException>()),
      );
    });

    test('solo espacios tampoco', () {
      final Map<String, Object?> json = _jsonDePrueba()..['name'] = '   ';

      expect(
        () => UserProfile.fromJson(json),
        throwsA(isA<UserProfileFormatException>()),
      );
    });

    test('un nombre con espacios alrededor se guarda tal como vino', () {
      // El recorte es solo para decidir si está vacío. Limpiar la entrada es
      // trabajo de T-016; una lectura que transforma lo que lee es una
      // sorpresa.
      final Map<String, Object?> json = _jsonDePrueba()..['name'] = ' Ana ';

      expect(UserProfile.fromJson(json).name, ' Ana ');
    });
  });

  group('Condición desconocida', () {
    test('un valor que no existe no cae en ninguno por defecto', () {
      // El caso que pidió la revisión. Elegir diabetes aquí haría que alguien
      // con otra condición viera contenido que nunca declaró (ADR-003).
      final Map<String, Object?> json = _jsonDePrueba()
        ..['condition'] = 'prediabetes';

      expect(
        () => UserProfile.fromJson(json),
        throwsA(
          isA<UserProfileFormatException>().having(
            (UserProfileFormatException e) => e.field,
            'campo señalado',
            'condition',
          ),
        ),
      );
    });

    test('la comparación distingue mayúsculas también aquí', () {
      final Map<String, Object?> json = _jsonDePrueba()
        ..['condition'] = 'Diabetes';

      expect(
        () => UserProfile.fromJson(json),
        throwsA(isA<UserProfileFormatException>()),
      );
    });
  });

  group('Fechas', () {
    test('una fecha ilegible falla en vez de sustituirse por «ahora»', () {
      // Sustituirla fabricaría la evidencia de que alguien aceptó un aviso
      // legal que nunca aceptó (RF-04).
      final Map<String, Object?> json = _jsonDePrueba()
        ..['disclaimerAcceptedAt'] = 'ayer';

      expect(
        () => UserProfile.fromJson(json),
        throwsA(isA<UserProfileFormatException>()),
      );
    });

    test('se serializan en UTC, terminadas en Z', () {
      final Map<String, Object?> json = _perfilDePrueba().toJson();

      expect(json['onboardingCompletedAt'], endsWith('Z'));
      expect(json['disclaimerAcceptedAt'], endsWith('Z'));
    });

    test('el constructor normaliza una fecha local a UTC', () {
      // Verificado en runtime: el == de DateTime compara el instante Y la
      // marca de zona, así que sin esta normalización dos perfiles idénticos
      // escritos en zonas distintas serían desiguales.
      final DateTime local = DateTime(2026, 9, 1, 10);
      final UserProfile perfil = _perfilDePrueba(onboardingCompletedAt: local);

      expect(perfil.onboardingCompletedAt.isUtc, isTrue);
      expect(perfil.onboardingCompletedAt.isAtSameMomentAs(local), isTrue);
    });

    test('una fecha local y su equivalente en UTC dan el mismo perfil', () {
      final DateTime local = DateTime(2026, 9, 1, 10);

      expect(
        _perfilDePrueba(onboardingCompletedAt: local),
        _perfilDePrueba(onboardingCompletedAt: local.toUtc()),
      );
    });

    test('límite conocido: una fecha imposible se desborda, no se rechaza', () {
      // Comportamiento de DateTime.tryParse, verificado en runtime:
      // '2026-13-45' devuelve el 14 de febrero de 2027 en lugar de null.
      // Este test no celebra el comportamiento: lo fija, para que el día que
      // Dart lo cambie nos enteremos aquí y no en el teléfono de alguien.
      final Map<String, Object?> json = _jsonDePrueba()
        ..['disclaimerAcceptedAt'] = '2026-13-45';

      expect(UserProfile.fromJson(json).disclaimerAcceptedAt.year, 2027);
    });
  });

  group('Compatibilidad hacia adelante', () {
    test('un campo desconocido se ignora y el perfil se lee igual', () {
      // Un campo escrito por una versión futura no debe inutilizar un perfil
      // que por lo demás es legible.
      final Map<String, Object?> json = _jsonDePrueba()
        ..['reminderTime'] = '08:30'
        ..['algoQueNoExiste'] = true;

      expect(UserProfile.fromJson(json), _perfilDePrueba());
    });
  });

  group('Frontera con el almacenamiento', () {
    test('un almacén dañado sale como StorageException, no del modelo',
        () async {
      // Es la distinción que sostiene los tres estados de T-020: «el almacén
      // está dañado» no es «el perfil está incompleto», y ninguna de las dos
      // es «no hay perfil».
      SharedPreferences.setMockInitialValues(<String, Object>{
        StorageKeys.profile: 'esto no es json',
      });
      final LocalStorage storage = await LocalStorage.open();

      expect(
        () => storage.readJsonObject(StorageKeys.profile),
        throwsA(isA<StorageException>()),
      );
    });
  });

  group('La excepción no filtra datos de la persona', () {
    test('el mensaje nombra el campo y el tipo, nunca el valor', () {
      // El perfil guarda el nombre de una persona y esta excepción termina en
      // registros de desarrollo. Los datos de salud son datos sensibles (§15).
      final Map<String, Object?> json = _jsonDePrueba()
        ..['birthYear'] = 'mil novecientos ochenta';

      try {
        UserProfile.fromJson(json);
        fail('se esperaba una UserProfileFormatException');
      } on UserProfileFormatException catch (error) {
        final String mensaje = error.toString();
        expect(mensaje, contains('birthYear'));
        expect(mensaje, contains('String'));
        expect(mensaje, isNot(contains('mil novecientos ochenta')));
      }
    });
  });

  group('Igualdad por valor', () {
    test('dos perfiles con los mismos datos son iguales', () {
      expect(_perfilDePrueba(), _perfilDePrueba());
      expect(_perfilDePrueba().hashCode, _perfilDePrueba().hashCode);
    });

    // Cada uno cambia un solo campo respecto del perfil base. Son cinco tests
    // y no uno con cinco expects a propósito: si la igualdad dejara de mirar
    // un campo, el informe dice cuál.

    test('cambiar el nombre los hace distintos', () {
      expect(_perfilDePrueba(name: 'Luz'), isNot(_perfilDePrueba()));
    });

    test('cambiar el año los hace distintos', () {
      expect(_perfilDePrueba(birthYear: 1959), isNot(_perfilDePrueba()));
    });

    test('cambiar la condición los hace distintos', () {
      expect(
        _perfilDePrueba(condition: HealthCondition.diabetes),
        isNot(_perfilDePrueba()),
      );
    });

    test('cambiar la fecha de onboarding los hace distintos', () {
      expect(
        _perfilDePrueba(onboardingCompletedAt: DateTime.utc(2026, 9, 2)),
        isNot(_perfilDePrueba()),
      );
    });

    test('cambiar la fecha de aceptación los hace distintos', () {
      expect(
        _perfilDePrueba(disclaimerAcceptedAt: DateTime.utc(2026, 9, 2)),
        isNot(_perfilDePrueba()),
      );
    });
  });

  group('Rango plausible de birthYear', () {
    test('las constantes son las declaradas', () {
      // Viven en el modelo para que T-016 no derive un rango distinto. El
      // validador que las compone es de T-016; aquí solo está la definición.
      expect(UserProfile.minBirthYear, 1900);
      expect(UserProfile.minAgeYears, 18);
    });

    test('un año implausible ya guardado se puede leer', () {
      // Presencia y tipo deciden si el dato se puede leer; el rango decide si
      // nunca debió aceptarse, y esa puerta es el formulario (RF-02).
      // Rechazarlo aquí sería un bloqueo del que solo se sale borrando todo.
      final Map<String, Object?> json = _jsonDePrueba()..['birthYear'] = 1899;

      expect(UserProfile.fromJson(json).birthYear, 1899);
    });
  });
}

// ---------------------------------------------------------------------------
// Fixtures
//
// Fechas fijas y en UTC para que ningún test dependa de cuándo se ejecuta ni
// de la zona horaria de la máquina.
// ---------------------------------------------------------------------------

UserProfile _perfilDePrueba({
  String name = 'Ana',
  int birthYear = 1958,
  HealthCondition condition = HealthCondition.both,
  DateTime? onboardingCompletedAt,
  DateTime? disclaimerAcceptedAt,
}) {
  return UserProfile(
    name: name,
    birthYear: birthYear,
    condition: condition,
    onboardingCompletedAt:
        onboardingCompletedAt ?? DateTime.utc(2026, 9, 1, 14, 30),
    disclaimerAcceptedAt:
        disclaimerAcceptedAt ?? DateTime.utc(2026, 9, 1, 14, 28),
  );
}

/// El JSON del perfil de prueba, mutable, para que cada test le quite o le
/// cambie exactamente un campo.
Map<String, Object?> _jsonDePrueba() => _perfilDePrueba().toJson();
