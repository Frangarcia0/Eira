# EIRA — Reglas del proyecto

App móvil Flutter/Android de apoyo al autocuidado para personas con diabetes tipo 2 (DM2),
hipertensión arterial (HTA) o **ambas condiciones**. Proyecto de título (APT), DuocUC.
Entrega: 30 de noviembre de 2026.

**El plan completo está en `docs/PLAN_MAESTRO.md`.** Este archivo contiene solo las reglas
operativas. Ante cualquier duda de alcance, arquitectura o calendario, consulta el plan maestro
y no improvises: el alcance está cerrado.

---

## Reglas absolutas

1. **Nunca hagas commits.** Los commits los hace el autor del proyecto, siempre, sin excepción.
   Prepara los cambios y detente. Es una condición académica, no una preferencia.
2. **Nunca agregues líneas de atribución** (`Co-Authored-By`, "Generated with…") a ningún commit,
   PR o archivo.
3. **No agregues funcionalidad que no esté en el plan maestro.** Si detectas algo útil que falta,
   dilo, no lo implementes. Va al backlog.
4. **No agregues dependencias sin preguntar.** Cada dependencia nueva requiere un ADR.
5. **EIRA no diagnostica.** Nunca escribas lógica que clasifique valores clínicos
   ("hipertensión etapa 2", "glucosa alta", "en rango"). Se registra y se grafica, nada más.
6. **Nada de red.** La app funciona 100 % offline. Sin `http`, `Dio`, `Image.network` ni llamadas
   a APIs. Todas las imágenes son assets locales.

---

## Stack

- Flutter + Dart · Android API 26+ · sin backend
- Estado: **Provider** · Navegación: **go_router** con `ShellRoute`
- Persistencia: **SharedPreferences**, siempre a través de `LocalStorage`
- Contenido: JSON en `assets/content/`, siempre a través de `ContentRepository`

---

## Estructura y arquitectura

Arquitectura **feature-first** con Repository Pattern.
Cadena de datos, sin atajos: `UI → Provider → Repositorio → LocalStorage`.

```
lib/
├── core/        theme · router · storage · content · models · services · utils · widgets
└── features/    onboarding · dashboard · habits · metrics · recipes · exercise ·
                 education · recommendations · profile · privacy
```

Cada feature: `data/` · `models/` · `providers/` · `pages/` · `widgets/`

| # | Regla estructural |
|---|---|
| E1 | **No existe carpeta `shared/`** |
| E2 | Un widget sube a `core/widgets/` solo si lo usan **3 o más** features. Con 2, se duplica |
| E3 | Ningún archivo de pantalla supera **300 líneas** |
| E4 | Solo `core/storage/` importa `shared_preferences` |
| E5 | Solo `core/theme/` contiene literales `Color(0xFF…)` |
| E6 | Un modelo usado por una sola feature vive en esa feature |
| E7 | Cero archivos sin referencias |

**Prohibido:** `catch` vacío · `Map<String, dynamic>` cruzando la capa de datos hacia arriba ·
`TODO` sin tarea asociada · `// ignore:` sin comentario justificativo.

Todo repositorio devuelve estado explícito. Todo provider expone `loading / ready / error`.

---

## Condición del usuario

`HealthCondition { diabetes, hypertension, both }`

**`both` es un valor propio, nunca la suma de los otros dos.** El contenido declara una lista
`conditions`; para aparecer en doble condición, el ítem debe tener `both` escrito explícitamente.

```dart
// PROHIBIDO
if (c == 'diabetes' || c == 'both') result.addAll(diabetesList);
if (c == 'hypertension' || c == 'both') result.addAll(hypertensionList);
```

---

## Persistencia

- Claves: `eira.v1.<dominio>.<detalle>`, todas en `core/storage/storage_keys.dart`
- Métricas separadas por tipo (`metrics.glucose`, `metrics.blood_pressure`, `metrics.weight`)
- `fromJson` **tolerante**: campo faltante → valor por defecto, nunca excepción
- Nunca asumas que una clave existe
- **Solo confirma al usuario que se guardó si el dato realmente se persistió**

Al agregar o cambiar una clave: actualizar `storage_keys.dart`, evaluar migración
y **revisar la pantalla "Sobre tus datos"** (`/profile/data`), que debe coincidir
exactamente con lo que se almacena.

---

## UX y accesibilidad — son criterios de aceptación

