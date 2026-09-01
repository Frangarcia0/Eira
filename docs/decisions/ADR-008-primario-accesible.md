# ADR-008 — Primario accesible: escala salvia derivada del color de marca

**Fecha:** 1 de septiembre de 2026
**Estado:** Aceptada
**Ámbito:** T-004 · PLAN_MAESTRO §24 (Color y contraste) · anexo A.10 · regla E5 (§20)

---

## Contexto

El color de marca de EIRA es el verde salvia **`#979F80`**. En el proyecto
anterior era el primario de la aplicación: relleno de los botones principales,
con texto blanco encima.

Medido con la fórmula de luminancia relativa de la WCAG 2.1, ese par da
**2.77:1**. El mínimo AA para texto normal es **4.5:1**. No es un caso límite:
falta el 40 % del contraste exigido, y afecta al elemento más pulsado de cada
pantalla.

Tres hechos delimitan la decisión y no la dejan abierta:

- **La auditoría del repositorio anterior ya lo detectó** (anexo A.10, junto con
  259 literales de color, 16 tamaños de fuente y cero usos de `Semantics`).
- **El plan maestro lo declara corrección obligatoria y no negociable** (§24):
  se conserva el verde salvia como identidad para superficies y decoración, pero
  se define una variante oscurecida para texto y fondos de botón, medida y
  documentada antes del primer sprint de UI.
- **El público de la app es el peor caso posible para este defecto.** Personas
  adultas con DM2 o HTA, un grupo con prevalencia alta de retinopatía diabética
  y de presbicia. El contraste no es aquí un requisito de formulario: es la
  diferencia entre poder usar la app y no poder.

Una particularidad ordena el calendario: **T-004 corrige el color antes de que
exista una sola pantalla**. Si los tokens llegaran después de la UI, corregirlos
significaría reescribir pantallas ya hechas — el patrón que produjo los 259
literales del proyecto anterior.

---

## Alternativas evaluadas

### A. Mantener `#979F80` como primario y aceptar el incumplimiento

Es lo que hacía el proyecto anterior.

- Costo cero. La identidad visual queda intacta y exactamente como se diseñó.
- **Incumple AA de forma medible y documentada**, en un proyecto cuyo §24
  declara la accesibilidad criterio de aceptación y no recomendación. Se
  entregaría una app que falla el requisito que su propio plan destaca.
- El defecto ya está escrito en la auditoría. Repetirlo a sabiendas es peor que
  haberlo cometido por ignorancia: es indefendible en la evaluación.
- Perjudica al usuario objetivo justo donde es más vulnerable.

### B. Cambiar la identidad de la app por otro color que apruebe AA

Elegir un primario nuevo —un verde más saturado, un azul— que dé ≥ 4.5:1 contra
blanco sin retoques.

- Resuelve el contraste de raíz y da libertad para elegir un color con buen
  comportamiento en toda la escala.
- **Descarta la identidad visual existente sin necesidad.** El §5 del plan lista
  las decisiones a conservar del proyecto anterior, y la paleta salvia es una de
  ellas: es reconocible, es sobria y encaja con el tono de una app de
  autocuidado.
- El problema no es el matiz salvia: es su **luminancia**. Cambiar de familia de
  color para arreglar un problema de luminosidad es sobrecorregir.
- Obligaría a rehacer el material gráfico del proyecto y a justificar ante la
  evaluación un cambio de identidad que nadie pidió.

### C. Conservar el salvia como identidad y derivar una variante oscurecida para texto y relleno

Construir una escala de seis pasos a partir del salvia original, manteniendo el
matiz, y usar un peldaño oscuro como primario funcional.

- Conserva la identidad: el color de marca sigue en la app, exacto, en
  superficies y decoración.
- Aprueba AA con margen en los elementos que llevan texto.
- Es lo que el §24 pide literalmente.
- Obliga a mantener la disciplina de que el color de marca **no** se use como
  texto, cosa que ninguna herramienta puede verificar sola.

---

## Decisión

**Se adopta la alternativa C.**

Se define en `lib/core/theme/app_colors.dart` una escala salvia de **seis
pasos**, con **`sage400` igual al color de marca exacto (`#979F80`)**, sin
retocar ni un dígito:

| Token | Hex | Rol |
|---|---|---|
| `sage50` | `#F2F4EC` | Fondo de sección suave |
| `sage100` | `#E4E8DA` | Contenedor primario: chips, tarjetas destacadas |
| `sage200` | `#CBD2BB` | Borde sobre superficie salvia |
| **`sage400`** | **`#979F80`** | **Identidad de marca: decoración y superficies grandes** |
| **`sage600`** | **`#626B4F`** | **PRIMARIO: relleno de botón, texto e iconos salvia** |
| `sage700` | `#4C5340` | Primario presionado, énfasis |

El reparto de responsabilidades es explícito:

