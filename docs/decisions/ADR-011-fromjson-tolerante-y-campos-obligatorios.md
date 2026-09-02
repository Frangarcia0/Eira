# ADR-011 — `fromJson` tolerante, pero no con los campos obligatorios

**Fecha:** 2 de septiembre de 2026
**Estado:** Aceptada
**Ámbito:** T-013 · PLAN_MAESTRO §22 (Serialización) · §21 A (Modelo de datos) · §24 (estado vacío ≠ estado de error) · CLAUDE.md (`fromJson` tolerante) · ADR-003 · ADR-009

---

## Contexto

El plan maestro dice dos cosas sobre la deserialización que no se pueden
cumplir a la vez.

El **§22**, en «Serialización»:

> `toJson()` / `fromJson()` explícitos en cada modelo, con `fromJson`
> **tolerante**: campo faltante → valor por defecto documentado, nunca
> excepción.

El **§21 A**, en la tabla de `UserProfile`:

| Campo | Tipo | Validación |
|---|---|---|
| `name` | String | 1-40 caracteres, **obligatorio** |
| `birthYear` | int | Rango plausible |
| `condition` | HealthCondition | **Obligatorio** |

Un campo obligatorio no tiene valor por defecto: si lo tuviera, no sería
obligatorio. Al implementar T-013 hay que elegir, y la elección determina qué
puede hacer T-019 con la redirección inicial y qué puede distinguir T-020 en su
estado `loading / ready / error`. Este ADR decide eso, y solo eso.

### El precedente que ya existe

El `ADR-009` partió este mismo pelo una vez, para `LocalStorage`:

> `CLAUDE.md` pide `fromJson` tolerante —campo faltante, valor por defecto,
> nunca excepción—, pero esa regla habla de un **campo ausente dentro de un
> JSON válido**, no de un JSON ilegible.

Este ADR extiende esa lectura un paso más, y conviene decir en qué dirección:
**la tolerancia del §22 está escrita para la evolución del esquema** —un campo
agregado en una versión posterior que falta en los datos antiguos— y presupone
que existe un valor por defecto defendible.

### Por qué para estos tres campos no existe ese valor

- Un **`name`** por defecto es un nombre inventado. La app saludaría a alguien
  por un nombre que nunca dio.
- Un **`birthYear`** por defecto es un hecho falso sobre la edad de una
  persona.
- Una **`condition`** por defecto es la grave: elegir `diabetes` porque hay que
  elegir algo hace que alguien con hipertensión vea hábitos, recetas y
  recomendaciones de diabetes. La app estaría afirmando algo sobre su salud sin
  que nadie lo dijera, que es contra lo que existe el `ADR-003`.

Un valor por defecto ahí no es tolerancia: es **fabricar datos de salud**.

### Las tres salidas que hay que poder distinguir

Cualquier opción se juzga por si conserva esta distinción, porque es la que
consumen T-019 y T-020:

| Estado del almacén | Qué significa | A dónde va la app |
|---|---|---|
| No existe la clave | No hay perfil. Instalación nueva | Onboarding. **No es error** |
| Hay dato, pero el JSON está roto | El almacén está dañado | Pantalla de error, **sin escribir nada encima** |
| JSON válido, falta un campo obligatorio | El perfil está incompleto o es de otra forma | Pantalla de error, **sin escribir nada encima** |

---

## Alternativas evaluadas

### A. Tolerante donde hay valor por defecto, excepción propia donde no *(elegida)*

`UserProfile.fromJson` se comporta así:

| Situación | Comportamiento |
|---|---|
| Campo **opcional** ausente | Valor por defecto documentado, sin excepción. Es el §22 cumplido en su caso real |
| Campo **desconocido** en el JSON | Se ignora. Un campo escrito por una versión futura no inutiliza un perfil legible |
| Campo **obligatorio** ausente, de otro tipo, o con un valor ilegible | Lanza `UserProfileFormatException` |

La excepción se declara **en el mismo archivo del modelo**, con el precedente
de `StorageException` dentro de `local_storage.dart`. **No hereda de
`StorageException` y `user_profile.dart` no importa `core/storage/`:** son
fallos de capas distintas, y unificarlos borraría justo la distinción de la
tabla anterior.

- Conserva las tres salidas, cada una con un origen distinto y ninguna
  inventada.
- **Usa el canal de fallo que ya existe.** El `ADR-009` estableció que el dato
  ilegible se lanza y el repositorio lo traduce a estado `error`. Aquí el
  repositorio hace lo mismo con un segundo tipo.
- Los tres estados del §22 —`loading / ready / error`— existen de verdad;
  ninguno es decorativo.
- **Cuesta que el repositorio de T-020 capture dos tipos de excepción**, no
  uno. Es la desventaja real de esta opción y está asumida más abajo.
