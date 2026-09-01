# ADR-003 — EIRA no clasifica valores clínicos

**Fecha:** 1 de septiembre de 2026
**Estado:** Aceptada — **documentación retroactiva**
**Ámbito:** RF-22 · OE4 · PLAN_MAESTRO §13 (Alcance) · §14 (Fuera permanente) · §21 (`MetricRecord`) · §3-D y §A.5 (auditoría) · §26 · CLAUDE.md regla 5

> **Sobre el carácter retroactivo de este ADR.** La decisión está tomada en el
> plan maestro (RF-22, §13, §21) desde antes del primer commit. Este documento la
> formaliza: alternativas, límite exacto de lo permitido y consecuencias
> negativas, que en este caso recaen sobre el usuario.

---

## Contexto

El repositorio anterior clasificaba. En un widget privado, sin fuente documentada
y sin fecha de revisión, había umbrales de presión arterial que devolvían
etiquetas como *"etapa 1"* y *"etapa 2 — consulta tu médico"* (hallazgo D de la
auditoría, §A.5). Ese código tenía tres problemas superpuestos, y solo uno era
técnico:

1. **Era un acto clínico.** Aplicar un umbral al valor particular de una persona
   y devolverle una categoría es interpretar su estado de salud. Eso lo hace un
   profesional con el contexto completo del paciente, no una función `if` dentro
   de un `build`.
2. **No era trazable.** Los números no venían de ninguna parte citable. Nadie
   podía decir de qué guía salieron, de qué año, ni para qué población.
3. **Contradecía a la propia app.** La pantalla de privacidad afirmaba una cosa
   mientras el resto de la aplicación hacía otra (§A.7). Un patrón que se repite:
   lo que la app declara y lo que la app hace tienen que coincidir.

Al mismo tiempo, EIRA registra glucosa, presión y peso, y los grafica. Es
inevitable que el usuario mire un número y quiera saber si está bien. La
pregunta que este ADR responde no es *si* clasificamos, sino **dónde queda
exactamente la línea** entre registrar y diagnosticar, porque esa línea hay que
saber trazarla en cada pantalla del módulo de métricas.

El plan la enuncia en el §13 en una frase que es a la vez la regla y su única
excepción:

> Las métricas se registran y grafican **sin clasificación diagnóstica**. Si se
> muestra un rango de referencia, se muestra su fuente.

---

## Alternativas evaluadas

| Opción | A favor | En contra | Veredicto |
|---|---|---|---|
| **Clasificar con umbrales incrustados** (lo que hacía el repositorio anterior) | Es lo que el usuario pide, es inmediato y se implementa en una tarde | Acto diagnóstico sin habilitación, sin fuente y sin contexto clínico. Cae en "diagnóstico, alertas médicas, ajuste de tratamiento", que el §14 marca como **fuera permanente** —no "future"—, porque EIRA no es un dispositivo médico. Riesgo ético y legal real, no formal | **Rechazada** |
| **Clasificar, pero con fuente y fecha visibles** | Corrige el defecto de trazabilidad, que era el más señalado en la auditoría; parece resolver la objeción de fondo | **No la resuelve.** Aunque la guía sea impecable, la app estaría aplicando un criterio clínico al valor concreto de una persona concreta, y los umbrales dependen de edad, comorbilidad, tratamiento en curso, embarazo y condiciones de medición —una glucosa en ayunas y una postprandial no se leen con la misma regla—. La app no conoce nada de eso. Citar la fuente hace la clasificación *trazable*, no *correcta* | **Rechazada** |
| **Señalizar por color o ícono según el valor** (verde/amarillo/rojo, flechas, caritas) | Evita escribir la palabra "hipertensión"; se siente más suave; visualmente atractivo | Es la misma clasificación por otro canal: un punto rojo comunica "esto está mal" con más fuerza que un texto. Además choca de frente con la regla de accesibilidad del §24 —**el color nunca es el único portador de información**—, así que para ser accesible habría que acompañarlo de una etiqueta textual, y esa etiqueta es exactamente la clasificación que se quería evitar | **Rechazada** |
| **Registrar y graficar, sin ninguna interpretación del valor del usuario**, con rangos de referencia solo como contenido estático y citado | Es lo que la app puede sostener; hace estructuralmente imposible reincidir en el hallazgo D; deja la interpretación donde corresponde | El usuario se queda sin la respuesta que más quiere; el gráfico es más difícil de leer sin bandas de referencia | **Adoptada** |

