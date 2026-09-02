# Tareas agregadas al backlog

Tareas que **no están en el §41** del plan maestro y aparecieron durante la
ejecución. El plan es un documento fechado y no se reescribe hacia atrás —mismo
criterio con el que el §22 conserva su redacción frente al `ADR-009` y el §41
frente a la errata de dependencias de T-014—, así que las tareas nuevas se
registran aquí y no allá.

Mismas columnas que el §41. Prioridad: P0 crítica, P1 alta, P2 media, P3 baja.
Estimaciones en horas. La columna **Origen** es la que el §41 no tiene, y es la
que hace falta aquí: dice de dónde salió la tarea, ya que no salió del plan.

## Sprint 2 — Onboarding

| ID | Tarea | Pri | Est | Dep | Criterio de aceptación | Origen |
|---|---|---|---|---|---|---|
| T-015c | Documento de referencia de diseño del proyecto anterior | P2 | 2 | T-013, T-014 | `docs/design/reference-legacy.md` con una sección por pantalla (Inicio, Perfil, Educación, Ejercicio, Recetas); cada patrón trasladable declara qué cambia al trasladarlo; cada exclusión cita la decisión que la cierra; distingue *rechazado* de *fuera de alcance*. **No toca `lib/`** | Revisión de capturas reales de `autocuidado_app` contra su código fuente, 2 sep 2026 |

---

**Qué cierra T-015c.** El §3 auditó qué estaba mal en el proyecto anterior; no
dejó escrito qué de lo que se veía bien vale la pena volver a hacer. Sin ese
documento, cada tarea de pantalla de T-016 en adelante vuelve a mirar las
capturas antiguas y a decidir de nuevo —o peor, repone un campo del perfil que
T-013 ya eliminó por minimización—.
