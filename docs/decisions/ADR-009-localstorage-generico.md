# ADR-009 — `LocalStorage` genérico: el dominio vive en los repositorios

**Fecha:** 1 de septiembre de 2026
**Estado:** Aceptada
**Ámbito:** T-006 · PLAN_MAESTRO §22 (Persistencia) · §20 regla E4 · CLAUDE.md (cadena de datos)

---

## Contexto

El §22 del plan maestro describe la clase de persistencia en una frase que es a la
vez la decisión correcta y una instrucción imposible de cumplir:

> `LocalStorage` es la **única** clase que importa `shared_preferences`. Expone
> operaciones tipadas (`readProfile`, `writeMetric`, `deleteAll`), nunca
> `getString` genérico hacia afuera.

La primera oración es la regla E4 y no se discute. La segunda propone una forma de
API concreta —un método por entidad del dominio— y es la que este ADR revisa, porque
al implementar T-006 quedó a la vista que no se sostiene.

Este ADR **no decide usar `shared_preferences`**. Esa decisión ya está tomada en el
§22 y su justificación, con los límites del paquete —no permite consultas, y el
crecimiento del historial obligará a migrar—, corresponde a `ADR-004`, previsto en
T-012. Aquí se decide solamente **qué forma tiene la API** de la clase que lo
envuelve.

### Tres hechos que delimitan la decisión

**1. La secuencia del backlog lo hace imposible hoy.**
`readProfile` devuelve `UserProfile` y `writeMetric` recibe `MetricRecord`. Esos
modelos son **T-013** y **T-034**; esta tarea es **T-006**. El propio plan declara
la dependencia en ese sentido: en la tabla de tareas, T-013 y T-024 dependen de
T-006, no al revés. Escribir hoy un método por modelo exigiría inventar los modelos
por adelantado, es decir, tomar en la tarea de persistencia decisiones de dominio
que pertenecen a otras siete tareas.

**2. Invierte la dirección de las dependencias.**
`readProfile` obliga a `lib/core/storage/local_storage.dart` a importar
`lib/features/onboarding/models/user_profile.dart`. Es decir, `core/` pasa a
depender de `features/`. A partir de ahí, cada feature nueva agrega dos métodos a
`LocalStorage`, y la clase termina siendo el archivo que hay que tocar en todos los
sprints y que conoce todos los modelos del proyecto.

Ese es exactamente el papel que cumplía la carpeta `shared/` en el repositorio
anterior y que el §3 identifica como origen de la deuda técnica. La regla **E1** la
prohíbe por nombre; recrearla con otro nombre dentro de `core/storage/` sería
cumplir la letra de E1 y romper su propósito.

**3. Dejaría sin trabajo al tercer eslabón de la cadena.**
El §22 fija la cadena de datos en cuatro niveles, «sin atajos»:

```
UI → Provider → Repositorio → LocalStorage
```

El nivel que conoce el dominio es el **repositorio**: `habits_repository.dart`
sabe qué es una racha, `metrics_repository.dart` sabe qué es una glucosa. Si
`LocalStorage` ya devolviera `UserProfile` ya construido, el repositorio no tendría
nada que hacer salvo delegar, y la cadena real serían tres niveles con un cuarto
decorativo. La forma genérica es la que hace que los cuatro niveles existan de
verdad.

---

## Alternativas evaluadas

### A. La letra del §22 — un método tipado por entidad

```dart
Future<UserProfile?> readProfile();
Future<bool> writeMetric(MetricRecord record);
```

- Da la API más cómoda en el sitio de uso: el repositorio recibe el modelo hecho.
- Centraliza la serialización, lo que evita que dos features escriban dos
  `fromJson` distintos para el mismo dato.
- **Imposible de implementar en T-006**, que es donde el plan la sitúa: los modelos
  no existen hasta T-013 y siguientes.
- Invierte la dirección de las dependencias (`core/` → `features/`).
- Convierte `LocalStorage` en un archivo que crece en cada sprint y que ninguna
  regla estructural limita: E3 solo acota las pantallas.
- Vacía de contenido a la capa de repositorios.

### B. Genérico por tipo primitivo, con el dominio en los repositorios *(elegida)*

```dart
Map<String, Object?>? readJsonObject(String key);
Future<bool> writeJsonObject(String key, Map<String, Object?> value);
```

- Implementable hoy, sin conocer un solo modelo del dominio.
- `core/` no importa nada de `features/`. Las dependencias apuntan hacia adentro.
- `LocalStorage` deja de crecer: agregar una feature no lo modifica, agrega un
  repositorio.
