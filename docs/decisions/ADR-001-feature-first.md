# ADR-001 — Arquitectura feature-first con Repository Pattern y Provider

**Fecha:** 1 de septiembre de 2026
**Estado:** Aceptada — **documentación retroactiva**
**Ámbito:** PLAN_MAESTRO §19 (Arquitectura) · §20 (Estructura y reglas E1-E7) · §3 y §4 (auditoría del repositorio anterior) · RNF-16 · T-001

> **Sobre el carácter retroactivo de este ADR.** La decisión que aquí se documenta
> se tomó en el §19 del plan maestro, antes del primer commit del repositorio.
> Este documento no la toma: la formaliza en el formato que exige el §30, con las
> alternativas y —sobre todo— las consecuencias negativas que el plan enuncia de
> forma dispersa o no enuncia. Lo mismo vale para ADR-002, ADR-003 y ADR-004.

---

## Contexto

EIRA se reescribe desde cero. La razón del reinicio está en el §3: el repositorio
anterior tenía problemas de autoría y una estructura que había dejado de sostener
el crecimiento del proyecto. Los hallazgos de estructura son tres y conviene
tenerlos a la vista, porque son los que esta decisión tiene que resolver:

1. **Una carpeta `shared/` convertida en cajón.** Nació para unas pocas utilidades
   y terminó conteniendo widgets, modelos, constantes y servicios sin relación
   entre sí. Nadie sabía qué dependía de qué, y borrar algo de ahí era imposible
   sin buscar en todo el proyecto.
2. **Un provider saltándose su propia capa de datos.** `exercise_provider`
   accedía directamente a `SharedPreferences` aunque existía un servicio para
   eso. La capa estaba escrita, pero nada obligaba a pasar por ella.
3. **Mapas sin tipar cruzando hasta los widgets.** `Map<String, dynamic>` viajaba
   desde el almacenamiento hasta la interfaz, y cualquier error de datos se
   manifestaba en tiempo de ejecución, dentro de un `build`.

El proyecto nuevo tiene **diez módulos funcionales** previstos (§20: onboarding,
dashboard, habits, metrics, recipes, exercise, education, recommendations,
profile, privacy), un solo desarrollador y el calendario del §33. La arquitectura
tiene que resolver los tres hallazgos sin consumir en ceremonia el tiempo que
necesita el contenido de salud, que es donde el proyecto se juega su valor.

---

## Alternativas evaluadas

| Opción | A favor | En contra | Veredicto |
|---|---|---|---|
| **Clean Architecture completa** (entidades, casos de uso, repositorios, presentadores) | Máxima separación de responsabilidades; la respuesta "correcta" en abstracto; testeable en cada capa | Cada funcionalidad simple exige 4-5 archivos. "Marcar un hábito como hecho" pasaría por un caso de uso, una entidad, un repositorio y un presentador para escribir un booleano. A esta escala es ceremonia sin beneficio, y el costo lo paga el contenido de salud | **Rechazada** |
| **MVC clásico** | Familiar; se explica en una frase | El "controller" no tiene lugar propio en Flutter: no es el widget, no es el estado. En la práctica termina difuminado y la lógica vuelve a caer dentro de los widgets — exactamente el defecto que se está corrigiendo | **Rechazada** |
| **Capas globales** (`models/`, `services/`, `widgets/`, `screens/` en la raíz) | Simplísima al empezar; cero decisiones el primer día | Con diez módulos, cada carpeta se convierte en un cajón de decenas de archivos sin relación. **Es literalmente lo que le pasó a `shared/`**: no es una hipótesis, es el hallazgo auditado. Además no ofrece ninguna frontera que impida el atajo del hallazgo 2 | **Rechazada** |
| **Feature-first + Repository Pattern + Provider** | Módulos autocontenidos: todo lo de recetas vive en `features/recipes/`. Las fronteras son carpetas, así que son verificables. Ataca los tres hallazgos con mecanismos distintos y concretos | Requiere disciplina sostenida para no recrear `shared/` bajo otro nombre; `core/` es exactamente ese riesgo | **Adoptada** |

### Sub-decisión: gestión de estado

El §19 resuelve esto en prosa. Se tabula aquí porque es una decisión propia, con
su propia renuncia:

| Opción | A favor | En contra | Veredicto |
|---|---|---|---|
| **Riverpod** | Inyección de dependencias limpia; mejor manejo de estado asíncrono; sin dependencia del `BuildContext` | Curva de aprendizaje real en un proyecto con un calendario cerrado y un solo desarrollador; su beneficio principal —composición de estado asíncrono— es marginal en una app sin red | **Rechazada** |
| **Bloc** | Flujo de eventos explícito y trazable; excelente para lógica compleja | Mucho código por interacción. La app tiene formularios, listas y un gráfico; no hay máquinas de estado que justifiquen el costo | **Rechazada** |
| **Provider** | Suficiente para este alcance; ya conocido por el autor; reduce el riesgo de calendario, que es el riesgo dominante del §38 | Sin inyección de dependencias: el cableado queda a mano. Manejo de estado asíncrono más pobre | **Adoptada** |

---

## Decisión

> **Arquitectura por features, con tres capas internas por feature
> (presentación / estado / datos), Repository Pattern en la capa de datos y
> Provider como gestión de estado.**

```
lib/
├── core/        theme · router · storage · content · models · services · utils · widgets
└── features/    onboarding · dashboard · habits · metrics · recipes · exercise ·
                 education · recommendations · profile · privacy
```

Cada feature tiene la misma forma interna: `data/` · `models/` · `providers/` ·
`pages/` · `widgets/`. La cadena de datos es de cuatro niveles y no admite
atajos:

```
UI → Provider → Repositorio → LocalStorage
```

### Cómo cada mecanismo ataca un hallazgo concreto

Esto es lo que separa esta decisión de una preferencia estética. Cada pieza
existe por un defecto auditado, no por elegancia:

| Hallazgo del §3 | Mecanismo | Regla que lo hace verificable |
|---|---|---|
| `shared/` como cajón | No existe `shared/`. Lo transversal vive en `core/`, y solo sube ahí lo que usan **3 o más** features | **E1** (prohibición del nombre), **E2** (umbral de 3), **E6** (un modelo de una sola feature vive en esa feature) |
| Provider saltándose su capa de datos | `LocalStorage` es la única clase que importa `shared_preferences`; los providers no tienen forma de alcanzarla sin pasar por un repositorio | **E4**, verificada por `tool/check_architecture.dart` (ADR-007) |
| Mapas sin tipar hasta los widgets | El repositorio devuelve modelos tipados. Ningún `Map<String, dynamic>` cruza la capa de datos hacia arriba | Regla del §22, revisión humana |

### Por qué el Repository Pattern sí se justifica aquí

Tres razones concretas, no la autoridad del patrón:

1. **Elimina el atajo como opción.** Con un repositorio de por medio, el acceso
   directo del `exercise_provider` anterior deja de ser una mala práctica y pasa
   a ser una importación que el verificador de E4 rechaza.
2. **Deja abierta la puerta al contenido remoto sin reescritura.**
   `ContentRepository` es una interfaz. Hoy la implementa
   `AssetContentRepository`; si algún día hubiera contenido remoto con caché
   local, se agrega una implementación y no cambia una línea de los providers.
   Esto es lo que hace que la parte reversible de ADR-002 sea efectivamente
   reversible.
3. **Hace testeable la lógica sin tocar el almacenamiento real**, que es la
   condición para cumplir la meta de cobertura del §27.

### Deliberadamente NO incluido

Capa de casos de uso · inyección de dependencias con `get_it` · gestores de
estado avanzados · generación de código. La ausencia es una decisión, no un
olvido: cada una de esas piezas resuelve un problema que este proyecto no tiene.

---

## Consecuencias

### Positivas

- **Las fronteras son carpetas, y las carpetas se pueden verificar.** Una regla
  arquitectónica que solo vive en la cabeza del desarrollador se incumple el día
  que hay prisa. E1, E3, E4, E5 y E7 las comprueba un script (ADR-007), y su
  resultado entra en la Definition of Done.
- **Un módulo se entiende sin leer el resto.** Todo lo de recetas —modelo,
  repositorio, provider, pantallas, widgets— está en `features/recipes/`. Para un
  proyecto que se evalúa leyéndolo, esto vale tanto como para mantenerlo.
- **El daño de un error queda acotado.** Un problema en `metrics/` no se propaga
  a `recipes/` porque no hay nada compartido entre ambos salvo lo que subió a
  `core/` por la regla de 3.
- **Permite trabajar el backlog en el orden del calendario.** Los sprints del §33
  están organizados por módulo; la arquitectura coincide con esa unidad de
  trabajo, así que un sprint toca sobre todo una carpeta.