- **Se aparta de la letra del §22.** Cualquiera que lea «nunca excepción» y
  luego el código va a encontrar una diferencia. La mitigación es este
  documento y la referencia desde el dartdoc del modelo.

### B. La letra del §22 — todo con valor por defecto, nunca falla

`name: ''`, `birthYear: 0`, `condition: diabetes`. `fromJson` es total y no
lanza jamás.

- Cumple el §22 al pie de la letra, y es la opción más simple de escribir.
- **T-019:** un perfil corrupto decodifica como un objeto «válido», así que la
  redirección manda a la persona al dashboard. Sin parpadeo, sí, pero al
  destino equivocado, con un saludo vacío y con el contenido de una condición
  que nadie eligió. El fallo es peor que el parpadeo que evita.
- **T-020:** el estado `error` se vuelve **inalcanzable** para la
  decodificación del perfil; el provider siempre está `ready`. Dos de los tres
  estados que exige el §22 serían adorno.
- Rompe el §24 —«estado vacío no es estado de error»— por construcción: los
  colapsa en el modelo, antes de que la interfaz pueda distinguirlos.
- En el caso de `condition`, contradice el `ADR-003`.
- **Rechazada.** Cumple la letra de una sección rompiendo otras tres.

### C. `fromJson` devuelve `UserProfile?`, nulo ante cualquier problema

Sin excepción y sin valores inventados: si algo falta o no calza, devuelve
nulo.

- Es la más barata y la más tentadora: una sola rama en el sitio de la llamada
  y ningún tipo nuevo.
- No inventa datos, que es lo que la separa de la opción B.
- **Colapsa «no hay clave» con «el dato está dañado»**, que son los dos casos
  que el `ADR-009` se tomó el trabajo de separar en `readJsonObject`.
- **T-019:** los dos casos van al onboarding. Una persona con un perfil dañado
  repite el onboarding y **su primer guardado sobrescribe el registro dañado**,
  incluida la evidencia de aceptación del aviso legal. Es la pérdida de datos
  silenciosa que el `ADR-009` rechazó, aplicada al archivo con el dato más
  sensible de la app, y rompe RF-05 por escrito: «al reiniciar, el onboarding
  no vuelve a mostrarse».
- **T-020:** `error` vuelve a ser inalcanzable; el provider solo puede decir
  «listo, sin nada».
- **Rechazada**, aunque sea la más cercana a la elegida: pierde exactamente la
  distinción que importa.

### D. Un tipo resultado en vez de una excepción

`fromJson` devuelve un objeto que contiene o bien el perfil o bien el problema.
No lanza nunca.

- **Cumple la letra del §22** —«nunca excepción»— y conserva las tres salidas.
  Es la finalista real y por eso queda escrita aquí.
- El fallo viaja con su causa, sin depender de que alguien escriba un `catch`.
- **Introduce un segundo protocolo de fallo para la misma decisión.** El
  repositorio de T-020 tendría que capturar `StorageException` del almacén
  **e** inspeccionar un objeto resultado del modelo, para acabar en el mismo
  estado `error`. Dos formas de decir lo mismo en cuatro líneas seguidas.
- Ningún otro modelo del proyecto usaría el tipo hoy, así que sería un
  mecanismo construido para un solo caso.
- **Rechazada por consistencia, no por incorrecta.** Queda anotada como la
  opción a revisar si `HabitCompletion`, `MetricRecord` o `StreakState`
  terminan necesitando lo mismo: si tres modelos la piden, el argumento de
  consistencia se invierte y esta gana.

---

## Decisión

**`fromJson` es tolerante con lo que tiene un valor por defecto defendible, y
falla de forma explícita con lo que no lo tiene.**

Se elige la opción **A**. `UserProfile.fromJson` lanza
`UserProfileFormatException` cuando falta un campo obligatorio, cuando uno
trae un tipo que no corresponde, o cuando un valor no se puede interpretar.

### Qué cuenta como obligatorio, y por qué son cinco y no tres

El §21 marca como obligatorios `name`, `birthYear` y `condition`. A ellos se
suman `onboardingCompletedAt` y `disclaimerAcceptedAt`, que el §21 tipa sin
interrogación, por la invariante que fija T-013:

> **Existe `eira.v1.profile` ⇒ el onboarding se completó y el aviso legal fue
> aceptado.**

El perfil se escribe una sola vez, completo, al final del onboarding. No se
persiste un perfil parcial. Con perfiles parciales, un cierre forzado a mitad
del onboarding dejaría a alguien con perfil guardado y sin registro de
aceptación; si T-019 se guía por la existencia de la clave —que es lo natural—,
esa persona entra a la app sin haber visto nunca el aviso legal, y RF-04 dice
que no se puede omitir.

### Presencia y tipo sí; plausibilidad no

