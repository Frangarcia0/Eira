# Créditos de imagen

Registro de licencia de **toda** imagen del repositorio. El PLAN_MAESTRO §25 lo
dice sin matices:

> **Sin registro de licencia, la imagen no entra al repositorio.**

El orden importa y es la regla que el proyecto anterior no tuvo: **primero la
fila de esta tabla, después el archivo**. El repositorio anterior commiteó
~2,8 MB de imágenes en 12 archivos sin un solo registro (§A.9), y no es un
descuido de trámite: sin esta tabla nadie puede responder de dónde salió una
foto ni con qué derecho está publicada.

Columnas fijadas por el §25: archivo, origen, licencia, URL, fecha.

**Presupuesto de peso (§7, RNF-23):** íconos ≤ 20 KB · ilustraciones y fotos
≤ 80 KB · formato WebP siempre.

---

## Marca (`assets/branding/`)

Las ocho piezas son **diseño propio del autor del proyecto**, creadas para el
proyecto anterior `autocuidado_app` y traídas a EIRA el 2 de septiembre de 2026.
No hay terceros involucrados: no hay licencia de stock que respetar, ni
atribución que mostrar en pantalla, ni URL de origen.

| Archivo | Origen | Licencia | URL | Fecha |
|---|---|---|---|---|
| `eira_isotype.webp` | Diseño propio del autor · proyecto anterior `autocuidado_app` | Obra propia · todos los derechos del autor | — | 2 sep 2026 |
| `eira_isotype_mark.webp` | **Derivado** de `eira_isotype.webp` (separación de la marca de su fondo) | Obra propia · todos los derechos del autor | — | 2 sep 2026 |
| `eira_wordmark.webp` | Diseño propio del autor · proyecto anterior `autocuidado_app` (`eira_logo.png`) | Obra propia · todos los derechos del autor | — | 2 sep 2026 |
| `cat_meditation.webp` | Diseño propio del autor · proyecto anterior `autocuidado_app` | Obra propia · todos los derechos del autor | — | 2 sep 2026 |
| `icon_education.webp` | Diseño propio del autor · proyecto anterior `autocuidado_app` | Obra propia · todos los derechos del autor | — | 2 sep 2026 |
| `icon_exercise.webp` | Diseño propio del autor · proyecto anterior `autocuidado_app` | Obra propia · todos los derechos del autor | — | 2 sep 2026 |
| `icon_water.webp` | Diseño propio del autor · proyecto anterior `autocuidado_app` | Obra propia · todos los derechos del autor | — | 2 sep 2026 |
| `icon_recipes.webp` | Diseño propio del autor · proyecto anterior `autocuidado_app` | Obra propia · todos los derechos del autor | — | 2 sep 2026 |

Los siete PNG originales viven en `design/source/`, que **no se commitea**
(regla del `.gitignore`, T-015b). Son el material en bruto del que se
re-exporta si alguna pieza hace falta a mayor tamaño; no son assets de la app.

### Procesado y peso (T-015b)

Herramienta: **libwebp 1.6.0 oficial (x64)**, binarios de
`storage.googleapis.com/downloads.webmproject.org`, sha256 del paquete
`48886f506b21f62e4661f0f4cbfca19800897c385128e8902542d29a950c93f1`. Es
herramienta de compilación, externa al repositorio, y **no** una dependencia de
`pubspec.yaml`.

