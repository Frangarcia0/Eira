# ADR-002 — Almacenamiento exclusivamente local, sin backend

**Fecha:** 1 de septiembre de 2026
**Estado:** Aceptada — **documentación retroactiva**
**Ámbito:** PLAN_MAESTRO §26 (Privacidad) · §14 (Fuera de alcance) · §15 (Restricciones legales) · §19 (Arquitectura) · RF-43 · RNF de privacidad · CLAUDE.md regla 6

> **Sobre el carácter retroactivo de este ADR.** La decisión se tomó en el plan
> maestro (§14, §15 y §26), antes del primer commit. Este documento la formaliza
> con las alternativas evaluadas y las consecuencias negativas que el plan no
> enuncia de forma reunida.

---

## Contexto

EIRA guarda datos de salud de una persona identificable: condición diagnosticada
—diabetes tipo 2, hipertensión o ambas—, año de nacimiento, glucosa, presión
arterial, peso y el historial diario de hábitos. En la legislación chilena eso
son **datos sensibles**, y la decisión sobre dónde viven es la decisión de diseño
con más consecuencias del proyecto.

El calendario la condiciona de una forma que conviene decir con precisión:

- La **Ley 19.628** rige hasta el **30 de noviembre de 2026**.
- La **Ley 21.719** —que crea la Agencia de Protección de Datos Personales y
  alinea a Chile con estándares tipo GDPR— entra en vigencia el **1 de diciembre
  de 2026**.
- La entrega de EIRA es el **30 de noviembre de 2026**: el último día del régimen
  antiguo.

El plan resuelve esa coincidencia sin ambigüedad (§15, §26): **el diseño se rige
por el estándar de la Ley 21.719**, no por el de la ley que técnicamente estará
vigente el día de la entrega. La nueva ley exige protección de datos **desde el
diseño y por defecto**: las medidas se aplican antes de iniciar el tratamiento y
deben garantizar que, por defecto, solo se traten los datos estrictamente
necesarios para una finalidad específica.

Hay además un antecedente técnico. El repositorio anterior no funcionaba sin
internet: el módulo de ejercicio cargaba imágenes con `Image.network` desde URLs
remotas, y las recetas tenían dos campos compitiendo —uno local y uno remoto—
usados de forma inconsistente según la pantalla. La dependencia de la red no era
una decisión: era un descuido con consecuencias visibles para el usuario.

---

## Alternativas evaluadas

| Opción | A favor | En contra | Veredicto |
|---|---|---|---|
| **Backend propio con cuentas** (Firebase/Firestore, Supabase o equivalente) | Multi-dispositivo; recuperación ante pérdida del teléfono; telemetría y corrección de contenido en caliente; es la dimensión técnica que un proyecto de título suele exhibir | **Convierte al autor en responsable del tratamiento de datos sensibles.** Eso arrastra consentimiento informado, medidas de seguridad demostrables, notificación de brechas, derechos ARCO operativos y una infraestructura que nadie sostiene después de la defensa. Además exige registro y contraseña *antes* de que la app entregue valor, con un público objetivo de adultos de 45 a 75 años | **Rechazada** |
| **Local + sincronización opcional a la nube** | Ofrece lo mejor de ambos: funciona sin red y respalda cuando la hay | La sincronización con resolución de conflictos es la parte técnicamente más difícil de la aplicación, y no es lo que el proyecto se propuso demostrar. Y no evita nada de lo anterior: **basta un solo byte de salud en un servidor para que exista tratamiento**; la opcionalidad no elimina la obligación, solo la vuelve intermitente | **Rechazada** |
| **Datos de usuario locales + contenido de salud remoto** | Permitiría corregir una receta o una contraindicación equivocada sin publicar una versión nueva | Reintroduce la dependencia de red que causó el hallazgo del módulo de ejercicio: sin conexión no hay receta ni rutina del día, que es justamente la propuesta de valor diaria (§10, RF-08). Rompe la prueba empírica de modo avión de RF-43 | **Rechazada para el MVP**, con la puerta abierta (ver abajo) |
| **100 % local, con exportación controlada por el usuario** | Los datos de salud no salen del dispositivo salvo por un acto explícito de su titular; el argumento de privacidad deja de ser una promesa y pasa a ser una propiedad estructural; la app funciona íntegra en modo avión | Sin multi-dispositivo, sin recuperación automática, sin telemetría, y el contenido solo se corrige publicando una versión | **Adoptada** |

