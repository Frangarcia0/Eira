# EIRA

Aplicación móvil Android de apoyo al autocuidado para personas con **diabetes tipo 2 (DM2)**,
**hipertensión arterial (HTA)** o **ambas condiciones**.

Proyecto de título (APT) — DuocUC. Entrega: 30 de noviembre de 2026.

> **EIRA no diagnostica.** No clasifica valores clínicos ni sustituye a un profesional de la
> salud. Registra, organiza y muestra información de fuentes reconocidas para que la persona
> lleve su propio seguimiento.

---

## Qué hace

- Registro diario de hábitos de autocuidado, con rachas
- Registro histórico de métricas: glucosa, presión arterial y peso
- Recetas, rutinas de ejercicio, artículos educativos y recomendaciones,
  diferenciados según la condición de la persona
- Todo el contenido de salud cita su fuente (MINSAL, ADA, AHA, OMS/OPS, INTA)

## Principios que condicionan el código

| Principio | Consecuencia técnica |
|---|---|
| **Funciona 100 % sin conexión** | Sin `http`, sin APIs, sin imágenes remotas. Todo asset es local |
| **Los datos no salen del dispositivo** | Persistencia local únicamente; el respaldo lo exporta la persona |
| **No clasifica valores clínicos** | No existe lógica que etiquete un valor como alto, bajo o "en rango" |
| **Accesibilidad como criterio de aceptación** | Cuerpo de 18 sp, mínimo 14 sp; contraste WCAG AA; áreas táctiles ≥ 48 dp |

## Stack

- Flutter · Dart · Android API 26+ (Android 8.0)
- Estado: Provider · Navegación: go_router con `ShellRoute`
- Persistencia: SharedPreferences, siempre a través de `LocalStorage`
- Contenido: JSON en `assets/content/`, siempre a través de `ContentRepository`
- Sin backend

## Requisitos

- Flutter 3.47 o superior (canal stable)
- Android SDK con API 26 o superior
- Dispositivo Android físico para verificación (parte de la Definition of Done)

## Cómo ejecutarlo

```bash
flutter pub get
flutter run
```

Verificación estática completa — reglas estructurales E1–E7, prohibición de red y
`flutter analyze`, en un solo comando:

```powershell
.\tool\verify.ps1
```

Por separado:

```bash
dart run tool/check_architecture.dart
flutter analyze
```

El verificador de reglas estructurales existe porque el analizador de Dart no admite reglas de
import ni de expresión acotadas por carpeta. La decisión está en
[`ADR-007`](docs/decisions/ADR-007-verificacion-reglas-estructurales.md).

## Estructura

Arquitectura **feature-first** con Repository Pattern.
Cadena de datos sin atajos: `UI → Provider → Repositorio → LocalStorage`.

```
lib/
├── main.dart      bootstrap mínimo
├── app.dart       MaterialApp, providers raíz, tema
├── core/          theme · router · storage · content · models · services · utils · widgets
└── features/      onboarding · dashboard · habits · metrics · recipes · exercise ·
                   education · recommendations · profile · privacy
```

Cada feature repite la misma forma interna: `data/` · `models/` · `providers/` · `pages/` · `widgets/`.

No existe carpeta `shared/`: fue el origen de la deuda técnica del proyecto anterior.

## Documentación

El alcance, la arquitectura, los requisitos y el calendario están cerrados en
[`PLAN_MAESTRO.md`](PLAN_MAESTRO.md). Las reglas operativas del repositorio están en
[`CLAUDE.md`](CLAUDE.md).

## Estado

En desarrollo — Sprint 1 (fundación).
