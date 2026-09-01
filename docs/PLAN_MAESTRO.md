# PLAN MAESTRO DE DESARROLLO — EIRA

**Aplicación móvil de apoyo al autocuidado para personas con enfermedades crónicas**

> *"Equilibrio en cada elección"*

| | |
|---|---|
| **Proyecto** | EIRA — Portafolio de Título (APT) |
| **Carrera** | Informática Biomédica — Instituto Profesional DuocUC |
| **Modalidad** | Individual |
| **Ventana de desarrollo** | 31 de agosto – 30 de noviembre de 2026 (13 semanas) |
| **Estado del documento** | Plan aprobado — base fija para la etapa de implementación |
| **Versión** | 1.0 |

---

## Cómo usar este documento

Este plan es la **fuente de verdad** del proyecto. Su propósito es evitar que las decisiones se rediscutan durante el desarrollo.

- Las decisiones marcadas como **no negociables** no se revisan sin registrar un ADR que las revierta.
- Toda idea nueva que aparezca durante el desarrollo va al backlog, nunca al sprint en curso (§43).
- Si el tiempo aprieta, se aplican las **palancas de recorte** en el orden definido (§39). No se improvisa.

---

## Índice

**Parte I — Fundamentos**
1. Resumen ejecutivo
2. Contexto académico
3. Auditoría del repositorio anterior
4. Lecciones aprendidas
5. Decisiones a conservar
6. Decisiones a cambiar
7. Deuda técnica detectada
8. Problema
9. Usuarios
10. Propuesta de valor
11. Objetivo general
12. Objetivos específicos
13. Alcance
14. Fuera de alcance
15. Restricciones

**Parte II — Requisitos**
16. Requisitos funcionales
17. Requisitos no funcionales
18. MVP definitivo

**Parte III — Diseño técnico**
19. Arquitectura
20. Estructura del proyecto
21. Modelo de datos
22. Persistencia
23. Navegación
24. UX y accesibilidad

**Parte IV — Calidad y disciplina**
25. Estrategia de contenido médico
26. Privacidad
27. Testing
28. Definition of Done
29. Estrategia de commits
30. Trazabilidad académica
31. Evidencias

**Parte V — Planificación**
32. Roadmap
33. Sprints
34. Carta Gantt
35. Hitos
36. Dependencias
37. Camino crítico

**Parte VI — Riesgos y arranque**
38. Matriz de riesgos
39. Plan de contingencia
40. Métricas de avance
41. Backlog inicial
42. Checklist previo al desarrollo
43. Control del alcance

**Anexo A** — Evidencia detallada de la auditoría

---

# PARTE I — FUNDAMENTOS

## 1. Resumen ejecutivo

EIRA es una aplicación móvil Android de apoyo al autocuidado para personas con diabetes mellitus tipo 2 (DM2), hipertensión arterial (HTA) o ambas condiciones simultáneamente. Se desarrolla en Flutter/Dart con persistencia exclusivamente local, sin backend.

El proyecto se reinicia desde cero por una condición académica: el 81% de los commits del repositorio anterior (13 de 16) fueron realizados por una tercera persona. El código anterior se conserva como **proyecto de referencia**, no como base.

**Alcance comprometido:** onboarding y perfil, configuración de condición, dashboard diario, hábitos con rachas, registro de métricas con historial persistido, módulo completo de recetas, módulo completo de ejercicio, recomendaciones diferenciadas, contenido educativo trazable, manejo explícito de doble condición, notificaciones locales, respaldo exportable, accesibilidad orientada a adultos mayores y transparencia de datos.

**Decisiones estructurales del reinicio:**

1. EIRA **registra y grafica**, no clasifica ni interpreta valores clínicos.
2. Todo contenido de salud lleva fuente, fecha y estado de validación desde su creación.
3. La doble condición es contenido propio, no la unión de dos listas.
4. La accesibilidad se implementa como criterio de aceptación, no como intención.
5. La pantalla de privacidad describe lo que la app hace realmente.
6. Los datos no salen del dispositivo; el respaldo lo controla el usuario.

**Presupuesto:** 345 horas comprometidas sobre 349 horas de capacidad. El plan cabe, pero sin margen natural; la contingencia se construye mediante palancas de recorte pre-designadas (§39).

---

## 2. Contexto académico

| Elemento | Definición |
|---|---|
| Asignatura | Portafolio de Título (APT), Informática Biomédica, DuocUC |
| Modalidad | Proyecto individual |
| Condición crítica | **Todos los commits deben ser del autor del proyecto** |
| Evidencia del problema | Repositorio anterior: 13 de 16 commits de un tercero |
| Decisión | Reinicio del código desde cero, conservando el trabajo intelectual |
| Fecha límite | 30 de noviembre de 2026 |

**Filosofía de reutilización:** aprender del proyecto anterior sin heredar sus decisiones técnicas ni su deuda. En términos operativos: se reutilizan *decisiones y conocimiento*; **no se copia y pega código**. Cada línea del nuevo repositorio se escribe con entendimiento de por qué está ahí.

**Riesgo académico secundario:** el historial anterior no solo tiene autoría ajena, tiene un patrón de commits por lotes (`"Sprint MVP-2 al MVP-4"` repetido tres veces). El nuevo historial debe demostrar **evolución continua**, no solo autoría correcta.

---

## 3. Auditoría del repositorio anterior

Repositorio auditado: `Frangarcia0/autocuidado_app` (rama `master`). Evidencia detallada en el **Anexo A**.

### Datos duros

| Métrica | Valor |
|---|---|
| Commits totales | 16 (11 may – 30 may 2026) |
| Commits del autor del proyecto | **3** |
| Commits de terceros | **13 (81%)** |
| Archivos Dart | 41 |
| Líneas Dart | ~8.127 |
| Tests reales | **0** (1 placeholder vacío) |
| Código muerto | 483 líneas |
| Literales de color hardcodeados | 259 (56 valores distintos) |
| Usos de `fontSize` ≤ 12 | 45 (mínimo: 9 px) |
| Anotaciones de accesibilidad | **0** |

### Hallazgos críticos

**A. Las métricas de salud eran una fachada.** Los formularios de glucosa, presión y agua vivían dentro de `home_page.dart` y no persistían nada. El historial era una lista hardcodeada con valores `'--'`. La función de guardado hacía `setState`, mostraba *"registrado correctamente"* y descartaba el dato.

**B. La pantalla de privacidad contradecía la app.** Afirmaba no solicitar datos clínicos como glucosa o presión, mientras el Home los registraba. Omitía estatura, peso, género y fecha de nacimiento, que sí se almacenaban, y no mencionaba el botón de compartir informe.

**C. "Doble condición" era una concatenación.** Los providers resolvían `both` sumando la lista de diabetes con la de hipertensión: sin resolución de conflictos, sin deduplicación, sin contenido específico para la interacción DM2+HTA.

**D. Interpretación clínica hardcodeada.** Umbrales de clasificación de hipertensión ("etapa 1", "etapa 2") incrustados en un widget privado, sin fuente documentada.

**E. Contenido médico sin trazabilidad.** Los seis JSON de educación y recomendaciones no tenían ningún campo de fuente, fecha de revisión ni estado de validación.

**F. El módulo de ejercicio no funcionaba sin internet.** Las imágenes de rutinas se cargaban con `Image.network` desde URLs remotas. Las recetas tenían dos campos compitiendo (`image` local e `imageUrl` remoto), usados de forma inconsistente según la pantalla.

**G. Respaldo automático no declarado.** El `AndroidManifest.xml` no declaraba `allowBackup`, por lo que Android respaldaba las SharedPreferences a Google Drive por defecto, contradiciendo la declaración de privacidad.

### Informe de auditoría

| Área | Situación anterior | Problema / aprendizaje | Decisión para EIRA nueva |
|---|---|---|---|
| **Arquitectura** | Modular por features + `core` + `shared`; Provider; go_router | Estructura correcta, pero `shared/` se volvió un cajón de sastre | **Mantener** features + core; **eliminar** `shared/` |
| **Estado** | 6 providers globales en cascada | Orden de carga acoplado; recarga manual al cambiar condición | Condición como fuente única; el contenido se deriva de ella |
| **Persistencia** | `PreferencesService` + acceso directo en `exercise_provider` | Dos caminos, claves duplicadas, sin versionado | Repositorio único con claves versionadas |
| **Métricas** | UI completa sin persistencia | Funcionalidad aparente ≠ funcionalidad real | Rediseño completo con `MetricRecord` persistido |
| **Navegación** | go_router + ShellRoute, 5 pestañas | Sólido. Ruta `/recommendations` huérfana | **Mantener**; sin rutas huérfanas |
| **UI/UX** | 259 colores hardcodeados, 0 anotaciones semánticas | Sin sistema de diseño, accesibilidad ausente | Design tokens obligatorios + accesibilidad como criterio |
| **Contenido médico** | 6 JSON sin metadatos; `both` = A+B | Indefendible académicamente | Esquema con fuente, fecha, estado, sensibilidad |
| **Dependencias** | 8 runtime; 2 de uso marginal | `share_plus` habilitaba salida de datos no declarada | Eliminar las marginales; nuevas requieren ADR |
| **Testing** | 1 test placeholder vacío | Cero cobertura | Tests en el mismo sprint que la funcionalidad |
| **Documentación** | README por defecto de Flutter | Cero trazabilidad | `docs/` desde el día 1 |
| **Commits** | 16 commits, 81% de terceros, agrupados | Origen del reinicio | Conventional commits, uno por unidad verificable |

**No determinable con el repositorio:** si la app compila actualmente, su rendimiento real en dispositivo, y el origen de los umbrales clínicos utilizados (no hay ninguna referencia en el código).

---

## 4. Lecciones aprendidas

| # | Lección | Origen concreto |
|---|---|---|
| **L1** | **UI existente ≠ funcionalidad existente.** Una pantalla que muestra confirmación puede no guardar nada | Formularios de métricas |
| **L2** | **La política de privacidad se escribe desde el modelo de datos**, no desde la intención | `privacy_page` vs `home_page` |
| **L3** | **"Ambas condiciones" es una condición**, no la suma de dos | `loadForCondition('both')` |
| **L4** | **Contenido de salud sin fuente es contenido no defendible** | 6 JSON sin campo `source` |
| **L5** | **Las pantallas crecen sin límite si no hay regla** | `home_page.dart`: 1.793 líneas |
| **L6** | **Una capa de datos que se puede saltar, se salta** | `exercise_provider` vs `PreferencesService` |
| **L7** | **Los `catch` vacíos convierten bugs en pantallas vacías** | 3 providers de contenido |
| **L8** | **La accesibilidad no ocurre por buena intención** | 0 `Semantics`, fuentes de 9 px |
| **L9** | **El código muerto se acumula silenciosamente** | 483 líneas nunca importadas |
| **L10** | **Los tests que no se escriben en el sprint no se escriben nunca** | `widget_test.dart` vacío con TODO |
| **L11** | **Postergar el commit produce commits indefendibles** | 3 commits idénticos |
| **L12** | **Lo que depende de la red falla sin red** | `Image.network` en rutinas |
| **L13** | **Los defaults de la plataforma también son decisiones** | `allowBackup` no declarado |

---

## 5. Decisiones a conservar

| Decisión | Justificación |
|---|---|
| **Flutter + Dart, Android primero** | Curva de aprendizaje ya recorrida; reiniciar el stack duplicaría el riesgo |
| **Organización por features** | Funcionó; el problema fue `shared/`, no `features/` |
| **go_router + ShellRoute** | Navegación por pestañas resuelta y estable |
| **Provider como gestión de estado** | Suficiente para el alcance; conocido; sin dependencias exóticas |
| **SharedPreferences para el MVP** | Sin backend, volumen bajo, decisión defendible por simplicidad |
| **Contenido en JSON de assets** | Separa contenido de lógica; permite revisión sin tocar Dart |
| **Onboarding que define la condición antes del dashboard** | Habilita toda la personalización |
| **Pantalla "Sobre tus datos"** | El concepto era correcto; el contenido era falso |
| **Disclaimer de no-diagnóstico en onboarding** | Necesario ética y académicamente |
| **Lenguaje simple y localizado al contexto chileno** | Es el diferenciador real del proyecto |

---

## 6. Decisiones a cambiar

| Área | Antes | Ahora |
|---|---|---|
| **Métricas** | UI sin persistencia | `MetricRecord` persistido, historial real, gráfico de tendencia |
| **Interpretación de valores** | Clasificación clínica en widgets | **EIRA no clasifica.** Registra y grafica. Rango de referencia solo con fuente visible |
| **Doble condición** | `listaA + listaB` | Contenido propio etiquetado `both`, con conflictos resueltos |
| **Contenido de salud** | JSON sin metadatos | Esquema obligatorio: `source`, `sourceUrl`, `reviewDate`, `status`, `sensitivity` |
| **Privacidad** | Texto que contradice la app | Texto derivado del modelo de datos real |
| **Persistencia** | Dos caminos | Repositorio único, claves versionadas |
| **Errores** | `catch` vacío | Estado de error explícito y mensaje al usuario |
| **`shared/`** | Cajón de sastre | `core/` para infraestructura; modelos dentro de su feature |
| **Estilos** | 259 literales de color | Design tokens obligatorios |
| **Accesibilidad** | Ausente | Criterios de aceptación verificables |
| **Imágenes** | `Image.network` remoto | **Assets locales siempre**, campo único, WebP ≤ 80 KB |
| **Respaldo del sistema** | Default no declarado | `allowBackup="false"` + ADR |
| **Testing** | 1 placeholder | Tests en el mismo sprint |
| **Commits** | Por lotes, sin convención | Conventional commits, una unidad por commit |

---

## 7. Deuda técnica detectada

| Tipo | Magnitud anterior | Regla en el proyecto nuevo |
|---|---|---|
| Código muerto | 483 líneas (3 archivos, 0 imports) | Cero archivos sin referencias |
| Archivos sobredimensionados | 5 archivos = 58% del código | Máximo 300 líneas por pantalla |
| Colores hardcodeados | 259 literales, 56 valores | Prohibido fuera de `core/theme/` |
| Tipografía sin escala | 16 tamaños, mínimo 9 px | 6 tamaños, mínimo 14 sp |
| Anotaciones de accesibilidad | 0 | Obligatorias en controles no textuales |
| Cobertura de tests | 0% | ≥ 70% en lógica de negocio |
| Errores silenciados | 3 providers | Prohibido el `catch` vacío |
| Lints suprimidos sin causa | 4 `// ignore:` innecesarios | Solo con comentario justificativo |
| Dependencias marginales | `percent_indicator`, `share_plus` | Eliminadas; nuevas requieren ADR |
| Assets sobredimensionados | Íconos de 576 KB | Íconos ≤ 20 KB, fotos ≤ 80 KB, WebP |
| Archivos basura commiteados | `eira_isotype.png.bak.jpg` | `.gitignore` y revisión antes de commitear |