---

## Decisión

> **EIRA registra y grafica. No clasifica, no interpreta y no alerta sobre
> ningún valor de salud del usuario.**

### El límite, con precisión

Lo que sigue es la regla operativa para el módulo de métricas y para cualquier
pantalla que muestre un número de salud:

| Permitido | Prohibido |
|---|---|
| Mostrar el valor con su unidad: `120 mg/dL` | Mostrar el valor con una etiqueta derivada de él: `120 mg/dL — normal` |
| Graficar la serie histórica tal cual | Pintar bandas de color por rango sobre el gráfico, o cambiar el color de un punto según su valor |
| Mostrar un rango de referencia **general**, como contenido de `assets/content/`, con `SourceMetadata` completo y fuente visible | Comparar el valor del usuario contra ese rango y comunicar el resultado, por texto, color, ícono o posición |
| Recordar registrar (notificación de hábito) | Notificar por un valor registrado |
| "No registraste presión esta semana" | "Tu presión está alta esta semana" |

La distinción operativa: **la app puede describir el dato y puede mostrar
información general; no puede emitir un juicio sobre el dato de esa persona.**

### El mecanismo es estructural, no reglamentario

Esta es la parte que hace que la decisión sobreviva a la prisa. `MetricRecord`
(§21) tiene `id`, `type`, `primaryValue`, `secondaryValue`, `context`,
`recordedAt` y `note`.

**No tiene `status`, ni `level`, ni `category`.** La ausencia es intencional: no
existe un campo donde escribir la clasificación, así que reintroducirla no es
agregar una línea, es modificar el modelo, la serialización, los tests de ida y
vuelta y la pantalla "Sobre tus datos". Deja de ser un descuido posible y pasa a
ser una decisión que alguien tiene que tomar a la vista de todos.

El campo `context` —`fasting`, `postMeal`, `other`, solo para glucosa— es
justamente lo contrario de una clasificación: **lo declara el usuario sobre las
circunstancias de su medición**, no lo deriva la app del valor.

### Dónde vive un rango de referencia, si algún día se muestra

En `assets/content/*.json`, nunca en un `.dart`, con `SourceMetadata` completo
(fuente admitida, URL, fecha de revisión, `status`, `sensitivity`) y con la
fuente visible en pantalla. Un ítem de sensibilidad `high` no entra sin
`validated` (§25). Esto es coherente con la regla general del proyecto: todo
texto que afirme algo sobre la salud vive en contenido curado y trazable.

---

## Consecuencias

### Positivas

- **El hallazgo D no puede repetirse por descuido.** No hay campo donde guardar
  una clasificación ni lugar en un `.dart` donde escribir un umbral sin que
  contradiga una regla explícita.
- **La app deja de contradecirse.** El §26 exige que "Sobre tus datos" declare
  que EIRA no diagnostica ni reemplaza atención médica. Con esta decisión esa
  frase es verdadera en todas las pantallas, no solo en la que la escribe.
- **El riesgo ético y legal queda fuera del proyecto**, no gestionado dentro de
  él. El §38 lo lista como riesgo y esta es la respuesta completa.
- **Simplifica el módulo de métricas.** Sin umbrales no hay que decidir qué guía
  seguir, ni actualizar los números cuando esa guía cambie, ni versionarlos.
- **Es coherente con la validación profesional.** El profesional de la semana 8
  revisa contenido curado con fuentes, no una lógica de clasificación escrita por
  un estudiante.

### Negativas — las que hay que asumir