| Regla | Valor |
|---|---|
| Tamaño de fuente | 6 tamaños: 32 / 26 / 21 / **18 (cuerpo)** / 16 / **14 (mínimo absoluto)** sp |
| Contraste | ≥ 4.5:1 texto normal · ≥ 3:1 texto grande e interactivos (WCAG AA) |
| Área táctil | ≥ 48×48 dp · ≥ 56×56 dp en acciones primarias |
| Escalado del sistema | Usable al 130 % sin desbordes |
| `Semantics` / `semanticLabel` | Obligatorio en controles no textuales |
| Acciones primarias | ≤ 5 por pantalla |
| Color | Nunca es el único portador de información |

Lenguaje: segunda persona, frases ≤ 20 palabras, sin jerga clínica sin explicar,
unidades siempre visibles (`120 mg/dL`), fechas legibles ("hoy", "12 de octubre").
Errores: qué pasó y qué hacer. Nunca códigos técnicos.
Estado vacío ≠ estado de error.

Navegación: 5 pestañas (Hoy · Hábitos · Métricas · Descubre · Perfil), con etiqueta de texto
visible. Máximo 3 niveles de profundidad. Sin rutas huérfanas. Toda acción destructiva
confirma con verbos claros ("Eliminar" / "Cancelar", nunca "Sí" / "No").

---

## Contenido de salud

Todo texto que afirme algo sobre la salud del usuario vive en `assets/content/*.json`,
**nunca en un archivo `.dart`**, y embebe:

```
SourceMetadata {
  source, sourceUrl, reviewDate,
  status: draft | reviewed | validated,
  sensitivity: low | medium | high
}
```

Fuentes admitidas: MINSAL, ADA, AHA, OMS/OPS, INTA. Nada más.
Ningún ítem `draft` compila. Ningún ítem `high` entra sin `validated`.
Toda imagen: WebP, ≤ 80 KB (íconos ≤ 20 KB), con licencia registrada en
`docs/content/image-credits.md`.

**No inventes contenido de salud.** Si falta un dato clínico, dilo y detente.

---

## Testing

Los tests se escriben **en el mismo sprint** que la funcionalidad. Nunca "después".

Prioridad P0 (cobertura 100 %): cálculo de rachas · serialización y persistencia ·
resolución de contenido por condición · rotación diaria determinista.

Cobertura de lógica de negocio ≥ 70 %. `flutter analyze` sin errores ni warnings.

Casos límite obligatorios de rachas: primer día · doble marca el mismo día · un día sin
actividad · cambio de mes y año · cambio manual de hora en ambos sentidos · la mejor racha
nunca decrece · el recálculo desde el historial coincide con el caché.

---

## Commits (los hace el autor, tú solo propones el mensaje)

`<tipo>(<alcance>): <imperativo, minúscula, sin punto>`

Tipos: `feat` `fix` `refactor` `test` `docs` `content` `style` `chore`
Alcances: `onboarding` `habits` `metrics` `recipes` `exercise` `education` `profile`
`privacy` `storage` `content` `theme` `router` `notifications` `backup`

Un commit = una unidad verificable. Si el mensaje necesita "y", son dos commits.
El commit que cierra un requisito lo referencia: `Refs: RF-13`.
Prohibidos: "cambios varios", "avance", "actualización", "fix bugs".

---

## Definition of Done

Toda tarea: criterio de aceptación cumplido · `flutter analyze` limpio · reglas E1-E7 ·
probada en dispositivo físico.

Además, según el caso:

- **Lógica de negocio** → tests unitarios con casos límite
- **Persistencia** → test de ida y vuelta + revisar "Sobre tus datos"
- **Pantalla nueva o modificada** → checklist de accesibilidad + captura
- **Contenido de salud** → `SourceMetadata` completo + registro en `content-registry.md`
- **Imagen** → registro de licencia + WebP + ≤ 80 KB
- **Decisión técnica no obvia** → ADR en `docs/decisions/`
- **Requisito cerrado** → matriz de trazabilidad actualizada

---

## Cómo quiero que trabajes

- Antes de escribir código, **dime qué vas a hacer y en qué archivos**. Espera confirmación.
- Trabaja en tareas del backlog (`T-0XX`), una a la vez. No adelantes las siguientes.
- Si algo del plan maestro te parece equivocado, **dilo antes de implementarlo**. No lo
  "corrijas" por tu cuenta.
- Si necesitas una decisión que el plan no cubre, pregunta. No elijas por mí.
- Explícame lo que escribiste como si tuviera que defenderlo en un examen oral. Voy a tener
  que hacerlo.
