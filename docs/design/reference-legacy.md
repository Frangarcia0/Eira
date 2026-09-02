# Referencia de diseño — proyecto anterior (`autocuidado_app`)

**Fecha:** 2 de septiembre de 2026
**Estado:** Vigente
**Ámbito:** T-015c · PLAN_MAESTRO §2 (filosofía de reutilización) · §3 (auditoría, hallazgos A-G) · §4 (L1-L13) · §14 (fuera de alcance) · §24 (UX y accesibilidad) · ADR-003 · T-013 · T-014
**Origen:** revisión conjunta de capturas reales de `autocuidado_app` (Inicio, Perfil, Educación, Ejercicio, Recetas) contra el código fuente de cada pantalla, 2 de septiembre de 2026.
**Quién lo consulta:** T-016 a T-022 leen las secciones **Inicio** y **Perfil**. Educación, Ejercicio y Recetas se consultan en sus sprints de contenido (T-023 en adelante).

---

## Para qué existe este documento, y para qué no

El §2 fija la regla de la que sale todo lo demás:

> Se reutilizan *decisiones y conocimiento*; **no se copia y pega código**. Cada
> línea del nuevo repositorio se escribe con entendimiento de por qué está ahí.

La auditoría del §3 respondió qué estaba mal en el proyecto anterior. No
respondió la pregunta contraria, que es la que aparece al sentarse a diseñar una
pantalla nueva: **de lo que se veía bien, ¿qué se puede volver a hacer, y qué
cambia al hacerlo otra vez?**

Este documento contesta eso y nada más. Es una lista de composición visual, no
una plantilla. La diferencia es operativa y conviene dejarla escrita:

- **Se consulta antes de diseñar una pantalla, y se cierra antes de escribirla.**
  Nadie abre este documento con un archivo del proyecto anterior al lado para
  transcribirlo.
- Un patrón listado aquí es una **composición** —qué elementos hay, en qué orden,
  con qué jerarquía—, nunca un archivo, un widget ni un fragmento de código.
- Ningún ítem de este documento es una autorización. La autorización la da el RF
  correspondiente. Si un patrón no tiene RF, no se implementa: se anota.

### Las tres categorías, y por qué solo dos son columnas

Cada sección tiene dos columnas fijas. Hay una tercera categoría que
deliberadamente **no** es columna:

| Categoría | Dónde vive |
|---|---|
| Composición que se traslada | **Columna 1** de cada sección |
| Decisión ya cerrada de no trasladar | **Columna 2** — existe solo en *Perfil* |
| Defecto ya documentado y ya decidido | §3 (hallazgos A-G), §6 y §7 del plan. **No se relitiga aquí** |

La tercera categoría cubre `Image.network`, los 259 literales de color, los 45
tamaños de fuente ≤ 12 sp, las cero anotaciones de accesibilidad, la
clasificación clínica incrustada y los formularios de métricas que no
persistían. Todos tienen decisión escrita en el plan desde el 31 de agosto.

> **Que un defecto no aparezca en la columna 2 no significa que se traslade.**
> Significa que ya tiene decisión en el plan y que este documento no la repite.
> La columna 2 lista únicamente lo que se decidió **no** llevar aun estando bien
> resuelto en el original.

### Qué significa exactamente «fidelidad visual completa»

Un patrón entra a la columna 1 cuando el trabajo de trasladarlo es **mecánico**:
el resultado se ve igual, o la diferencia es la que el §24 exige por escrito.

| Cambio al trasladar | ¿Se nota en pantalla? |
|---|---|
| `Image.network` desde URL remota → **el mismo archivo** empaquetado como WebP local, ≤ 80 KB | **No.** Misma foto, mismo encuadre. Cambia de dónde viene, y con eso deja de fallar sin red (L12) |
| `fontSize` literal de 9-12 sp → escala de `AppTypography`, piso de 14 sp | **Sí, y ese es el punto.** El texto crece. Lo que se conserva es la **proporción**: lo que era apoyo sigue siendo apoyo, lo que era título sigue dominando |
| Sin `Semantics` → etiqueta semántica en cada control no textual | **No** para quien ve la pantalla. **Todo** para quien la escucha |
| `Color(0xFF…)` suelto → token de `core/theme/` (E5) | **No**, salvo donde el color original no llegaba a 4.5:1 y hubo que corregirlo (ADR-008) |
| Un texto que afirma algo sobre salud, en `.dart` → `assets/content/*.json` con `SourceMetadata` | **No.** Cambia dónde vive y qué se le exige, no cómo se lee |

