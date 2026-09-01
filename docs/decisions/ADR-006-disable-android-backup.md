# ADR-006 — Desactivar el respaldo automático de Android

**Fecha:** 1 de septiembre de 2026
**Estado:** Aceptada
**Ámbito:** T-011 · PLAN_MAESTRO §22 (Persistencia) · §26 (Privacidad) · §3-G y §A.12
(auditoría del repositorio anterior) · RF-43

---

## Contexto

Android respalda los datos de una aplicación **por defecto**. Desde API 23, si el
manifest no dice nada, el sistema activa Auto Backup: sube hasta 25 MB de datos
—incluidas las SharedPreferences completas— a la cuenta de Google Drive del
usuario, cifrados, y los restaura en la próxima instalación. No requiere código,
no requiere permiso, no avisa.

El repositorio anterior no declaraba `allowBackup` (§A.12, hallazgo G del §3).
Eso significa que sus SharedPreferences —perfil, condición de salud, métricas—
salían del teléfono hacia Drive, mientras la pantalla de privacidad de esa misma
app afirmaba que los datos no salían del dispositivo. La contradicción no fue una
decisión: fue el default de la plataforma actuando en ausencia de una.

Ese es el punto de la lección L13 del §4: **los defaults de la plataforma también
son decisiones**. La única diferencia es que no las toma el autor.

Este ADR se escribe **antes de que exista un solo dato real que respaldar**. El
proyecto todavía no persiste métricas ni perfil de usuario: `LocalStorage`
(T-006) existe pero no tiene consumidores de producción. Es deliberado —una
declaración de privacidad que llega después de los datos ya llegó tarde.

### Por qué esto es jurídico y no solo técnico

El §26 fija que EIRA se diseña bajo el estándar de la **Ley 21.719**, vigente
desde el 1 de diciembre de 2026 —el día siguiente a la entrega—, y no bajo la
19.628 que rige hasta esa fecha. La 21.719 exige **protección de datos desde el
diseño y por defecto**: las medidas se aplican *antes* de iniciar el tratamiento,
y la configuración por defecto debe tratar solo lo estrictamente necesario.

"Por defecto" es la palabra que obliga aquí. Un manifest que no declara
`allowBackup` cumple la ley por accidente o la incumple por accidente, según lo
que Google decida que hace el default ese año. El §26 lista `allowBackup="false"`
como la implementación concreta del principio de **protección por defecto**, y el
§26 (RF-43, punto 4) lo exige como una de las cuatro evidencias de no
transmisión, junto a la auditoría de dependencias, la búsqueda de red en el
código y la prueba en modo avión.

Tratándose de datos sensibles de salud, la diferencia no es formal: el respaldo
automático es una transferencia a un tercero (Google) de la condición de salud
del titular, hecha sin acto de voluntad del titular.

---

## Alternativas evaluadas

| Opción | A favor | En contra | Veredicto |
|---|---|---|---|
| **No declarar nada** (el default) | Cero trabajo; el usuario recupera sus datos gratis al cambiar de teléfono | Es exactamente el hallazgo G de la auditoría; los datos de salud salen a Drive sin consentimiento; contradice el §26 y la pantalla "Sobre tus datos"; incumple protección *por defecto* | **Rechazada** |
| `allowBackup="true"` + `fullBackupContent="@xml/backup_rules"` con exclusiones selectivas | Conserva el respaldo para datos no sensibles | En EIRA **todos** los datos persistidos son de salud o derivan de ella: no hay nada que incluir. Además obliga a mantener un archivo de reglas sincronizado con `storage_keys.dart` para siempre: una regresión silenciosa esperando ocurrir | **Rechazada** |
| `allowBackup="false"` sin ADR | Corrige el problema | Un atributo sin justificación es indistinguible de un accidente; el §28 exige ADR para toda decisión técnica no obvia, y esta tiene una consecuencia negativa real para el usuario | **Rechazada** |
| **`allowBackup="false"` + `fullBackupContent="false"` + este ADR** | Protección por defecto verificable por inspección; coherente con el §26 y con "Sobre tus datos"; deja el respaldo bajo control explícito del usuario vía `BackupService` | El usuario pierde el respaldo automático hasta que exista `BackupService` (T-072..T-074, sprint 9) | **Adoptada** |

---

## Decisión

En `android/app/src/main/AndroidManifest.xml`, tag `<application>`:

```xml
android:allowBackup="false"
android:fullBackupContent="false"
```

### Qué hace cada uno, sin inflar

- **`allowBackup="false"`** es el que actúa. Desactiva el respaldo del sistema
  para esta aplicación: ni clave-valor ni Auto Backup. Es la línea que corrige el
  hallazgo G.
- **`fullBackupContent="false"`** es **redundante hoy** y se declara igual, por
  dos razones: el §22 lo especifica textualmente, y funciona como segunda barrera
  —si alguien en el futuro pone `allowBackup="true"` sin leer este ADR, Auto
  Backup sigue apagado. No pretende hacer algo que el primero no haga ya.

Ambos son válidos ante AAPT: `allowBackup` es `format="boolean"` y
`fullBackupContent` es `format="reference|boolean"` en `attrs_manifest.xml` del
SDK. Verificado, no supuesto.