---

## 8. Problema

Las personas con DM2 e HTA en Chile enfrentan un vacío de acompañamiento **entre controles médicos**. El control clínico ocurre cada varios meses; el autocuidado ocurre todos los días.

Problemas específicos que EIRA aborda:

1. **Discontinuidad del acompañamiento** entre consultas.
2. **Contenido no localizado**: alimentos, porciones y referencias culturales ajenas al contexto chileno.
3. **Dificultad para sostener hábitos** sin registro ni retroalimentación visible.
4. **Ausencia de herramientas para doble condición**: quien tiene ambas debe conciliar dos fuentes que pueden contradecirse.
5. **Barreras de acceso digital** para adultos mayores: letra pequeña, densidad alta, jerga técnica.
6. **Desconfianza sobre el uso de datos de salud.**

**Lo que EIRA no resuelve:** no reemplaza el control médico, no ajusta tratamientos, no interpreta resultados clínicos.

---

## 9. Usuarios

**Usuario primario — Persona con condición crónica en control.**
Adulto entre 45 y 75 años, diagnosticado con DM2, HTA o ambas, en control en atención primaria. Alfabetización digital básica. Motivación variable, típicamente alta después de un control y decreciente con las semanas.

*Necesidades:* saber qué hacer hoy; ver que lo que hace sirve; entender su condición sin jerga; registrar valores sin miedo a que se compartan.

**Segmento crítico — Persona con doble condición (DM2 + HTA).**
Es el caso más frecuente en la práctica y el peor atendido por las herramientas existentes. **Define el diferenciador del proyecto y no se trata como caso derivado.**

**Segmento con restricciones de accesibilidad — Adulto mayor.**
Menor agudeza visual, menor precisión motora fina, menor tolerancia a interfaces densas. **Determina las reglas de UX del proyecto** (§24).

**No usuarios:** profesionales de salud, personas con diabetes tipo 1, menores de edad, personas en descompensación aguda.

---

## 10. Propuesta de valor

> **EIRA acompaña el autocuidado diario entre controles médicos, con contenido en lenguaje simple, adaptado al contexto chileno, que trata la doble condición como un caso propio y guarda todo en el teléfono del usuario.**

Diferenciadores, en orden de defensibilidad:

1. **Doble condición como caso de primera clase**, con contenido específico.
2. **Trazabilidad del contenido de salud** a MINSAL, ADA y AHA, con fuente visible.
3. **Datos exclusivamente locales**, sin cuenta ni servidor — verificable.
4. **Accesibilidad como requisito verificable**, no como intención.
5. **Localización chilena** en alimentos, porciones, momentos de comida y lenguaje.
6. **Valor de uso diario**: receta y rutina del día, funcionando sin conexión.

---

## 11. Objetivo general

> Desarrollar y validar una aplicación móvil Android de apoyo al autocuidado —EIRA— que permita a personas adultas con diabetes mellitus tipo 2, hipertensión arterial o ambas condiciones registrar hábitos y métricas de salud con persistencia local, y acceder a recomendaciones, contenido educativo, recetas y rutinas de ejercicio diferenciados por condición y trazables a fuentes oficiales, entregando antes del 30 de noviembre de 2026 una versión funcional documentada, probada y validada con al menos 3 usuarios del público objetivo.

Medible en cinco dimensiones: *funcional*, *temporal*, *de trazabilidad*, *de calidad* y *de validación*.

---

## 12. Objetivos específicos

| ID | Objetivo | Verificación |
|---|---|---|
| **OE1** | Diseñar e implementar una arquitectura modular por features con separación efectiva entre UI, lógica y datos | Ningún archivo de pantalla supera 300 líneas; un único camino de acceso a datos |
| **OE2** | Implementar onboarding y configuración de condición que habilite la personalización para DM2, HTA y doble condición | El contenido corresponde a la condición y se actualiza al cambiarla |
| **OE3** | Implementar registro de hábitos con rachas y persistencia local verificada | Los datos sobreviven al reinicio; racha correcta en casos límite |
| **OE4** | Implementar registro de métricas con historial persistido y visualización de tendencia, sin interpretación clínica | Los registros persisten y se grafican; ninguna pantalla clasifica valores |
| **OE5** | Construir un repositorio de contenido de salud con trazabilidad obligatoria, incluyendo contenido específico de doble condición | 100% de ítems con fuente, fecha y estado; existe contenido propio DM2+HTA |
| **OE6** | Implementar módulos de recetas y ejercicio que entreguen valor de uso diario y funcionen sin conexión | Receta y rutina del día disponibles en modo avión |
| **OE7** | Aplicar criterios de accesibilidad orientados a adultos mayores como requisitos verificables | Contraste AA, tamaño y área táctil mínimos cumplidos en todas las pantallas |
| **OE8** | Garantizar el tratamiento local de los datos conforme a la normativa chilena, con transparencia y capacidad de eliminación | "Sobre tus datos" consistente con el modelo real; borrado verificado |
| **OE9** | Validar la aplicación con al menos 3 personas del público objetivo e incorporar las mejoras priorizadas | Protocolo aplicado, hallazgos documentados, mejoras implementadas o justificadas |
| **OE10** | Mantener trazabilidad académica completa entre requisito, tarea, implementación, prueba, commit y evidencia | Cada requisito MUST rastreable hasta sus commits y evidencia |

---

## 13. Alcance

**Incluido en el MVP:**

- Onboarding: bienvenida, datos básicos, selección de condición, disclaimer de no-diagnóstico
- Configuración de condición (DM2 / HTA / ambas), modificable
- Perfil básico local y edición
- Dashboard "Hoy" con receta y rutina del día
- Hábitos diarios diferenciados por condición
- Sistema de rachas (actual y mejor)
- Registro de métricas con historial persistido: glucosa, presión arterial, peso
- Visualización de tendencia del historial
- Recomendaciones diferenciadas por condición
- **Contenido y recomendaciones específicos para doble condición**
- Contenido educativo con fuente visible
- **Módulo de recetas** organizado por momento de comida (desayuno, almuerzo, once)
- **Módulo de ejercicio** con biblioteca de ejercicios y rutinas compuestas
- Notificación diaria configurable
- Respaldo exportable e importable por el usuario
- Pantalla "Sobre tus datos" consistente con la implementación
- Eliminación total de datos locales
- Accesibilidad base como criterio de aceptación
- Persistencia local exclusiva, funcionamiento offline completo

**Condición explícita:** las métricas se registran y grafican **sin clasificación diagnóstica**. Si se muestra un rango de referencia, se muestra su fuente.

---

## 14. Fuera de alcance

| Elemento | Categoría | Razón |
|---|---|---|
| Resistencia a la insulina como condición | Future | Entidad clínica distinta; duplicaría contenido y matriz de doble condición |
| Cuarto momento de comida (cena) | Future | La once cubre la comida vespertina en el contexto chileno |
| Compartir informe / exportación a terceros | Future | Habilita salida de datos de salud sin análisis de privacidad suficiente |
| Firebase, autenticación, Firestore | Future | Convertiría al autor en responsable de tratamiento de datos sensibles |
| Sincronización en la nube | Future | Ídem; reemplazado por respaldo local exportable |
| Exportación a PDF | Future | No necesaria para el objetivo |
| Integración clínica / hospitalaria | Fuera permanente | Excede el propósito y el marco regulatorio |
| Diagnóstico, alertas médicas, ajuste de tratamiento | **Fuera permanente** | EIRA no es un dispositivo médico |
| iOS | Future | Requiere macOS con Xcode; bloqueador de hardware, no de esfuerzo. El código se mantiene multiplataforma |
| Modo oscuro | Future | No aporta al objetivo y multiplica la verificación de contraste |
| Multiidioma | Future | El contexto chileno es el diferenciador |

---

## 15. Restricciones

**Temporales**

- Ventana total: 31/08/2026 – 30/11/2026 (13 semanas)
- Feriados que afectan el calendario: 18-19 de septiembre (S3) y 12 de octubre (S7)
- Dedicación de estudiante con otras asignaturas: la planificación no asume jornada completa
- Debe existir contingencia real, no nominal

**Académicas**

- **Todos los commits deben ser propios** — no negociable y verificable
- El historial debe evidenciar evolución continua
- Toda decisión técnica debe ser justificable en la defensa
- La trazabilidad requisito → evidencia debe poder demostrarse

**Técnicas**

- Flutter/Dart, Android como plataforma objetivo (API 26+)
- Sin backend propio
- SharedPreferences como mecanismo de persistencia
- Dispositivo Android físico para pruebas
- Equipo de desarrollo de gama media: favorece pruebas en dispositivo físico sobre emuladores pesados

**Legales y éticas**

- Ley 19.628 vigente hasta el 30/11/2026; Ley 21.719 entra en vigencia el 01/12/2026
- **El diseño se rige por el estándar de la Ley 21.719** (protección desde el diseño y por defecto)
- Los datos de salud son datos sensibles
- Los datos no salen del dispositivo
- El contenido de salud debe ser trazable a fuentes oficiales
- La app no diagnostica ni reemplaza atención médica, y lo declara visiblemente
- Si una recomendación no puede sustentarse en una fuente verificable, no entra al MVP

**De contenido**

- Fuentes admitidas: MINSAL, ADA, AHA y guías equivalentes
- La validación profesional es parte del roadmap, no un supuesto
- El contenido de doble condición requiere revisión reforzada
- Toda imagen requiere registro de licencia antes de entrar al repositorio

---

# PARTE II — REQUISITOS

## 16. Requisitos funcionales

### Onboarding, perfil y condición

| ID | Descripción | Prior. | Dep. | Criterio de aceptación |
|---|---|---|---|---|
| RF-01 | Pantalla de bienvenida con propósito de la app | MUST | — | Se muestra en el primer inicio y solo en el primero |
| RF-02 | Ingreso de datos básicos (nombre, año de nacimiento) | MUST | RF-01 | No permite continuar con campos obligatorios vacíos; error comprensible |
| RF-03 | Selección de condición: DM2 / HTA / ambas | MUST | RF-02 | Las tres opciones seleccionables; "ambas" es opción propia |
| RF-04 | Disclaimer de no-diagnóstico con aceptación explícita | MUST | RF-03 | Requiere acción del usuario; no se puede omitir; aceptación registrada |
| RF-05 | Persistencia local del perfil | MUST | RF-04 | Al reiniciar, el onboarding no vuelve a mostrarse y el perfil se recupera íntegro |
| RF-06 | Edición de perfil y cambio de condición | MUST | RF-05 | Al cambiar la condición, todos los módulos reflejan la nueva sin reiniciar la app |

### Dashboard

| ID | Descripción | Prior. | Dep. | Criterio de aceptación |
|---|---|---|---|---|
| RF-07 | Dashboard "Hoy": saludo, progreso de hábitos, racha actual | MUST | RF-05, RF-13 | Los valores coinciden con el estado persistido |
| RF-08 | Sugerencia del día: receta y rutina destacadas | MUST | RF-28, RF-33 | Cambia diariamente, es determinista, respeta la condición y se mantiene igual todo el día |
| RF-09 | Accesos rápidos a los módulos principales | SHOULD | RF-07 | Cada acceso navega a la sección correcta |

### Hábitos y rachas

| ID | Descripción | Prior. | Dep. | Criterio de aceptación |
|---|---|---|---|---|
| RF-10 | Listado de hábitos diarios según condición | MUST | RF-03 | DM2, HTA y ambas reciben conjuntos distintos; sin duplicados en "ambas" |
| RF-11 | Marcar y desmarcar hábito completado | MUST | RF-10 | Cambio inmediato y persistido |
| RF-12 | Reinicio automático al cambiar el día | MUST | RF-11 | Al primer inicio de un nuevo día los hábitos aparecen sin marcar |
| RF-13 | Racha actual y mejor racha | MUST | RF-12 | Se incrementa una vez al día; se rompe tras un día sin actividad; la mejor nunca decrece |
| RF-14 | Persistencia de hábitos y rachas | MUST | RF-13 | Los datos sobreviven al cierre forzado y al reinicio del dispositivo |

### Métricas de salud

| ID | Descripción | Prior. | Dep. | Criterio de aceptación |
|---|---|---|---|---|
| RF-15 | Registro de glucosa (valor + contexto) | MUST | RF-05 | Persistido con fecha, hora y contexto; se recupera tras reiniciar |
| RF-16 | Registro de presión arterial (sistólica/diastólica) | MUST | RF-05 | Valida rango plausible; persiste ambos valores |
| RF-17 | Registro de peso | MUST | RF-05 | Registro histórico; no sobrescribe el perfil |
| RF-18 | Historial cronológico por tipo de métrica | MUST | RF-15..17 | Muestra registros reales ordenados; estado vacío explicado |
| RF-19 | Visualización de tendencia | MUST | RF-18 | Correcta con 0, 1 y N registros |
| RF-20 | Eliminación de un registro individual | MUST | RF-18 | Requiere confirmación; desaparece del historial y de la tendencia |
| RF-21 | Métricas priorizadas según condición | SHOULD | RF-03 | Glucosa prioritaria en DM2, presión en HTA; ninguna se oculta por completo |
| RF-22 | **Ausencia de interpretación clínica** | MUST | RF-18 | Ninguna pantalla emite clasificación diagnóstica. Todo rango de referencia lleva fuente y fecha |

### Contenido de salud

| ID | Descripción | Prior. | Dep. | Criterio de aceptación |
|---|---|---|---|---|
| RF-23 | Recomendaciones diferenciadas por condición | MUST | RF-03 | El listado corresponde a la condición activa |
| RF-24 | **Contenido específico para doble condición** | MUST | RF-23 | Contenido propio DM2+HTA; no concatenación; sin duplicados; conflictos resueltos |
| RF-25 | Contenido educativo con fuente visible | MUST | RF-03 | Cada artículo muestra fuente y fecha de revisión |
| RF-26 | Detalle de contenido educativo | MUST | RF-25 | Texto legible, retorno explícito, fuente presente |
| RF-27 | Filtro por categoría | SHOULD | RF-23 | Altera el listado y es reversible |

### Recetas

| ID | Descripción | Prior. | Dep. | Criterio de aceptación |
|---|---|---|---|---|
| RF-28 | Catálogo por momento de comida (desayuno, almuerzo, once) | MUST | RF-03 | Las tres categorías con contenido; respeta la condición |
| RF-29 | Etiquetado por condición, incluida doble condición | MUST | RF-28 | Cada receta declara condiciones; existen recetas aptas DM2+HTA |
| RF-30 | Detalle: imagen, ingredientes, preparación, nota nutricional, fuente | MUST | RF-28 | Todos los campos presentes; imagen local; fuente visible |
| RF-31 | Búsqueda de recetas | SHOULD | RF-28 | Por título e ingrediente; estado vacío explicado |
| RF-32 | Favoritos de recetas | SHOULD | RF-30 | Persiste tras reiniciar |