Las tres primeras filas son invisibles o proporcionales. Ninguna toca la
composición, que es lo que este documento conserva.

---

## 1. Inicio

**Archivo original:** `home_page.dart` — 1.793 líneas, el archivo más grande del
proyecto anterior (§A.2) y el origen directo de la lección **L5**.

El tamaño era el problema, no el diseño. La pantalla mezclaba tres cosas —el
resumen del día, los formularios de métricas y el historial— en un solo archivo.
De esas tres, **solo la primera es composición reutilizable**: los formularios de
métricas y su historial son el hallazgo A, y las métricas se rediseñan completas
en su propio sprint. E3 (máximo 300 líneas) existe por este archivo.

### Se adapta con fidelidad visual completa

| Patrón | Qué es | Qué cambia al trasladarlo |
|---|---|---|
| **Accesos rápidos circulares** | Fila de accesos con ícono en círculo y etiqueta de texto debajo, hacia los módulos principales | Diámetro del círculo ≥ 48 dp (≥ 56 dp si es acción primaria). Ícono WebP ≤ 20 KB. La etiqueta de texto **ya estaba** en el original y se conserva: es el §24 —«el color nunca es el único portador de información»— cumplido sin proponérselo. Cubre **RF-09** |
| **Tarjeta «Consejo del día» con el gato meditando** | Ilustración a un lado, consejo breve al otro, dentro de una tarjeta con fondo propio | La ilustración se traslada **tal cual**: es el elemento con más carácter de la app y no hay razón para rehacerlo. Ver las dos condiciones más abajo. Se apoya en **RF-08** |
| **Saludo personalizado en cabecera** | «Hola, ‹nombre›» con el nombre del perfil | El nombre sale de `UserProfile.name`, que ya existe desde T-013. **RF-07** |
| **Tarjeta de progreso del día** | Progreso de hábitos y racha, destacados arriba de todo | El valor tiene que coincidir con el estado persistido, que es el criterio literal de **RF-07**. La composición se conserva; el número que va dentro es nuevo y es real |

**Dos condiciones sobre el gato, antes de que el archivo entre al repositorio:**

1. **Licencia registrada** en `docs/content/image-credits.md` *antes* de mover el
   archivo, y convertido a WebP ≤ 80 KB. Es Definition of Done, no trámite: el
   proyecto anterior commiteó ~2,8 MB de imágenes sin un solo registro de
   licencia (§A.9).
2. **El texto del consejo no viaja con la ilustración.** Si afirma algo sobre la
   salud de quien lo lee, vive en `assets/content/*.json` con `SourceMetadata`
   completo, nunca en el `.dart` de la tarjeta. Y su rotación es determinista y
   estable durante todo el día: es P0 de cobertura en el §27 y criterio textual
   de RF-08.

### No se traslada — decisión ya cerrada

**Nada.** Ningún elemento de composición de esta pantalla se descarta por
decisión previa.

Lo que no aparece arriba —los formularios de glucosa, presión y agua, el
historial con valores `'--'` y la clasificación «etapa 1 / etapa 2»— no es una
exclusión de este documento: es el **hallazgo A** (funcionalidad aparente ≠
funcionalidad real) y el **hallazgo D** (interpretación clínica hardcodeada),
ambos cerrados en el §6 y en ADR-003. Ni siquiera son un problema de diseño: son
una pantalla que decía haber guardado algo que descartaba.

---

## 2. Perfil

**Archivos originales:** `profile_page.dart` (617 líneas) y
`edit_profile_page.dart` (735 líneas) — el tercer y el cuarto archivo más
grandes del proyecto anterior.

Es la única pantalla con columna 2, y es la razón por la que este documento
existe: sin él, alguien mira la captura del Perfil anterior, ve un formulario
completo y bien compuesto, y vuelve a agregar campos que ya se decidió no pedir.

### Se adapta con fidelidad visual completa