### La puerta que queda abierta, y por qué no es una contradicción

"Local" se argumenta de dos maneras distintas, y mezclarlas sería deshonesto:

- **Los datos del usuario son locales por privacidad.** Esta parte de la decisión
  es deliberadamente cara de revertir: cambiarla obligaría a rehacer la pantalla
  "Sobre tus datos", el argumento del §26 y el modelo de consentimiento.
- **El contenido de salud es local por disponibilidad**, no por privacidad: es
  información pública que ya viene incluida en la app (§19, tabla de separación
  conceptual). Por eso `ContentRepository` es una interfaz y hoy la implementa
  `AssetContentRepository`. Si algún día hubiera contenido remoto con caché
  local, se agrega una implementación y no cambia una línea de los providers
  (ADR-001).

---

## Decisión

> **Los datos del usuario se generan, se guardan y se leen en el dispositivo. No
> hay backend, no hay cuentas y no hay peticiones de red con datos del usuario.
> La única salida posible es un archivo de respaldo que el usuario exporta
> deliberadamente y guarda donde él elija.**

Consecuencias directas sobre el código, que son las que hacen verificable la
decisión:

1. **Cero red.** Sin `http`, sin `Dio`, sin `Image.network`, sin llamadas a APIs.
   Todas las imágenes son assets locales (CLAUDE.md regla 6).
2. **Sin identificadores.** No hay cuenta, no hay correo, no hay identificador de
   dispositivo ni de instalación. `UserProfile` guarda el **año** de nacimiento,
   no la fecha; estatura y género se eliminaron del modelo anterior por
   minimización (§26).
3. **Sin analítica ni telemetría de fallos.** Ninguna dependencia con capacidad
   de red no justificada (RF-43, punto 1).
4. **La exportación es un acto del usuario.** `BackupService` genera un JSON con
   `schemaVersion` y `exportedAt`; el usuario elige dónde guardarlo con el
   selector del sistema. La importación exige confirmación explícita porque
   reemplaza los datos actuales (§22, RF-39 y RF-40, sprint 9).

### Las dos salidas que había que cerrar

Un "no sale del dispositivo" solo es cierto si se cierran **todas** las salidas,
no solo las que uno escribe:

- **La que escribimos**: la red. Cerrada por las cuatro consecuencias de arriba.
- **La que no escribimos**: el respaldo automático de Android, activo **por
  defecto** desde API 23. Sin declarar nada en el manifest, el sistema habría
  subido las SharedPreferences completas a Google Drive sin código, sin permiso y
  sin aviso. Es el hallazgo G de la auditoría y lo cierra **ADR-006**
  (`allowBackup="false"`).

Sin ADR-006, este ADR sería falso. Se citan juntos a propósito.

---

## Consecuencias

### Positivas

- **El argumento de privacidad es estructural, no declarativo.** No hay que
  confiar en que los datos estén bien protegidos en un servidor: no hay servidor.
  La afirmación se verifica leyendo el `pubspec.yaml` y el manifest.
- **La pantalla "Sobre tus datos" es derivable del modelo.** El §26 exige que
  cada afirmación corresponda a una clave real de `storage_keys.dart`. Con
  almacenamiento local eso es una enumeración; con un backend habría que
  describir además qué se envía, a quién, cuánto se conserva y bajo qué base
  legal.
- **La app funciona íntegra sin conexión**, incluidas receta y rutina del día.
  Corrige el hallazgo del módulo de ejercicio y hace que la propuesta de valor
  diaria no dependa de la cobertura del usuario.
- **Cero costo de operación y cero superficie de ataque remota.** No hay nada que
  pagar, mantener ni parchear después de la entrega, y no existe una base de
  datos de salud que pueda filtrarse.
- **Es defendible con una frase**, la del §26: el almacenamiento local no es una
  limitación del MVP, es la consecuencia del principio de protección desde el
  diseño aplicado a datos sensibles.

### Negativas — las que hay que asumir