### Ejercicio

| ID | Descripción | Prior. | Dep. | Criterio de aceptación |
|---|---|---|---|---|
| RF-33 | Catálogo de rutinas por condición y nivel | MUST | RF-03 | Rutinas para DM2, HTA y ambas, en al menos dos niveles |
| RF-34 | Detalle de ejercicio: imagen, pasos, errores frecuentes y **contraindicaciones visibles** | MUST | RF-33 | Las advertencias aplicables se muestran **antes** de los pasos |
| RF-35 | Registro de rutina realizada reutilizando la infraestructura de hábitos | MUST | RF-11, RF-33 | Contribuye al progreso del día sin crear un sistema de rachas paralelo |
| RF-36 | Favoritos de rutinas | COULD | RF-34 | Persiste tras reiniciar |

### Notificaciones y respaldo

| ID | Descripción | Prior. | Dep. | Criterio de aceptación |
|---|---|---|---|---|
| RF-37 | Recordatorio diario configurable | MUST | RF-05 | Un solo recordatorio; hora elegida por el usuario; **sin alarma exacta** |
| RF-38 | Activar y desactivar el recordatorio | MUST | RF-37 | El cambio persiste y surte efecto |
| RF-39 | Exportar respaldo de datos del usuario | MUST | RF-05 | Genera archivo JSON con versión de esquema; el usuario elige destino |
| RF-40 | Importar respaldo | MUST | RF-39 | Valida versión; exige confirmación explícita porque reemplaza los datos |

### Privacidad y datos

| ID | Descripción | Prior. | Dep. | Criterio de aceptación |
|---|---|---|---|---|
| RF-41 | Pantalla "Sobre tus datos" | MUST | RF-05 | Enumera **exactamente** los datos almacenados, verificado contra `storage_keys.dart` |
| RF-42 | Eliminación total de datos locales | MUST | RF-41 | Requiere confirmación; vuelve al onboarding sin residuos en memoria ni disco |
| RF-43 | Ausencia de transmisión de datos | MUST | — | Sin peticiones de red con datos del usuario; verificable por inspección y prueba en modo avión |

---

## 17. Requisitos no funcionales

| ID | Categoría | Requisito | Criterio verificable |
|---|---|---|---|
| RNF-01 | Accesibilidad | Tamaño mínimo de texto | Ningún texto bajo 14 sp; cuerpo ≥ 18 sp |
| RNF-02 | Accesibilidad | Contraste | ≥ 4.5:1 texto normal; ≥ 3:1 texto grande (WCAG AA) |
| RNF-03 | Accesibilidad | Área táctil | Todo control interactivo ≥ 48×48 dp |
| RNF-04 | Accesibilidad | Escalado del sistema | Usable al 130% sin desbordes ni texto cortado |
| RNF-05 | Accesibilidad | Lectores de pantalla | Controles no textuales con `Semantics` o `semanticLabel` |
| RNF-06 | Usabilidad | Densidad | Máximo 5 acciones primarias por pantalla |
| RNF-07 | Usabilidad | Lenguaje | Sin jerga clínica sin explicar; frases cortas; segunda persona |
| RNF-08 | Usabilidad | Errores | Indican qué pasó y qué hacer; nunca códigos técnicos |
| RNF-09 | Rendimiento | Inicio | Primera pantalla interactiva en ≤ 3 s en gama media |
| RNF-10 | Rendimiento | Fluidez | Sin bloqueos perceptibles; carga asíncrona |
| RNF-11 | Privacidad | Localidad | 100% de los datos en el dispositivo |
| RNF-12 | Privacidad | Minimización | No se solicita ningún dato sin uso declarado |
| RNF-13 | Privacidad | Reversibilidad | Eliminación total desde la app |
| RNF-14 | Confiabilidad | Persistencia | Ningún dato confirmado al usuario se pierde tras cierre forzado |
| RNF-15 | Confiabilidad | Manejo de errores | Prohibido el `catch` vacío; todo fallo produce estado explícito |
| RNF-16 | Confiabilidad | Funcionamiento offline | El 100% del MVP funciona sin conexión |
| RNF-17 | Mantenibilidad | Tamaño de archivo | Ningún archivo de pantalla supera 300 líneas |
| RNF-18 | Mantenibilidad | Tokens de diseño | Cero literales `Color(0xFF…)` fuera de `core/theme/` |
| RNF-19 | Mantenibilidad | Acceso a datos | Un único camino de persistencia |
| RNF-20 | Mantenibilidad | Código muerto | Cero archivos sin referencias |
| RNF-21 | Trazabilidad | Contenido de salud | 100% con `source`, `sourceUrl`, `reviewDate`, `status`, `sensitivity` |
| RNF-22 | Trazabilidad | Imágenes | 100% con licencia registrada en `image-credits.md` |
| RNF-23 | Rendimiento | Peso de assets | Íconos ≤ 20 KB; fotos ≤ 80 KB; formato WebP |
| RNF-24 | Compatibilidad | Plataforma | Android 8.0 (API 26)+, verificado en dispositivo físico |
| RNF-25 | Calidad | Análisis estático | `flutter analyze` sin errores ni warnings |

---

## 18. MVP definitivo

| Módulo | Prior. | MVP | Dependencias | Justificación |
|---|---|---|---|---|
| Onboarding + condición | MUST | Sí | — | Habilita toda la personalización |
| Perfil y edición | MUST | Sí | Onboarding | Permite corregir la condición |
| Dashboard "Hoy" | MUST | Sí | Hábitos, recetas, ejercicio | Superficie de visita diaria |
| Hábitos + rachas | MUST | Sí | Persistencia | Núcleo de adherencia |
| Métricas + historial + tendencia | MUST | Sí | Persistencia | Elevado a MUST por decisión explícita |
| Recomendaciones por condición | MUST | Sí | Contenido | Personalización básica |
| Contenido doble condición | MUST | Sí | Recomendaciones | Diferenciador central |
| Contenido educativo | MUST | Sí | Contenido | Objetivo declarado |
| **Recetas (módulo completo)** | MUST | Sí | Contenido | Motor de visita diaria y mayor diferenciador de localización |
| **Ejercicio (módulo completo)** | MUST | Sí | Hábitos, contenido | Ídem; reutiliza rachas, no las duplica |
| Notificación diaria | MUST | Sí | Perfil | Sostiene la racha y el retorno del usuario |
| Respaldo exportable | MUST | Sí | Persistencia | Resuelve la reinstalación sin nube |
| Privacidad + borrado | MUST | Sí | Modelo de datos | Requisito legal y ético |
| Accesibilidad base | MUST | Sí | Transversal | Es requisito, no mejora |
| Búsqueda y favoritos de recetas | SHOULD | Condicionado | Recetas | Entra si el camino crítico lo permite |
| Filtro por categoría | SHOULD | Condicionado | Contenido | Ídem |
| Priorización de métricas por condición | SHOULD | Condicionado | Métricas | Ídem |
| Favoritos de rutinas | COULD | Condicionado | Ejercicio | Primer candidato a recorte |
| Resistencia a la insulina | Future | No | — | Decidido: fuera |
| Firebase / nube / iOS / modo oscuro | Future | No | — | Fuera del MVP por diseño |

### Volumen de contenido

| Tipo | Mínimo (Escenario C) | **Comprometido** | Meta (excedente) |
|---|---|---|---|
| Recetas | 15 (5 por momento) | **30 (10 por momento)** | 51 (17 por momento) |
| Ejercicios (biblioteca) | 15 | **35** | 45 |
| Rutinas (compuestas) | 6 | **12** | 18 |
| Recomendaciones | 12 | **24** (8 por condición) | 30 |
| Artículos educativos | 9 | **15** (5 por condición) | 21 |


---

# PARTE III — DISEÑO TÉCNICO

## 19. Arquitectura

### Alternativas evaluadas

| Opción | A favor | En contra | Veredicto |
|---|---|---|---|
| Clean Architecture completa | Máxima separación | Cada funcionalidad simple exige 4-5 archivos; ceremonia sin beneficio a esta escala | Rechazada |
| MVC clásico | Familiar | El "controller" se difumina en Flutter; termina en lógica dentro de widgets | Rechazada |
| Por capas globales | Simple al inicio | Con 10 módulos cada carpeta se vuelve un cajón; es lo que le pasó a `shared/` | Rechazada |
| **Feature-first + Repository + Provider** | Módulos autocontenidos; resuelve defectos auditados concretos | Requiere disciplina para no recrear `shared/` | **Adoptada** |

### Decisión

> **Arquitectura por features, con tres capas internas por feature (presentación / estado / datos), Repository Pattern en la capa de datos y Provider como gestión de estado.**

**Por qué el Repository Pattern sí se justifica aquí:**

1. `exercise_provider` accedía directo a SharedPreferences saltándose el servicio. Un repositorio con interfaz elimina ese atajo como opción.
2. Deja abierta la puerta a contenido remoto: `ContentRepository` es una interfaz; hoy la implementa `AssetContentRepository`, mañana `RemoteContentRepository` con caché local. **Cero reescritura.**
3. Hace testeable la lógica sin tocar el almacenamiento real.

**Deliberadamente NO incluido:** capa de casos de uso, inyección de dependencias con `get_it`, gestores de estado avanzados.

**Sobre Provider frente a Riverpod o Bloc:** Provider es suficiente para este alcance, ya es conocido y reduce riesgo. Se renuncia a mejor manejo de estado asíncrono y a inyección más limpia — limitación real, pero irrelevante en una app sin red.

### Separación conceptual clave

| | Contenido | Datos del usuario |
|---|---|---|
| Origen | Assets JSON (o remoto futuro) | Generados en el dispositivo |
| Mutabilidad | Solo lectura | Lectura y escritura |
| Sensibilidad | Pública | **Sensible (salud)** |
| Persistencia | No aplica | `LocalStorage` |
| Trazabilidad | Fuente, fecha, estado obligatorios | No aplica |
| Sale del dispositivo | Ya viene incluido | **Nunca**, salvo respaldo exportado por el usuario |

Esta separación es la que permite derivar "Sobre tus datos" del modelo real: basta enumerar lo que vive en `LocalStorage`.

---

## 20. Estructura del proyecto

```
lib/
├── main.dart                    # bootstrap mínimo
├── app.dart                     # MaterialApp, providers raíz, tema
│
├── core/
│   ├── theme/
│   │   ├── app_colors.dart      # ÚNICO lugar con literales de color
│   │   ├── app_typography.dart  # escala tipográfica cerrada
│   │   ├── app_spacing.dart
│   │   └── app_theme.dart
│   ├── router/
│   │   ├── app_router.dart
│   │   └── routes.dart          # constantes de ruta
│   ├── storage/
│   │   ├── local_storage.dart   # ÚNICO acceso a SharedPreferences
│   │   ├── storage_keys.dart    # claves versionadas
│   │   └── schema_migration.dart
│   ├── content/
│   │   ├── content_repository.dart      # interfaz
│   │   ├── asset_content_repository.dart
│   │   └── content_exception.dart
│   ├── models/
│   │   ├── health_condition.dart
│   │   └── source_metadata.dart
│   ├── services/
│   │   ├── daily_rotation_service.dart  # función pura, determinista
│   │   ├── notification_service.dart
│   │   └── backup_service.dart
│   ├── utils/
│   │   └── date_utils.dart
│   └── widgets/                 # solo widgets usados por 3+ features
│
└── features/
    ├── onboarding/  ├── dashboard/  ├── habits/    ├── metrics/
    ├── recipes/     ├── exercise/   ├── education/ ├── recommendations/
    ├── profile/     └── privacy/
```

Cada feature con la misma forma interna:

```
features/recipes/
├── data/recipes_repository.dart
├── models/recipe.dart
├── providers/recipes_provider.dart
├── pages/recipes_page.dart
├── pages/recipe_detail_page.dart
└── widgets/recipe_card.dart
```

### Reglas de estructura (verificables, entran a la DoD)

| # | Regla |
|---|---|
| **E1** | **No existe carpeta `shared/`.** Fue el origen de la deuda anterior |
| **E2** | Un widget sube a `core/widgets/` solo cuando lo usan **3 o más** features. Con 2, se duplica a propósito |
| **E3** | Ningún archivo de pantalla supera **300 líneas** |
| **E4** | Ningún archivo fuera de `core/storage/` importa `shared_preferences` |
| **E5** | Ningún archivo fuera de `core/theme/` contiene `Color(0xFF…)` |
| **E6** | Un modelo usado por una sola feature vive en esa feature |
| **E7** | Cero archivos sin referencias en el repositorio |

---

## 21. Modelo de datos

### A. Datos del usuario (mutables, persistidos)

**`UserProfile`** — uno por instalación

| Campo | Tipo | Validación |
|---|---|---|
| `name` | String | 1-40 caracteres, obligatorio |
| `birthYear` | int | Rango plausible. **Se guarda el año, no la fecha** (minimización) |
| `condition` | HealthCondition | Obligatorio |
| `onboardingCompletedAt` | DateTime | — |
| `disclaimerAcceptedAt` | DateTime | Evidencia de aceptación |
| `reminderTime` | TimeOfDay? | null = sin recordatorio |

> **Decisión de minimización:** el proyecto anterior pedía fecha exacta, estatura y género sin usarlos. Se eliminan. Menos dato, menos riesgo.

**`HabitCompletion`** — `habitId`, `date` (yyyy-MM-dd), `completedAt`

**`StreakState`** — `currentStreak`, `bestStreak` (nunca decrece), `lastQualifyingDate`

> **`Streak` no es una entidad separada.** Es estado derivado de las marcas. Se guarda el resultado como *caché*, no como fuente de verdad: debe poder recalcularse desde `HabitCompletion`. Ese recálculo es el test de regresión del bug de rachas anterior.

**`MetricRecord`**

| Campo | Tipo | Nota |
|---|---|---|
| `id` | String | UUID local |
| `type` | enum {glucose, bloodPressure, weight} | — |
| `primaryValue` | double | Glucosa, sistólica o peso |
| `secondaryValue` | double? | Solo diastólica |
| `context` | enum? {fasting, postMeal, other} | Solo glucosa |
| `recordedAt` | DateTime | Editable por el usuario |
| `note` | String? | ≤ 120 caracteres |

> **Una entidad con `type`, no tres.** Un repositorio, una pantalla de historial parametrizada, un gráfico parametrizado.
>
> **Ningún campo de clasificación.** No hay `status`, `level` ni `category`. La ausencia es intencional: hace estructuralmente imposible reintroducir el diagnóstico (RF-22).

**`Favorites`** — `Set<String>` de IDs, separado por tipo.

