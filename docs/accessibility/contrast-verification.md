# Verificación de contraste — tokens de color

**Fecha de la medición:** 1 de septiembre de 2026
**Tarea:** T-004 · **Prioridad:** P0 · **Depende de:** T-001
**Archivo verificado:** `lib/core/theme/app_colors.dart`
**Verificación automática:** `test/core/theme/app_colors_contrast_test.dart`
**Ámbito:** PLAN_MAESTRO §24 (Color y contraste) · RNF de accesibilidad · ADR-008

---

## Método

Los ratios se calculan con la **fórmula de luminancia relativa de la WCAG 2.1**,
sin redondeos intermedios:

1. Cada canal sRGB se normaliza a `[0, 1]`.
2. Se linealiza:
   `c ≤ 0.03928 → c / 12.92`, en otro caso `((c + 0.055) / 1.055) ^ 2.4`.
3. Luminancia relativa: `L = 0.2126·R + 0.7152·G + 0.0722·B`.
4. Ratio de contraste: `(L_claro + 0.05) / (L_oscuro + 0.05)`.

Los valores de la tabla están redondeados a dos decimales solo para mostrarlos.
El cálculo se ejecuta sobre las constantes reales de `AppColors`, no sobre copias
de los hexadecimales, de modo que cambiar un token y no revisar esta tabla hace
fallar `flutter test`.

### Umbrales aplicados

| Caso | Mínimo | Origen |
|---|---|---|
| Texto normal (< 24 sp, o < 19 sp en negrita) | **4.5:1** | WCAG 2.1 SC 1.4.3 (AA) |
| Texto grande (≥ 24 sp) | **3:1** | WCAG 2.1 SC 1.4.3 (AA) |
| Elementos interactivos y bordes que delimitan un control | **3:1** | WCAG 2.1 SC 1.4.11 (AA) |

Todos los tamaños de la escala tipográfica de EIRA salvo `display` (32 sp) están
por debajo de 24 sp. Por eso **el umbral por defecto de este proyecto es 4.5:1**:
el de 3:1 se aplica solo a bordes y controles, nunca a texto de cuerpo.

---

## Pares medidos

| Primer plano | Fondo | Ratio | Umbral | Resultado | Dónde se usa |
|---|---|---:|---:|---|---|
| `#FFFFFF` `textOnPrimary` | `#626B4F` `sage600` | 5.62 | 4.5 | ✅ APRUEBA | Texto sobre botón primario |
| `#FFFFFF` `textOnPrimary` | `#4C5340` `sage700` | 8.02 | 4.5 | ✅ APRUEBA | Texto sobre botón primario presionado |
| `#626B4F` `sage600` | `#FBFBF8` `background` | 5.42 | 4.5 | ✅ APRUEBA | Texto e iconos salvia sobre fondo |
| `#626B4F` `sage600` | `#F2F4EC` `sage50` | 5.07 | 4.5 | ✅ APRUEBA | Texto salvia sobre superficie suave |
| `#1B1D18` `textPrimary` | `#FBFBF8` `background` | 16.39 | 4.5 | ✅ APRUEBA | Texto principal sobre fondo |
| `#1B1D18` `textPrimary` | `#FFFFFF` `surface` | 17.00 | 4.5 | ✅ APRUEBA | Texto principal sobre tarjeta |
| `#1B1D18` `textPrimary` | `#E4E8DA` `sage100` | 13.64 | 4.5 | ✅ APRUEBA | Texto sobre contenedor primario |
| `#1B1D18` `textPrimary` | `#CBD2BB` `sage200` | 10.91 | 4.5 | ✅ APRUEBA | Texto sobre superficie salvia media |
| `#4A4F44` `textSecondary` | `#FBFBF8` `background` | 8.13 | 4.5 | ✅ APRUEBA | Texto secundario |
| `#6B7163` `textTertiary` | `#FBFBF8` `background` | 4.86 | 4.5 | ✅ APRUEBA | Texto terciario — **mínimo del sistema** |
| `#8A9081` `outline` | `#FFFFFF` `surface` | 3.29 | 3.0 | ✅ APRUEBA | Borde de campo sobre tarjeta |
| `#8A9081` `outline` | `#FBFBF8` `background` | 3.17 | 3.0 | ✅ APRUEBA | Borde de campo sobre fondo |
| `#A03028` `error` | `#FFFFFF` `surface` | 7.12 | 4.5 | ✅ APRUEBA | Texto de error |
| `#A03028` `error` | `#FBEBE9` `errorSurface` | 6.16 | 4.5 | ✅ APRUEBA | Texto de error sobre su superficie |
| `#FFFFFF` `textOnPrimary` | `#A03028` `error` | 7.12 | 4.5 | ✅ APRUEBA | Texto sobre relleno de error |
| `#2F6B4F` `success` | `#FFFFFF` `surface` | 6.29 | 4.5 | ✅ APRUEBA | Texto de confirmación |
| `#2F6B4F` `success` | `#E8F2EC` `successSurface` | 5.50 | 4.5 | ✅ APRUEBA | Confirmación sobre su superficie |
| `#2B5C7A` `info` | `#FFFFFF` `surface` | 7.21 | 4.5 | ✅ APRUEBA | Texto informativo |