- **El usuario se queda sin la respuesta que más quiere, y esto se va a notar en
  la validación.** Alguien registra 145/95, mira la pantalla y lo único que la
  app le devuelve es su propio número dibujado en un gráfico. La pregunta
  *"¿esto está mal?"* queda sin responder por diseño. Es muy probable que
  aparezca como hallazgo en las sesiones de usuario de las semanas 10-11, y la
  respuesta correcta ahí **no** será implementarlo: será registrarlo en
  `validation/findings.md` como una tensión conocida entre lo que el usuario pide
  y lo que la app puede sostener responsablemente.
- **Un gráfico sin referencia es más difícil de leer.** Una serie de puntos sin
  bandas obliga al usuario a saber por sí mismo qué significa la altura de cada
  punto. La carga de interpretación se traslada íntegra a él y a su equipo de
  salud. Es coherente con el propósito de la app —llevar el registro a un
  control médico—, pero es menos útil en el momento de mirarlo.
- **Prohíbe funcionalidades que serían naturales**, y esa ausencia hay que saber
  defenderla: sin alertas por valor fuera de rango, sin resúmenes del tipo "esta
  semana estuviste mejor", sin metas por valor. No están en el backlog, y su
  ausencia es intencional, no un olvido.
- **La frontera no siempre es nítida, y va a exigir criterio.** Una línea de
  tendencia ya es una forma de interpretación: decir "sube" es afirmar algo sobre
  la evolución del usuario. La decisión de dónde cae exactamente esa raya —qué
  puede mostrar el gráfico del sprint de métricas sin cruzarla— **no se resuelve
  en este ADR** y es la discusión que hay que dar en T-032 y siguientes. La guía
  provisional: describir lo que el dato es, nunca lo que el dato significa para
  esa persona.
- **No es verificable por herramientas.** El verificador estructural no puede
  detectar una clasificación clínica: la forma de `MetricRecord` atrapa el caso
  obvio —un campo `status`— pero nada impide que alguien escriba una frase
  interpretativa dentro de un widget o un `if` sobre `primaryValue` en un
  `Text()`. La protección es la regla 5 de `CLAUDE.md`, este documento y la
  revisión humana. Es más débil que E4, y hay que decirlo.
- **Puede leerse como una app que hace poco.** "Registra y grafica" es menos
  vistoso que "analiza tus valores". La respuesta es que la restricción es el
  resultado de un análisis, no su ausencia — pero, igual que en ADR-002, hay que
  darla explícitamente porque la interfaz no la comunica sola.

---

## Verificación

1. **Inspección del modelo** — `MetricRecord` sin `status`, `level` ni
   `category`. Entra en la revisión de T-032.
2. **Búsqueda en código** — cero umbrales numéricos comparados contra
   `primaryValue` o `secondaryValue` fuera de la validación de entrada (rango de
   plausibilidad del formulario, que no clasifica: impide registrar un imposible).
3. **Checklist de accesibilidad por pantalla** (§24) — comprueba que el color no
   sea el único portador de información, lo que de paso detecta cualquier
   señalización por rango.
4. **Revisión de contenido** — todo rango de referencia mostrado debe existir en
   `assets/content/` con `SourceMetadata` completo y estar registrado en
   `content/content-registry.md`.
5. **Hito H5** (§35) — "los tres tipos persisten; historial cronológico; gráfico
   con 0, 1 y N puntos; **ninguna pantalla clasifica valores**".

---

## Referencias

- PLAN_MAESTRO RF-22 — Ausencia de interpretación clínica
- PLAN_MAESTRO §13 — Condición explícita del alcance; rango de referencia con fuente
- PLAN_MAESTRO §14 — Diagnóstico y alertas médicas: fuera permanente
- PLAN_MAESTRO §21 — `MetricRecord`; ningún campo de clasificación
- PLAN_MAESTRO §3-D y §A.5 — Interpretación clínica hardcodeada (hallazgo)
- PLAN_MAESTRO §24 — El color nunca es el único portador de información
- PLAN_MAESTRO §25 — Ciclo de vida y sensibilidad del contenido de salud
- PLAN_MAESTRO §26 — "Sobre tus datos", punto 6: qué no es EIRA
- CLAUDE.md — regla 5
- ADR-008 — El color como decisión de interfaz, no de valor clínico