- La cadena de cuatro niveles se sostiene, con el repositorio haciendo el trabajo
  que el §22 le asigna.
- **Cuesta que cada repositorio escriba su propio `toJson`/`fromJson`.** Es trabajo
  repetido y es la desventaja real de esta opción.
- Deja pasar mapas sin tipar entre `LocalStorage` y el repositorio. Se acota con
  `Map<String, Object?>` en lugar de `Map<String, dynamic>`, pero la disciplina de
  que el mapa **no suba** del repositorio queda en manos de quien programa.

### C. Genérico ahora y fachada tipada después

Implementar B en T-006 y, cuando los modelos existan, agregar sobre él los métodos
`readProfile` / `writeMetric` que pide el §22.

- Cumpliría con la letra del plan sin bloquear T-006.
- Reintroduce el problema 2 en cuanto se escribe el primer método de la fachada:
  `core/` volvería a importar modelos de `features/`, solo que más tarde y con más
  código encima.
- Produce dos caminos válidos para el mismo dato —el genérico y el tipado— y ninguna
  regla que obligue a elegir uno. Dos caminos es como empezó la deuda anterior.

---

## Decisión

**`LocalStorage` no conoce el dominio.** Guarda y lee tipos primitivos y JSON. La
conversión a modelos ocurre en el repositorio de cada feature.

Se conserva íntegra la parte del §22 que importa: **E4 sigue vigente sin
excepciones**, `lib/core/storage/local_storage.dart` es el único archivo del
proyecto que importa `shared_preferences`, y `tool/check_architecture.dart` lo
verifica en cada ejecución.

### Superficie de la API

| Grupo | Métodos |
|---|---|
| Apertura | `open()` |
| Lectura | `readString` · `readBool` · `readStringList` · `readJsonObject` · `readJsonObjectList` |
| Escritura | `writeString` · `writeBool` · `writeStringList` · `writeJsonObject` · `writeJsonObjectList` |
| Existencia y borrado | `contains` · `remove` · `deleteAll` |

No hay `readInt`/`writeInt`: la única clave entera del §22 es `eira.schema_version`
y la agrega **T-007** junto con la lógica de migración que le da sentido. Tampoco
hay `readDouble` —ninguna clave del plan lo necesita— ni lecturas de fecha:
`eira.v1.app.last_opened` se guarda como texto ISO-8601 e interpretarlo es trabajo
de `core/utils/date_utils.dart`.

### Contrato de lectura

| Situación | Comportamiento |
|---|---|
| La clave no existe | Devuelve el valor por defecto. **Nunca lanza** |
| Hay dato, pero de otro tipo o con JSON roto | Lanza `StorageException` |
| Escritura fallida | Devuelve `false`. **No lanza** |

Las lecturas usan `SharedPreferences.get`, que devuelve `Object?`, y no los métodos
tipados del paquete. Los tipados hacen un cast interno que revienta con un error sin
contexto si el valor guardado es de otro tipo; con `get`, la comprobación es propia,
el fallo nombra la clave y —lo importante— **la clave ausente se distingue del dato
corrupto**. Además evita todo `as` sobre un valor anulable, que es lo que persigue
el lint `cast_nullable_to_non_nullable` ya activo.

### Por qué el dato corrupto lanza en vez de devolver el valor por defecto

Es la decisión menos evidente del archivo. `CLAUDE.md` pide `fromJson` tolerante
—campo faltante, valor por defecto, nunca excepción—, pero esa regla habla de un
**campo ausente dentro de un JSON válido**, no de un JSON ilegible.

Si `eira.v1.metrics.glucose` contuviera texto corrupto y devolviéramos lista vacía,
la app le diría *«aún no tienes registros»* a alguien con trescientos, y el
siguiente guardado los sobrescribiría de forma definitiva. Sería pérdida de datos
silenciosa provocada por la propia app.

Lanzando `StorageException`, el repositorio la traduce a estado `error` y la
pantalla puede decir *«no pudimos cargar tus registros»*. El §22 y el §24 exigen
justamente esa distinción: estado vacío no es estado de error.

### Escrituras que devuelven `Future<bool>`

Ninguna escritura devuelve `void`. El booleano es lo único que autoriza a decirle a
alguien que su dato quedó guardado, que es una regla explícita de `CLAUDE.md` y la
lección L1 de la auditoría. `unawaited_futures`, en severidad `error`, impide
olvidar el `await` y mostrar un «Listo» que sea mentira.

### `deleteAll()` por prefijo

