# Documentación de EIRA

Índice de entrada a la documentación del proyecto. La estructura sigue el
**PLAN_MAESTRO §30 — Trazabilidad académica**.

EIRA es una app móvil Flutter/Android de apoyo al autocuidado para personas con
diabetes tipo 2, hipertensión arterial o **ambas condiciones**. Proyecto de
título (APT), DuocUC. Entrega: **30 de noviembre de 2026**.

---

## La cadena que esta documentación tiene que demostrar

```
Requisito → Tarea → Implementación → Prueba → Commit → Evidencia
  RF-13     T-042    streak_service   3 tests   a3f9c21   captura
```

Cada carpeta cubre un tramo de esa cadena. El documento que la recorre entera es
`requirements/traceability-matrix.md`, y se actualiza **al cerrar cada
requisito, no al final** (§30).

---

## Documentos raíz

| Archivo | Qué es |
|---|---|
| [`PLAN_MAESTRO.md`](PLAN_MAESTRO.md) | El plan completo: alcance, requisitos, diseño técnico, calidad, calendario y riesgos. **Ante cualquier duda de alcance, arquitectura o calendario, manda este documento** |
| [`../CLAUDE.md`](../CLAUDE.md) | Reglas operativas del día a día, derivadas del plan |

---

## Carpetas

| Carpeta | Contenido | Estado |
|---|---|---|
| `requirements/` | `functional.md`, `non-functional.md` y **`traceability-matrix.md`** — el documento clave del §30 | Vacía. Se llena al cerrar los primeros requisitos |
| `architecture/` | `overview.md`, `data-model.md`, `persistence.md`, `navigation.md` y los diagramas | Vacía. Los diagramas se agregan al diseñarse y al cambiar (§31) |
| `decisions/` | **ADRs numerados.** Toda decisión técnica no obvia (§28) | Activa — ver índice abajo |
| `content/` | `content-registry.md`, `image-credits.md`, `sources.md` y **`dual-condition-analysis.md`** | Vacía. Empieza con el primer ítem de contenido de salud |
| `testing/` | `strategy.md`, `manual-test-plan.md` y `results/` | Vacía. `results/` recibe el resultado de `flutter test` cada sprint |
| `accessibility/` | `rules.md`, `contrast-verification.md` y `screen-checklists/` | Parcial — `contrast-verification.md` existe desde T-004 |
| `privacy/` | `data-inventory.md` (fuente de la pantalla "Sobre tus datos") y `legal-analysis.md` (Ley 19.628 / 21.719) | Vacía. Se llena junto con la pantalla `/profile/data` |
| `validation/` | `protocol.md`, `findings.md` y `sessions/` | Vacía. Validación profesional en S8; sesiones con usuarios en S11 |
| `progress/` | Bitácora de trabajo: decisiones, bugs y su solución | Activa — una entrada por día con actividad |
| `evidence/` | `screenshots/`, `videos/`, `test-results/` | Parcial — capturas y evidencia de T-011 |

> Las carpetas vacías llevan un `.gitkeep` para existir en el repositorio. **No
> se rellenan con contenido de relleno**: una carpeta con un documento inventado
> es peor que una carpeta vacía con una tarea asignada.

### Nota sobre `progress/`

El §30 nombra los archivos de esta carpeta como `sprint-XX.md`. En la práctica se
usa **una entrada por fecha** (`AAAA-MM-DD.md`), que se ajusta mejor a la rutina
de fin de sesión del §31 —anotar el mismo día la decisión o el bug— y conserva el
orden cronológico real del trabajo. Es una divergencia deliberada respecto de la
letra del plan, no un descuido.

---

## Índice de decisiones (ADRs)

Formato obligatorio (§30): título, fecha, estado, contexto, **alternativas
evaluadas**, decisión y consecuencias **incluidas las negativas**.

> Un ADR que solo lista ventajas no es un análisis, es una justificación.

| # | Decisión | Origen |
|---|---|---|
| [001](decisions/ADR-001-feature-first.md) | Arquitectura feature-first con Repository Pattern y Provider | §19 · retroactivo |
| [002](decisions/ADR-002-local-only-storage.md) | Almacenamiento exclusivamente local, sin backend | §26 · retroactivo |
| [003](decisions/ADR-003-no-clinical-classification.md) | EIRA no clasifica valores clínicos | RF-22 · retroactivo |
| [004](decisions/ADR-004-shared-preferences.md) | `shared_preferences` como mecanismo de persistencia | §22 · retroactivo |
| 005 | Modelo de la biblioteca de ejercicio (`Routine` referencia `Exercise`) | §21 · **pendiente, sprint S8** |
| [006](decisions/ADR-006-disable-android-backup.md) | Desactivar el respaldo automático de Android | T-011 |
| [007](decisions/ADR-007-verificacion-reglas-estructurales.md) | Verificación de reglas estructurales sin dependencias de lint | T-003 |
| [008](decisions/ADR-008-primario-accesible.md) | Primario accesible: escala salvia derivada del color de marca | T-004 |
| [009](decisions/ADR-009-localstorage-generico.md) | `LocalStorage` genérico: el dominio vive en los repositorios | T-006 |
| [010](decisions/ADR-010-go-router-shell-con-estado.md) | `go_router` 18 y un shell con estado por pestaña | T-010 |

Los ADR **001 a 004** son documentación retroactiva: formalizan decisiones
tomadas en el plan maestro antes del primer commit. Los **006 a 010** documentan
decisiones tomadas al implementar. El §30 solo enumera hasta el 006 porque su
listado ilustra la estructura, no cierra el catálogo.

---

## Evidencia

Se recopila **durante** el desarrollo. Nunca se reconstruye al final (§31).

| Tipo | Cuándo | Dónde |
|---|---|---|
| Capturas de cada pantalla | Al completarla y al modificarla | `evidence/screenshots/` |
| Video de flujos completos y del **modo avión** | Al cerrar cada fase | `evidence/videos/` |
| Resultado de `flutter test` | Cada sprint | `evidence/test-results/` |
| Captura de `git shortlog -sne` | Cada cierre de fase | `evidence/` |
| Checklists de accesibilidad | Por pantalla | `accessibility/screen-checklists/` |
| Verificación de contraste | Al definir y al cambiar colores | `accessibility/contrast-verification.md` |
| Registro de bugs y su solución | Al ocurrir | `progress/` |
| Decisiones técnicas | Al tomarse | `decisions/` |
| Registro de contenido y licencias | Al crear cada ítem | `content/` |
| Validación profesional y con usuarios | S8 y S11 | `validation/` |
