# ADR-004 — `shared_preferences` como mecanismo de persistencia

**Fecha:** 1 de septiembre de 2026
**Estado:** Aceptada — **documentación retroactiva**
**Ámbito:** PLAN_MAESTRO §22 (Persistencia) · §15 (Restricciones técnicas) · §30 (formato de ADR, mandato expreso sobre este documento) · CLAUDE.md regla 4 · T-006, T-007, T-012

> **Sobre el carácter retroactivo de este ADR.** El §15 fija `SharedPreferences`
> como restricción técnica y el §22 la desarrolla, todo antes del primer commit.
> Este documento formaliza esa decisión con sus alternativas y sus límites.
>
> **Deuda que este ADR cierra.** La dependencia entró en `pubspec.yaml` en
> **T-006**, y la regla 4 de `CLAUDE.md` —toda dependencia nueva exige un ADR—
> quedó incumplida desde ese commit. Está declarado en la bitácora del 1 de
> septiembre de 2026 bajo "Deuda declarada — `ADR-004` es exigible desde hoy". La
> deuda se cierra aquí.
>
> **Mandato expreso del §30.** Es el único ADR cuyo contenido el plan maestro
> especifica de antemano: *"ADR-004 debe decir que SharedPreferences no permite
> consultas y que el crecimiento del historial obligará a migrar"*. Ambas cosas
> están en "Consecuencias negativas", puntos 1 y 6.

---

## Contexto

EIRA guarda datos de usuario en el dispositivo y en ninguna otra parte
(ADR-002). Queda decidir con qué tecnología.

Lo que hay que almacenar (§21, §22) es modesto y está acotado de antemano:

| Clave | Contenido |
|---|---|
| `eira.schema_version` | int — control de migraciones |
| `eira.v1.profile` | JSON de `UserProfile` |
| `eira.v1.habits.completions` | JSON, últimos 90 días |
| `eira.v1.habits.streak` | JSON de `StreakState` |
| `eira.v1.metrics.glucose` · `.blood_pressure` · `.weight` | JSON array de `MetricRecord` |
| `eira.v1.favorites.recipes` · `.routines` | array de IDs |
| `eira.v1.app.last_opened` | fecha, para el reinicio diario |
| `eira.v1.notifications.enabled` | bool |

**Once claves. Ninguna consulta, ningún filtro por rango, ninguna relación.** Las
lecturas reales de la aplicación son "dame el perfil", "dame todas las glucosas"
y "dame las marcas de hábitos", y todas devuelven el documento completo para
mostrarlo o graficarlo.

El volumen previsto está calculado en el §22, no estimado a ojo:

- Usuario activo: ~3 registros/día × 365 ≈ **1.100 registros al año**
- ~120 bytes por registro → **~130 KB anuales**
- **Umbral de alerta: 1 MB**, ≈ 8 años de uso intensivo

Esa cifra es la que ordena toda esta decisión: el problema de almacenamiento de
EIRA es pequeño, y elegir una herramienta dimensionada para uno grande tiene un
costo hoy a cambio de un beneficio que probablemente nunca llegue.

---

## Alternativas evaluadas

| Opción | A favor | En contra | Veredicto |
|---|---|---|---|
| **`sqflite`** (SQLite) | Consultas reales con `WHERE`, `ORDER BY` e índices; escritura de un registro sin reescribir el resto; transacciones; es la respuesta correcta para un historial que crece sin techo | Exige esquema SQL, DDL de migración y un DAO por entidad: cada repositorio se vuelve el doble de código para resolver un problema que hoy no existe. Y la lectura real de la app —"todas las glucosas para graficarlas"— es justo aquella en la que SQLite no aporta nada frente a leer un documento | **Rechazada ahora; designada como destino de migración** |
| **`hive`** | Muy rápido; cajas tipadas; sin SQL | Formato binario propio, opaco para inspección y depuración. Exige adaptadores por tipo —a mano o con generación de código— y trae **su propia** historia de migraciones y de compatibilidad de esquema, encima de la que ya tenemos con `schema_version`. Es más dependencia y más superficie a cambio de un rendimiento que a 130 KB anuales no es medible | **Rechazada** |
| **Archivos JSON planos con `dart:io`** | Cero dependencias; formato legible; control total | Habría que reimplementar escritura atómica, manejo de corrupción, rutas por plataforma y permisos. Es exactamente lo que `shared_preferences` ya hace y probó en producción a gran escala; reescribirlo es asumir riesgo sin comprar nada | **Rechazada** |
| **`shared_preferences`** | Dimensionada al problema real: pares clave-valor, once claves, documentos pequeños. API mínima; sin generación de código; sin esquema; mantenida por el equipo de Flutter. Preaprobada por el §15 y el §22 | No permite consultas; lectura-modificación-escritura completa por clave; sin transacciones; sin cifrado | **Adoptada** |

