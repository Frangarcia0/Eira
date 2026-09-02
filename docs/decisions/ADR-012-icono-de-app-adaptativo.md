# ADR-012 — Ícono de aplicación adaptativo generado con `flutter_launcher_icons`

**Fecha:** 2 de septiembre de 2026
**Estado:** Aceptada
**Ámbito:** T-015b · PLAN_MAESTRO §7 (assets sobredimensionados) · §28 (una dependencia exige justificación escrita) · §24 (color y contraste) · ADR-008 · CLAUDE.md regla 4

---

## Contexto

Tres hechos delimitan la decisión.

**La app se instala hoy con el ícono por defecto de Flutter.** Es lo primero que
ve quien abre el cajón de aplicaciones, evaluador incluido, y el proyecto ya
tiene identidad de marca diseñada y aprobada. Es la evidencia visual más barata
que existe (§31) y la estaríamos regalando.

**`minSdk = 26`.** Desde API 26, Android usa **íconos adaptativos**: dos capas
—fondo y frente— de 108 dp de las que una máscara del sistema deja ver los 72 dp
centrales, con la forma que elija el lanzador. Un único PNG cuadrado *no* es un
ícono adaptativo: el sistema lo encoge dentro de una insignia blanca.

La consecuencia de ese `minSdk` es la que ordena todo lo demás: **no existe un
dispositivo soportado por EIRA que use el camino heredado.** La vía adaptativa
no es el caso avanzado, es el único caso. El PNG cuadrado de `mipmap-*/` queda
como recurso de reserva que nadie llega a mostrar.

**Producir las capas a mano son ~16 archivos.** Cinco densidades × dos capas,
más los cinco heredados, más el XML de `mipmap-anydpi-v26/` y el recurso del
color de fondo, cada uno con su tamaño exacto en píxeles.

---

## Alternativas evaluadas

### A. Dejar el ícono por defecto de Flutter

- Costo cero, ninguna dependencia, ningún archivo nuevo.
- Se entrega un proyecto de título con el logo de otro producto en la pantalla
  de inicio del dispositivo.
- Sin capas adaptativas, **todos** los dispositivos soportados lo recortan mal.
- Es un defecto visible para cualquiera que instale la app, y gratuito de
  arreglar. No hay argumento a favor más allá de la inercia.

### B. Generar las ~16 capas a mano

- Cero dependencias nuevas y control total sobre cada píxel. El resultado final
  es idéntico al de la alternativa C.
- Dieciséis archivos con medidas exactas y **nada que verifique que están
  bien**. Un error de tamaño no lo detecta `flutter analyze`, ni los tests, ni
  la revisión de código: se descubre instalando.
- Hay que rehacerlo entero cada vez que el isotipo cambie.
- Es exactamente el tipo de trabajo repetitivo, manual y sin verificación donde
  el proyecto anterior acumuló los assets mal dimensionados del §A.9. **Se
  descarta por eso**: la alternativa manual reproduce el patrón que T-015b
  existe para corregir.

### C. `flutter_launcher_icons` como `dev_dependency`

- Un bloque declarativo en `pubspec.yaml`, un comando, y el conjunto completo
  generado y reproducible.
- Agrega una dependencia al proyecto, que es lo que la regla 4 de `CLAUDE.md` y
  el §7 obligan a justificar.

---

## Decisión

**Se adopta la alternativa C.**

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.4

flutter_launcher_icons:
  android: "ic_launcher"
  ios: false
  image_path: "assets/branding/eira_isotype.webp"
  adaptive_icon_background: "#979F80"
  adaptive_icon_foreground: "assets/branding/eira_isotype_mark.webp"
  adaptive_icon_foreground_inset: 8