| Patrón | Qué es | Qué cambia al trasladarlo |
|---|---|---|
| **Cabecera de identidad** | Avatar circular, nombre y edad debajo | Se conserva entera. La edad **sigue apareciendo** — ver la nota de la columna 2 |
| **Opciones agrupadas en tarjetas** | Lista de accesos con ícono, título y chevron, agrupados por tema | Alto de fila ≥ 48 dp. `Semantics` en la fila completa; el chevron es decorativo y se excluye del árbol semántico en vez de leerse |
| **Ver y editar en dos pantallas** | El perfil se lee en una pantalla y se edita en otra | Se conserva. `/profile` → `/profile/edit` son dos de los tres niveles que permite el §23, y separar lectura de edición evita que un toque accidental modifique un dato |
| **Acceso a «Sobre tus datos» desde Perfil** | Entrada propia dentro del listado | El concepto era correcto; el contenido era falso (hallazgo B). Se traslada la **ubicación**; el texto se deriva de `storage_keys.dart`, que es **RF-41** |
| **Confirmación antes de borrar los datos** | La acción destructiva pide confirmación | La composición se traslada. La redacción no se hereda: el §24 exige verbos claros —«Eliminar» / «Cancelar», nunca «Sí» / «No»—. **RF-42** |

### No se traslada — decisión ya cerrada, no defecto de estilo

Dos campos, y **ninguno de los dos está mal hecho en el original**. Se excluyen
por una decisión tomada antes, no por un problema de implementación.

| Elemento excluido | Dónde estaba | Decisión que lo cierra |
|---|---|---|
| **Selector de género** | `edit_profile_page.dart`, sección «Selector de género» | §21 A (minimización) · aplicado en T-013 |
| **Fecha de nacimiento completa** (`birthDate`) | `edit_profile_page.dart` | §21 A · aplicado en T-013 · criterio de aceptación textual de la tarea |

La razón tiene dos capas independientes. **Cada una basta por sí sola**, y eso
importa: si mañana cayera el argumento clínico, la exclusión seguiría en pie por
la capa legal; si cayera el legal, seguiría en pie por la clínica.

#### Capa (a) — Minimización de datos

El §15 fija que EIRA se diseña bajo el estándar de la **Ley 21.719**, vigente
desde el 1 de diciembre de 2026, que exige protección **desde el diseño y por
defecto**: que solo se traten los datos estrictamente necesarios para la
finalidad específica. El §21 A ya lo dejó escrito para estos dos campos:

> **Decisión de minimización:** el proyecto anterior pedía fecha exacta, estatura
> y género sin usarlos. Se eliminan. Menos dato, menos riesgo.

Sobre la fecha, el criterio operativo es el que se aplicó en T-013: **nombre más
fecha de nacimiento es un par casi identificador**, y nada del alcance necesita
el día. El año basta y no identifica.

El punto que hace la decisión defendible en un examen oral es que los campos
**no se usaban**. No se eliminó una funcionalidad: se eliminó la recolección de
un dato sensible que no alimentaba ninguna pantalla, ninguna recomendación y
ningún cálculo. Un dato que no se usa no es neutro; es riesgo puro.

#### Capa (b) — Investigación clínica: el sexo no cambia qué mostrar

La pregunta que se investigó no fue «¿existen diferencias por sexo en DM2 e
HTA?», que es trivialmente sí. Fue la única que decide el diseño: **¿alguna de
esas diferencias cambia qué receta, qué rutina o qué consejo debe ver esta
persona?**

| Hallazgo de la revisión | Consecuencia para EIRA |
|---|---|
| Las guías de la **ADA (Standards of Care, 2026)** formulan sus recomendaciones de **dieta y ejercicio en términos universales**, sin diferenciar por sexo | El contenido que EIRA entrega —recetas, rutinas, hábitos, consejos— no tiene una versión masculina y una femenina que estemos omitiendo. No hay nada que elegir |
| Las diferencias documentadas en la literatura son de **epidemiología y complicaciones clínicas**: mayor riesgo cardiovascular y renal en hombres; mayor riesgo de ansiedad y depresión en mujeres tras el diagnóstico | Son afirmaciones de **riesgo sobre una persona**. Usarlas exigiría que la app dijera algo sobre lo que a alguien le puede pasar, que es exactamente lo que **ADR-003** prohíbe. Quedan fuera de alcance por decisión, no por desconocimiento |
| Lo que sí cambia el contenido mostrado es la **condición** | Se resuelve con `HealthCondition` (T-014), donde `both` es un valor propio. Ese es el eje de personalización de la app, y ya está implementado |

Dicho en una línea: **el sexo habría sido un campo que se pide, se guarda y no
decide nada** — salvo que se usara para algo que ADR-003 no permite.