- **Es defendible con una frase por decisión**, y cada frase apunta a un hallazgo
  auditado, no a una preferencia.

### Negativas — las que hay que asumir

- **E2 obliga a duplicar código a propósito, y va a doler en casos concretos.**
  Si `recipes/` y `exercise/` necesitan la misma tarjeta con imagen, título y
  etiqueta de condición, se escribe dos veces. Corregir un defecto de
  accesibilidad en esa tarjeta significará corregirlo dos veces, y existe el
  riesgo real de arreglar una y olvidar la otra. La regla se sostiene porque el
  fracaso anterior fue por el extremo opuesto, pero el costo es verdadero y se
  paga con revisión, no con excepciones.
- **`core/` es un `shared/` con otro nombre, y lo único que lo separa es una
  regla que ningún script comprueba.** El verificador confirma que E1 se cumple
  —no existe la carpeta `shared/`—, pero **no cuenta cuántas features usan un
  widget de `core/widgets/`**. E2 es un juicio humano. El día que alguien suba
  ahí un widget usado por dos features "porque seguro lo usará una tercera", la
  degradación empieza y nada la detecta. Es el riesgo principal de esta
  arquitectura y no está mitigado por herramientas.
- **Sin inyección de dependencias, el cableado vive a mano en `app.dart`.** Con
  diez features, ese archivo va a acumular un `MultiProvider` largo, con
  dependencias entre providers resueltas por orden de declaración. Es frágil de
  una manera silenciosa: un provider declarado antes que aquel del que depende
  falla en tiempo de ejecución, no de compilación. E3 (300 líneas) no aplica a
  `app.dart` porque no es una pantalla, así que ni siquiera hay un tope que
  obligue a partirlo.
- **Sin capa de casos de uso, la lógica de negocio tiende a filtrarse a los
  providers.** El sitio natural para "calcular la racha" es un servicio
  (`core/services/streak_service.dart`, según el §20), pero nada impide que
  mañana esa lógica aparezca dentro de `habits_provider`. La arquitectura no lo
  prohíbe estructuralmente; lo prohíben la disciplina y la exigencia de tests
  unitarios del §27, que son mucho más fáciles de escribir sobre una función pura
  que sobre un `ChangeNotifier`.
- **RF-35 cruza la frontera entre dos features y esta arquitectura no dice quién
  manda.** "Registrar una rutina realizada reutilizando la infraestructura de
  hábitos" significa que `exercise/` necesita escribir un `HabitCompletion`, que
  pertenece a `habits/`. Feature-first es fuerte separando y débil coordinando:
  que `exercise/` importe el repositorio de `habits/` crea un acoplamiento entre
  features que ninguna regla actual prohíbe, y subir el modelo a `core/models/`
  chocaría con E6 mientras lo use una sola feature. **Es un hueco conocido**, no
  se resuelve aquí, y hay que decidirlo antes del sprint 8 (T-051..T-059).
- **Provider deja el estado asíncrono en manos del desarrollador.** No hay
  equivalente a `AsyncValue`: cada provider expone `loading / ready / error` a
  mano, y esa tríada se escribe una vez por feature. Es repetición aceptada a
  cambio de no aprender una herramienta nueva a mitad de calendario.
- **La estructura completa existe antes que el código que la llena.** Hoy
  `lib/features/` son cincuenta carpetas con `.gitkeep`. Un revisor puede leerlo
  como andamiaje vacío. La respuesta honesta es que el orden de los sprints la
  llena, y que crearla al final habría sido reconstruirla, no diseñarla.

---

## Verificación

1. `dart run tool/check_architecture.dart` — comprueba E1, E3, E4, E5 y E7
   (ADR-007). **E2 y E6 no son verificables por script** y quedan en revisión
   humana; está declarado como tal en ADR-007.
2. `flutter analyze` sin errores ni warnings (§27).
3. Inspección de la estructura de `lib/` contra el árbol del §20.

---

## Referencias

- PLAN_MAESTRO §19 — Arquitectura; alternativas evaluadas; Provider frente a Riverpod y Bloc
- PLAN_MAESTRO §20 — Estructura del proyecto; reglas E1-E7
- PLAN_MAESTRO §3 y §4 — Auditoría del repositorio anterior y lecciones aprendidas
- PLAN_MAESTRO §22 — Cadena de datos de cuatro niveles
- ADR-007 — Verificación de reglas estructurales sin dependencias de lint
- ADR-009 — Forma de la API de `LocalStorage`