**`AppMeta`** — `schemaVersion`, `lastOpenedDate`, `contentVersion`.

### B. Contenido (inmutable, en assets)

Todas las entidades de contenido **de salud** embeben:

```
SourceMetadata {
  source, sourceUrl, reviewDate,
  status: draft | reviewed | validated,
  sensitivity: low | medium | high
}
```

| Entidad | Campos principales |
|---|---|
| `HabitDefinition` | id, título, descripción, `conditions`, icono, `SourceMetadata` |
| `Recommendation` | id, categoría, título, cuerpo, `conditions`, `SourceMetadata` |
| `EducationalArticle` | id, título, resumen, contenido, categoría, `conditions`, `SourceMetadata` |
| `Recipe` | id, título, `mealTime` {desayuno, almuerzo, once}, `conditions`, tiempo, dificultad, **imagen (asset local, campo único)**, ingredientes[], pasos[], nota nutricional, `SourceMetadata`, `ImageCredit` |
| `Exercise` | id, nombre, imagen, descripción, pasos[], errores frecuentes[], **contraindicaciones[]**, `SourceMetadata`, `ImageCredit` |
| `Routine` | id, nombre, `conditions`, nivel, duración, **`List<RoutineItem>`** (referencia a `Exercise` + series/repeticiones), contraindicaciones agregadas, `SourceMetadata` |

> **`Routine` referencia ejercicios, no los copia.** La unidad reutilizable es el ejercicio. Crear la rutina 13 cuesta minutos, no horas, y las imágenes se hacen una vez por ejercicio.
>
> **`conditions` es una lista, no un valor.** Un ítem declara `[diabetes]`, `[hypertension]`, `[both]` o combinaciones. **`both` es un valor propio de la lista, no la intersección de los otros dos.** Para que un contenido aparezca en doble condición, alguien tuvo que escribir `both` explícitamente y validarlo. Esto hace imposible reincidir en `listaA + listaB`.

### Entidades evaluadas y descartadas

| Entidad | Decisión | Razón |
|---|---|---|
| `HealthCondition` como clase | enum | Sin comportamiento ni estado |
| `Streak` | campos en `StreakState` | Estado derivado |
| `User` con credenciales | descartada | No hay cuentas ni backend |
| `WaterIntake` | descartada | Es un hábito, no una entidad |
| `ExerciseSession` con minutos semanales | descartada | Era el sistema de rachas paralelo anterior; se reemplaza por `HabitCompletion` |

---

## 22. Persistencia

### Punto único de acceso

`LocalStorage` es la **única** clase que importa `shared_preferences`. Expone operaciones tipadas (`readProfile`, `writeMetric`, `deleteAll`), nunca `getString` genérico hacia afuera.

**Cadena:** UI → Provider → Repositorio → `LocalStorage`. Cuatro niveles, sin atajos (regla E4).

### Convención de claves

`eira.v1.<dominio>.<detalle>`

| Clave | Contenido |
|---|---|
| `eira.schema_version` | int — control de migraciones |
| `eira.v1.profile` | JSON de `UserProfile` |
| `eira.v1.habits.completions` | JSON, últimos 90 días |
| `eira.v1.habits.streak` | JSON de `StreakState` |
| `eira.v1.metrics.glucose` | JSON array de `MetricRecord` |
| `eira.v1.metrics.blood_pressure` | JSON array |
| `eira.v1.metrics.weight` | JSON array |
| `eira.v1.favorites.recipes` | array de IDs |
| `eira.v1.favorites.routines` | array de IDs |
| `eira.v1.app.last_opened` | fecha, para reinicio diario |
| `eira.v1.notifications.enabled` | bool |

> Métricas separadas **por tipo**, no en una sola clave: escribir un peso no reescribe el historial de glucosa.

### Serialización

`toJson()` / `fromJson()` explícitos en cada modelo, con `fromJson` **tolerante**: campo faltante → valor por defecto documentado, nunca excepción.

> **Prohibido: ningún `Map<String, dynamic>` cruza la capa de datos hacia arriba.** El proyecto anterior pasaba mapas sin tipar hasta los widgets, trasladando errores de datos a tiempo de ejecución en la UI.

### Límites y migración futura

- Usuario activo: ~3 registros/día × 365 ≈ 1.100 al año
- ~120 bytes por registro → **~130 KB anuales**
- **Umbral de alerta: 1 MB** (≈ 8 años de uso intensivo)

Si se superara, la migración natural es `sqflite` o `hive`. `schemaVersion` existe para permitirla sin pérdida. **No se migra ahora:** sería resolver un problema inexistente.

### Estrategia de migración

Al arrancar: leer `schema_version`. Si es menor a la actual, aplicar migraciones en cadena y reescribir la versión. Si no existe la clave → instalación nueva. **Prohibido asumir que un dato existe.**

### Respaldo exportable

`BackupService` genera un JSON con `schemaVersion`, `exportedAt` y todos los datos de usuario. El usuario elige dónde guardarlo mediante el selector del sistema. La importación valida versión y **exige confirmación explícita** porque reemplaza los datos actuales. El archivo nunca se sube a ningún servidor.

### Configuración de respaldo del sistema

En `AndroidManifest.xml`:

```xml
android:allowBackup="false"
android:fullBackupContent="false"
```

Documentado en `ADR-006`: coherencia con la declaración de privacidad; el respaldo queda bajo control explícito del usuario vía exportación.

### Manejo de errores

**Prohibido el `catch` vacío** (RNF-15). Todo repositorio devuelve estado explícito; todo provider expone `loading / ready / error`. La UI distingue estado vacío de estado de error: *"aún no tienes registros"* no es *"no pudimos cargar tus registros"*.

---

## 23. Navegación

### Estructura de pestañas

```
Hoy  ·  Hábitos  ·  Métricas  ·  Descubre  ·  Perfil
```

**Cinco pestañas, con etiqueta de texto siempre visible** (nunca solo icono — regla de accesibilidad).

**Por qué Recetas y Ejercicio no tienen pestaña propia:** la visita diaria se resuelve en la pantalla de inicio, no con una pestaña. "Hoy" muestra la receta y la rutina del día como tarjetas grandes con imagen. El usuario que abre EIRA para ver qué cocinar ya lo tiene sin navegar. "Descubre" es para *explorar el catálogo*, una intención distinta y menos frecuente.

*Alternativa descartada: pestañas propias para Recetas y Ejercicio con Métricas dentro de Perfil — rechazada porque métricas es MUST y quedaría a dos toques.*

### Mapa de rutas

```
/                          → redirección: ¿onboarding completo?
│
├── /onboarding
│     ├── /welcome
│     ├── /profile-setup
│     ├── /condition
│     └── /disclaimer        → aceptación obligatoria
│
└── ShellRoute (5 pestañas)
      ├── /today
      │     ├── /today/recipe/:id
      │     └── /today/routine/:id
      ├── /habits
      ├── /metrics
      │     ├── /metrics/:type/history
      │     └── /metrics/:type/add
      ├── /discover
      │     ├── /discover/recipes       → /discover/recipes/:id
      │     ├── /discover/exercise      → /discover/routines/:id
      │     │                             /discover/exercises/:id
      │     ├── /discover/education     → /discover/education/:id
      │     └── /discover/recommendations
      └── /profile
            ├── /profile/edit
            ├── /profile/notifications
            ├── /profile/data        ← "Sobre tus datos"
            ├── /profile/backup
            └── /profile/about
```

### Reglas de navegación

| # | Regla |
|---|---|
| **N1** | Sin rutas huérfanas — toda ruta alcanzable desde la UI |
| **N2** | Profundidad máxima: **3 niveles** desde la pestaña |
| **N3** | Toda pantalla de detalle tiene retorno explícito |
| **N4** | Toda acción destructiva pide confirmación con verbos claros ("Eliminar" / "Cancelar", nunca "Sí" / "No") |
| **N5** | Al cambiar de condición se invalida el contenido derivado sin reiniciar la app |
| **N6** | La redirección inicial no muestra spinner si resuelve en < 300 ms |

---

## 24. UX y accesibilidad

Estas reglas **son criterios de aceptación**, no recomendaciones.

### Tipografía

| Rol | Tamaño | Peso | Uso |
|---|---|---|---|
| `display` | 32 sp | Bold | Números de métricas, racha |
| `headline` | 26 sp | Bold | Títulos de pantalla |
| `title` | 21 sp | SemiBold | Títulos de tarjeta |
| `body` | **18 sp** | Regular | Texto principal |
| `bodySecondary` | 16 sp | Regular | Texto de apoyo |
| `label` | **14 sp** | Medium | Etiquetas — mínimo absoluto |

> **Mínimo absoluto 14 sp; cuerpo por defecto 18 sp.** El proyecto anterior tenía 45 usos ≤ 12 sp, llegando a 9 sp. **Seis tamaños en total**, contra 16 anteriores.

### Color y contraste

| Regla | Verificación |
|---|---|
| Texto normal: ≥ 4.5:1 | Verificador WCAG; resultado registrado en `docs/accessibility/` |
| Texto grande (≥ 24 sp): ≥ 3:1 | Ídem |
| Elementos interactivos: ≥ 3:1 contra el fondo | Ídem |
| El color **nunca** es el único portador de información | Acompañado de icono o texto |

> **Corrección obligatoria de marca:** el primario `#979F80` con texto blanco ronda 2.3:1, muy por debajo de AA. Se conserva el verde salvia como identidad para superficies y decoración, pero se define una **variante oscurecida para texto y fondos de botón**, medida y documentada antes del primer sprint de UI. No es negociable: es el color de los botones principales.

### Interacción

| Regla | Valor |
|---|---|
| Área táctil mínima | 48 × 48 dp |
| Área táctil de acción primaria | 56 × 56 dp |
| Separación entre controles | ≥ 8 dp |
| Acciones primarias por pantalla | ≤ 5 |
| Escalado del sistema soportado | hasta **130%** |
| Botones con icono y texto | Siempre en acciones primarias |
| `Semantics` / `semanticLabel` | Obligatorio en todo control no textual |

### Lenguaje y contenido

- Segunda persona, tono directo: *"Registra tu presión"*, no *"Registro de presión arterial del usuario"*
- Sin jerga clínica sin explicar en la misma pantalla
- Frases de máximo ~20 palabras en textos de interfaz
- Números con unidad siempre visible (`120 mg/dL`, no `120`)
- Fechas legibles ("hoy", "ayer", "12 de octubre"), nunca `2026-10-12`

### Errores y retroalimentación

| Situación | Regla |
|---|---|
| Error | Dice **qué pasó** y **qué hacer**. Nunca códigos ni jerga |
| Validación | Al confirmar, no mientras se escribe |
| Confirmación de guardado | **Solo si el dato realmente se persistió** (lección L1) |
| Estado vacío | Explica por qué está vacío y ofrece la acción para llenarlo |
| Estado de carga | Visible solo si supera 300 ms |

### Carga cognitiva

- Una decisión principal por pantalla
- Onboarding: máximo 3 campos por paso
- Listados: máximo 3 datos por tarjeta
- Sin animaciones decorativas que retrasen la interacción

### Checklist de accesibilidad por pantalla

- [ ] Ningún texto bajo 14 sp
- [ ] Contraste AA verificado y anotado
- [ ] Áreas táctiles ≥ 48 dp
- [ ] Usable al 130% de escala del sistema
- [ ] Controles no textuales con etiqueta semántica
- [ ] ≤ 5 acciones primarias
- [ ] Errores comprensibles sin conocimiento técnico
- [ ] Sin información transmitida solo por color


---

# PARTE IV — CALIDAD Y DISCIPLINA

## 25. Estrategia de contenido médico

### Principio rector

> **Si una afirmación de salud no puede rastrearse a una fuente verificable, no entra a EIRA.**

No es aspiración: es condición de compilación del contenido. El validador rechaza cualquier ítem sin `SourceMetadata` completo.

### Separación de contenidos

| Tipo | Ejemplos | Requiere fuente | Dónde vive |
|---|---|---|---|
| **Contenido de aplicación** | Botones, títulos, mensajes de error | No | Constantes en Dart |
| **Contenido de salud** | Hábitos, recomendaciones, artículos, recetas, ejercicios, contraindicaciones | **Sí** | JSON en `assets/content/` |

Regla operativa: **si un texto afirma algo sobre la salud del usuario, es contenido de salud**, aunque sea una línea dentro de una tarjeta.

### Fuentes admitidas

| Nivel | Fuente | Uso |
|---|---|---|
| 1 — Preferente | **MINSAL**: Guías GES de DM2 e HTA, Guía Alimentaria para Chile | Base de todo el contenido; contexto local |
| 1 — Preferente | **ADA** (Standards of Care) | Diabetes tipo 2 |
| 1 — Preferente | **AHA** | Hipertensión y ejercicio cardiovascular |
| 2 — Complementaria | OMS/OPS, INTA (Universidad de Chile) | Contexto nutricional chileno |
| 3 — Solo recetas | Recetarios institucionales (JUNAEB, MINSAL, INTA) | Base de preparaciones, adaptadas |
| **Inadmisible** | Blogs, redes sociales, sitios comerciales, IA generativa sin verificación | — |

> **Sobre las recetas:** una preparación culinaria no necesita fuente clínica, pero **sí la necesita su afirmación nutricional**. La receta puede ser adaptada; la frase "baja en sodio, apta para hipertensión" requiere el criterio y la fuente que la sostienen.

### Ciclo de vida de un ítem

```
draft  →  reviewed  →  validated
  │          │            │
  │          │            └─ Revisado por profesional de salud
  │          │               Único estado apto para sensibilidad alta
  │          └─ Fuente verificada, redacción revisada, criterios documentados
  │             Estado mínimo para entrar al MVP
  └─ Redactado, sin verificar. NO se compila en la app
```

**Regla de corte:** ningún ítem en `draft` llega a producción. Ningún ítem `high` llega a producción sin estado `validated`.

### Niveles de sensibilidad

| Nivel | Qué incluye | Requisito |
|---|---|---|
| `low` | Educación general, motivación, hábitos genéricos | `reviewed` |
| `medium` | Recomendaciones por condición, recetas con afirmación nutricional | `reviewed` + fuente nivel 1 |
| `high` | **Contenido de doble condición**, contraindicaciones de ejercicio, intensidad de esfuerzo en HTA | **`validated`** por profesional |

### Proceso de doble condición

1. **Inventario de conflictos.** Por cada tema (alimentación, ejercicio, hidratación, control), listar qué recomienda la guía de DM2 y qué la de HTA.
2. **Clasificar la relación:** *convergente*, *complementaria* o *en tensión*.
3. **Resolver las tensiones con fuente**, no con juicio propio. Ejemplos reales: control de carbohidratos frente a control de sodio en una misma preparación; jugos naturales recomendables por potasio para HTA pero con carga glucémica relevante en DM2.
4. **Redactar contenido propio** etiquetado `both`. Nunca reutilizar el ítem de una condición marcándolo también para la otra.
5. **Validación profesional obligatoria** antes de entrar al MVP.
6. **Si una tensión no puede resolverse con fuente, el tema queda fuera** y se documenta la exclusión. Un tema ausente es defendible; un tema mal resuelto no.