**18 pares medidos, 18 aprueban.**

El par más ajustado es `textTertiary` sobre `background`, con **4.86:1** frente a
un mínimo de 4.5:1. Ese margen es la razón de la restricción escrita en el token:
`textTertiary` solo se usa en texto de cuerpo de 14 sp o más.

---

## Pares que reprueban y por qué existen igual

| Primer plano | Fondo | Ratio | Umbral | Resultado | Por qué se conserva |
|---|---|---:|---:|---|---|
| `#FFFFFF` `textOnPrimary` | `#979F80` `sage400` | 2.77 | 4.5 | ❌ REPRUEBA | Es el color de marca. Se conserva como identidad, pero **restringido a decoración, ilustración y superficies grandes sin texto encima**. Nunca es color de texto ni relleno de botón. Para eso existe `sage600` (5.62:1). Decisión completa en ADR-008 |
| `#D6D8CE` `divider` | `#FFFFFF` `surface` | 1.44 | 3.0 | ❌ REPRUEBA | Es un divisor **decorativo**. No porta información: no comunica estado, ni límite de un control, ni separación que no esté ya dada por el espaciado o por un encabezado de texto. Bajo ese uso, la WCAG no le exige contraste mínimo |

Ninguno de los dos es una excepción concedida: son **restricciones de uso**
escritas en el propio token y verificadas en el test.

### La medición corrige al plan maestro

El PLAN_MAESTRO §24 y el anexo A.10 estiman el contraste del color de marca en
**"aproximadamente 2.3:1"**. La medición con la fórmula WCAG 2.1 da **2.77:1**.

La conclusión no cambia —reprueba AA por un margen amplio, 4.5:1 exigidos contra
2.77:1 medidos— pero **el valor correcto es 2.77 y es el que queda registrado**.
Un documento de accesibilidad con una cifra estimada a ojo no es evidencia.

---

## Nota sobre estados deshabilitados

La WCAG 2.1 exime del contraste mínimo a los componentes de interfaz
deshabilitados (SC 1.4.3 y SC 1.4.11, excepción de *controles inactivos*).

**EIRA no se acoge a esa exención como atajo.** Un control deshabilitado nunca
comunicará su estado solo bajando el contraste: llevará además texto, un cambio
de forma o un mensaje que explique por qué está inactivo y qué hacer para
activarlo. La regla del §24 —el color nunca es el único portador de
información— no tiene excepciones en este proyecto, aunque la norma las permita.

Por la misma razón `textTertiary` no es un color de estado deshabilitado: es un
color de jerarquía de texto que ya está en su límite de contraste.

---

## Mantenimiento

Un color nuevo entra a `AppColors` solo con:

1. Su ratio medido contra **cada** superficie sobre la que se vaya a usar.
2. Una fila nueva en la tabla de arriba, con el uso concreto.
3. Un `expect` nuevo en `test/core/theme/app_colors_contrast_test.dart`.

Si el par reprueba, no entra: se oscurece hasta que apruebe, o se restringe por
escrito a decoración como se hizo con `sage400`.
