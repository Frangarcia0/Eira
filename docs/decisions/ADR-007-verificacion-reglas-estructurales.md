# ADR-007 — Verificación de reglas estructurales sin dependencias de lint

**Fecha:** 1 de septiembre de 2026
**Estado:** Aceptada
**Ámbito:** E1, E3, E4, E5, E7 (PLAN_MAESTRO §20) · RNF-16 · RNF-25 · CLAUDE.md regla 6

---

## Contexto

El §20 del plan maestro declara siete reglas estructurales y las califica de
**"verificables, entran a la DoD"**. El §28 las incluye en la Definition of Done base de
toda tarea. Sin embargo, al configurar el análisis estático en T-003 quedó a la vista que
tres de ellas no son expresables como reglas de lint:

| Regla | Lo que haría falta | Por qué el analizador no puede |
|---|---|---|
| **E4** — nada fuera de `core/storage/` importa `shared_preferences` | Una regla de *import prohibido por carpeta* | El analizador de Dart no tiene ninguna. `depend_on_referenced_packages` solo verifica que el paquete esté en `pubspec.yaml`; `implementation_imports` solo bloquea el `src/` de otros paquetes. No existe mecanismo para condicionar una regla a la ruta del archivo |
| **E5** — cero colores literales fuera de `core/theme/` | Una regla de *expresión prohibida por carpeta* | Igual. `use_full_hex_values_for_flutter_colors`, que sí viene en `flutter_lints`, solo comprueba que el hexadecimal tenga ocho dígitos; no prohíbe el literal |
| **E7** — cero archivos sin referencias | Análisis del grafo de imports del proyecto | Los lints operan dentro de un archivo. `unused_import`, `unused_element` y `dead_code` detectan lo muerto *dentro* de un archivo, nunca un archivo que nadie importa |

La misma limitación afecta a la **regla 6 de CLAUDE.md** (nada de red) y a **RNF-16**: no hay
forma de prohibir `package:http`, `Dio` o `Image.network` desde `analysis_options.yaml`.

La configuración de análisis por sí sola cierra **RNF-25** y cubre parcialmente **RNF-20**,
pero deja cinco reglas de la DoD sin ningún mecanismo de verificación. Sin decisión, esas
reglas quedarían como revisión manual durante los quince meses del proyecto — exactamente el
patrón que produjo la deuda técnica documentada en el §3.

---

## Alternativas evaluadas

### A. `custom_lint` con reglas propias

Permite escribir reglas sobre el AST real e integrarlas en el IDE y en `flutter analyze`.

- Es la solución técnicamente correcta y la única que da retroalimentación mientras se escribe.
- Introduce dos dependencias de desarrollo (`custom_lint`, `custom_lint_builder`) más un
  paquete propio de reglas, con su propio `pubspec.yaml`.
- Cada dependencia nueva exige su propio ADR según el §7 y la regla 4 de CLAUDE.md. La
  auditoría del repositorio anterior (§3) identificó las dependencias marginales como causa
  directa de deuda.
- Obliga a seguir la evolución del paquete `analyzer` durante quince meses. Un cambio de
  versión del SDK que rompa la API del AST bloquearía `flutter analyze` en pleno sprint.

### B. `dart_code_metrics`

Trae `banned-usage` y comprobaciones de imports ya escritas.

- Cubriría E4 y E5 sin escribir código.
- Desde la versión 5.7 el producto pasó a licencia comercial (DCM). Un proyecto de título no
  puede depender de una herramienta de pago ni justificar su costo ante la evaluación.
- Arrastra un árbol de dependencias considerable para usar dos reglas.

### C. Script propio en `tool/`, con `dart:io` puro

Un verificador de ~500 líneas, sin dependencias, ejecutable con `dart run`.

- Cero dependencias nuevas: `dart:io` y `dart:convert` vienen en el SDK.
- Se ejecuta en cualquier máquina que ya pueda compilar el proyecto.
- El código es propio: se puede leer, explicar y defender en la evaluación.
- No usa el AST, sino expresiones regulares sobre el texto previamente despojado de
  comentarios y de literales de string.

### D. Revisión manual con checklist

- Costo cero de implementación.
- Es exactamente lo que falló en el proyecto anterior. Una regla que solo existe en un
  documento no es una regla verificable.

---

## Decisión

**Se adopta la alternativa C.** Se agrega `tool/check_architecture.dart`, escrito con
`dart:io` puro y sin dependencias, que falla con código de salida 1 cuando detecta:

| Regla | Detección |
|---|---|
| **E1** | Cualquier directorio llamado `shared` bajo `lib/` |
| **E3** | Archivo cuya ruta contiene `pages/` con más de 300 líneas |
| **E4** | Directiva `import`/`export` de `package:shared_preferences` fuera de `lib/core/storage/` |
| **E5** | `Color(0x…)`, `Color.fromARGB(`, `Color.fromRGBO(` o `Colors.*` fuera de `lib/core/theme/` |
| **E7** | Archivo `.dart` que ningún otro archivo de `lib/` ni de `test/` importa. Exento: `main.dart` |
| **Red** | Imports de `package:http/`, `package:dio/`, `package:web/`, `dart:html`, `dart:js_interop`; y llamadas a `Image.network(`, `NetworkImage(`, `HttpClient(` |