> **Límite de este análisis, declarado.** Este apartado es *justificación de
> diseño*, no contenido de salud: no se muestra a nadie, no vive en
> `assets/content/` y no lleva `SourceMetadata`, porque `SourceMetadata` existe
> para lo que el usuario lee. Si algo de esto llegara alguna vez a una pantalla,
> deja de ser justificación y entra al ciclo del §25, con fuente, fecha y estado.

#### La edad sigue en pantalla — no se pierde nada visible

Es el malentendido que este documento tiene que prevenir. La cabecera del Perfil
**sigue mostrando «25 años»**. Lo que cambió no es lo que se ve: es lo que se
almacena.

| | Proyecto anterior | EIRA |
|---|---|---|
| Se guarda | `birthDate` completa (día, mes, año) | `birthYear` (§21 A) |
| Se muestra | «25 años» | «25 años» |

Y la razón de guardar el año en vez de la edad ya está escrita en T-013: **una
edad es un hecho con fecha de vencimiento.** Guardada como `25`, es falsa 365
días después, y corregirla exigiría justamente la fecha que decidimos no tener.
El año es estable para siempre y la edad se deriva de él.

> **Punto abierto para T-021, y hay que decidirlo, no descubrirlo en pantalla.**
> Desde el año solo, `añoActual - birthYear` es exacto **después** del cumpleaños
> y sobra un año antes. La salida honesta es que el texto no afirme una precisión
> que el dato no tiene. Queda anotado como decisión de T-021; no se resuelve aquí
> porque este documento no diseña pantallas.

#### El ícono de cámara — fuera de alcance, no rechazado

`edit_profile_page.dart` ofrecía un ícono de cámara para foto de perfil.

**No hay RF que lo cubra ni tarea que lo implemente.** Los requisitos de perfil
son RF-01 a RF-06 y ninguno menciona imagen del usuario; el §14 tampoco lo
declara fuera de alcance, porque nunca se evaluó.

La distinción con los dos campos de arriba es exacta y hay que sostenerla:

| | Género y fecha completa | Foto de perfil |
|---|---|---|
| Estado | **Rechazado.** Se evaluó y se decidió no llevarlo | **Fuera de alcance.** No se evaluó |
| Para reponerlo | Habría que revertir una decisión escrita | Tarea nueva con su propio RF |

Si en el futuro se quiere, entra por la puerta normal: RF nuevo, tarea nueva y,
por tratarse de una imagen aportada por el usuario, análisis de privacidad
propio —dónde se guarda, qué pasa al exportar el respaldo (RF-39) y qué dice de
ella la pantalla «Sobre tus datos» (RF-41)—. Nada de eso está hecho, y por eso
hoy no entra.

---

## 3. Educación

### Se adapta con fidelidad visual completa

| Patrón | Qué es | Qué cambia al trasladarlo |
|---|---|---|
| **Estructura de cuatro bloques** | Buscador arriba · chips de categoría · artículo destacado · lista del resto | Se traslada completa. Es el orden correcto: buscar, filtrar, una entrada obvia, y después todo. Cubre **RF-25** y **RF-27** |
| **Chips de categoría horizontales** | Fila desplazable de filtros, uno activo a la vez | Alto ≥ 48 dp. El chip activo se distingue por **algo más que el color** (§24). El filtro tiene que ser reversible, que es el criterio de **RF-27** |
| **Tarjeta de artículo** | Miniatura, título y resumen de una o dos líneas | La miniatura es WebP local. El resumen conserva su límite de líneas |
| **Detalle con retorno explícito** | El artículo se abre en pantalla propia, con vuelta clara | Se conserva. **RF-26**; el retorno explícito es §23 |

**La tarjeta gana una línea que el original no tenía:** fuente y fecha de
revisión visibles. Es el criterio literal de RF-25 y la respuesta al hallazgo E
—seis JSON sin un solo campo de fuente—. Es la única modificación estructural a
la composición de esta pantalla, y hay que reservarle el espacio al diseñarla,
no encajarla después.

### No se traslada — decisión ya cerrada

**Nada.**

---

## 4. Ejercicio

**Archivo original:** `exercise_page.dart` — 996 líneas, y la pantalla que
originó la lección **L12** («lo que depende de la red falla sin red»).

### Se adapta con fidelidad visual completa