- **No hay recuperación. Perder el teléfono es perder los datos.** Y no es una
  hipótesis remota: desinstalar la app, restablecer el equipo de fábrica o
  cambiar de teléfono borra todo —perfil, rachas, historial completo de glucosa,
  presión y peso— sin advertencia. La única red de seguridad es un respaldo que
  el usuario haya exportado **por iniciativa propia**, y el público objetivo del
  §9 es precisamente el que menos probablemente lo hará. Un backend habría
  resuelto esto sin que el usuario hiciera nada. Se acepta el costo, pero es un
  costo del usuario, no del proyecto.
- **No hay multi-dispositivo.** Quien tenga un teléfono y una tablet tendrá dos
  historiales distintos, y ninguna forma de unirlos salvo exportar e importar
  reemplazando uno con el otro.
- **Ningún error en producción es observable.** Sin telemetría de fallos, un
  cierre inesperado en el teléfono de un usuario real no deja rastro que llegue
  al desarrollador. La única detección de defectos en terreno son las sesiones de
  validación de las semanas 10-11 y lo que el usuario relate. Es una renuncia
  real a la calidad, no solo a una comodidad.
- **El contenido de salud no se puede corregir sin publicar una versión.** Esta
  es la consecuencia más seria y merece decirse sin suavizar: si un ítem de
  sensibilidad `high` —una contraindicación de ejercicio, una nota nutricional—
  resulta estar equivocado después de la entrega, **sigue equivocado en todos los
  teléfonos donde ya está instalado** hasta que el usuario actualice, si es que
  actualiza. Un contenido remoto se corrige en minutos. La mitigación es
  preventiva y vive en otra parte: el ciclo `draft → reviewed → validated` del
  §25, la prohibición de que un ítem `high` entre sin validación profesional, y
  la validación con profesional de la semana 8. No es una mitigación equivalente:
  reduce la probabilidad del error, no su costo si ocurre.
- **Se renuncia a una dimensión completa del trabajo académico.** Un proyecto de
  título sin backend puede leerse como alcance reducido. La respuesta es el
  argumento del §26 —la ausencia de servidor es el resultado del análisis de
  privacidad, no su punto de partida—, pero **hay que darla explícitamente**: el
  código por sí solo no la comunica, y por eso el §31 exige el video del modo
  avión como evidencia de que la decisión es real y no una declaración.
- **Nada se valida del lado del servidor.** Toda garantía de integridad de los
  datos es local: si el archivo de preferencias se corrompe o alguien edita un
  respaldo exportado a mano y lo reimporta, no hay una segunda fuente contra la
  cual contrastar. La importación valida versión y estructura; no puede validar
  veracidad.
- **`allowBackup="false"` no cubre la transferencia directa entre dispositivos en
  Android 12+.** La afirmación defendible es *"los datos no se respaldan en la
  nube"*, no *"el sistema nunca los mueve"*. El hueco está documentado en
  ADR-006 y sigue abierto.

---

## Verificación

Las cuatro evidencias de no transmisión de RF-43. Son evidencia archivada, no
afirmación:

1. **Auditoría de dependencias** — ninguna con capacidad de red no justificada.
2. **Búsqueda en código** — cero `http`, `Dio`, `Image.network` o llamadas a APIs.
3. **Prueba empírica** — la app en modo avión durante un flujo completo, con
   receta y rutina del día incluidas. Video archivado en `docs/evidence/videos/`
   al cierre de cada fase (§31).
4. **`allowBackup="false"`** declarado en el manifest y documentado en ADR-006;
   verificado en dispositivo físico con `adb shell dumpsys package`
   (`docs/evidence/T-011-allowbackup-dumpsys.md`).

---

## Referencias

- PLAN_MAESTRO §26 — Privacidad; marco normativo; principios aplicados; RF-43
- PLAN_MAESTRO §15 — Restricciones legales y éticas; "sin backend propio"
- PLAN_MAESTRO §14 — Fuera de alcance: Firebase, autenticación, sincronización en la nube
- PLAN_MAESTRO §19 — Separación conceptual entre contenido y datos del usuario
- PLAN_MAESTRO §22 — Respaldo exportable (RF-39, RF-40)
- PLAN_MAESTRO §25 — Ciclo de vida del contenido de salud y niveles de sensibilidad
- Ley 21.719 — protección de datos desde el diseño y por defecto (vigente desde el 01/12/2026)
- Ley 19.628 — régimen vigente hasta el 30/11/2026
- ADR-001 — `ContentRepository` como interfaz
- ADR-006 — Desactivación del respaldo automático de Android
