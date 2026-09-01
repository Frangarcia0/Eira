import 'dart:convert';

import 'package:eira/core/storage/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fallo de persistencia atribuible a un dato **corrupto o de tipo inesperado**.
///
/// Nunca se lanza porque una clave no exista: eso no es un error, es una
/// instalación nueva, y [LocalStorage] lo resuelve con el valor por defecto.
///
/// ## Por qué esto existe en vez de devolver el valor por defecto
///
/// Si `eira.v1.metrics.glucose` contiene un JSON roto y devolviéramos una
/// lista vacía en silencio, la pantalla diría *«aún no tienes registros»* a
/// alguien que tiene trescientos, y el siguiente guardado los sobrescribiría
/// para siempre. Sería pérdida de datos silenciosa.
///
/// Lanzando, el repositorio traduce el fallo a un estado `error` explícito
/// (`PLAN_MAESTRO` §22) y la interfaz puede decir *«no pudimos cargar tus
/// registros»*, que no es lo mismo que *«aún no tienes registros»*. Estado
/// vacío y estado de error son cosas distintas y la app las distingue.
///
/// Esta excepción **no se le muestra nunca a la persona usuaria**: es
/// información para el repositorio. El mensaje visible lo decide la capa de
/// arriba.
class StorageException implements Exception {
  const StorageException({
    required this.key,
    required this.reason,
    this.cause,
  });

  /// Clave cuyo contenido no se pudo interpretar.
  final String key;

  /// Qué se esperaba y qué se encontró, en términos de datos.
  final String reason;

  /// Excepción original, cuando el fallo viene de `json.decode`.
  final Object? cause;

  @override
  String toString() {
    final String origen = cause == null ? '' : ' (causa: $cause)';
    return 'StorageException: la clave "$key" no se pudo leer. $reason$origen';
  }
}

/// Único punto de acceso a `SharedPreferences` en todo el proyecto.
///
/// Ningún archivo fuera de `lib/core/storage/` importa `shared_preferences`
/// (regla estructural **E4**, `PLAN_MAESTRO` §20). El verificador
/// `tool/check_architecture.dart` falla si ese import aparece en otra carpeta.
///
/// ## Qué NO sabe esta clase
///
/// **Nada del dominio.** No sabe qué es un hábito, una métrica ni un perfil.
/// Guarda y lee tipos primitivos y JSON, y ahí termina su trabajo. Convertir
/// un mapa en `UserProfile` es responsabilidad del repositorio de cada
/// feature.
///
/// Esto se aparta de la letra del §22, que describía métodos como
/// `readProfile` o `writeMetric`. La decisión, sus tres razones y sus
/// consecuencias negativas están en `docs/decisions/ADR-009`. En resumen: un
/// método por modelo obligaría a `core/` a importar modelos de `features/`,
/// invirtiendo la dirección de las dependencias, y dejaría sin función al
/// repositorio, que es el tercer eslabón de la cadena
/// `UI → Provider → Repositorio → LocalStorage`.
///
/// ## Contrato de lectura
///
/// | Situación | Comportamiento |
/// |---|---|
/// | La clave no existe | Devuelve el valor por defecto. **Nunca lanza** |
/// | Hay dato, pero de otro tipo o con JSON roto | Lanza [StorageException] |
/// | Escritura fallida | Devuelve `false`. **No lanza** |
///
/// Las lecturas son **sincrónicas** porque `SharedPreferences` mantiene en
/// memoria una copia de todo el almacén desde [open]: leer no toca el disco.
/// Gracias a eso un provider puede pintar la primera pantalla sin pasar por un
/// estado de carga.
///
/// Las escrituras devuelven `Future<bool>`, no `Future<void>`, y ese booleano
/// es lo único que autoriza a decir que un dato quedó guardado (`CLAUDE.md`:
/// *«solo confirma al usuario que se guardó si el dato realmente se
/// persistió»*). El lint `unawaited_futures`, en severidad `error`, impide
/// olvidar el `await` y mostrar un «Listo» que sea mentira.
///
/// ## Sobre `Map<String, Object?>`
///
/// Los mapas se tipan con `Object?`, nunca con `dynamic`: `avoid_dynamic_calls`
/// obliga a comprobar el tipo antes de operar sobre un valor leído. Ese mapa
/// viaja de [LocalStorage] al repositorio —ambos son la capa de datos— y **no
/// sube de ahí**: el repositorio devuelve modelos. Un mapa sin tipar llegando
/// a un widget es exactamente el defecto que `CLAUDE.md` prohíbe.
///
/// ## Uso
///
/// ```dart
/// final LocalStorage storage = await LocalStorage.open();
/// final bool guardado = await storage.writeJsonObject(
///   StorageKeys.profile,
///   perfil.toJson(),
/// );
/// ```
class LocalStorage {
  const LocalStorage._(this._preferences);

