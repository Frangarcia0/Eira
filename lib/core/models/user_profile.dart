import 'package:eira/core/models/health_condition.dart';
import 'package:flutter/foundation.dart' show immutable;

/// Un JSON válido que no describe un perfil.
///
/// La lanza [UserProfile.fromJson] cuando falta un campo obligatorio, cuando
/// uno trae un tipo que no corresponde, o cuando un valor no se puede
/// interpretar —una condición desconocida, una fecha ilegible—.
///
/// ## Por qué no es una `StorageException`
///
/// No hereda de ella y este archivo **no importa `core/storage/`**. Son fallos
/// de dos capas distintas y mezclarlos borraría la única distinción que
/// importa al leer un perfil:
///
/// | Qué falló | Quién lo dice | Qué significa |
/// |---|---|---|
/// | El texto guardado no es JSON, o no es un objeto | `StorageException` | El almacén está dañado |
/// | Es JSON válido, pero no es un perfil | [UserProfileFormatException] | El perfil está incompleto o tiene otra forma |
/// | No hay clave | `readJsonObject` devuelve `null` | No hay perfil. **No es error** |
///
/// **El repositorio de perfil (T-020) tiene que capturar las dos
/// excepciones.** Uno que capture solo una deja la otra subiendo hasta la
/// interfaz. Ambas se traducen a estado `error`, pero con causas y mensajes
/// distintos; el tercer caso no es error y va al onboarding.
///
/// ## Nunca se le muestra a una persona
///
/// Es información para el repositorio. El texto visible lo decide la capa de
/// arriba, en los términos del §24: qué pasó y qué hacer, sin códigos
/// técnicos.
///
/// **[reason] no contiene nunca el valor que falló**, solo qué se esperaba y
/// de qué tipo era lo que había. El perfil guarda el nombre de una persona y
/// esta excepción termina en registros de desarrollo; los datos de salud son
/// datos sensibles (§15) y un mensaje de error no es sitio para ellos. Es la
/// misma disciplina que `StorageException`, que informa `runtimeType` y no
/// contenido.
@immutable
class UserProfileFormatException implements Exception {
  const UserProfileFormatException({
    required this.field,
    required this.reason,
  });

  /// Campo del JSON que no se pudo interpretar, con el nombre que tiene en el
  /// almacenamiento.
  final String field;

  /// Qué se esperaba y qué había, en términos de tipos. Nunca el valor.
  final String reason;

  @override
  String toString() =>
      'UserProfileFormatException: el campo "$field" no se pudo leer. $reason';
}