### Registros de curación

`docs/content/content-registry.md`:

| ID | Tipo | Condición | Sensib. | Fuente | URL | Fecha revisión | Estado | Revisor | Notas |
|---|---|---|---|---|---|---|---|---|---|

`docs/content/image-credits.md`: archivo, origen, licencia, URL, fecha. **Sin registro de licencia, la imagen no entra al repositorio.**

### Validación profesional

| Aspecto | Definición |
|---|---|
| Quién | Profesional de salud del área (nutricionista, kinesiólogo o médico) |
| Qué se valida | Todo el contenido `high` + muestra de `medium` |
| **Cuándo se solicita** | **Semana 1-4** (T-031). No en la semana 8 |
| Cuándo se ejecuta | Semana 8, antes de la validación con usuarios |
| Evidencia | Pauta firmada o correo con observaciones, en `docs/validation/` |
| Si no se consigue | Todo el contenido `high` sale del MVP y se documenta como limitación |

### Separación de la lógica de UI

`assets/content/*.json` → `ContentRepository` → modelo tipado → provider → widget.

**Ningún texto de salud escrito en un archivo `.dart`.** Consecuencia: un profesional puede revisar el contenido completo sin abrir código, y una corrección de contenido es un cambio de JSON.

---

## 26. Privacidad

### Marco normativo

Hasta el 30 de noviembre de 2026 rige la Ley 19.628 original. La **Ley 21.719 entra en vigencia el 1 de diciembre de 2026**, crea la Agencia de Protección de Datos Personales y alinea a Chile con estándares tipo GDPR. La entrega ocurre el último día del régimen antiguo.

> **Decisión de diseño:** EIRA se diseña bajo el estándar de la Ley 21.719, no el de la 19.628. La nueva ley exige **protección desde el diseño y por defecto**: las medidas deben aplicarse antes de iniciar el tratamiento y garantizar que, por defecto, solo se procesen los datos estrictamente necesarios para la finalidad específica.

**Argumento de defensa académica:**

> *"El almacenamiento local no es una limitación del MVP: es una decisión de diseño derivada del principio de protección desde el diseño y por defecto que introduce la Ley 21.719, vigente desde el 1 de diciembre de 2026. Tratándose de datos sensibles de salud, el diseño que minimiza el riesgo del titular es aquel en que los datos no salen de su dispositivo."*

### Principios aplicados

| Principio | Implementación concreta |
|---|---|
| **Minimización** | Se guarda el año de nacimiento, no la fecha; se eliminaron estatura y género |
| **Finalidad** | Cada dato tiene un uso declarado; si no lo tiene, no se pide |
| **Localidad** | 100% de los datos en el dispositivo; sin peticiones de red con datos del usuario |
| **Protección por defecto** | `allowBackup="false"`; métricas voluntarias; sin cuenta ni identificadores |
| **Transparencia** | "Sobre tus datos" enumera exactamente lo almacenado |
| **Supresión** | Borrado total desde la app, sin residuos |
| **Portabilidad** | Exportación en formato legible, controlada por el usuario |
| **Consentimiento** | Disclaimer con aceptación explícita y registrada |

> **Nota honesta para el informe:** al no salir los datos del dispositivo y no existir un responsable que los trate, EIRA queda en la práctica **fuera del ámbito de tratamiento regulado**. Eso no es una laguna: es el objetivo del diseño.

### Pantalla "Sobre tus datos" — regla de construcción

**El texto se deriva del modelo de datos, no se redacta libremente.** Cada afirmación corresponde a una clave real de `storage_keys.dart`.

1. Qué guardamos — lista **exacta**
2. Dónde — solo en este teléfono
3. Para qué — un propósito por dato
4. Qué **no** hacemos — sin cuentas, sin envío a servidores, sin publicidad, sin respaldo automático
5. Qué puedes hacer — exportar respaldo, eliminar registros, borrar todo
6. Qué **no** es EIRA — no diagnostica, no reemplaza atención médica

**Control de regresión:** ningún sprint que agregue o modifique una clave de almacenamiento puede cerrarse sin revisar esta pantalla. Va en la DoD.

### Verificación de no transmisión (RF-43)

Evidencia archivada, no afirmación:

1. Auditoría de dependencias: ninguna con capacidad de red no justificada
2. Búsqueda en código: cero `http`, `Dio`, `Image.network` o llamadas a APIs
3. **Prueba empírica:** app en modo avión durante un flujo completo — todo funciona, incluidas recetas y rutinas del día. Captura archivada
4. `allowBackup="false"` declarado y documentado

---

## 27. Testing

### Priorización por riesgo

| Prior. | Área | Por qué | Tipo |
|---|---|---|---|
| **P0** | Cálculo de rachas | Bug conocido anterior; casos límite abundantes | Unit |
| **P0** | Serialización y persistencia | Lección L1: el usuario cree que guardó y no guardó | Unit + integración |
| **P0** | Resolución de contenido por condición | Diferenciador; `both` no puede degradarse a concatenación | Unit |
| **P0** | Rotación diaria determinista | Si falla, la app pierde su motivo de visita diaria | Unit |
| **P1** | Validación de entradas de métricas | Datos de salud mal ingresados | Unit |
| **P1** | Reinicio diario de hábitos | Depende de fechas: fuente clásica de errores | Unit |
| **P1** | Borrado total de datos | Requisito legal | Integración |
| **P2** | Widgets de tarjetas y formularios | Regresiones visuales | Widget |
| **P2** | Navegación entre pantallas | — | Widget |
| **P3** | Accesibilidad | Verificación manual con checklist | Manual |

### Casos límite obligatorios

**Rachas** (el bug del proyecto anterior vivía aquí):

- Primer día de uso
- Dos marcas el mismo día (no debe sumar dos)
- Un día sin actividad (debe romper)
- Cambio de mes y de año
- Cambio manual de hora del dispositivo, hacia atrás y hacia adelante
- La mejor racha nunca decrece
- **El recálculo desde el historial coincide con el valor cacheado**

**Persistencia:**

- Primera instalación: sin claves, valores por defecto
- JSON malformado → no crashea, devuelve error explícito
- Campo faltante → valor por defecto
- Escritura, cierre forzado, relectura → dato intacto
- Migración de versión de esquema

**Doble condición:**

- `both` devuelve contenido etiquetado `both`, no la suma de listas
- Cero duplicados en el resultado
- Cambiar de condición actualiza todos los módulos

**Métricas:**

- Historial vacío, con 1 registro y con 200
- Gráfico con 0, 1 y 2 puntos
- Eliminar el único registro existente

**Contenido:**

- Validador de `SourceMetadata`: ningún ítem sin fuente compila
- Todo ítem `high` está en estado `validated`
- Toda imagen referenciada existe como asset

### Metas cuantitativas

| Métrica | Meta |
|---|---|
| Cobertura de lógica de negocio (`core/` + repositorios + servicios) | **≥ 70%** |
| Cobertura de casos P0 | **100%** |
| Cobertura global | ≥ 40% (la UI no se persigue con tests) |
| `flutter analyze` | Cero errores y cero warnings |

### Regla temporal

> **El test se escribe en el mismo sprint que la funcionalidad. Nunca "después".**

El proyecto anterior terminó con un `widget_test.dart` de cuerpo vacío y un comentario que decía "por implementar en sprints futuros". Ese sprint futuro no llegó.

### Pruebas manuales

`docs/testing/manual-test-plan.md` con guiones por flujo completo. Ejecución al cierre de cada fase, resultado archivado con fecha y dispositivo.

**Prueba de modo avión: obligatoria en cada cierre de fase.**

---

## 28. Definition of Done

**Ninguna tarea está terminada porque "funciona".**

### Base — toda tarea

- [ ] Implementada según su criterio de aceptación
- [ ] `flutter analyze` sin errores ni warnings
- [ ] Sin `catch` vacío, sin `TODO` sin ticket asociado
- [ ] Cumple las reglas E1–E7
- [ ] Probada manualmente en dispositivo físico
- [ ] Commit propio, atómico, con convención

### Adicional según tipo de tarea

| Si la tarea… | Además requiere |
|---|---|
| …contiene lógica de negocio | Tests unitarios, incluidos casos límite |
| …**toca persistencia** | Test de ida y vuelta + **revisión de "Sobre tus datos"** + verificar que el mensaje de éxito corresponde a un guardado real |
| …**agrega o cambia una clave de almacenamiento** | Actualizar `storage_keys.dart`, evaluar migración, revisar "Sobre tus datos" |
| …crea o modifica una pantalla | Checklist de accesibilidad completo y archivado + captura |
| …**agrega contenido de salud** | `SourceMetadata` completo + registro en `content-registry.md` + estado ≥ `reviewed` |
| …agrega contenido `high` | Estado `validated` + evidencia de revisión profesional |
| …**agrega una imagen** | Registro en `image-credits.md` + WebP + ≤ 80 KB |
| …agrega una dependencia | Justificación escrita en `docs/decisions/` |
| …implica una decisión técnica no obvia | ADR en `docs/decisions/` |
| …cierra un requisito funcional | Actualización de la matriz de trazabilidad |

### DoD de sprint

- [ ] Todas las tareas comprometidas cumplen su DoD
- [ ] La app compila e instala en dispositivo físico
- [ ] Los tests pasan
- [ ] **Prueba de modo avión superada**
- [ ] Evidencia del sprint archivada
- [ ] `docs/progress/` actualizado
- [ ] Matriz de trazabilidad al día

---

## 29. Estrategia de commits

### Por qué esta sección es crítica

El reinicio del proyecto existe por esto. El historial nuevo debe demostrar **autoría propia** y **evolución continua**.

### Configuración previa — antes del primer commit

```bash
git config user.name  "<nombre completo>"
git config user.email "<correo institucional DuocUC>"
```

**Verificación obligatoria antes de cada entrega:**

```bash
git shortlog -sne --all    # debe mostrar UN solo autor
```

Esta verificación entra al checklist de cierre de cada fase.

### Convención

`<tipo>(<alcance>): <descripción en imperativo, minúscula, sin punto>`

| Tipo | Uso |
|---|---|
| `feat` | Nueva funcionalidad visible |
| `fix` | Corrección de error |
| `refactor` | Cambio interno sin alterar comportamiento |
| `test` | Tests |
| `docs` | Documentación, ADRs, trazabilidad |
| `content` | **Contenido de salud** — tipo propio del proyecto |
| `style` | Formato, sin cambio de lógica |
| `chore` | Configuración, dependencias, assets |

> `content` no es estándar en Conventional Commits, y por eso vale: hace visible en el historial que la curación es trabajo del proyecto —cerca de 70 horas— y no una tarea invisible.

**Alcances:** `onboarding`, `habits`, `metrics`, `recipes`, `exercise`, `education`, `profile`, `privacy`, `storage`, `content`, `theme`, `router`, `notifications`, `backup`.

### Reglas de granularidad

| # | Regla |
|---|---|
| **C1** | **Un commit = una unidad de trabajo verificable.** Si el mensaje necesita "y", son dos commits |
| **C2** | **Nunca acumular más de un día de trabajo** sin commit |
| **C3** | Un commit no mezcla funcionalidades distintas |
| **C4** | El código commiteado compila. Nunca se sube algo roto a `main` |
| **C5** | Mensajes en imperativo, describiendo **qué cambia** |
| **C6** | Los tests van en su propio commit `test:`, salvo que sean inseparables |
| **C7** | Prohibidos: "cambios varios", "avance", "actualización", "fix bugs" |
| **C8** | El commit que cierra un requisito lo menciona: `Refs: RF-13` |

**Ritmo esperado:** 3-6 commits por sesión; **250-400 commits** al final del proyecto.

### Ramas

`main` como rama de trabajo, con etiquetas en los hitos (`v0.1-arquitectura`, `v0.5-mvp-core`, `v1.0-entrega`). Ramas de feature solo para experimentos descartables.

> **Justificación:** un flujo de ramas de equipo sería teatro en un proyecto individual y fragmentaría el historial lineal que se necesita demostrar.

### Ejemplos de commits esperados

```
chore(setup): initialize flutter project structure
chore(setup): configure analysis options and lint rules
feat(theme): add color tokens with AA contrast values
feat(storage): add local storage with versioned keys
test(storage): add serialization round-trip tests
feat(onboarding): add condition selection step
feat(habits): add habit completion persistence
test(habits): add streak edge case tests
fix(habits): correct streak on same-day double completion
content(recipes): add 6 breakfast recipes with sources
docs(decisions): record local-only storage rationale
feat(exercise): add exercise library model
feat(metrics): add glucose record persistence
test(metrics): add empty and single-record chart cases
docs(privacy): update data screen after metrics keys
```

---

## 30. Trazabilidad académica

### Cadena a demostrar

```
Requisito → Tarea → Implementación → Prueba → Commit → Evidencia
  RF-13     T-042    streak_service   3 tests   a3f9c21   captura
```

### Estructura de documentación

```
docs/
├── README.md
├── requirements/
│   ├── functional.md
│   ├── non-functional.md
│   └── traceability-matrix.md         ← documento clave
├── architecture/
│   ├── overview.md
│   ├── data-model.md
│   ├── persistence.md
│   └── navigation.md
├── decisions/                         ← ADRs numerados
│   ├── ADR-001-feature-first.md
│   ├── ADR-002-local-only-storage.md
│   ├── ADR-003-no-clinical-classification.md
│   ├── ADR-004-shared-preferences.md
│   ├── ADR-005-exercise-library-model.md
│   └── ADR-006-disable-android-backup.md
├── content/
│   ├── content-registry.md
│   ├── image-credits.md
│   ├── sources.md
│   └── dual-condition-analysis.md     ← el diferenciador, documentado
├── testing/
│   ├── strategy.md
│   ├── manual-test-plan.md
│   └── results/
├── accessibility/
│   ├── rules.md
│   ├── contrast-verification.md
│   └── screen-checklists/
├── privacy/
│   ├── data-inventory.md              ← fuente de "Sobre tus datos"
│   └── legal-analysis.md              ← 19.628 / 21.719
├── validation/
│   ├── protocol.md
│   ├── sessions/
│   └── findings.md
├── progress/
│   └── sprint-XX.md
└── evidence/
    ├── screenshots/
    ├── videos/
    └── test-results/
```

> **Diferencias respecto a la estructura estándar:** se agregan `content/`, `accessibility/` y `privacy/` como carpetas propias, porque son los tres pilares diferenciadores. Enterrarlos en `architecture/` los haría invisibles justo donde el proyecto es más fuerte.