| Patrón | Qué es | Qué cambia al trasladarlo |
|---|---|---|
| **Tarjeta de rutina con foto** | Foto de la rutina, título, duración y nivel | **El cambio es exactamente el que ilustra este documento:** `Image.network` → el mismo archivo empaquetado como WebP local ≤ 80 KB. Misma foto, mismo encuadre, misma tarjeta. La única diferencia visible aparece **sin conexión**, donde antes había un hueco. **RF-33** |
| **Intensidad con color + texto** | El nivel se indica con un color **y** con su nombre escrito | Se traslada tal cual, y conviene decir por qué: es el §24 —«el color nunca es el único portador de información»— ya cumplido en el original. Lo único que cambia es que el color pasa a ser un token de `core/theme/` con contraste verificado |
| **Agrupación por nivel** | Las rutinas se presentan agrupadas por dificultad | Se conserva. **RF-33** pide al menos dos niveles |
| **Detalle de ejercicio con pasos** | Foto, pasos numerados y errores frecuentes | Se conserva, con la adición estructural de abajo. **RF-34** |

**El detalle gana un bloque, y va en un lugar concreto:** las
**contraindicaciones aplicables se muestran antes de los pasos**, no al final.
Es el criterio textual de RF-34 y no es negociable por razones de maquetación:
una advertencia que aparece después de la instrucción llega tarde. Al diseñar la
pantalla, ese bloque se ubica primero y el resto se acomoda.

### No se traslada — decisión ya cerrada

**Nada.**

---

## 5. Recetas

**Archivo original:** `recipes_page.dart` — 570 líneas.

### Se adapta con fidelidad visual completa

| Patrón | Qué es | Qué cambia al trasladarlo |
|---|---|---|
| **Estructura de cuatro bloques** | Buscador · chips de categoría · receta destacada · lista | Idéntica a la de Educación, y funcionaba en las dos. Ver la nota sobre E2 más abajo. **RF-28** y **RF-31** |
| **Chips por momento de comida** | Desayuno · almuerzo · once | Se trasladan. Son tres y son las del contexto chileno: el §14 deja la cena fuera a propósito, porque la once cubre la comida vespertina. **RF-28** |
| **Tarjeta de receta con foto** | Foto, título y categoría | Un solo campo de imagen, local. El original tenía `image` e `imageUrl` compitiendo, y cada pantalla usaba uno distinto (hallazgo F). La composición no cambia; deja de haber dos fuentes para la misma foto |
| **Detalle con secciones** | Foto, ingredientes, preparación y nota nutricional | Se conserva el orden. Gana la fuente visible, que es **RF-30** |
| **Favorito con ícono en la tarjeta** | Marcar favorito desde el listado | Área táctil ≥ 48 dp y `Semantics` que diga el **estado**, no solo el nombre del ícono. Persiste tras reiniciar: **RF-32** |

**Sobre el patrón compartido con Educación — E2 aplica, y el resultado es
duplicar.** La estructura «buscador + chips + destacado + lista» la usan **dos**
features. La regla estructural E2 exige **tres o más** para subir un widget a
`core/widgets/`. Con dos, **se duplica**, y esto no es un descuido que corregir
más adelante: es la regla funcionando. La abstracción prematura de un patrón
compartido por dos pantallas es exactamente como nació `shared/` en el proyecto
anterior. Si una tercera feature adopta la misma estructura, ahí se evalúa; antes
no.

### No se traslada — decisión ya cerrada

**Nada.**

---

## Cómo se usa este documento en una tarea

1. Antes de diseñar la pantalla, se lee **su sección**, no el documento entero.
2. De la columna 1 se toma la **composición**: qué elementos, en qué orden y con
   qué jerarquía. Nunca código.
3. La columna «qué cambia al trasladarlo» es una lista de verificación al cerrar
   la tarea, y coincide con la Definition of Done.
4. Si aparece un patrón que este documento no lista, se decide desde el §24 y el
   RF, no desde la captura anterior.
5. Si aparece un patrón que **sí** está listado pero el RF no lo pide, **no se
   implementa**: se anota en el backlog. La regla absoluta 3 de `CLAUDE.md` no
   tiene una excepción para «estaba en el proyecto anterior».

## Lo que este documento no autoriza

- **No autoriza copiar código.** El §2 es explícito, y es la razón académica del
  reinicio completo.
- **No autoriza reponer un campo del perfil.** La columna 2 de *Perfil* está
  cerrada por dos capas independientes.
- **No autoriza saltarse un RF.** Un patrón sin requisito es backlog.
- **No sustituye al §3.** Lo que este documento no menciona conserva la decisión
  que el plan le dio el 31 de agosto.