/// Perfil de la persona que usa la app. Uno por instalación
/// (`PLAN_MAESTRO` §21 A · RF-02, RF-03, RF-04, RF-05).
///
/// Se guarda serializado bajo `StorageKeys.profile`. Este archivo define la
/// **forma** del dato y nada más: quién lo lee y lo escribe es el repositorio
/// de perfil (**T-020**), y quién lo edita es **T-021**.
///
/// ## La invariante: no existe medio perfil
///
/// > **Existe `eira.v1.profile` ⇒ el onboarding se completó y el aviso legal
/// > fue aceptado.**
///
/// El perfil se escribe **una sola vez, completo, al final del onboarding**,
/// después de que la persona acepte el aviso legal. Lo que va entregando por
/// el camino —nombre y año en T-016, condición en T-017— vive en memoria, en
/// el provider de onboarding, y no toca el almacenamiento hasta esa única
/// escritura.
///
/// Por eso [onboardingCompletedAt] y [disclaimerAcceptedAt] **no son
/// anulables**, igual que los tipa el §21.
///
/// Qué compra la invariante:
///
/// - **T-019** se reduce a una sola pregunta: ¿existe el perfil y se puede
///   leer? Sin ella, la redirección tendría que evaluar «hay perfil **y** la
///   fecha de onboarding no es nula **y** la de aceptación tampoco» —tres
///   condiciones con el mismo significado, y cualquier código futuro que
///   olvide una deja pasar a alguien—.
/// - **RF-04, «no se puede omitir».** Con perfiles parciales, un cierre
///   forzado a mitad del onboarding dejaría a alguien con perfil guardado y
///   sin registro de aceptación. Si el guardia se guía por la existencia de la
///   clave —que es lo natural—, esa persona entra a la app sin haber visto
///   nunca el aviso legal.
/// - **RF-05, «el perfil se recupera íntegro».** Medio perfil no es íntegro.
///
/// Si alguna vez se quiere «retomar el onboarding donde se dejó», eso es un
/// borrador con su propia clave y su propio modelo, no un perfil a medias.
///
/// ## Contrato de [UserProfile.fromJson]
///
/// | Situación | Comportamiento |
/// |---|---|
/// | Campo obligatorio ausente, de otro tipo o ilegible | Lanza [UserProfileFormatException] |
/// | Campo desconocido en el JSON | Se ignora. Un campo de una versión futura no inutiliza un perfil legible |
/// | Campo opcional ausente | Valor por defecto documentado. **Hoy no hay ninguno** |
///
/// Esto se aparta de la letra del §22 —«campo faltante → valor por defecto,
/// nunca excepción»— y la decisión, con sus tres alternativas descartadas,
/// está en `docs/decisions/ADR-011`. En resumen: esa regla está escrita para
/// la evolución del esquema y presupone que existe un valor por defecto
/// defendible. Para [name], [birthYear] y [condition] no existe. Un nombre por
/// defecto es un nombre inventado; un año por defecto es un hecho falso; y una
/// condición por defecto haría que alguien con hipertensión viera contenido de
/// diabetes, que es la app afirmando algo sobre su salud (`ADR-003`). Un valor
/// por defecto ahí no es tolerancia: es fabricar datos.
///
/// ## Las fechas se guardan en UTC
///
/// [onboardingCompletedAt] y [disclaimerAcceptedAt] son **instantes**, no días
/// de calendario, y el constructor los normaliza a UTC. Se serializan en
/// ISO-8601 terminado en `Z`, que no admite dos lecturas.
///
/// Verificado, no supuesto: el `==` de `DateTime` compara el instante **y** la
/// marca de zona, así que `fecha == fecha.toUtc()` es `false` aunque
/// `isAtSameMomentAs` sea `true`. Sin normalizar en el constructor, dos
/// perfiles idénticos escritos en zonas distintas serían desiguales y la
/// prueba de ida y vuelta fallaría sin que nada estuviera mal.
///
/// **Este criterio no se hereda a las rachas.** El §21 tipa
/// `HabitCompletion.date` como `yyyy-MM-dd`, que es un día de calendario
/// **local**: «hoy» solo tiene sentido en la zona de la persona, y pasarlo a
/// UTC movería el día a quien marque un hábito de noche. Son dos problemas
/// distintos con dos formas distintas.
@immutable
class UserProfile {
  /// Construye un perfil completo. Normaliza las dos fechas a UTC.
  ///
  /// No es `const` justamente por esa normalización, y no se pierde nada: un
  /// perfil nunca se construye desde literales —siempre viene de lo que
  /// escribió una persona o de un JSON—, así que ningún sitio de llamada
  /// podría haberlo invocado como constante.
  UserProfile({
    required this.name,
    required this.birthYear,
    required this.condition,
    required DateTime onboardingCompletedAt,
    required DateTime disclaimerAcceptedAt,
  })  : onboardingCompletedAt = onboardingCompletedAt.toUtc(),
        disclaimerAcceptedAt = disclaimerAcceptedAt.toUtc();

  /// Reconstruye un perfil desde el mapa que devuelve
  /// `LocalStorage.readJsonObject`.
  ///
  /// Lanza [UserProfileFormatException] si el JSON no describe un perfil
  /// completo. Ver «Contrato de [UserProfile.fromJson]» más arriba.
  factory UserProfile.fromJson(Map<String, Object?> json) {
    return UserProfile(
      name: _leerNombre(json),
      birthYear: _leerEntero(json, _campoBirthYear),
      condition: _leerCondicion(json),
      onboardingCompletedAt: _leerFecha(json, _campoOnboardingCompletedAt),
      disclaimerAcceptedAt: _leerFecha(json, _campoDisclaimerAcceptedAt),
    );
  }

  // ---------------------------------------------------------------------
  // Rango plausible de birthYear
  //
  // Viven aquí, y no en el formulario de T-016, porque son la definición
  // compartida: si el rango viviera solo en el formulario, la validación de
  // entrada y cualquier otra lectura futura —una importación de respaldo—
  // podrían diferir sin que nada lo notara.
  //
  // Lo que NO vive aquí es el validador que las compone ni el mensaje de
  // error: eso es T-016, que es la tarea que los usa. Mismo criterio con el
  // que T-006 dejó readInt para T-007.
  // ---------------------------------------------------------------------