```

Versión resuelta: **0.14.4**. Lee WebP sin intermediarios —se verificó
ejecutándolo, no se dio por supuesto—, así que las fuentes del ícono son los
mismos assets que la app declara y no hay una copia paralela que mantener.

### Por qué esta dependencia sí, con la regla 4 en la mano

La regla dice que ninguna dependencia entra sin ADR. Este es el ADR, y el
argumento es que **el riesgo que la regla existe para contener no aplica aquí**:

1. **No entra al APK.** Una `dev_dependency` no se compila en la aplicación. No
   hay código de terceros ejecutándose en el dispositivo del usuario, no hay
   permisos nuevos que declarar y no hay superficie de red que auditar (§14,
   `CLAUDE.md` regla 6). La preocupación de la regla es código ajeno *dentro*
   del producto; aquí no hay ninguno.
2. **Es de un solo uso y su salida es revisable.** Lo que queda versionado son
   PNG y XML que cualquiera puede abrir y comprobar. No hay acoplamiento en
   tiempo de ejecución ni en tiempo de compilación: si el paquete desapareciera
   mañana, el ícono ya generado seguiría funcionando igual.
3. **La deuda que evita está medida en este mismo proyecto**, en el §7 y en el
   A.9. Generar dieciséis archivos a mano es la vía directa a repetirla.
4. Es la herramienta estándar del ecosistema Flutter para esta tarea, no una
   elección exótica que haya que defender aparte.

### El color de fondo, y por qué su bajo contraste es correcto aquí

`#979F80` es `AppColors.sage400`: el color de marca exacto, ya medido en T-004 y
registrado en `docs/accessibility/contrast-verification.md`. **No es un
hexadecimal nuevo ni re-derivado a mano.**

ADR-008 le asignó a ese token un rol preciso —*decoración, ilustración y
superficies grandes sin texto encima*— y el fondo de un ícono de lanzador es
literalmente eso: una superficie grande, sin texto.

El par blanco sobre `#979F80` da **2,77:1** y no alcanza el 4,5:1 de AA. **Aquí
eso es correcto, y conviene dejar escrito por qué**: la WCAG 2.1 excluye de
forma explícita los logotipos y nombres de marca de sus umbrales de contraste,
tanto en SC 1.4.3 (texto) como en SC 1.4.11 (elementos no textuales). El ícono
de la app no es texto ni un control de la interfaz.

Queda anotado para dos lectores futuros, y ninguno de los dos tiene razón:

- El que quiera "arreglarlo" cambiándolo a `sage600` creyendo que hay un
  incumplimiento que corregir. No lo hay.
- El que lo cite como precedente para pintar un botón o un texto con `sage400`.
  ADR-008 lo prohíbe y esta excepción no lo habilita: se aplica a un logotipo,
  no a la interfaz.

### La capa de frente es un derivado, no un archivo nuevo

`eira_isotype.png` es RGB **sin canal alfa**: fondo salvia opaco a sangre. Usado
tal cual como capa de frente, taparía el color de fondo y lo volvería una
declaración decorativa.

`eira_isotype_mark.webp` se obtiene despejando, canal por canal, la ecuación de
composición `p = α·frente + (1−α)·fondo` sobre los colores planos medidos del
archivo (`#99A081` de fondo y `#FEFEFE` de la marca — ver
`docs/content/image-credits.md`). Para una imagen de dos colores el despeje es
exacto: los píxeles del borde recuperan su alfa real en vez de un recorte por
umbral, y no aparece halo. La marca queda al **66,0 % del lienzo**, medido sobre
el archivo final, que es la zona segura del ícono adaptativo.

Con esa capa, **el fondo del ícono lo pinta Android con el token exacto**, no el
PNG: la desviación de color del archivo (`#99A081`) no llega al ícono instalado.

### El `inset` de la capa de frente: 8 %, no el 16 % por defecto

El generador envuelve la capa de frente en un `<inset>` y su valor por defecto
es **16 %**, que reduce el dibujo al 68 % de la capa. Sobre una marca ya
dimensionada al 66 % del lienzo, eso la dejaría en el **44,9 %** — visiblemente
pequeña dentro de la máscara.

La aritmética que fija el valor elegido:

| | Cálculo | Resultado |
|---|---|---|
| Marca dentro del archivo de frente | medido sobre el WebP final | 66,0 % |
| `inset` 16 % (por defecto) | 66,0 % × 0,68 | 44,9 % del lienzo |
| **`inset` 8 % (elegido)** | 66,0 % × 0,84 | **55,4 % del lienzo** |
| `inset` 0 % | 66,0 % × 1,00 | 66,0 % del lienzo |