Borra las claves que empiezan por `eira.` en lugar de llamar a `clear()`. `clear()`
vaciaría el almacén completo del proceso, incluidas claves escritas por plugins que
no son datos de la persona. El prefijo, en vez de una lista fija de claves, hace que
el borrado alcance también a claves de versiones anteriores o de funcionalidad
retirada: si la app promete borrar todo, borra todo.

### Sub-decisión: API sincrónica cacheada, no `SharedPreferencesAsync`

El paquete ofrece hoy dos superficies. Se usa la clásica, `getInstance()`, por dos
razones:

- Mantiene en memoria una copia del almacén desde la apertura, así que **las
  lecturas son sincrónicas**. Un provider puede pintar la primera pantalla sin pasar
  por un estado de carga, y los repositorios no propagan `Future` en cada getter.
- Es la que ya asume el resto del proyecto: `analysis_options.yaml` documenta, al
  justificar `unawaited_futures`, que `LocalStorage.setString()` devuelve
  `Future<bool>`.

La contrapartida está en las consecuencias negativas.

---

## Consecuencias

### Positivas

- **T-006 se puede cerrar sin inventar el dominio.** Ninguna decisión de modelado
  se adelanta a la tarea que le corresponde.
- **`core/` no depende de `features/`.** Las dependencias apuntan hacia adentro y
  la regla E1 se cumple en propósito, no solo en el nombre de la carpeta.
- **`LocalStorage` no vuelve a crecer.** Agregar una feature agrega un repositorio,
  no un método aquí. Es el archivo más peligroso del proyecto —lo atraviesa todo el
  dato del usuario— y queda cerrado en T-006.
- **Los cuatro niveles de la cadena existen de verdad**, cada uno con trabajo
  propio: el repositorio serializa y decide, `LocalStorage` guarda.
- **La clave ausente está resuelta por construcción**, no por disciplina: cada
  lectura exige un valor por defecto y ninguna hace un cast sobre un anulable.
- **Se puede probar sin ningún modelo.** T-008 escribe los tests de ida y vuelta
  contra tipos primitivos y JSON, sin esperar a T-013.

### Negativas — las que hay que asumir

- **Cada repositorio escribe su propio `toJson`/`fromJson`.** Es trabajo repetido en
  diez features, y con él la posibilidad de que dos repositorios serialicen una
  fecha de dos formas distintas. La única defensa prevista es la revisión y los
  tests de T-008; no hay nada en el compilador que lo impida.
- **Un mapa sin tipar circula entre `LocalStorage` y el repositorio.** `CLAUDE.md`
  prohíbe que un `Map` cruce la capa de datos hacia arriba, y aquí el mapa nace
  legítimamente en la capa de datos. Que no suba de ahí depende de quien programa.
  `Map<String, Object?>` en vez de `dynamic` acota el daño —`avoid_dynamic_calls`
  obliga a comprobar el tipo antes de operar—, pero no lo impide.
- **Las claves se pasan como texto.** `readJsonObject(StorageKeys.profile)` no
  impide `readJsonObject('eira.v1.profil')`. Un error de tipeo compila, devuelve
  `null` y se lee desde la UI como «esta persona no tiene datos». Es el riesgo
  concreto que introduce la forma genérica frente a la opción A, y por eso
  `storage_keys.dart` es un catálogo cerrado y ninguna clave se escribe como
  literal fuera de él.
- **Nada obliga a pasar por el repositorio.** Un provider podría inyectarse
  `LocalStorage` y leer JSON directamente, saltándose un nivel de la cadena. El
  verificador comprueba E4 —quién importa `shared_preferences`— pero no puede
  comprobar quién importa `LocalStorage`. Es una regla sostenida por revisión.
- **`StorageException` obliga a que cada repositorio la maneje.** Un repositorio que
  no la capture propaga la excepción hasta el provider y, si tampoco la captura,
  hasta la UI. La API es honesta pero exigente: quien la usa tiene que decidir qué
  hacer con el fallo.
- **La API sincrónica es la superficie más antigua del paquete.** Si el proyecto
  algún día tuviera que moverse a `SharedPreferencesAsync`, todas las lecturas
  pasarían a devolver `Future` y habría que revisar cada repositorio y cada
  provider. La cambia una tarea acotada —`LocalStorage` es un solo archivo— pero es
  trabajo real, y hoy se elige la comodidad de leer sin `await`.
- **El plan maestro queda contradicho por escrito.** Cualquiera que lea el §22 y
  luego el código va a encontrar una diferencia. La única mitigación es que esa
  diferencia esté anotada en este ADR y referenciada desde el dartdoc de
  `local_storage.dart`; el §22 conserva su redacción original a propósito, porque
  el plan es un documento fechado y no se reescribe hacia atrás.