### Matriz de trazabilidad

| Req | Descripción | Tarea(s) | Archivo(s) | Test(s) | Commits | Evidencia | Estado |
|---|---|---|---|---|---|---|---|
| RF-13 | Racha actual y mejor | T-041, T-042 | `streak_service.dart` | 7 casos | `a3f9c21` | cap-rachas.png | ✅ |

**Actualización al cerrar cada requisito, no al final.**

### ADRs — formato

Título, fecha, estado, contexto, alternativas evaluadas, decisión, consecuencias **incluidas las negativas**.

> Las consecuencias negativas son obligatorias: un ADR que solo lista ventajas no es un análisis, es una justificación. ADR-004 debe decir que SharedPreferences no permite consultas y que el crecimiento del historial obligará a migrar.

---

## 31. Evidencias

> **La evidencia se recopila durante el desarrollo. Nunca se reconstruye al final.**

### Qué se conserva

| Tipo | Cuándo | Dónde |
|---|---|---|
| Capturas de cada pantalla | Al completarla y al modificarla | `evidence/screenshots/` |
| Video de flujos completos | Al cerrar cada fase | `evidence/videos/` |
| Resultado de `flutter test` | Cada sprint | `evidence/test-results/` |
| Checklists de accesibilidad | Por pantalla | `accessibility/screen-checklists/` |
| Verificación de contraste | Al definir y al cambiar colores | `accessibility/contrast-verification.md` |
| Registro de bugs y solución | Al ocurrir | `progress/` |
| Decisiones técnicas | Al tomarse | `decisions/` |
| Registro de contenido y licencias | Al crear cada ítem | `content/` |
| Evidencia de validación profesional | Semana 8 | `validation/` |
| Sesiones con usuarios | Semanas 10-11 | `validation/sessions/` |
| **Captura de `git shortlog -sne`** | Cada cierre de fase | `evidence/` |
| **Video del modo avión funcionando** | Cada cierre de fase | `evidence/videos/` |
| Diagramas | Al diseñarse y al cambiar | `architecture/` |

### Evidencias específicas de este proyecto

1. **Autoría** — el `git shortlog` con un solo autor es la respuesta directa a la razón del reinicio.
2. **Funcionamiento offline** — el video en modo avión demuestra la decisión de arquitectura, no solo la declara.
3. **Análisis de doble condición** — `dual-condition-analysis.md` con la tabla de convergencias y tensiones resueltas es la evidencia del diferenciador. Probablemente el documento más valioso del proyecto.

### Rutina de fin de sesión (5 minutos)

- [ ] Commits del día hechos y con convención
- [ ] Captura si hubo cambio visual
- [ ] Nota en `progress/` si hubo decisión o bug
- [ ] Matriz de trazabilidad al día si se cerró un requisito


---

# PARTE V — PLANIFICACIÓN

## Advertencia de presupuesto

| Concepto | Horas |
|---|---|
| Capacidad disponible (13 semanas, descontados feriados) | **349 h** |
| Trabajo MUST itemizado | **345 h** |
| **Contingencia natural** | **4 h (1%)** |

**Un 1% de holgura no es un plan.** La contingencia se construye con **palancas de recorte pre-designadas**, para que la decisión ya esté tomada cuando el atraso ocurra:

| Orden | Palanca | Horas | Impacto en el MVP |
|---|---|---|---|
| 1 | Favoritos de rutinas (COULD) | 4 h | Ninguno |
| 2 | Búsqueda y favoritos de recetas (SHOULD) | 10 h | Bajo: el catálogo sigue navegable |
| 3 | Filtro por categoría (SHOULD) | 5 h | Bajo |
| 4 | Recetas de 30 → 24 | 4 h | Bajo: 8 días sin repetir |
| 5 | Ejercicios de 35 → 28 | 5 h | Bajo: menos variedad, mismas rutinas |
| 6 | Gráfico de tendencia → historial en lista | 8 h | **Medio**: pierde visualización, conserva el dato |
| | **Total** | **36 h** | |

**Contingencia efectiva: 40 h ≈ 11,5%.** Las palancas 1-3 se cortan sin consultar. La 6 requiere decisión explícita.

**Protecciones adicionales:** la curación de contenido arranca en S2 (no al final), y S12-S13 están reservadas casi por completo a corrección, no a funcionalidad nueva.

---

## 32. Roadmap

| Fase | Semanas | Objetivo |
|---|---|---|
| **F0 — Cierre de planificación** | S1 (parcial) | Plan aprobado, entorno listo |
| **F1 — Fundación técnica** | S1–S2 | Repositorio, arquitectura, tema, almacenamiento, contenido base |
| **F2 — Identidad y hábitos** | S2–S4 | Onboarding, condición, perfil, hábitos, rachas |
| **F3 — Métricas** | S5–S6 | Registro, historial, tendencia |
| **F4 — Contenido y módulos diarios** | S6–S8 | Recetas, ejercicio, educación, recomendaciones |
| **F5 — Integración diaria** | S9 | Dashboard "Hoy", rotación, notificaciones, respaldo |
| **F6 — Calidad, privacidad, accesibilidad** | S10 | Auditoría transversal y correcciones |
| **F7 — Validación** | S11 | Sesiones con usuarios y análisis |
| **F8 — Estabilización y entrega** | S12–S13 | Correcciones, release candidate, documentación final |

**Transversal desde S2:** curación de contenido (~69 h) y documentación continua.

---

## 33. Sprints

Sprints de una semana, lunes a domingo.

| ID | Fechas | Objetivo | Horas | Entregable verificable |
|---|---|---|---|---|
| **S1** | 31 ago – 6 sep | Fundación técnica | 25 | Proyecto inicializado, tema con contraste AA, `LocalStorage`, `ContentRepository` |
| **S2** | 7 – 13 sep | Onboarding y perfil | 28 | Primer flujo completo: bienvenida → condición → disclaimer → persistido |
| **S3** | 14 – 20 sep | Hábitos (base) — *Fiestas Patrias* | 18 | Listado por condición, marcado, persistencia |
| **S4** | 21 – 27 sep | Rachas y cierre de hábitos | 30 | Racha correcta en todos los casos límite, con tests |
| **S5** | 28 sep – 4 oct | Métricas: registro y persistencia | 30 | Glucosa, presión y peso persistidos y recuperables |
| **S6** | 5 – 11 oct | Métricas: historial y tendencia | 30 | Historial cronológico, gráfico, eliminación |
| **S7** | 12 – 18 oct | Módulo de recetas — *feriado 12 oct* | 26 | Catálogo por momento de comida, detalle, imágenes locales |
| **S8** | 19 – 25 oct | Módulo de ejercicio | 30 | Biblioteca, rutinas, contraindicaciones, registro vía hábitos |
| **S9** | 26 oct – 1 nov | Integración diaria | 30 | Dashboard "Hoy", notificación, respaldo |
| **S10** | 2 – 8 nov | Calidad y privacidad | 28 | "Sobre tus datos" verificada, borrado, accesibilidad, modo avión |
| **S11** | 9 – 15 nov | Validación con usuarios | 28 | 4 sesiones ejecutadas, hallazgos priorizados |
| **S12** | 16 – 22 nov | Correcciones | 26 | Hallazgos críticos resueltos, release candidate |
| **S13** | 23 – 29 nov | Estabilización y cierre | 20 | Documentación final, evidencia completa, APK firmado |
| — | **30 nov** | **Entrega** | — | — |

### Detalle de sprints críticos

**S1 — Fundación (31 ago – 6 sep)**
- Inicializar proyecto y `git config`; `analysis_options` estricto; tokens de color con contraste medido; escala tipográfica; `LocalStorage` + claves + migración; `ContentRepository`; `app_router` con shell de 5 pestañas
- **Bloqueo raíz de todo lo demás**
- Tests: serialización de ida y vuelta, lectura con clave inexistente
- ~18 commits esperados · Hito **H2**

**S4 — Rachas (21 – 27 sep)**
- Sprint de mayor riesgo técnico: el bug de rachas anterior vivía aquí
- Los 7 casos límite obligatorios, incluido cambio manual de hora
- El recálculo desde historial debe coincidir con el caché
- Hito **H4**

**S8 — Ejercicio (19 – 25 oct)**
- Reutiliza `HabitCompletion` (RF-35); **no crea sistema de rachas paralelo**
- Contraindicaciones renderizadas **antes** de los pasos
- **Cierre de la validación profesional** solicitada en S1-S4
- Hito **H7**

**S11 — Validación (9 – 15 nov)**
- 4 personas del público objetivo, sesiones de ~45 min
- Protocolo preparado en S10, no improvisado
- Foco: usabilidad, comprensión, legibilidad, percepción de utilidad diaria
- Hallazgos en crítico / mayor / menor / mejora futura. **Solo críticos y mayores entran a S12**
- Hito **H10**

---

## 34. Carta Gantt

```
                        SEP              OCT              NOV
                  S1 S2 S3 S4 S5 S6 S7 S8 S9 10 11 12 13
F0 Planificación  ##
F1 Fundación      ####.
F2 Onboarding        ###
F2 Hábitos              ######
F3 Métricas                    ######.
F4 Recetas                        ######
F4 Ejercicio                        #####
F5 Dashboard/rot.                      ####
F5 Notificaciones                      ###
F5 Respaldo                            ##.
F6 Privacidad                             ###
F6 Accesibilidad                          ###
F7 Validación                                ####
F8 Correcciones                                 ####
F8 Cierre/entrega                                  ###
---------------------------------------------------------
CURACIÓN          ~~~~~~~~~~~~~~~~~~~~~~~~
DOCUMENTACIÓN     ==========================
TESTING              ======================
CONTINGENCIA                                    ......
HITOS             H2 H3    H4    H5 H6 H7 H8 H9 H10 H11 H12
```

### Detalle por semana

| Sem | Fechas | Foco principal | Curación | Docs/Test | Total | Hito |
|---|---|---|---|---|---|---|
| 1 | 31/08 – 06/09 | Fundación técnica | — | 4 h | 25 h | H1, H2 |
| 2 | 07/09 – 13/09 | Onboarding + condición | 6 h | 4 h | 28 h | H3 |
| 3 | 14/09 – 20/09 | Hábitos base *(feriado)* | 5 h | 3 h | 18 h | — |
| 4 | 21/09 – 27/09 | Rachas + tests | 7 h | 5 h | 30 h | **H4** |
| 5 | 28/09 – 04/10 | Métricas: registro | 8 h | 5 h | 30 h | — |
| 6 | 05/10 – 11/10 | Métricas: historial | 8 h | 5 h | 30 h | **H5** |
| 7 | 12/10 – 18/10 | Recetas *(feriado)* | 9 h | 4 h | 26 h | **H6** |
| 8 | 19/10 – 25/10 | Ejercicio | 9 h | 5 h | 30 h | **H7** |
| 9 | 26/10 – 01/11 | Dashboard, notif., respaldo | 8 h | 5 h | 30 h | **H8** |
| 10 | 02/11 – 08/11 | Privacidad y accesibilidad | 5 h | 8 h | 28 h | **H9** |
| 11 | 09/11 – 15/11 | Validación con usuarios | 2 h | 8 h | 28 h | **H10** |
| 12 | 16/11 – 22/11 | Correcciones | 2 h | 6 h | 26 h | **H11** |
| 13 | 23/11 – 29/11 | Cierre y documentación | — | 12 h | 20 h | — |
| — | **30/11** | **Entrega** | | | | **H12** |

**Semanas con capacidad reducida:** S3 (18-19 sep) y S7 (12 oct), planificadas con menos carga desde el inicio.

**Reserva:** S12 y S13 suman 46 h, de las cuales solo ~25 h son trabajo comprometido.

---

## 35. Hitos

| ID | Hito | Fecha | Criterio objetivo |
|---|---|---|---|
| **H1** | Planificación aprobada | 01/09 | Plan revisado; primera tarea identificada |
| **H2** | Fundación técnica operativa | 06/09 | Compila e instala; navegación entre 5 pestañas; un dato sobrevive al reinicio; `git shortlog` con un solo autor |
| **H3** | Primer flujo completo | 13/09 | Onboarding de punta a punta; al reabrir no se repite; la condición persiste |
| **H4** | Hábitos y rachas verificados | 27/09 | Hábitos diferenciados; racha correcta en los 7 casos límite; recálculo coincide con caché |
| **H5** | Métricas con historial real | 11/10 | Los tres tipos persisten; historial cronológico; gráfico con 0, 1 y N puntos; **ninguna pantalla clasifica valores** |
| **H6** | Recetas operativas | 18/10 | ≥24 recetas en 3 momentos; imágenes locales < 80 KB; todas con fuente; funciona en modo avión |
| **H7** | Ejercicio operativo y contenido validado | 25/10 | ≥28 ejercicios y ≥12 rutinas; contraindicaciones visibles; registro vía hábitos; **evidencia de validación profesional** |
| **H8** | MVP funcional completo | 01/11 | Dashboard con receta y rutina del día; notificación programada; respaldo exportado e importado |
| **H9** | Calidad y privacidad verificadas | 08/11 | Checklist de accesibilidad completo; "Sobre tus datos" coincide con `storage_keys`; borrado sin residuos; video modo avión; `flutter analyze` limpio; cobertura ≥70% |
| **H10** | Validación ejecutada | 15/11 | ≥3 sesiones (meta 4); hallazgos documentados y priorizados |
| **H11** | Release candidate | 22/11 | Críticos y mayores resueltos; APK firmado en dispositivo limpio; sin regresiones |
| **H12** | Entrega final | 30/11 | Documentación completa; trazabilidad al 100% de MUST; evidencia archivada; **historial con un solo autor verificado** |

---

## 36. Dependencias

```
LocalStorage ─────┬──→ UserProfile ──→ HealthCondition ──┬──→ Hábitos ──→ Rachas
                  │                                      │       │
                  ├──→ MetricRecord ──→ Historial ──→ Tendencia  │
                  │                                      │       ↓
                  ├──→ Favoritos                         │  Registro de rutina
                  │                                      │       ↑
                  └──→ Respaldo ←── (todos los datos)     │       │
                                                          │       │
ContentRepository ─┬──→ Recomendaciones ──────────────────┤       │
                   ├──→ Educación ─────────────────────────┤      │
                   ├──→ Recetas ───────────────────────────┼──┐   │
                   └──→ Ejercicios ──→ Rutinas ────────────┴──┼───┘
                                                              │
Curación de contenido ──→ (alimenta todo lo anterior)          │
                                                               ↓
DailyRotationService ──────────────────────────→ Dashboard "Hoy"
                                                               │
Validación profesional ──→ Contenido `high` ───────────────────┤
                                                               ↓
                                               Validación con usuarios
                                                               ↓
                                                     Correcciones → Entrega
```