El lienzo del ícono adaptativo es de 108 dp y el área garantizada como visible
son los 72 dp centrales. **55,4 % del lienzo son 59,8 dp: un 83 % del área
visible**, que es la proporción que la retícula de íconos de producto de
Material asigna a una marca circular.

Los dos extremos se descartan por la razón opuesta y simétrica: con 0 % la marca
—que es un círculo— quedaría a 71,3 dp dentro de una máscara circular de 72 dp,
tocando el borde sin aire; con 16 % sobra aire y la marca se lee pequeña.

Es el único parámetro de esta configuración que es juicio visual y no medición,
y por eso queda escrito con su aritmética: **cambiarlo es editar una línea de
`pubspec.yaml` y volver a generar.**

**Validado en dispositivo físico** el 2 de septiembre de 2026 sobre un Xiaomi
`24117RK2CG` con Android 16 (API 36). El valor deja de ser provisional.
Evidencia en `docs/evidence/screenshots/t015b-icono-app.jpeg`.

---

## Consecuencias

### Positivas

- La app se instala con su propia identidad, en las cinco densidades y con las
  dos capas que el sistema espera.
- El fondo del ícono es el color de marca exacto, no una aproximación heredada
  del archivo fuente.
- Regenerar el ícono tras un cambio de isotipo es un comando, no una tarde.
- El límite de accesibilidad queda escrito donde se puede leer: por qué este
  2,77:1 es admisible y por qué no sirve de precedente.

### Negativas — las que hay que asumir

- **El token de color queda duplicado fuera de Dart.** `flutter_launcher_icons`
  se configura en YAML y no lee `AppColors`. `#979F80` pasa a existir en
  `app_colors.dart` **y** en `pubspec.yaml`. No viola E5 —que habla de literales
  `Color(0xFF…)` en archivos `.dart`— pero es exactamente la clase de deriva que
  E5 existe para evitar, y `tool/check_architecture.dart` no la detecta. La
  única defensa es el comentario que acompaña al valor en `pubspec.yaml` y este
  ADR. Es disciplina, no compilador.

- **Entran ~16 archivos generados al control de versiones**, dentro de
  `android/app/src/main/res/`, que ninguna otra tarea del proyecto toca. Un
  `git diff` sobre ellos no explica nada porque nadie los escribió.
  **Esos archivos se regeneran, no se editan a mano.** Editar uno directamente
  lo deja desincronizado del resto y el próximo `dart run flutter_launcher_icons`
  lo sobrescribe sin avisar. Si hay que cambiar algo, se cambia la fuente en
  `assets/branding/` o la configuración de `pubspec.yaml`, y se vuelve a generar.

- **Nueve paquetes más en `pubspec.lock`**, no uno: `flutter_launcher_icons`
  arrastra `archive`, `args`, `checked_yaml`, `cli_util`, `image`,
  `json_annotation`, `posix` y `yaml`. Aunque ninguno llegue al APK, sí pueden
  romper `flutter pub get` el día que entren en conflicto de versiones con otra
  dependencia de desarrollo. Es un costo real y desproporcionado frente a lo que
  la herramienta hace: escribir dieciséis archivos una vez.

- **El resultado queda atado a una versión del paquete.** Versiones distintas
  generan conjuntos de archivos distintos: unas agregan
  `ic_launcher-playstore.png`, otras cambian el nombre del recurso de fondo. Se
  declara con caret y la versión efectivamente resuelta queda registrada en
  `pubspec.lock` y en la bitácora de T-015b.

- **El ícono deja de ser reproducible sin la herramienta.** Si algún día el
  paquete no resuelve, hay que volver a la alternativa B —las dieciséis capas a
  mano— tarde y bajo presión.

- **Un error del generador se nota tarde.** No lo ve `flutter analyze`, no lo ven
  los tests y no lo ve el verificador de arquitectura: solo aparece al instalar
  en un dispositivo físico. Por eso la verificación de esta tarea incluye esa
  instalación y su captura, hecha el 2 de septiembre de 2026 y archivada en
  `docs/evidence/screenshots/`. **Cada regeneración futura del ícono vuelve a
  exigirla**: es la única comprobación que existe para este archivo.