### Lo que esta decisión NO hace

No implementa el respaldo del usuario. `BackupService` —exportación e
importación de un JSON con `schemaVersion` elegido y guardado por el usuario
(§22, RF-39 y RF-40)— es T-072 en adelante, sprint 9. Este ADR apaga el respaldo
*del sistema*; el respaldo *del usuario* es una tarea posterior y es la
contrapartida obligatoria de esta decisión.

---

## Consecuencias

### Positivas

- **La pantalla "Sobre tus datos" deja de mentir antes de existir.** El §26 exige
  que su punto 4 diga "sin respaldo automático"; a partir de esta tarea esa frase
  es verdadera y verificable en el manifest.
- **Se cumple la cuarta evidencia de no transmisión de RF-43** sin trabajo
  adicional: se satisface por inspección.
- **La protección por defecto de la Ley 21.719 queda demostrable**, no afirmada.
  En una defensa oral, el manifest es el documento; el ADR es el motivo.
- **La decisión se toma antes del primer dato real.** No hay que borrar nada de
  Drive ni razonar sobre qué se subió mientras tanto.
- **Un archivo menos que mantener**: sin reglas de respaldo selectivo, no hay un
  XML que pueda desincronizarse de `storage_keys.dart`.

### Negativas — las que hay que asumir

- **El usuario pierde el respaldo automático, y hasta el sprint 9 no tiene nada
  a cambio.** Entre hoy y T-072 (26 de octubre – 1 de noviembre), desinstalar la
  app, restablecer el teléfono o cambiar de equipo **borra todo**: rachas,
  historial de glucosa, presión y peso, perfil. Sin advertencia y sin
  recuperación posible. Es una ventana de aproximadamente ocho semanas de
  desarrollo en la que la app es menos segura contra pérdida de datos que si no
  hubiéramos tocado nada. Se asume porque en esa ventana los únicos usuarios son
  el autor y las pruebas.
- **Después del sprint 9 el respaldo deja de ser gratis y pasa a ser un acto
  deliberado.** El usuario tiene que abrir `/profile/backup`, exportar y elegir
  dónde guardar el archivo. El respaldo de Android era automático y silencioso;
  este no lo es. **El usuario que nunca exporte no tendrá respaldo**, y el
  público objetivo del §9 —adultos mayores con DM2 o HTA— es precisamente el que
  menos probablemente exportará por iniciativa propia. Mitigación prevista, no
  implementada aquí: que la app recuerde exportar. Es diseño de T-072 en
  adelante, y sin ella esta decisión traslada al usuario un riesgo que antes
  cubría la plataforma.
- **`allowBackup="false"` no detiene la transferencia dispositivo a dispositivo
  en Android 12+.** El atributo gobierna el respaldo a la nube; el traspaso
  directo entre dos teléfonos durante la configuración inicial se rige por
  `android:dataExtractionRules` (API 31+), que no aceptaría `"false"` y exige un
  XML con `<device-transfer>`. Este ADR **no lo cubre**, y por lo tanto la
  afirmación defendible es *"los datos no se respaldan en la nube"*, no *"los
  datos nunca abandonan el dispositivo por medio del sistema"*. Queda como
  hueco conocido, a verificar empíricamente y a resolver —o a declarar
  aceptado— cuando se redacte "Sobre tus datos". No se cierra aquí porque
  T-011 tiene el alcance acotado a los dos atributos del §22.
- **Un atributo en un manifest no lo lee nadie.** No hay test de Dart que pueda
  fallar si alguien lo borra; el `tool/check_architecture.dart` actual solo mira
  `lib/`. La protección es este documento y la revisión humana.
- **`fullBackupContent="false"` puede leerse como ruido.** Un revisor que sepa
  Android verá un atributo que no cambia el comportamiento. Por eso queda
  explicado arriba en vez de justificado por omisión.
- **No hay marcha atrás gratuita.** Si más adelante se decidiera reactivar el
  respaldo del sistema, no bastaría cambiar el manifest: habría que rehacer la
  pantalla de privacidad, el argumento del §26 y probablemente pedir
  consentimiento explícito. La decisión es barata hoy y cara de revertir.

---

## Verificación

1. **Inspección** de `android/app/src/main/AndroidManifest.xml`.
2. **Manifest fusionado** tras compilar:
   `android/app/build/intermediates/merged_manifests/…/AndroidManifest.xml`
   debe conservar ambos atributos (nadie los sobrescribe).
3. **En dispositivo físico** (DoD base): `adb shell dumpsys package app.eiraapp`
   no debe listar el flag `ALLOW_BACKUP` entre las banderas de la aplicación.
   Captura archivada en `docs/evidence/`.

---

## Referencias

- PLAN_MAESTRO §22 — "Configuración de respaldo del sistema"
- PLAN_MAESTRO §26 — Privacidad; principio de protección por defecto; RF-43
- PLAN_MAESTRO §3-G, §4-L13, §A.12 — el hallazgo que origina esta decisión
- Ley 21.719, protección de datos desde el diseño y por defecto