### Lo que este ADR **no** decide

La **forma de la API** de la clase que envuelve el paquete —genérica por tipo
primitivo, con el dominio en los repositorios— es **ADR-009**, y no sustituye a
este: aquel decide cómo se ve `LocalStorage` hacia arriba, este decide qué hay
debajo. El uso de `SharedPreferences` cacheado en memoria en vez de
`SharedPreferencesAsync` también está razonado en ADR-009.

---

## Decisión

> **`shared_preferences: ^2.5.5`** (resuelto a 2.5.5) como único mecanismo de
> persistencia de datos de usuario, accedido exclusivamente a través de
> `lib/core/storage/local_storage.dart`.

- **Regla E4 sin excepciones:** `local_storage.dart` es el único archivo del
  proyecto que importa `shared_preferences`. Lo verifica
  `tool/check_architecture.dart` (ADR-007).
- **Formato de valor:** JSON serializado como `String` para todo lo compuesto;
  primitivos (`bool`, `int`, `List<String>`) para lo simple. `toJson()` /
  `fromJson()` explícitos en cada modelo, con `fromJson` **tolerante**: campo
  faltante → valor por defecto documentado, nunca excepción (§22).
- **Claves:** el catálogo cerrado de `storage_keys.dart`, con la convención
  `eira.v1.<dominio>.<detalle>`. Métricas separadas **por tipo**: escribir un
  peso no reescribe el historial de glucosa.
- **Migración:** `eira.schema_version` se lee al arrancar y las migraciones se
  aplican en cadena antes de que ningún repositorio lea un dato
  (`schema_migration.dart`, T-007). Existe desde el día uno precisamente porque
  esta decisión tiene fecha de caducidad.
- **Borrado:** `deleteAll()` opera por prefijo `eira.`, no con `clear()`, para no
  tocar claves de plugins que no son datos de la persona.

---

## Consecuencias

### Positivas

- **Es proporcional al problema.** Once claves, documentos pequeños, sin
  relaciones. La herramienta más simple que resuelve el caso es la que deja más
  tiempo para el contenido de salud, que es donde el proyecto se juega su valor.
- **Sin generación de código ni esquema.** Nada que regenerar al cambiar un
  modelo, ningún paso de build que pueda fallar en una máquina distinta.
- **Inspeccionable.** Los datos son JSON legible dentro de un XML; en desarrollo
  se pueden leer con `adb` sin herramientas especiales, lo que hace verificable
  de verdad la pantalla "Sobre tus datos": se compara lo que dice con lo que hay.
- **La barrera E4 es de una sola línea.** Con un único punto de acceso, el atajo
  del `exercise_provider` anterior (§3) deja de ser posible sin que el
  verificador lo note.
- **La migración futura tiene ruta.** `schemaVersion` y un `LocalStorage`
  genérico permiten cambiar de motor sin tocar providers ni pantallas: el cambio
  quedaría contenido en `core/storage/` y en los repositorios.

### Negativas — las que hay que asumir

1. **No permite consultas. Ninguna.** *(mandato expreso del §30)* No hay `WHERE`,
   ni `ORDER BY`, ni `LIMIT`, ni índices. "Las últimas 30 glucosas" significa
   leer la cadena completa, decodificar el arreglo entero a objetos Dart y
   filtrar en memoria — **cada vez que una pantalla lo pida**. Con 1.100
   registros al año eso es aceptable; es una operación de milisegundos sobre un
   arreglo pequeño. Pero es una limitación de diseño, no un detalle: cualquier
   funcionalidad que necesite filtrar por rango de fechas del lado del
   almacenamiento no tiene dónde apoyarse.
2. **Escribir un registro reescribe el historial completo de esa clave.** Agregar
   una medición de glucosa es leer el arreglo, decodificarlo, añadir un elemento,
   volver a serializarlo y escribirlo entero. El costo de una escritura crece
   linealmente con el historial acumulado. A ocho años de uso serían ~1 MB
   reescritos para guardar 120 bytes.