| Archivo | Original | Final | Dimensiones | Codificación | Presup. | SSIM |
|---|---:|---:|---|---|---:|---:|
| `eira_isotype.webp` | 145.862 B | **16.834 B** | 512×512 | sin pérdida | 20 KB | 1,00000 |
| `eira_isotype_mark.webp` | *(derivado)* | **7.700 B** | 512×512 | sin pérdida | 20 KB | 1,00000 |
| `eira_wordmark.webp` | 37.471 B | **14.882 B** | 492×507 | sin pérdida | 20 KB | 1,00000 |
| `cat_meditation.webp` | 197.764 B | **74.378 B** | 500×500 | near-lossless 60 | 80 KB | 0,99921 |
| `icon_education.webp` | 381.614 B | **16.500 B** | 224×224 | near-lossless 60 | 20 KB | 0,99966 |
| `icon_exercise.webp` | 401.456 B | **19.592 B** | 224×224 | near-lossless 60 | 20 KB | 0,99956 |
| `icon_water.webp` | 314.211 B | **17.818 B** | 224×224 | near-lossless 60 | 20 KB | 0,99954 |
| `icon_recipes.webp` | 576.486 B | **18.578 B** | 224×224 | near-lossless 50 | 20 KB | 0,99895 |
| **Total** | **2.054.864 B** | **186.282 B** | | | | **−90,9 %** |

Ninguna imagen se recortó. La única operación que altera píxeles es un
reescalado proporcional por promedio de área sobre alfa premultiplicado, y tres
de las ocho son **idénticas bit a bit** a su entrada. El SSIM se mide sobre las
imágenes compuestas sobre su fondo real, no sobre los planos RGB crudos: en
imágenes con fondo transparente, el RGB bajo alfa 0 no representa nada.

Detalle completo del método, de la escalera de compresión y de las cuatro
verificaciones en `docs/progress/2026-09-02.md`.

### Tamaño máximo de uso

`224 px` cubre un círculo de acceso rápido de hasta **56 dp a densidad 4×**, que
es el uso que `docs/design/reference-legacy.md` §1 tiene previsto. **Si una
pantalla futura necesita una de estas piezas a más de 56 dp, se re-exporta desde
`design/source/`** — no se escala hacia arriba el WebP.

`cat_meditation.webp` conserva sus 500 px nativos: 125 dp a 4×, la ilustración
dentro de la tarjeta "Consejo del día".

---

## Medición: el archivo del isotipo no es exactamente el token de marca

Medido sobre `eira_isotype.png` con decodificación sin pérdida y un histograma
de tres regiones independientes (75.240 px superiores, 62.700 px inferiores y
una fila completa a media altura):

| | Valor |
|---|---|
| Fondo del archivo, media ponderada | **`#99A081`** |
| Token `AppColors.sage400` (ADR-008, §24) | **`#979F80`** |
| Diferencia | **(+2, +1, +1)** por canal |
| "Blanco" de la marca en el archivo | **`#FEFEFE`** (90 %) y `#FDFDFD` (10 %) |

El fondo no es plano: es un tramado de ±1 nivel entre `#99A081` (54–59 %),
`#9AA182` (39–42 %) y `#9BA283` (2–3 %). El hexadecimal exacto de marca
prácticamente no aparece: `#989F80` sale 24 veces en 75.240 píxeles, y
`#979F80`, ninguna. No es ruido de compresión — el PNG es sin pérdida.

**Contraste real:** `#FEFEFE` sobre `#99A081` da **2,70:1**, frente a los
**2,77:1** que `docs/accessibility/contrast-verification.md` registra para
`#FFFFFF` sobre `#979F80`. Ambos reprueban el 4,5:1 de AA y ambos están
cubiertos por la excepción de logotipos de la WCAG 2.1 (SC 1.4.3 y 1.4.11). La
conclusión no cambia; el número que le corresponde a este archivo, sí.

**Decisión: el archivo se deja tal cual.** No se re-aplana al token. El encargo
era reprocesar formato y peso, no editar el diseño; la desviación es
imperceptible (ΔE ≈ 0,6) y ninguna pantalla consume todavía el asset. Si algún
día se coloca junto a una superficie `sage400` y aparece una costura, se decide
entonces con el caso a la vista.

**Lo que sí usa el token exacto es el ícono de la app.** El fondo del ícono
adaptativo se declara como `#979F80` en `pubspec.yaml` y lo pinta Android, no
este archivo — ver `docs/decisions/ADR-012-icono-de-app-adaptativo.md`.