Tres decisiones de diseño acompañan a la principal:

1. **Pre-paso léxico.** Antes de aplicar cualquier patrón, el verificador sustituye por
   espacios los comentarios y el contenido de los literales de string, conservando los saltos
   de línea para que los números de línea sigan coincidiendo. Sin esto, un comentario que
   documentara la regla — "aquí no va ningún `Color(0xFF…)`" — haría fallar la verificación.
   Se conservan dos versiones del texto: una sin comentarios pero con strings intactos, porque
   la URI de un `import` vive dentro de un string, y otra sin ninguna de las dos cosas, para
   los patrones de color y de red.

2. **Raíz configurable.** El verificador acepta la raíz como argumento
   (`dart run tool/check_architecture.dart [raizLib] [raizTest]`). Existe para poder apuntarlo
   a un directorio de fixtures con violaciones deliberadas y comprobar que detecta lo que dice
   detectar. Sin ese argumento, la única forma de probar el verificador sería romper el
   proyecto a propósito.

3. **`Colors.*` cuenta como violación de E5.** El §20 dice literalmente `Color(0xFF…)`, pero
   el objetivo de la regla es que el tema sea la única fuente de color. La paleta de Material
   es tan ajena al sistema de tokens como un hexadecimal escrito a mano.

**E5 depende de E4 en un punto:** la regla `always_use_package_imports`, activada en
`analysis_options.yaml` en T-003, es lo que hace deterministas las comprobaciones de E4 y E7.
Con imports relativos, resolver a qué archivo apunta cada directiva sería un problema de
normalización de rutas.

### Cómo se ejecuta

No es posible colgar el verificador de `flutter analyze`: ese comando no admite pre-pasos ni
plugins sin dependencias, que es precisamente la limitación que origina este ADR. Se adopta:

- `tool/verify.ps1` — envoltorio que ejecuta el verificador y después `flutter analyze`, y
  devuelve el primer fallo. Es el comando de uso diario.
- Una línea nueva en la DoD base del §28, para que la regla sea criterio de aceptación y no
  costumbre.

Un hook `pre-commit` sería lo único imposible de saltarse, pero los hooks no viajan en el
repositorio y los commits los hace el autor en su entorno local. Queda como instalación
opcional suya, no como parte del proyecto.

---

## Consecuencias

### Positivas

- E1, E3, E4, E5, E7 y la prohibición de red pasan de ser texto en un documento a ser
  verificables con un comando, desde el primer sprint y no al final.
- Cero dependencias nuevas. El árbol de `pubspec.yaml` no crece.
- El verificador es código propio, corto y legible: se puede explicar en la defensa.
- La detección de red cubre un requisito (RNF-16) que ninguna otra herramienta del proyecto
  vigila.

### Negativas — las que hay que asumir

- **Es código propio que hay que mantener.** Cada regla nueva o cada cambio de estructura
  obliga a tocar el verificador. Es superficie de mantenimiento que `custom_lint` no habría
  requerido escribir desde cero.
- **Usa expresiones regulares, no el AST.** Puede tener falsos negativos ante código
  retorcido: una constante de color construida en tiempo de ejecución, un import armado por
  concatenación o un alias que oculte el nombre del paquete pasarían sin detectarse. El
  pre-paso léxico elimina los falsos positivos habituales, pero no convierte al verificador en
  un analizador semántico.
- **No se integra en el IDE.** La violación se descubre al ejecutar el comando, no mientras se
  escribe. El ciclo de retroalimentación es más largo que con un lint real.
- **Acopla este ADR a una regla de `analysis_options.yaml`.** Si algún día se desactiva
  `always_use_package_imports`, las comprobaciones de E4 y E7 dejan de ser fiables. La
  dependencia queda registrada aquí, pero no hay nada que la haga cumplir automáticamente.
- **E7 detecta "nadie me importa", no "me importan y no me usan".** Lo segundo queda cubierto
  por `unused_import`, promovido a severidad `error` en T-003. La regla queda cerrada por los
  dos lados, pero por dos mecanismos distintos que hay que recordar.
- **El envoltorio es PowerShell.** Es coherente con el entorno de desarrollo actual (Windows),
  pero no es portable. Si el proyecto se mueve a otra plataforma habrá que escribir el
  equivalente.

---

## Verificación

El verificador se probó contra un directorio de fixtures con ocho violaciones deliberadas —
una por cada regla, dos en E5 y dos en red — y las detectó todas, devolviendo código de salida
1. El mismo conjunto incluye un archivo que menciona `Color(0xFF00FF00)`, `Colors.red`,
`Image.network(` y un `import` de `shared_preferences` **únicamente dentro de comentarios y de
literales de string**: un grep ingenuo produce seis falsos positivos sobre ese archivo, el
verificador produce cero. Contra `lib/` real devuelve cero violaciones y código de salida 0.
