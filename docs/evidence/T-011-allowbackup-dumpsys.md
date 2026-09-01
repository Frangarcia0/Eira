# Evidencia T-011 — Respaldo del sistema desactivado

**Fecha de captura:** 1 de septiembre de 2026
**Tarea:** T-011 · **Decisión:** `docs/decisions/ADR-006-disable-android-backup.md`
**Requisito que respalda:** RF-43, punto 4 (PLAN_MAESTRO §26)

---

## Dispositivo

| Dato | Valor |
|---|---|
| Modelo | Xiaomi 24117RK2CG (`zorn_global`) |
| Android | 16 (API 36) |
| Serie adb | `e79248e5` |
| Paquete | `app.eiraapp` v1.0.0 (versionCode 1) |
| Compilación instalada | `flutter build apk --debug` |

---

## 1. Manifest fuente

`android/app/src/main/AndroidManifest.xml`, tag `<application>`:

```xml
android:allowBackup="false"
android:fullBackupContent="false"
```

## 2. Manifest fusionado

`build/app/intermediates/merged_manifests/debug/processDebugManifest/AndroidManifest.xml`
— ambos atributos sobreviven la fusión; ninguna dependencia los sobrescribe:

```xml
<application
    android:name="android.app.Application"
    android:allowBackup="false"
    android:appComponentFactory="androidx.core.app.CoreComponentFactory"
    android:debuggable="true"
    android:extractNativeLibs="false"
    android:fullBackupContent="false"
    android:icon="@mipmap/ic_launcher"
    android:label="eira" >
```

## 3. Verificación en dispositivo físico

Comando:

```
adb shell dumpsys package app.eiraapp
```

Salida relevante:

```
versionCode=1 minSdk=26 targetSdk=36
versionName=1.0.0
flags=[ DEBUGGABLE HAS_CODE ALLOW_CLEAR_USER_DATA ]
privateFlags=[ PRIVATE_FLAG_ACTIVITIES_RESIZE_MODE_RESIZEABLE_VIA_SDK_VERSION ALLOW_AUDIO_PLAYBACK_CAPTURE PRIVATE_FLAG_ALLOW_NATIVE_HEAP_POINTER_TAGGING ]
```

**Resultado:** el flag `ALLOW_BACKUP` **no aparece** entre las banderas del
paquete. Android tiene registrado que esta aplicación no se respalda.

`DEBUGGABLE` está presente porque la compilación verificada es de depuración; no
aparecerá en la compilación de publicación y no afecta esta verificación.

---

## Notas honestas sobre esta evidencia

- En el dispositivo de prueba (Xiaomi, MIUI) el `dumpsys` lista `com.miui.backup`
  en la sección de visibilidad de paquetes; es normal y no indica respaldo activo
  — queda anotado por si se reproduce esta prueba en el mismo tipo de
  dispositivo, no como comportamiento propio de EIRA.
- **Esto verifica el respaldo a la nube, no la transferencia dispositivo a
  dispositivo.** En Android 12+ el traspaso directo entre teléfonos se rige por
  `android:dataExtractionRules`, que este ADR no declara. Limitación registrada
  en las consecuencias negativas de ADR-006.
- **La app todavía no persiste datos de usuario.** La verificación demuestra la
  configuración, no que un dato concreto haya dejado de subirse: a esta fecha no
  hay ninguno que pudiera subir.