  /// Año de nacimiento más antiguo que se considera plausible.
  ///
  /// Es una cota de sanidad, **no un dato clínico**: las personas verificadas
  /// más longevas llegan a unos 122 años, así que 1900 es un piso que nadie
  /// real alcanza y que atrapa los errores de tipeo que sí ocurren —`19`,
  /// `190`, `1090`—.
  static const int minBirthYear = 1900;

  /// Edad mínima. Sale del §9, que declara a los menores de edad **no
  /// usuarios** de la app.
  ///
  /// El usuario primario del §9 tiene entre 45 y 75 años, pero acotar ahí
  /// dejaría fuera a personas legítimas: hay diagnósticos de DM2 e HTA muy por
  /// debajo de los 45. 18 es el único umbral que el plan declara.
  static const int minAgeYears = 18;

  /// Nombre con el que la persona quiere que se le hable. Obligatorio.
  ///
  /// Es el único dato del almacén que identifica a alguien por su nombre. El
  /// límite de 1 a 40 caracteres del §21 lo aplica el formulario (**T-016**);
  /// aquí solo se exige que no esté vacío, porque un texto vacío no es un
  /// nombre corto: es la ausencia de nombre disfrazada del tipo correcto.
  final String name;

  /// Año de nacimiento. **El año, nunca la fecha completa** (§21,
  /// minimización).
  ///
  /// No se guarda la fecha exacta porque nombre más fecha de nacimiento es un
  /// par casi identificador, y nada del alcance necesita el día. No se guarda
  /// la edad porque una edad es un hecho con fecha de vencimiento: guardada
  /// como `62`, es falsa 365 días después, y corregirla exigiría la fecha que
  /// decidimos no tener. El año es estable para siempre y la edad se deriva.
  ///
  /// **No se valida la plausibilidad al leer.** Presencia y tipo deciden si el
  /// dato *se puede leer*; el rango decide si *nunca debió aceptarse*, y esa
  /// puerta es el formulario (RF-02). Rechazar un `1899` ya guardado
  /// convertiría un problema cosmético en un bloqueo del que solo se sale
  /// borrando todo.
  final int birthYear;

  /// Condición declarada. Obligatoria, y `both` es un valor propio.
  final HealthCondition condition;

  /// Instante en que terminó el onboarding, en UTC.
  final DateTime onboardingCompletedAt;

  /// Instante en que se aceptó el aviso legal de no diagnóstico, en UTC.
  ///
  /// Es la evidencia que exige RF-04. Por eso una fecha ilegible falla en vez
  /// de sustituirse por «ahora»: eso sería fabricar el registro de que alguien
  /// aceptó un aviso que nunca aceptó.
  final DateTime disclaimerAcceptedAt;

  /// El perfil en la forma exacta en que se guarda.
  ///
  /// Devuelve `Map<String, Object?>` porque es lo que recibe
  /// `LocalStorage.writeJsonObject`. Ese mapa nace en la capa de datos y no
  /// sube de ahí: hacia arriba viaja este modelo.
  Map<String, Object?> toJson() => <String, Object?>{
        _campoName: name,
        _campoBirthYear: birthYear,
        _campoCondition: condition.jsonValue,
        _campoOnboardingCompletedAt: onboardingCompletedAt.toIso8601String(),
        _campoDisclaimerAcceptedAt: disclaimerAcceptedAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is UserProfile &&
        other.name == name &&
        other.birthYear == birthYear &&
        other.condition == condition &&
        other.onboardingCompletedAt == onboardingCompletedAt &&
        other.disclaimerAcceptedAt == disclaimerAcceptedAt;
  }

  @override
  int get hashCode => Object.hash(
        name,
        birthYear,
        condition,
        onboardingCompletedAt,
        disclaimerAcceptedAt,
      );

  // No hay toString. Imprimiría el nombre y el año de nacimiento de una
  // persona en cualquier registro o mensaje de error, y los datos de salud son
  // datos sensibles (§15, §26). Tampoco hay copyWith: no tiene un solo
  // consumidor hasta la edición de perfil (T-021), y su forma —cómo distinguir
  // «no lo toques» de «ponlo en nulo»— es una decisión que solo se toma bien
  // con el caso de uso delante. Mismo criterio con el que T-006 dejó readInt
  // para T-007.

