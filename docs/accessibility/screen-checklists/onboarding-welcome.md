# Checklist de accesibilidad — Bienvenida

**Fecha de la revisión:** 2 de septiembre de 2026
**Tarea:** T-015 · **Prioridad:** P0 · **Requisito:** RF-01
**Pantalla:** `lib/features/onboarding/pages/welcome_page.dart`
**Ruta:** `/onboarding/welcome` (`Routes.onboardingWelcome`)
**Ámbito:** PLAN_MAESTRO §24 — «Checklist de accesibilidad por pantalla»

Esta ficha **no repite el análisis**: cada ítem apunta a dónde vive la
verificación. Los valores de contraste están en
[`../contrast-verification.md`](../contrast-verification.md); el resto de las
decisiones y su justificación, en la bitácora
[`../../progress/2026-09-02.md`](../../progress/2026-09-02.md), entrada
«T-015 · Pantalla de bienvenida».

---

## Los ocho ítems del §24

- [x] **Ningún texto bajo 14 sp**
  Cuatro roles en uso, ninguno por debajo del mínimo: `headline` 26 sp (título),
  `body` 18 sp (propósito y las cuatro líneas de qué hace), `bodySecondary`
  16 sp (cierre) y `body` 18 sp en la etiqueta del botón. El menor es 16 sp.
  Ningún `copyWith(fontSize: …)` en el archivo.
  → Bitácora, «Contenido: qué dice y por qué no está en un JSON».

- [x] **Contraste AA verificado y anotado**
  Cuatro pares, todos por sobre su umbral: título y cuerpo **16.39:1**, cierre
  **8.13:1**, texto del botón **5.62:1**, relleno del botón contra el fondo
  **5.42:1** (umbral de 3:1 por ser elemento interactivo).
  → `contrast-verification.md`, filas de `textPrimary`, `textSecondary`,
  `textOnPrimary`/`sage600` y `sage600`/`background`. Medidos en T-004 y
  verificados en cada `flutter test` por
  `test/core/theme/app_colors_contrast_test.dart`; esta pantalla no introduce
  ningún par nuevo.
  Nota: se usa `sage600` y no el color de marca `sage400`, que reprueba AA
  (2.77:1) — `ADR-008`.

- [x] **Áreas táctiles ≥ 48 dp**
  Un solo control. `minimumSize: Size.fromHeight(56)`: **56 dp**, que es el
  mínimo de *acción primaria* del §24, no los 48 de un control cualquiera.
  Ancho completo por el mismo parámetro. El relleno vertical de 12 dp deja que
  el alto crezca en vez de recortar la etiqueta.
  → Bitácora, «Accesibilidad — checklist del §24».

- [ ] **Usable al 130 % de escala del sistema — PENDIENTE DE EVIDENCIA**
  **Único ítem sin resolver.** La estructura está construida para cumplirlo
  —`Column → Expanded(SingleChildScrollView) → botón`, con el botón fuera del
  desplazamiento para que no quede bajo el pliegue— y el argumento está en la
  bitácora, sección «El botón queda fuera del desplazamiento». Pero eso es el
  diseño, no la prueba.
  **Falta la captura en dispositivo físico con el escalado del sistema al
  130 %**, que la Definition of Done exige para toda pantalla nueva. Hasta que
  exista, este ítem no se marca.
  Se cierra junto con la prueba en dispositivo pendiente de T-015.

- [x] **Controles no textuales con etiqueta semántica**
  No hay ninguno: la única acción es un botón con texto visible
  («Continuar»). El icono que lo acompaña es decorativo y **no** lleva
  `semanticLabel` a propósito —etiquetarlo haría que el lector de pantalla
  anunciara dos veces la misma acción—.
  Añadido por sobre el mínimo: `Semantics(header: true)` en el título, para
  poder saltar a él.
  → Bitácora, «Accesibilidad — checklist del §24».

- [x] **≤ 5 acciones primarias**
  **Una.** Es también la «única decisión principal por pantalla» que pide el §24
  en carga cognitiva.

- [~] **Errores comprensibles sin conocimiento técnico**
  **No aplica en esta pantalla.** No hay campos, ni validación, ni escritura en
  `LocalStorage`, ni lectura que pueda fallar: la pantalla muestra texto fijo y
  navega. No existe ningún estado de error que redactar.
  El ítem entra en vigor en **T-016** (primer formulario, con validación al
  confirmar) y en **T-018** (aceptación persistida). Se marca como no aplicable
  y no como cumplido: cumplir algo que no ocurre no demuestra nada.

- [x] **Sin información transmitida solo por color**
  Todo el contenido de la pantalla es texto. El único color con carga funcional
  es el relleno del botón, que además lleva etiqueta e icono. No hay estados,
  chips ni indicadores.

---

## Estado

**Siete de ocho resueltos**, uno no aplicable por la naturaleza de la pantalla,
y **uno abierto**: el escalado al 130 %, que espera la captura en dispositivo
físico.

Mientras ese ítem siga abierto, la Definition of Done de T-015 **no está
completa**. Se cierra con la misma sesión de dispositivo que produzca la captura
de la pantalla, y esta ficha se actualiza entonces —marcando el ítem y
enlazando la evidencia en `docs/evidence/`—, no antes.