### Bloqueos duros

| Elemento | Bloquea a |
|---|---|
| `LocalStorage` | Todo lo que persiste |
| `HealthCondition` + perfil | Todo el contenido diferenciado |
| `ContentRepository` | Recetas, ejercicio, educación, recomendaciones |
| `HabitCompletion` | Rachas **y registro de rutinas** (RF-35) |
| Curación de contenido | Los módulos se ven vacíos sin ella |
| App funcionando | Validación con usuarios |

> **Dependencia oculta:** ejercicio depende de hábitos por RF-35. Si hábitos se atrasa, ejercicio se atrasa con él. Es la razón de que hábitos ocupe dos sprints (S3-S4).

---

## 37. Camino crítico

```
Fundación → Perfil/Condición → Hábitos → Rachas → Ejercicio →
Contenido validado → Dashboard → Validación usuarios → Correcciones → Entrega
```

Con un solo desarrollador casi todo es serial. El análisis útil no es "qué está en el camino crítico" sino **qué se puede sacrificar y qué no**.

### No pueden retrasarse

| Elemento | Consecuencia del atraso |
|---|---|
| `LocalStorage` (S1) | Bloquea el 100% del proyecto |
| Perfil y condición (S2) | Bloquea todo el contenido diferenciado |
| Hábitos y rachas (S3-S4) | Bloquea ejercicio; retrasa el camino completo |
| **Solicitud de validación profesional** | Ver abajo |
| Fin del MVP funcional (S9) | Sin app funcionando no hay validación |
| Validación con usuarios (S11) | Sin ella falta un objetivo específico completo |

### La única dependencia externa

> **La validación profesional del contenido es lo único que no depende del esfuerzo propio.** Depende de que un profesional de salud tenga tiempo, y tiene el plazo de espera más largo del proyecto.

**Se solicita en la semana 1** (idealmente) **y a más tardar en la 4**, no en la 8. Si en la semana 6 no hay confirmación, se activa la contingencia: todo el contenido `high` sale del MVP y se documenta como limitación explícita.

### Paralelizables

- Curación de contenido — continuo desde S2, independiente del código
- Documentación y ADRs — junto a las decisiones
- Diagramas de arquitectura — desde S1
- Protocolo de validación — S10
- Búsqueda y licenciamiento de imágenes — cualquier momento

### Sacrificables sin destruir el MVP

Palancas 1→6, en el orden definido en la advertencia de presupuesto.

### Posponibles al final

Notificaciones (S9) y respaldo (S9) son autocontenidos y no bloquean nada. Pueden moverse a S12. **Son el amortiguador estructural del plan.**

### Lo que jamás se sacrifica

| Elemento | Razón |
|---|---|
| Persistencia real de lo que se declara guardado | Lección L1; falsearlo invalida el proyecto |
| Trazabilidad del contenido de salud | Sin fuente, el contenido es indefendible |
| Ausencia de clasificación clínica | Riesgo ético y legal |
| Coherencia de "Sobre tus datos" | Es la contradicción que el proyecto vino a corregir |
| Accesibilidad base | Es el diferenciador declarado |
| **Autoría única de los commits** | Es la razón del reinicio completo |


---

# PARTE VI — RIESGOS Y ARRANQUE

## 38. Matriz de riesgos

| ID | Riesgo | Prob. | Imp. | Nivel | Mitigación | Contingencia |
|---|---|---|---|---|---|---|
| **R1** | **Presupuesto sin holgura** (345 h sobre 349 h) | Alta | Alto | **Crítico** | Palancas pre-designadas; S12-S13 con reserva; revisión cada viernes | Activar palancas 1→6 en orden |
| **R2** | **Validación profesional no se consigue** | Media | Alto | **Crítico** | Solicitar en S1-S4; contactar 2-3 profesionales en paralelo; red de carreras de salud DuocUC | Contenido `high` sale del MVP; doble condición limitada a temas convergentes; documentado como limitación |
| **R3** | **Curación de contenido subestimada** (69 h) | Alta | Alto | **Crítico** | Arranca en S2; 30 recetas comprometidas y 51 como excedente; plantillas desde el día 1 | Bajar a 24 recetas y 28 ejercicios (palancas 4-5) |
| **R4** | Bug de rachas se repite | Media | Alto | Alto | 7 casos límite obligatorios en S4; racha recalculable | Simplificar: días consecutivos con ≥1 hábito, sin variantes |
| **R5** | Ejercicio se convierte en módulo paralelo | Media | Medio | Alto | RF-35 reutiliza `HabitCompletion`; revisión en la DoD de S8 | Registro como hábito genérico "actividad física" |
| **R6** | **Carga académica no prevista** | Alta | Medio | Alto | Revisión semanal de capacidad; S3 y S7 ya aligeradas | Mover notificaciones y respaldo a S12; activar palancas |
| **R7** | Licenciamiento de imágenes bloquea el contenido | Media | Medio | Alto | Solo bancos libres verificados; registro obligatorio antes de commitear | Ilustraciones propias simples o placeholders tipográficos |
| **R8** | Peso de assets desborda | Media | Bajo | Medio | WebP obligatorio, ≤80 KB, verificado en la DoD | Recomprimir por lote |
| **R9** | Notificaciones fallan por restricciones de Android 14 | Media | Bajo | Medio | Recordatorio **inexacto** desde el diseño; sin `SCHEDULE_EXACT_ALARM` | Recordatorio dentro de la app al abrirla |
| **R10** | Reclutamiento de usuarios se retrasa | Media | Medio | Medio | Buscar participantes en S8, agendar en S10 | Reducir a 3 sesiones |
| **R11** | Hallazgos de validación exigen rediseño mayor | Baja | Alto | Medio | Validar pantallas antes de implementar; accesibilidad resuelta en S10 | Solo críticos y mayores a S12; el resto a "mejoras futuras" |
| **R12** | Documentación se acumula para el final | Media | Medio | Medio | Rutina de fin de sesión; DoD exige docs por tarea | 12 h reservadas en S13 |
| **R13** | Pérdida de trabajo | Baja | Alto | Medio | Push a GitHub al menos diario | Recuperar desde el último push |
| **R14** | SharedPreferences resulta insuficiente | Baja | Medio | Bajo | ~130 KB anuales; umbral 1 MB; `schemaVersion` desde el día 1 | Migrar a `hive`; el repositorio aísla el cambio |
| **R15** | **Un commit ajeno entra al historial** | Baja | **Crítico** | Alto | `git config` verificado en S1; **nunca desarrollar en equipo compartido ni con sesión de otra persona**; `git shortlog` en cada cierre de fase | Reescritura de historial (costosa y visible). **Este riesgo no se gestiona, se evita** |
| **R16** | Alcance crece durante el desarrollo | Media | Alto | Alto | Procedimiento de control de alcance (§43) | Congelar alcance desde S9 sin excepción |
| **R17** | Fatiga por ritmo sostenido | Media | Alto | Alto | Ritmo distribuido; S3 y S7 aligeradas; medición objetiva evita el trabajo ansioso | Activar palancas antes de extender jornadas. **Recortar alcance es más barato que perder una semana** |

> **R1, R2 y R3 comparten causa:** el proyecto está lleno hasta el borde. Se gestionan con las mismas herramientas — recortes pre-designados y arranque temprano — y por eso las revisiones semanales son el sistema de alerta, no burocracia.

---

## 39. Plan de contingencia

### Escenario A — Normal (avance ≥ 90%)

**Se entrega:** MVP completo con los módulos MUST, 30 recetas, 35 ejercicios y 12 rutinas, gráfico de tendencia, notificaciones, respaldo exportable, SHOULD implementados, accesibilidad verificada pantalla por pantalla, validación profesional y con 4 usuarios, documentación y trazabilidad completas.

**Si sobra tiempo, en este orden:** recetas hacia la meta de 51 → cuarto momento de comida (cena) → favoritos de rutinas → pulido visual. **Nunca** funcionalidad nueva no planificada.

### Escenario B — Retraso moderado (avance 70-89%, ~2 semanas perdidas)

**Se activan las palancas 1 a 5** (~28 h recuperadas):

| Sale | Queda |
|---|---|
| Favoritos de rutinas | Todos los módulos MUST completos |
| Búsqueda y favoritos de recetas | 24 recetas (8 por momento) |
| Filtros de contenido | 28 ejercicios y 12 rutinas |
| Recetas 30 → 24 | Gráfico de tendencia |
| Ejercicios 35 → 28 | Validación con 3 usuarios |

**Se conserva íntegro:** persistencia real, trazabilidad, ausencia de clasificación clínica, accesibilidad, coherencia de privacidad.

**Disparador:** cierre de S8 (25 oct) sin H7 cumplido.

### Escenario C — Retraso grave (avance < 70%, ~4 semanas perdidas)

**MVP mínimo defendible** — la app más pequeña que sigue siendo EIRA.

| Se conserva | Por qué |
|---|---|
| Onboarding + condición (DM2 / HTA / **ambas**) | Sin personalización no hay proyecto |
| Hábitos + rachas | Núcleo de adherencia |
| Métricas: registro e **historial en lista** | Se sacrifica el gráfico, no el dato |
| Recetas: **15** (5 por momento) + detalle | Conserva el valor diario |
| Ejercicio: **15 ejercicios, 6 rutinas** | Con contraindicaciones intactas |
| Contenido de doble condición | **El diferenciador. Se recorta volumen, nunca la existencia** |
| "Sobre tus datos" + borrado total | Requisito legal y ético |
| Accesibilidad base | Diferenciador declarado |
| Validación con 3 usuarios | Objetivo específico OE9 |

| Se elimina | Horas recuperadas |
|---|---|
| Notificaciones | 14 h |
| Respaldo exportable | 10 h |
| Gráfico de tendencia | 8 h |
| Todos los SHOULD y COULD | 19 h |
| Volumen de contenido | ~28 h |
| **Total** | **~79 h** |

**Disparador:** cierre de S9 (1 nov) sin H8 cumplido.

> **Regla transversal a los tres escenarios:** ante la duda, se recorta **volumen de contenido**, no **calidad de lo existente**. Quince recetas bien fundamentadas defienden el proyecto; cincuenta sin fuente lo hunden.

---

## 40. Métricas de avance

| Indicador | Fórmula | Meta al 30/11 |
|---|---|---|
| Requisitos MUST completados | cumplen criterio / total MUST | **100%** |
| Hitos alcanzados en fecha | alcanzados / planificados a la fecha | ≥ 90% |
| Tareas cerradas con DoD | tareas DoD ✅ / tareas del sprint | ≥ 90% por sprint |
| Cobertura de lógica de negocio | `flutter test --coverage` | ≥ 70% |
| Casos P0 cubiertos | tests P0 / casos P0 definidos | **100%** |
| Contenido curado | ítems `reviewed`+ / comprometidos | 100% del compromiso |
| Contenido `high` validado | `validated` / total `high` | **100%** |
| Pantallas con checklist de accesibilidad | ✅ / pantallas del MVP | **100%** |
| Trazabilidad | requisitos MUST completos en matriz / total | **100%** |
| Bugs abiertos críticos y mayores | conteo | **0** |
| **Autoría del historial** | autores distintos en `git shortlog` | **1** |
| Commits acumulados | conteo | 250-400 |

### Fórmula de avance global

```
Avance = 0,40 × (requisitos MUST completos)
       + 0,25 × (contenido curado)
       + 0,20 × (tests P0 cubiertos)
       + 0,15 × (documentación y trazabilidad al día)
```

> El contenido pesa 25% porque es el 21% del esfuerzo. Medir avance solo por código produciría un 80% en la semana 9 con la app vacía — que es exactamente cómo se pierde un proyecto.

### Revisión semanal (viernes, 20 minutos)

- [ ] Avance real vs. planificado
- [ ] Horas trabajadas vs. 27 h
- [ ] Bugs abiertos
- [ ] Contenido curado esta semana
- [ ] ¿Se cumplió el hito previsto?
- [ ] **¿Hay que activar una palanca?**

> Dos semanas consecutivas bajo el 80% del plan → activar Escenario B sin esperar al disparador formal.

---

## 41. Backlog inicial

Prioridad: P0 crítica, P1 alta, P2 media, P3 baja. Estimaciones en horas.

### Sprint 1 — Fundación

| ID | Tarea | Pri | Est | Dep | Criterio de aceptación |
|---|---|---|---|---|---|
| T-001 | Inicializar proyecto Flutter y estructura de carpetas | P0 | 2 | — | Compila; estructura E1-E7 respetada |
| T-002 | **Configurar `git config` y verificar autoría** | P0 | 0,5 | T-001 | `git shortlog` muestra un solo autor |
| T-003 | Configurar `analysis_options.yaml` estricto | P0 | 1 | T-001 | `flutter analyze` sin warnings |
| T-004 | Tokens de color con contraste AA verificado | P0 | 4 | T-001 | Ratios medidos y documentados; primario corregido |
| T-005 | Escala tipográfica (6 tamaños, mínimo 14 sp) | P0 | 2 | T-004 | `app_typography.dart` completo |
| T-006 | Implementar `LocalStorage` + `storage_keys` | P0 | 5 | T-001 | Escritura y lectura tipada; único acceso a prefs |
| T-007 | Implementar `schema_migration` | P1 | 2 | T-006 | Instalación nueva y versión antigua manejadas |
| T-008 | Tests de serialización ida y vuelta | P0 | 3 | T-006 | Vacío, completo, campo faltante, JSON malformado |
| T-009 | `ContentRepository` + implementación de assets | P0 | 4 | T-001 | Interfaz lista para fuente remota futura |
| T-010 | `app_router` con shell de 5 pestañas | P0 | 4 | T-001 | Navegación entre pantallas vacías |
| T-011 | Declarar `allowBackup="false"` + ADR-006 | P0 | 1 | T-001 | Manifest y decisión documentada |
| T-012 | Estructura de `docs/` + ADR-001 a 004 | P1 | 3 | — | Carpetas creadas, ADRs redactados |

### Sprint 2 — Onboarding

| ID | Tarea | Pri | Est | Dep | Criterio de aceptación |
|---|---|---|---|---|---|
| T-013 | Modelo `UserProfile` + serialización | P0 | 3 | T-006 | Año de nacimiento, no fecha completa |
| T-014 | Enum `HealthCondition` | P0 | 1 | — | `both` es valor propio |
| T-015 | Pantalla de bienvenida | P0 | 3 | T-010 | Solo en el primer inicio |
| T-016 | Datos básicos con validación | P0 | 4 | T-013 | Máx. 3 campos; errores comprensibles |
| T-017 | Selección de condición | P0 | 4 | T-014 | Tres opciones; áreas táctiles ≥56 dp |
| T-018 | Disclaimer con aceptación registrada | P0 | 3 | T-013 | No se puede omitir; fecha persistida |
| T-019 | Redirección inicial | P0 | 2 | T-015 | Sin parpadeo (< 300 ms) |
| T-020 | `UserProvider` + repositorio de perfil | P0 | 4 | T-013 | Estado loading/ready/error explícito |
| T-021 | Perfil y edición de condición | P0 | 5 | T-020 | Cambiar condición invalida contenido derivado |
| T-022 | Tests de persistencia de perfil | P0 | 2 | T-020 | Sobrevive a cierre forzado |