  // ---------------------------------------------------------------------
  // Nombres de los campos en el JSON
  //
  // Constantes y no literales sueltos por la misma razón que storage_keys: un
  // error de tipeo entre toJson y fromJson compila, devuelve null y se lee
  // desde la interfaz como «esta persona no tiene datos».
  // ---------------------------------------------------------------------

  static const String _campoName = 'name';
  static const String _campoBirthYear = 'birthYear';
  static const String _campoCondition = 'condition';
  static const String _campoOnboardingCompletedAt = 'onboardingCompletedAt';
  static const String _campoDisclaimerAcceptedAt = 'disclaimerAcceptedAt';

  // ---------------------------------------------------------------------
  // Lectura campo por campo
  //
  // Cada una distingue tres fallos —ausente, de otro tipo, ilegible— para que
  // el mensaje diga cuál de los tres fue. Ninguna incluye el valor leído.
  // ---------------------------------------------------------------------

  static String _leerNombre(Map<String, Object?> json) {
    final Object? valor = json[_campoName];
    if (valor == null) {
      throw const UserProfileFormatException(
        field: _campoName,
        reason: 'no viene en el JSON y es obligatorio.',
      );
    }
    if (valor is! String) {
      throw UserProfileFormatException(
        field: _campoName,
        reason: _seEsperaba('un texto', valor),
      );
    }
    if (valor.trim().isEmpty) {
      // Un texto vacío no es un nombre corto: es la ausencia de nombre con el
      // tipo correcto puesto encima, y es exactamente el valor que habría
      // usado por defecto la alternativa que el ADR-011 descarta.
      //
      // El recorte es solo para esta comprobación: el valor se devuelve tal
      // como vino. Limpiar espacios en la entrada es trabajo de T-016; una
      // lectura que transforma lo que lee es una sorpresa.
      throw const UserProfileFormatException(
        field: _campoName,
        reason: 'está vacío, y el nombre es obligatorio.',
      );
    }
    return valor;
  }

  static int _leerEntero(Map<String, Object?> json, String campo) {
    final Object? valor = json[campo];
    if (valor == null) {
      throw UserProfileFormatException(
        field: campo,
        reason: 'no viene en el JSON y es obligatorio.',
      );
    }
    if (valor is! int) {
      throw UserProfileFormatException(
        field: campo,
        reason: _seEsperaba('un entero', valor),
      );
    }
    return valor;
  }

  static HealthCondition _leerCondicion(Map<String, Object?> json) {
    final Object? valor = json[_campoCondition];
    if (valor == null) {
      throw const UserProfileFormatException(
        field: _campoCondition,
        reason: 'no viene en el JSON y es obligatorio.',
      );
    }
    if (valor is! String) {
      throw UserProfileFormatException(
        field: _campoCondition,
        reason: _seEsperaba('un texto', valor),
      );
    }
    final HealthCondition? condicion = HealthCondition.tryParse(valor);
    if (condicion == null) {
      // Sin valor por defecto a propósito. Elegir uno haría que alguien viera
      // el contenido de una condición que nunca declaró.
      throw const UserProfileFormatException(
        field: _campoCondition,
        reason: 'no es ninguna de las condiciones conocidas.',
      );
    }
    return condicion;
  }

  static DateTime _leerFecha(Map<String, Object?> json, String campo) {
    final Object? valor = json[campo];
    if (valor == null) {
      throw UserProfileFormatException(
        field: campo,
        reason: 'no viene en el JSON y es obligatorio.',
      );
    }
    if (valor is! String) {
      throw UserProfileFormatException(
        field: campo,
        reason: _seEsperaba('un texto ISO-8601', valor),
      );
    }
    final DateTime? fecha = DateTime.tryParse(valor);
    if (fecha == null) {
      throw UserProfileFormatException(
        field: campo,
        reason: 'no es una fecha ISO-8601 que se pueda interpretar.',
      );
    }
    // Límite conocido y verificado en runtime: DateTime.tryParse desborda en
    // vez de rechazar, así que '2026-13-45' devuelve el 14 de febrero de 2027
    // en lugar de null. Una fecha imposible escrita por otra versión o por un
    // respaldo manipulado se lee como una fecha válida y desplazada. Detectarlo
    // exigiría un analizador propio de ISO-8601; queda anotado y no fingido.
    return fecha;
  }

  static String _seEsperaba(String esperado, Object? encontrado) =>
      'se esperaba $esperado y hay ${encontrado.runtimeType}.';
}