  /// Instancia cacheada. Es privada y no tiene getter: exponerla permitiría
  /// saltarse esta clase y vaciaría de sentido la regla E4.
  final SharedPreferences _preferences;

  /// Abre el almacén. Es la única llamada a `SharedPreferences.getInstance()`
  /// del proyecto.
  ///
  /// Conviene llamarla una sola vez, durante el arranque, e inyectar la
  /// instancia resultante a los repositorios. `getInstance()` devuelve un
  /// singleton, así que llamarla de nuevo no duplica la caché, pero sí
  /// dispersa el punto de arranque.
  static Future<LocalStorage> open() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return LocalStorage._(preferences);
  }

  // ---------------------------------------------------------------------
  // Lectura
  //
  // Todas leen con `get`, que devuelve `Object?`, y no con `getString` o
  // `getBool`. La diferencia importa: los métodos tipados del paquete hacen un
  // cast interno que revienta si el valor guardado es de otro tipo. Con `get`
  // la comprobación es nuestra, el fallo tiene nombre y la ausencia de la
  // clave se distingue del dato corrupto. Además evita todo `as` sobre un
  // valor anulable, que es lo que persigue el lint
  // `cast_nullable_to_non_nullable`.
  // ---------------------------------------------------------------------

  /// Texto guardado en [key], o [defaultValue] si la clave no existe.
  ///
  /// [defaultValue] es obligatorio a propósito: obliga a decidir en el sitio
  /// qué significa «no hay dato». Un `''` por omisión terminaría guardado como
  /// si fuera un valor real.
  String readString(String key, {required String defaultValue}) {
    final Object? raw = _preferences.get(key);
    if (raw == null) {
      return defaultValue;
    }
    if (raw is! String) {
      throw StorageException(key: key, reason: _seEsperaba('un texto', raw));
    }
    return raw;
  }

  /// Booleano guardado en [key], o [defaultValue] si la clave no existe.
  bool readBool(String key, {required bool defaultValue}) {
    final Object? raw = _preferences.get(key);
    if (raw == null) {
      return defaultValue;
    }
    if (raw is! bool) {
      throw StorageException(
        key: key,
        reason: _seEsperaba('un booleano', raw),
      );
    }
    return raw;
  }

  /// Entero guardado en [key], o [defaultValue] si la clave no existe.
  ///
  /// Existe por `eira.schema_version` (`PLAN_MAESTRO` §22), la única clave
  /// entera del plan. En T-006 se dejó fuera a propósito —un método sin ningún
  /// consumidor— y la agrega **T-007**, junto con la lógica de migración que
  /// le da sentido. La decisión está en `ADR-009`, sección «Superficie de la
  /// API».
  int readInt(String key, {required int defaultValue}) {
    final Object? raw = _preferences.get(key);
    if (raw == null) {
      return defaultValue;
    }
    if (raw is! int) {
      throw StorageException(key: key, reason: _seEsperaba('un entero', raw));
    }
    return raw;
  }

  /// Lista de textos guardada en [key], o [defaultValue] si la clave no
  /// existe. Pensada para listas de identificadores, como los favoritos.
  List<String> readStringList(
    String key, {
    List<String> defaultValue = const <String>[],
  }) {
    final Object? raw = _preferences.get(key);
    if (raw == null) {
      return defaultValue;
    }
    // El paquete cachea las listas como `List<Object?>` hasta la primera
    // lectura tipada, así que no basta con comprobar `is List<String>`: hay
    // que mirar los elementos.
    if (raw is! List<Object?>) {
      throw StorageException(
        key: key,
        reason: _seEsperaba('una lista de textos', raw),
      );
    }
    final List<String> valores = <String>[];
    for (final Object? elemento in raw) {
      if (elemento is! String) {
        throw StorageException(
          key: key,
          reason: 'la lista contiene un elemento que no es texto '
              '(${elemento.runtimeType}).',
        );
      }
      valores.add(elemento);
    }
    return valores;
  }

  /// Objeto JSON guardado en [key], o `null` si la clave no existe.
  ///
  /// `null` significa **«nunca se guardó»**, que no es lo mismo que un objeto
  /// vacío. Es la diferencia entre «esta persona todavía no completó el
  /// onboarding» y «lo completó y no respondió nada».
  ///
  /// Lanza [StorageException] si el texto no es JSON válido o si el JSON no
  /// describe un objeto.
  Map<String, Object?>? readJsonObject(String key) {
    final String? fuente = _readRawJson(key);
    if (fuente == null) {
      return null;
    }
    final Object? decodificado = _decode(key, fuente);
    if (decodificado is! Map<String, Object?>) {
      throw StorageException(
        key: key,
        reason: _seEsperaba('un objeto JSON', decodificado),
      );
    }
    return decodificado;
  }

  /// Arreglo JSON de objetos guardado en [key], o lista vacía si la clave no
  /// existe.
  ///
  /// Aquí la ausencia sí se colapsa con la lista vacía, al revés que en
  /// [readJsonObject]: un historial que no existe y un historial sin registros
  /// se presentan igual —*«aún no tienes registros»*— y obligar a cada
  /// repositorio a distinguirlos solo produciría ramas muertas.
  ///
  /// Lanza [StorageException] si el texto no es JSON válido, si no describe un
  /// arreglo, o si algún elemento no es un objeto.
  List<Map<String, Object?>> readJsonObjectList(String key) {
    final String? fuente = _readRawJson(key);
    if (fuente == null) {
      return const <Map<String, Object?>>[];
    }
    final Object? decodificado = _decode(key, fuente);
    if (decodificado is! List<Object?>) {
      throw StorageException(
        key: key,
        reason: _seEsperaba('un arreglo JSON', decodificado),
      );
    }
    final List<Map<String, Object?>> registros = <Map<String, Object?>>[];
    for (final Object? elemento in decodificado) {
      if (elemento is! Map<String, Object?>) {
        throw StorageException(
          key: key,
          reason: 'el arreglo contiene un elemento que no es un objeto JSON '
              '(${elemento.runtimeType}).',
        );
      }
      registros.add(elemento);
    }
    return registros;
  }

  // ---------------------------------------------------------------------
  // Escritura
  //
  // El booleano devuelto es el del propio paquete: `true` solo si el dato
  // quedó efectivamente en el almacén. Ninguna de estas operaciones lanza por
  // sí misma; sí puede propagar un error de codificación si un `toJson()`
  // devuelve algo que JSON no representa, y eso es un defecto del modelo que
  // debe verse, no silenciarse.
  // ---------------------------------------------------------------------

  /// Guarda un texto. Devuelve `true` solo si se persistió.
  Future<bool> writeString(String key, String value) =>
      _preferences.setString(key, value);

  /// Guarda un booleano. Devuelve `true` solo si se persistió.
  ///
  /// El parámetro es nombrado porque el lint
  /// `avoid_positional_boolean_parameters` está activo: `write(clave, true)`
  /// no dice nada en el sitio de la llamada.
  Future<bool> writeBool(String key, {required bool value}) =>
      _preferences.setBool(key, value);

  /// Guarda un entero. Devuelve `true` solo si se persistió.
  Future<bool> writeInt(String key, int value) =>
      _preferences.setInt(key, value);

  /// Guarda una lista de textos. Devuelve `true` solo si se persistió.
  Future<bool> writeStringList(String key, List<String> value) =>
      _preferences.setStringList(key, value);

  /// Serializa y guarda un objeto JSON. Devuelve `true` solo si se persistió.
  Future<bool> writeJsonObject(String key, Map<String, Object?> value) =>
      _preferences.setString(key, json.encode(value));

  /// Serializa y guarda un arreglo de objetos JSON. Devuelve `true` solo si se
  /// persistió.
  Future<bool> writeJsonObjectList(
    String key,
    List<Map<String, Object?>> value,
  ) =>
      _preferences.setString(key, json.encode(value));

  // ---------------------------------------------------------------------
  // Existencia y borrado
  // ---------------------------------------------------------------------

  /// Si la clave existe en el almacén.
  ///
  /// No sirve para leer —para eso está el valor por defecto de cada lectura—
  /// sino para responder preguntas sobre el estado de la instalación, como
  /// «¿es la primera vez que se abre la app?».
  bool contains(String key) => _preferences.containsKey(key);

  /// Borra una clave. Devuelve `true` si quedó borrada.
  Future<bool> remove(String key) => _preferences.remove(key);

  /// Borra **todos** los datos de usuario de EIRA. Devuelve `true` solo si no
  /// quedó ninguna clave sin borrar.
  ///
  /// Recorre las claves con prefijo [StorageKeys.prefix] en lugar de llamar a
  /// `clear()`, que vaciaría el almacén completo del proceso, incluidas claves
  /// de plugins que no son datos de la persona y que EIRA no escribió.
  ///
  /// Por prefijo y no por una lista fija de claves, para que el borrado
  /// alcance también a claves de versiones anteriores o de funcionalidad ya
  /// retirada: si la app promete borrar todo, borra todo.
  Future<bool> deleteAll() async {
    final List<String> claves = _preferences
        .getKeys()
        .where((String clave) => clave.startsWith(StorageKeys.prefix))
        .toList();

    bool completo = true;
    for (final String clave in claves) {
      final bool borrada = await _preferences.remove(clave);
      if (!borrada) {
        completo = false;
      }
    }
    return completo;
  }

  // ---------------------------------------------------------------------
  // Apoyo interno
  // ---------------------------------------------------------------------

  /// Texto crudo bajo [key], o `null` si la clave no existe. Lanza si lo
  /// guardado no es texto, porque todo JSON se almacena como texto.
  String? _readRawJson(String key) {
    final Object? raw = _preferences.get(key);
    if (raw == null) {
      return null;
    }
    if (raw is! String) {
      throw StorageException(
        key: key,
        reason: _seEsperaba('un texto con JSON', raw),
      );
    }
    return raw;
  }

  /// Decodifica [fuente] o convierte el fallo en una [StorageException] que
  /// nombra la clave culpable.
  ///
  /// El `catch` está acotado a `FormatException` y **no está vacío**: relanza
  /// con contexto. `CLAUDE.md` prohíbe el `catch` vacío, no el manejo de
  /// errores.
  Object? _decode(String key, String fuente) {
    try {
      return json.decode(fuente);
    } on FormatException catch (error) {
      throw StorageException(
        key: key,
        reason: 'el contenido guardado no es JSON válido.',
        cause: error,
      );
    }
  }

  static String _seEsperaba(String esperado, Object? encontrado) =>
      'se esperaba $esperado y hay ${encontrado.runtimeType}.';
}
