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
| T-015b | Branding: imágenes de marca e ícono de app | P2 | 3 | T-004, T-015c | Las siete imágenes de marca convertidas a WebP en `assets/branding/`, dentro de presupuesto (íconos ≤ 20 KB, ilustración ≤ 80 KB); cada una registrada en `docs/content/image-credits.md` con origen y fecha **antes** de entrar al repositorio; `pubspec.yaml` declara `assets/branding/`; `flutter_launcher_icons` como `dev_dependency` aplica el isotipo como ícono adaptativo de Android con fondo `AppColors.sage400`, documentado en ADR-012. **No toca `lib/`** | Diseño propio del autor, proyecto anterior `autocuidado_app`, traído y reprocesado el 2 sep 2026 |
| T-015c | Documento de referencia de diseño del proyecto anterior | P2 | 2 | T-013, T-014 | `docs/design/reference-legacy.md` con una sección por pantalla (Inicio, Perfil, Educación, Ejercicio, Recetas); cada patrón trasladable declara qué cambia al trasladarlo; cada exclusión cita la decisión que la cierra; distingue *rechazado* de *fuera de alcance*. **No toca `lib/`** | Revisión de capturas reales de `autocuidado_app` contra su código fuente, 2 sep 2026 |

---

> **La tabla ordena por ID, no por fecha.** T-015b se registró *después* de
> T-015c y se ejecutó después. Va arriba porque el ID manda; el orden real de
> ejecución vive en `progress/`, que es el documento cronológico.

**Qué cierra T-015b.** El §7 lista "assets sobredimensionados" como deuda
heredada y el A.9 la cuantifica en ~2,8 MB. Esta tarea la salda para el material
de marca —2.054.864 B en siete PNG pasan a 186.282 B en ocho WebP— y de paso
quita el logo de Flutter del cajón de aplicaciones, que es lo primero que ve
quien evalúa el proyecto. No toca ninguna pantalla: deja las piezas disponibles
y registradas para que T-016 en adelante las consuma.

**Qué cierra T-015c.** El §3 auditó qué estaba mal en el proyecto anterior; no
dejó escrito qué de lo que se veía bien vale la pena volver a hacer. Sin ese
documento, cada tarea de pantalla de T-016 en adelante vuelve a mirar las
capturas antiguas y a decidir de nuevo —o peor, repone un campo del perfil que
T-013 ya eliminó por minimización—.