La frontera de este ADR es exacta y conviene dejarla escrita:

| Qué decide el modelo | Qué decide el formulario (T-016) |
|---|---|
| Si el dato **se puede leer**: está, y es del tipo que dice ser | Si el dato **debió aceptarse**: 1-40 caracteres, año dentro del rango plausible |

Un `birthYear` de `1899` ya guardado **se lee sin problema**. Rechazarlo
convertiría un problema cosmético en un bloqueo del que solo se sale borrando
todos los datos. El rango vive en el modelo como dos constantes —`minBirthYear`
y `minAgeYears`— porque es la definición compartida, pero el validador que las
compone y el mensaje de error son de T-016, que es la tarea que los usa.

La única excepción es el **texto vacío en `name`**: no es un nombre corto, es
la ausencia de nombre con el tipo correcto puesto encima, y es justamente el
valor que la opción B habría usado por defecto.

### Un valor de enum desconocido falla

`HealthCondition.tryParse` devuelve nulo ante lo que no reconoce y **no decide
política**: no elige un valor por defecto. Quien deserializa convierte ese nulo
en un fallo explícito. Inventar una condición sería la app afirmando algo sobre
la salud de una persona.

### Las fechas ilegibles reciben el mismo trato que un campo ausente

No hay valor por defecto posible para una evidencia. Sustituir una
`disclaimerAcceptedAt` ilegible por «ahora» fabricaría el registro de que
alguien aceptó, con la fecha de hoy, un aviso que nunca aceptó.

---

## Consecuencias

### Positivas

- **Las tres salidas se distinguen por construcción**, no por disciplina. T-019
  manda al onboarding solo cuando no hay clave, y nunca sobrescribe un perfil
  dañado.
- **Los tres estados de T-020 existen de verdad**, cada uno con un origen
  propio. El §22 pide `loading / ready / error` y ninguno queda decorativo.
- **La app no inventa ni un dato de salud.** Ninguna rama de la deserialización
  produce una condición, un nombre o una fecha que nadie escribió.
- **Un solo canal de fallo.** El repositorio traduce excepciones a estado
  `error`, igual que ya hace con `StorageException`. No hay un segundo
  mecanismo que aprender.
- **La tolerancia del §22 se conserva donde sirve:** campo opcional ausente con
  valor por defecto, y campo desconocido ignorado. Agregar `reminderTime` más
  adelante no exigirá migración por eso mismo.
- **El precedente queda escrito para los siete modelos que faltan.**
  `HabitCompletion`, `StreakState` y `MetricRecord` copian esta forma en vez de
  volver a decidirla cada uno por su cuenta.

### Negativas — las que hay que asumir

- **El repositorio de perfil tiene que capturar dos tipos de excepción**,
  `StorageException` y `UserProfileFormatException`. Uno que capture solo una
  deja la otra subiendo hasta la interfaz, y nada en el compilador lo obliga.
  Está escrito en el dartdoc de ambas y es la deuda real de esta decisión.
- **El plan maestro queda contradicho por escrito**, otra vez. Quien lea el §22
  y luego el código encuentra una diferencia. El §22 conserva su redacción a
  propósito —es un documento fechado y no se reescribe hacia atrás, mismo
  criterio que con el `ADR-009`—, así que la única mitigación es este ADR y la
  referencia desde el dartdoc del modelo.
- **Un perfil dañado deja la app inutilizable hasta que la persona borre sus
  datos.** Es deliberado —lo contrario es sobrescribirlo en silencio— pero es
  una experiencia mala, y la pantalla que la explique tendrá que ofrecer una
  salida clara. Esa pantalla no existe todavía y su tarea no está en el
  backlog: queda anotado como pendiente para el sprint de privacidad, junto a
  RF-42.
- **La plausibilidad queda sin verificar en la lectura.** Un año imposible
  escrito por un respaldo manipulado entra sin resistencia. Es la contrapartida
  de no bloquear a nadie por un dato cosmético, y depende de que T-016 haga bien
  su trabajo en la entrada.
- **`DateTime.tryParse` desborda en vez de rechazar.** Verificado en runtime:
  `'2026-13-45'` devuelve el 14 de febrero de 2027, no nulo. Una fecha
  imposible escrita por otra versión o por un respaldo manipulado se lee como
  una fecha válida y desplazada. Detectarlo exigiría un analizador propio de
  ISO-8601; queda anotado como límite conocido y fijado por un test que se
  pondrá rojo el día que Dart cambie ese comportamiento.
- **La excepción obliga a disciplina sobre qué se le mete dentro.** Su mensaje
  nombra el campo y el tipo, nunca el valor, porque el perfil guarda el nombre
  de una persona y estos mensajes terminan en registros de desarrollo. Que siga
  siendo así depende de la revisión; hay un test que lo comprueba, pero solo
  para el caso que prueba.
