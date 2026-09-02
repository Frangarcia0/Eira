/// Condición de salud declarada por la persona durante el onboarding
/// (`PLAN_MAESTRO` §21 A · RF-03).
///
/// Es un enum y no una clase porque el propio §21 lo decidió así en
/// «Entidades evaluadas y descartadas»: *`HealthCondition` como clase → enum,
/// sin comportamiento ni estado*. Aquí no hay más que tres constantes y la
/// forma en que cada una se escribe en JSON.
///
/// ## `both` es un valor propio
///
/// [both] **no** es «diabetes más hipertensión». Es la doble condición tratada
/// como caso de primera clase: el segmento crítico del §9 y el primer
/// diferenciador del §10. Un contenido aparece en doble condición solo si
/// alguien escribió `both` en su lista `conditions` y lo validó; nunca por la
/// suma de las otras dos listas.
///
/// ## Lo que este enum NO expone, y por qué es lo importante
///
/// No hay `isDiabetes`, `isHypertension`, `includes(...)` ni nada con la forma
/// `this == diabetes || this == both`. `CLAUDE.md` prohíbe por escrito el
/// patrón equivalente en la resolución de contenido:
///
/// ```
/// // PROHIBIDO
/// if (c == 'diabetes' || c == 'both') result.addAll(diabetesList);
/// if (c == 'hypertension' || c == 'both') result.addAll(hypertensionList);
/// ```
///
/// Un getter `isDiabetes` no evitaría ese patrón: lo empaquetaría y lo
/// bendeciría. La primera resolución de contenido escrita encima diría
/// `if (condicion.isDiabetes) …; if (condicion.isHypertension) …;`, que es la
/// línea prohibida con [both] degradado otra vez a la unión de las otras dos:
/// con duplicados y sin un solo ítem revisado para doble condición. El §27 lo
/// pone como caso límite obligatorio —«`both` devuelve contenido etiquetado
/// `both`, no la suma de listas»— y este es el sitio donde se pierde.
///
/// Que ese getter **no exista** es lo que obliga a la capa de contenido a
/// preguntar lo correcto: si la condición de la persona **pertenece** a la
/// lista `conditions` que el ítem declara. Esa resolución es de **T-025**, no
/// de aquí.
///
/// Tampoco lleva etiquetas legibles, íconos, colores ni orden de
/// presentación. Todo texto que vea una persona sobre su condición es de
/// **T-017**; este archivo no contiene una sola palabra destinada a la
/// pantalla.
///
/// ## Por qué el valor de JSON es una cadena escrita a mano
///
/// [jsonValue] es una constante propia de cada valor: ni `.name`, ni el
/// índice. La diferencia se ve el día que alguien renombre un valor en Dart.
///
/// | Opción | Qué pasa ese día |
/// |---|---|
/// | Índice (`0`, `1`, `2`) | Reordenar las constantes reinterpreta en silencio los perfiles ya guardados: quien tiene hipertensión pasa a ver contenido de diabetes, y nada falla |
/// | `.name` | El identificador de Dart **es** el formato de almacenamiento. Un renombre —que el IDE ofrece y que no rompe ninguna compilación— deja ilegibles todos los perfiles guardados, en todos los dispositivos |
/// | Cadena explícita | El renombre no toca el dato. Cambiar el formato exige editar esta constante a propósito, y ese acto deliberado es justo lo que hace preguntarse si hace falta una migración (§22) |
///
/// Hay un segundo motivo, y decide el empate: **estas tres cadenas ya son el
/// vocabulario del contenido**. El §21 B declara que cada ítem de
/// `assets/content/*.json` lleva una lista `conditions` con `both` escrito de
/// forma explícita. Con `.name` habría dos vocabularios que mantener iguales
/// sin nada que los sincronice; con cadenas explícitas hay uno solo, y esta
/// misma clase lo decodifica en los dos lados.
enum HealthCondition {
  /// Diabetes mellitus tipo 2.
  diabetes('diabetes'),

  /// Hipertensión arterial.
  hypertension('hypertension'),

  /// Ambas condiciones a la vez. Valor propio, no la suma de los otros dos.
  both('both');

  const HealthCondition(this.jsonValue);

  /// Cómo se escribe este valor en JSON: tanto en `eira.v1.profile` como en
  /// las listas `conditions` de `assets/content/*.json`.
  ///
  /// **Es formato de almacenamiento, no texto de interfaz.** Cambiar una de
  /// estas cadenas invalida los datos ya guardados en los dispositivos y
  /// obliga a evaluar una migración (§22).
  final String jsonValue;

  /// El valor cuyo [jsonValue] es exactamente [value], o `null` si no hay
  /// ninguno.
  ///
  /// **Estricto a propósito.** No recorta espacios ni ignora mayúsculas:
  /// `'Diabetes'` y `' diabetes'` devuelven `null`. Estas cadenas las escribe
  /// la app, no una persona; aceptar variantes crearía dos codificaciones
  /// válidas del mismo valor, que es lo que `ADR-009` rechazó como «dos
  /// caminos para el mismo dato».
  ///
  /// **No decide política.** `null` significa «no reconozco esto», nunca «usa
  /// diabetes por defecto». Qué hacer con ese `null` lo decide quien
  /// deserializa: en el perfil es `UserProfile.fromJson`, que lo convierte en
  /// un fallo explícito, porque inventar una condición sería la app afirmando
  /// algo sobre la salud de alguien (`ADR-003`, `ADR-011`).
  ///
  /// Acepta `null` y devuelve `null` para que el caso «el campo no venía en el
  /// JSON» no necesite una rama aparte en el sitio de la llamada.
  ///
  /// Recorre [values] en lugar de consultar un mapa estático: son tres
  /// elementos, y un mapa exigiría una inicialización perezosa para ganar
  /// nada medible.
  static HealthCondition? tryParse(String? value) {
    if (value == null) {
      return null;
    }
    for (final HealthCondition condicion in values) {
      if (condicion.jsonValue == value) {
        return condicion;
      }
    }
    return null;
  }
}