### Sprints 3-4 — Hábitos y rachas

| ID | Tarea | Pri | Est | Dep | Criterio de aceptación |
|---|---|---|---|---|---|
| T-023 | `HabitDefinition` + JSON por condición | P0 | 4 | T-009 | Con `SourceMetadata`; sin duplicados en `both` |
| T-024 | `HabitCompletion` + repositorio | P0 | 4 | T-006 | Persistencia por fecha |
| T-025 | `HabitsProvider` con resolución por condición | P0 | 4 | T-023 | `both` devuelve contenido `both`, no concatenación |
| T-026 | Pantalla de hábitos con marcado | P0 | 6 | T-025 | Cambio inmediato y persistido |
| T-027 | Reinicio diario automático | P0 | 3 | T-024 | Primer inicio del día limpia marcas |
| T-028 | `StreakService` (función pura, recalculable) | P0 | 6 | T-024 | Recálculo coincide con caché |
| T-029 | **Tests de rachas — 7 casos límite** | P0 | 5 | T-028 | Todos en verde |
| T-030 | Visualización de racha actual y mejor | P1 | 3 | T-028 | La mejor nunca decrece |
| T-031 | **Contactar profesionales para validación** | P0 | 2 | — | ≥2 contactos; disponibilidad confirmada |

### Sprints 5-6 — Métricas

| ID | Tarea | Pri | Est | Criterio de aceptación |
|---|---|---|---|---|
| T-032 | Modelo `MetricRecord` | P0 | 3 | Sin campo de clasificación |
| T-033 | `MetricsRepository`, claves separadas por tipo | P0 | 4 | Escribir peso no reescribe glucosa |
| T-034 | Formulario de glucosa | P0 | 5 | Contexto ayuno/postprandial; validación al confirmar |
| T-035 | Formulario de presión arterial | P0 | 4 | Sistólica y diastólica; rango plausible |
| T-036 | Formulario de peso | P0 | 3 | Registro histórico, no sobrescribe perfil |
| T-037 | Confirmación solo si persistió | P0 | 2 | Lección L1 verificada con test |
| T-038 | Historial cronológico | P0 | 6 | Estado vacío explicado |
| T-039 | Eliminación de registro | P0 | 3 | Confirmación con verbos claros |
| T-040 | Gráfico de tendencia | P1 | 8 | Funciona con 0, 1 y N puntos |
| T-041 | Tests de métricas y casos límite | P0 | 4 | Vacío, 1 registro, 200 registros |
| T-042 | Priorización de métricas por condición | P1 | 3 | Ninguna se oculta por completo |

### Sprints 7-9 — Módulos diarios

| ID | Tarea | Pri | Est |
|---|---|---|---|
| T-043..T-050 | Recetas: modelo, repositorio, catálogo por momento, detalle, imágenes, tests | P0 | 26 |
| T-051..T-059 | Ejercicio: biblioteca, rutinas, contraindicaciones, registro vía hábitos, tests | P0 | 30 |
| T-060..T-063 | Educación y recomendaciones: pantallas, detalle, fuente visible | P0 | 14 |
| T-064 | `DailyRotationService` (función pura, determinista) | P0 | 4 |
| T-065..T-068 | Dashboard "Hoy": progreso, racha, receta y rutina del día | P0 | 12 |
| T-069..T-071 | Notificaciones: permiso, programación inexacta, configuración | P1 | 14 |
| T-072..T-074 | Respaldo: exportar, importar, validación de esquema | P1 | 10 |

### Transversal — Curación de contenido (desde S2)

| ID | Tarea | Pri | Est |
|---|---|---|---|
| C-001 | **Análisis de doble condición: convergencias y tensiones** | P0 | 8 |
| C-002 | 30 recetas con fuente y nota nutricional | P0 | 20 |
| C-003 | 35 fichas de ejercicio con contraindicaciones | P0 | 18 |
| C-004 | 12 rutinas compuestas | P0 | 4 |
| C-005 | 24 recomendaciones (incluye set `both` propio) | P0 | 9 |
| C-006 | 15 artículos educativos | P0 | 6 |
| C-007 | ~85 imágenes: búsqueda, licencia, WebP, registro | P0 | 12 |
| C-008 | Registro de curación y créditos de imagen | P0 | 4 |

**Total backlog: ~345 h.**

---

## 42. Checklist previo al desarrollo

### Respuestas al checklist de preparación

| Pregunta | Respuesta |
|---|---|
| ¿Está definido qué vamos a construir? | ✅ 43 RF, 25 RNF, MVP definitivo |
| ¿Está definido qué NO vamos a construir? | ✅ §14, con razón por ítem |
| ¿Está definido por qué? | ✅ Cada exclusión justificada; ADRs previstos |
| ¿La arquitectura está justificada? | ✅ 4 alternativas evaluadas; Repository justificado por 3 defectos auditados |
| ¿Las dependencias están justificadas? | ✅ Marginales eliminadas; nuevas requieren ADR |
| ¿El modelo de datos está definido? | ✅ 5 entidades de usuario, 6 de contenido, 5 descartadas con razón |
| ¿La persistencia está definida? | ✅ Claves, serialización, migración, límites, respaldo |
| ¿La navegación está definida? | ✅ 5 pestañas, mapa de rutas, 6 reglas |
| ¿El MVP puede terminarse antes del 30/11? | ⚠️ **Sí, pero sin margen.** Depende de sostener el ritmo y activar palancas ante el primer atraso |
| ¿Existe tiempo de contingencia? | ⚠️ **Insuficiente de origen (1%).** Elevado a ~11,5% mediante palancas |
| ¿Existe camino crítico? | ✅ Identificado, con dependencia externa señalada |
| ¿Sabemos qué sacrificar? | ✅ 6 palancas en orden + 3 escenarios con disparadores por fecha |
| ¿Está definido el testing? | ✅ Priorizado por riesgo, casos límite explícitos, metas cuantitativas |
| ¿Está definida la privacidad? | ✅ Ley 19.628 y 21.719; 8 principios con implementación concreta |
| ¿Está definido el contenido médico? | ✅ Fuentes, ciclo de vida, sensibilidad, registro |
| ¿Está contemplada la doble condición? | ✅ `both` como valor propio; proceso de 6 pasos; validación obligatoria |
| ¿Está contemplada la validación con usuarios? | ✅ S11, 4 sesiones, protocolo en S10 |
| ¿Existe estrategia de commits? | ✅ Convención, 8 reglas, verificación de autoría por fase |
| ¿Existe trazabilidad académica? | ✅ Matriz + estructura `docs/` de 10 carpetas |
| ¿Sabemos qué evidencia guardar? | ✅ 13 tipos, con momento y ubicación |
| ¿Existe backlog inicial? | ✅ ~74 tareas de código + 8 de curación |
| ¿La primera tarea está identificada? | ✅ **T-001** |

### Antes del primer commit

- [ ] Flutter SDK actualizado y `flutter doctor` sin errores
- [ ] Dispositivo Android físico configurado para depuración
- [ ] Repositorio nuevo creado en GitHub, **vacío**
- [ ] **`git config user.name` y `user.email` verificados** ← antes de nada
- [ ] Herramienta de verificación de contraste elegida
- [ ] Guías MINSAL de DM2 e HTA descargadas
- [ ] Al menos un profesional de salud contactado (T-031)
- [ ] Bloques de trabajo semanales agendados

### La primera tarea

> **T-001 — Inicializar el proyecto Flutter y crear la estructura de carpetas**
>
> `flutter create` con el nombre de paquete definitivo, creación de `core/` y `features/` según §20, borrado del contador de ejemplo, verificación de que compila e instala en el dispositivo físico.
>
> **Commit:** `chore(setup): initialize flutter project structure`
>
> Inmediatamente después, **T-002**: `git config` y captura de `git shortlog -sne` como primera evidencia del proyecto.

---

## 43. Control del alcance

Durante todo el proyecto, **no se incorporan funcionalidades automáticamente**. Cuando aparece una idea nueva:

1. Documentarla en el backlog
2. Evaluar valor para el usuario
3. Evaluar esfuerzo en horas
4. Evaluar riesgo
5. Evaluar impacto en el calendario
6. Decidir si entra al MVP
7. **Si no entra, va a Future/Backlog** — no queda "pendiente de decisión"

**Congelamiento de alcance: desde S9 (26 de octubre), sin excepción.** A partir de esa fecha solo entran correcciones, nunca funcionalidad.

### No sobreingeniería

No se agregan patrones, dependencias, backend ni abstracciones sin razón documentada. **Cada decisión técnica tiene un ADR o no se toma.** El proyecto debe ser suficientemente profesional para defenderlo y suficientemente simple para terminarlo.

### Calidad

No se aplica el criterio "si funciona, no lo toques". Cuando se detecte código duplicado, deuda técnica, solución frágil, responsabilidad mal ubicada o problema de mantenibilidad, y sea seguro y justificable corregirlo, se corrige y se documenta.

---

# ANEXO A — Evidencia detallada de la auditoría

Repositorio: `Frangarcia0/autocuidado_app`, rama `master`. Auditoría realizada el 31 de agosto de 2026.

## A.1 Historial de commits

- 16 commits entre el 11 y el 30 de mayo de 2026
- **13 commits (81%)** de `Tetelar <estelasepulveda1528@gmail.com>`
- 3 commits de `Frangarcia0`
- Una sola rama (`master`), sin etiquetas
- Mensajes agrupados y repetidos: `"Sprint MVP-2 al MVP-4"` tres veces consecutivas; `"Sprint MVP-6"` dos veces
- Cero commits de tipo `test:` o `docs:`

## A.2 Tamaño y distribución del código

| Archivo | Líneas |
|---|---|
| `home_page.dart` | 1.793 |
| `exercise_page.dart` | 996 |
| `edit_profile_page.dart` | 735 |
| `profile_page.dart` | 617 |
| `recipes_page.dart` | 570 |
| **Subtotal (5 archivos)** | **4.711 (58%)** |
| Total del proyecto | ~8.127 en 41 archivos |

## A.3 Código muerto (0 imports)

| Archivo | Líneas | Nota |
|---|---|---|
| `lib/shared/data/recommendations_data.dart` | 320 | Reemplazado por JSON; contiene el comentario que describe la intención correcta de doble condición |
| `lib/shared/widgets/recommendation_card.dart` | 120 | Duplicado exacto del de `features/`, salvo dos espacios |
| `lib/shared/widgets/section_card.dart` | 43 | — |
| **Total** | **483** | |

## A.4 Métricas de salud sin persistencia

Los formularios de glucosa, presión y agua eran clases privadas dentro de `home_page.dart`. El historial era una lista literal con valores `'--'`. La función de guardado ejecutaba `setState`, mostraba un mensaje de confirmación y descartaba el dato. Solo el peso se guardaba, sobrescribiendo el campo del perfil, sin historial.

## A.5 Interpretación clínica hardcodeada

Umbrales de clasificación de presión arterial ("etapa 1", "etapa 2 — consulta tu médico") incrustados en un widget privado, sin fuente documentada ni fecha de revisión.

## A.6 Doble condición como concatenación

Los providers de recomendaciones y educación resolvían `both` agregando la lista de diabetes y después la de hipertensión. Sin deduplicación, sin resolución de conflictos, sin contenido propio. Los tres providers de contenido capturaban excepciones asignando lista vacía, sin log ni estado de error.

## A.7 Contradicción de privacidad

`privacy_page.dart` afirmaba no solicitar datos clínicos como glucosa o presión, mientras el Home los registraba. Omitía estatura, peso, género y fecha de nacimiento, efectivamente almacenados, y no mencionaba la función de compartir informe mediante `Share.share`.

## A.8 Dependencia de red en contenido

- `exercise_page.dart`: imágenes de rutinas mediante `Image.network` desde URLs remotas
- `recipes.json`: dos campos competidores, `image` (asset) e `imageUrl` (remoto)
- `recipes_page.dart` usaba el remoto; `recipe_detail_page.dart` el local
- Solo 4 fotos de recetas existían localmente

## A.9 Assets sin optimizar

| Archivo | Peso |
|---|---|
| `icon_recipes.png` | 576 KB |
| `recipe_quinoa.jpg` | 508 KB |
| `icon_education.png` | 381 KB |
| `icon_water.png` | 314 KB |
| `eira_isotype.png.bak.jpg` | 23 KB (archivo de respaldo commiteado) |

Total: ~2,8 MB en 12 archivos, promedio 233 KB por archivo.

## A.10 Estilos y accesibilidad

- 259 literales `Color(0xFF…)`, con 56 valores distintos, frente a 10 tokens definidos en `AppColors`
- 16 tamaños de fuente distintos; 45 usos ≤ 12 sp; mínimo 9 sp
- Cero usos de `Semantics`, `semanticLabel` o manejo de `textScaler`
- Primario `#979F80` con texto blanco: contraste aproximado 2.3:1 (AA exige 4.5:1)

## A.11 Persistencia inconsistente

`PreferencesService` centralizaba claves, pero `exercise_provider.dart` llamaba directamente a `SharedPreferences.getInstance()` y definía sus propias claves. `clearAll()` borraba las preferencias y navegaba al inicio, pero los providers conservaban su estado en memoria.

## A.12 Configuración de Android

`AndroidManifest.xml` no declaraba `android:allowBackup` ni reglas de respaldo, por lo que Android respaldaba las SharedPreferences a Google Drive por defecto. Solicitaba `SCHEDULE_EXACT_ALARM`, permiso restringido desde Android 14 para casos de uso de alarmas y calendario. `flutter_local_notifications` fijado en `17.2.4` sin caret, única dependencia con versión clavada y sin justificación documentada. Cuatro supresiones `// ignore: depend_on_referenced_packages` sobre dependencias efectivamente declaradas en `pubspec.yaml`.

## A.13 Testing

Un único archivo `test/widget_test.dart` con un test de cuerpo vacío y el comentario "por implementar en sprints futuros". Cobertura efectiva: 0%.

## A.14 No determinable

- Si la aplicación compila en su estado actual (no se ejecutó `flutter build`)
- Rendimiento real en dispositivo físico
- Origen de los umbrales clínicos utilizados: no existe ninguna referencia bibliográfica en el código ni en el contenido

---

*Fin del documento. Versión 1.0 — 31 de agosto de 2026.*