3. **No hay atomicidad entre claves.** No existe transacción. La importación de
   un respaldo escribe varias claves en secuencia, y si el proceso muere a mitad
   —o el usuario cierra la app— quedan unas escritas y otras no, con el perfil
   nuevo y las métricas viejas. `schema_version` no salva de esto porque el
   estado inconsistente es *dentro* de la misma versión de esquema. Es un riesgo
   real de T-072..T-074 (sprint 9) y hay que diseñarlo ahí, no aquí.
4. **Todo vive en memoria mientras la app vive.** El plugin carga el archivo de
   preferencias completo al abrir y mantiene el mapa en memoria. En el umbral de
   1 MB, es 1 MB retenido durante toda la vida del proceso, en un dispositivo de
   gama media (§15). Es el precio de la API sincrónica que ADR-009 eligió a
   conciencia.
5. **No hay cifrado.** Es un XML en el almacenamiento privado de la aplicación:
   protegido por el sandbox de Android frente a otras apps, pero legible en un
   dispositivo con root o con acceso físico y depuración habilitada. Sobre datos
   de salud, eso no es trivial y conviene declararlo antes de que alguien lo
   pregunte. Es parte de por qué `allowBackup="false"` importa (ADR-006) y de por
   qué la exportación es un acto deliberado del usuario (ADR-002). **No se
   mitiga con cifrado en esta versión**: agregarlo exigiría una dependencia más y
   un manejo de claves que el plan no contempla.
6. **El crecimiento del historial obligará a migrar.** *(mandato expreso del
   §30)* El umbral de 1 MB equivale a ~8 años para un usuario intensivo bajo el
   modelo de datos **actual**, y ese "actual" es la parte frágil del cálculo:
   cualquier funcionalidad futura que guarde más por registro —notas largas,
   fotos, un cuarto tipo de métrica— acorta ese horizonte de golpe. El día que se
   cruce, la migración natural es `sqflite`, `schemaVersion` existe para
   permitirla sin pérdida, y el trabajo estará contenido en `core/storage/` y los
   repositorios. **No se migra ahora porque sería resolver un problema
   inexistente**, pero la decisión es explícitamente temporal y así hay que
   defenderla: no es "SharedPreferences es suficiente", es "SharedPreferences es
   suficiente para este volumen y este horizonte".
7. **El umbral de 1 MB está documentado, no implementado.** Hoy **nada en la app
   mide el tamaño de lo almacenado ni avisa al acercarse al límite**. Es un
   número en un plan, no un mecanismo. Si el proyecto siguiera vivo más allá de
   la entrega, esa alerta sería lo primero que habría que agregar; en el alcance
   actual, se declara como hueco conocido en vez de simularlo.
8. **`List<String>` y JSON conviven como formatos.** Favoritos son
   `List<String>`, las métricas son un JSON serializado. Son dos maneras de
   guardar una colección, elegidas por conveniencia de cada caso, y esa asimetría
   es una pequeña deuda de coherencia que hay que recordar al escribir cada
   repositorio.

---

## Verificación

1. `dart run tool/check_architecture.dart` — **E4 limpio**: ningún archivo fuera
   de `core/storage/` importa `shared_preferences`.
2. `flutter analyze` sin errores ni warnings.
3. **Tests de ida y vuelta** (T-008): vacío, completo, campo faltante y JSON
   malformado, según la prioridad P0 del §27.
4. **Test de migración** (T-007): instalación nueva, versión antigua y versión al
   día.
5. **Inspección en dispositivo físico** del XML de preferencias, contrastado con
   la pantalla "Sobre tus datos" cuando exista (control de regresión del §26).
6. **Sin verificación automática del umbral de 1 MB** — declarado en la
   consecuencia negativa 7.

---

## Referencias

- PLAN_MAESTRO §22 — Persistencia; punto único de acceso; convención de claves; límites y migración futura
- PLAN_MAESTRO §15 — Restricciones técnicas: SharedPreferences como mecanismo de persistencia
- PLAN_MAESTRO §21 — Modelo de datos del usuario
- PLAN_MAESTRO §30 — Formato de ADR; mandato expreso sobre el contenido de este documento
- PLAN_MAESTRO §27 — Prioridad P0: serialización y persistencia
- CLAUDE.md — regla 4 (toda dependencia nueva requiere un ADR)
- `docs/progress/2026-09-01.md` — T-006, "Deuda declarada"
- ADR-002 — Almacenamiento exclusivamente local
- ADR-006 — Desactivación del respaldo automático de Android
- ADR-007 — Verificación de la regla E4
- ADR-009 — Forma de la API de `LocalStorage` (decisión distinta y complementaria)