- **`sage400` es identidad, no interfaz.** Decoración, ilustración y superficies
  grandes sin texto encima. Prohibido como color de texto y como relleno de un
  botón con texto.
- **`sage600` es el primario funcional.** 5.62:1 contra blanco y 5.42:1 sobre el
  fondo de la app. Es el color de los botones principales, de los iconos activos
  y del texto salvia.
- **`sage700` es el estado presionado**, con 8.02:1 contra blanco.

Que `sage400` conserve el hexadecimal exacto de la marca es deliberado: la
identidad no se aproxima, se conserva íntegra y se le asigna un lugar donde el
contraste no aplica.

### Lo que acompaña a la decisión

1. **La medición queda registrada**, no estimada. Los 18 pares que aprueban y
   los 2 que reprueban están en `docs/accessibility/contrast-verification.md`
   con su ratio, su umbral y su uso concreto en la app.

2. **El valor del plan maestro se corrige.** El §24 y el anexo A.10 dicen
   "~2.3:1". La fórmula WCAG 2.1 da **2.77:1**. La conclusión es la misma
   —reprueba AA con holgura— pero el número correcto es 2.77 y es el que se
   registra. Un documento de accesibilidad con cifras estimadas a ojo no sirve
   como evidencia.

3. **La restricción se verifica en cada `flutter test`.**
   `test/core/theme/app_colors_contrast_test.dart` recalcula todos los pares
   desde las constantes reales de `AppColors`. Oscurecer o aclarar un token sin
   revisar la tabla rompe el build. Incluye un test que documenta la excepción
   de `sage400` de forma explícita: afirma que **no** llega a 4.5:1, para que
   nadie lo "arregle" convirtiéndolo en color de texto.

4. **La restricción se escribe en el propio token.** El dartdoc de `sage400`
   dice, en el archivo donde se lee, que está prohibido usarlo como texto y por
   qué. Un documento en `docs/` no se lee mientras se programa; un dartdoc sí.

5. **`app_theme.dart` no entra aquí.** El `ThemeData` se arma en T-005, cuando
   exista la escala tipográfica: un tema sin `TextTheme` habría que reescribirlo
   una semana después.

---

## Consecuencias

### Positivas

- El primario aprueba AA con margen (5.62:1 frente a 4.5:1 exigidos), y el
  estado presionado lo aprueba de sobra (8.02:1).
- La corrección llega **antes de la primera pantalla**. Ninguna UI nace con el
  color equivocado, y no hay que refactorizar nada más adelante.
- Toda la paleta —20 tokens, 20 pares medidos— queda documentada y verificada
  automáticamente. Es evidencia directa para la defensa del proyecto.
- La identidad visual sobrevive intacta: el color de marca sigue presente y
  exacto en la app.
- El límite clínico queda escrito donde se programa: los tokens `error`,
  `success` e `info` llevan la advertencia de que describen estados de la
  interfaz y no valores de salud (CLAUDE.md regla 5, ADR-003).

### Negativas — las que hay que asumir

- **El botón principal se ve más oscuro que el diseño original de marca.** El
  salvia claro es lo que le daba a la app su carácter, y el elemento más visible
  y más repetido de cada pantalla ya no lo lleva. La identidad visual pierde
  intensidad justo donde más se mira. Es una pérdida estética real y es el
  precio de cumplir AA; no se compensa con nada.

- **El color de marca exacto queda relegado a decoración.** Eso obliga a
  vigilar, en **cada** revisión de UI, que nadie lo use como texto ni como
  relleno de botón. Es la regla más fácil de romper de todo el sistema de color,
  porque romperla se ve *bien*: el resultado es bonito y es inaccesible. Ninguna
  herramienta lo detecta — para el verificador `sage400` es un token legítimo
  dentro de `core/theme/`, y para el analizador es una constante más. La única
  defensa es el dartdoc del token y la revisión humana.

- **Toda propuesta de color futura pasa por medición y registro.** Agregar un
  color deja de ser escribir una línea: hay que medirlo contra cada superficie,
  agregar la fila a `contrast-verification.md` y el `expect` al test. Es
  fricción deliberada sobre el diseño, y va a doler el día que haga falta un
  color a mitad de un sprint.

- **La escala tiene seis pasos, no diez.** Habrá casos —un tercer nivel de
  elevación, un estado intermedio de presión— donde el peldaño que se necesita
  no existe. La respuesta correcta será agregarlo con su medición, no improvisar
  una variante con transparencia dentro de una pantalla, que además viola E5.

- **Los tres colores semánticos son un riesgo permanente de deriva clínica.**
  Existen rojo, verde y azul en la paleta, y la tentación de pintar con ellos un
  gráfico de glucosa va a aparecer. La advertencia está escrita en el archivo,
  pero es una prohibición sostenida por disciplina, no por el compilador.
