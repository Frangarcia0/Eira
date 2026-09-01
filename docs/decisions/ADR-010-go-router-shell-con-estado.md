# ADR-010 — `go_router` 18 y un shell con estado por pestaña

**Fecha:** 1 de septiembre de 2026
**Estado:** Aceptada
**Ámbito:** T-010 · PLAN_MAESTRO §23 (Navegación) · §19 (Arquitectura) · CLAUDE.md (regla 4: toda dependencia nueva requiere un ADR)

---

## Contexto

T-010 monta el enrutado: el mapa de rutas del §23, con el onboarding fuera del
armazón y cinco pestañas dentro. El plan da `go_router` por adoptado en el §19 y
lo nombra en el §23, así que la elección del paquete no está en discusión. Lo
que sí hay que decidir —y documentar, porque la regla 4 de `CLAUDE.md` no hace
excepciones con las dependencias que el plan ya previó— es **qué versión entra,
qué arrastra con ella, y con qué mecanismo concreto se construye el shell**.

La segunda parte es la que importa, porque el §23 nombra un mecanismo por su
nombre —`ShellRoute`— y este ADR se aparta de él.

---

## A. La dependencia: `go_router: ^18.0.0`

### Qué resuelve el solver

No es una versión elegida a dedo. Con Flutter 3.47.2 / Dart 3.13.2 y el
`environment: sdk: ^3.13.2` de este proyecto, `flutter pub add go_router`
resuelve **18.0.0**, que exige `flutter >=3.44.0` y `sdk: ^3.12.0`. Entra sin
tocar el `environment`.

Arrastra cinco dependencias **transitivas** —`material_ui 1.1.0`,
`cupertino_ui 1.0.1`, `flutter_localizations`, `intl 0.20.3` y `logging 1.3.0`—.
En `pubspec.yaml` se declara `go_router` y nada más; las otras cinco no son
decisiones del proyecto y no se fijan.

### Alternativas evaluadas

| Opción | A favor | En contra | Veredicto |
|---|---|---|---|
| `Navigator` 1.0 imperativo, sin paquete | Cero dependencias | El shell de cinco pestañas con pila propia por pestaña hay que escribirlo a mano; el §23 pide rutas con parámetro (`/metrics/:type/history`) y eso es un analizador de rutas casero | Rechazada |
| `auto_route` | Rutas tipadas, generadas | Exige generación de código y `build_runner`: dos dependencias más y un paso de compilación que el §43 no justifica a esta escala | Rechazada |
| **`go_router` 18** | Lo adopta el §19; es del equipo de Flutter; `StatefulShellRoute` resuelve el shell de pestañas sin código propio | Historial de cambios incompatibles frecuente (17.0.0 y 18.0.0 en menos de un año) | **Adoptada** |

### El cambio de la 18.0.0 que sí nos afecta

El changelog de la 18.0.0 dice una sola cosa:

> *Migrates to material_ui and cupertino_ui.*

Verificado en el paquete descargado, no supuesto:

- `material_ui` **no** es un alias de `package:flutter/material.dart`: trae su
  propio `lib/src/` con una copia completa de la biblioteca Material. El
  `MaterialPage` de `material_ui` y el de `package:flutter/material.dart` son
  **dos clases distintas**.
- `package:flutter/material.dart` sigue existiendo en Flutter 3.47.2, así que la
  app no cambia ni un `import`.
- Las dos bibliotecas conviven porque ambas se apoyan en los mismos tipos del
  SDK: `material_ui` reexporta `package:flutter/widgets.dart`, y `Page`,
  `Widget`, `BuildContext` y `RouterConfig` —que es todo lo que la API pública
  de `go_router` nos pide— vienen de ahí.
- `go_router` toca `material_ui` en exactamente dos archivos:
  `lib/src/pages/material.dart` y `lib/src/pages/cupertino.dart`. Son sus
  transiciones y su pantalla de error internas.

**Dos consecuencias que el código asume por escrito:**

1. **`builder:` siempre, `pageBuilder:` nunca.** Con `builder:` la configuración
   del enrutador no nombra ningún tipo de Material y la duplicación de
   bibliotecas no nos alcanza.
2. **Pantalla de error propia.** La interna de `go_router` se construye sobre el
   `Theme` de `material_ui`, que es un `InheritedWidget` distinto del que
   instalará el tema de la app: saldría sin nuestro tema y en inglés. El
   `errorBuilder` propio también es lo que pide el §24 —decir qué pasó y qué
   hacer, sin códigos técnicos—, así que el costo se paga una sola vez.

El otro cambio incompatible reciente —17.0.0, «`ShellRoute` notifica a los
observadores raíz por defecto»— no nos afecta: la app no registra ningún
`NavigatorObserver`.

---

## B. El shell: `StatefulShellRoute.indexedStack`

Aquí está la desviación. **El §23 dice `ShellRoute`; se usa
`StatefulShellRoute.indexedStack`.**

### Qué se pierde exactamente con `ShellRoute`

`ShellRoute` pone las cinco pestañas sobre **un solo `Navigator`**. Cambiar de
pestaña reemplaza la pila: la pantalla de detalle en la que estaba la persona,
su desplazamiento y su estado desaparecen. Entrar en una receta desde
«Descubre», consultar «Perfil» y volver devuelve al catálogo desde arriba, no a
la receta.

El mapa del propio §23 dice cuánto pesa eso: **cuatro de las cinco pestañas
tienen subárbol de rutas.** Solo «Hábitos» es una pantalla plana.

### Alternativas evaluadas

#### A. `ShellRoute`, la letra del §23

- Es lo que el plan nombra. Menos código: no hay ramas ni claves de navegador.
- Suficiente **hoy**, porque hoy ninguna pestaña tiene subrutas construidas.
- Pierde la pila y el desplazamiento de las otras cuatro pestañas en cada
  cambio.
- Cambiar de mecanismo más adelante significa reescribir el shell **cuando ya
  cuelguen de él diez pantallas reales**, cada una con su propia navegación
  interna, y volver a probarlas todas.

#### B. `StatefulShellRoute.indexedStack` *(elegida)*

- Un `Navigator` por pestaña: la pila y el desplazamiento de cada una se
  conservan al cambiar de pestaña.
- Es del **mismo paquete y la misma familia**: `StatefulShellRoute` extiende
  `ShellRouteBase`, igual que `ShellRoute`. No es un paquete distinto ni un
  patrón ajeno al plan.
- El costo se paga ahora, con cinco pantallas vacías: declarar cada pestaña como
  `StatefulShellBranch` y cambiar de pestaña con
  `StatefulNavigationShell.goBranch` en vez de `context.go`.
- Cuesta un acoplamiento nuevo: el orden de las ramas y el orden de la barra de
  navegación tienen que coincidir, y nada en el lenguaje lo obliga.
- `indexedStack` mantiene las cinco ramas **construidas** a la vez, no solo la
  visible.

#### C. Empezar con `ShellRoute` y migrar cuando haga falta

- Cumple la letra del §23 hoy.
- Traslada exactamente el mismo trabajo a un momento en que costará mucho más y
  competirá con tareas P0 de contenido. Es la opción que parece prudente y
  reparte la factura al revés.

### Por qué esto no contradice el espíritu del plan

El §23 no pide «un solo `Navigator`»: pide cinco pestañas con etiqueta visible,
retorno explícito desde toda pantalla de detalle (N3), profundidad máxima de tres
niveles (N2) y ninguna ruta huérfana (N1). `StatefulShellRoute` cumple las
cuatro; `ShellRoute` también, pero con peor comportamiento en la única de ellas
que depende del mecanismo —el retorno—.

Lo que el §23 nombra es un **mecanismo concreto de una biblioteca**, escrito
cuando el plan describía la navegación, no cuando la implementaba. Es el mismo
caso del §22 y `ADR-009`: la intención se conserva íntegra y lo que cambia es la
pieza con la que se cumple. El plan es un documento fechado y no se reescribe
hacia atrás; la diferencia queda anotada aquí y referenciada desde el dartdoc de
`app_router.dart`.

---

## C. Decisiones menores, tomadas aquí para no repetirlas

### Ninguna ruta usa `name`

`go_router` permite nombrar rutas y navegar por nombre. No se usa. Los nombres
crearían un segundo catálogo de identificadores en paralelo a los caminos, sin
nada que mantenga los dos sincronizados: **dos caminos válidos para el mismo
dato**, que es como empezó la deuda técnica descrita en el §3 y lo mismo que
`ADR-009` rechazó en su opción C. `routes.dart` guarda caminos y nada más.

### La redirección solo reescribe `/`

El §23 dibuja la flecha «¿onboarding completo?» sobre `/`, y ahí se queda. Un
guardia global que además bloqueara el shell mientras el onboarding esté
incompleto es trabajo de T-018 y T-019, que es donde existirá el dato de la
aceptación del aviso legal. Implementarlo hoy, con el marcador de posición
devolviendo siempre `false`, dejaría la app entera inalcanzable y el criterio de
aceptación de T-010 —«navegación entre pantallas vacías»— sin forma de
demostrarse.

### La redirección es síncrona, y eso es lo que cumple N6

N6 pide que la redirección inicial no muestre un indicador de carga si resuelve
en menos de 300 ms. **No es un presupuesto de tiempo que haya que medir: es una
restricción sobre la forma de la redirección.** Lo que obliga a mostrar un
indicador es una redirección que tiene que esperar algo antes de decidir; si no
espera, no hay estado intermedio que dibujar.

Por eso la función devuelve `String?` y no `Future<String?>`, aunque
`GoRouterRedirect` admita las dos. Y podrá seguir devolviéndolo en T-019, porque
`LocalStorage` usa la API cacheada de `SharedPreferences` (`ADR-009`): `main()`
hará `await LocalStorage.open()` una sola vez antes de `runApp`, dentro de la
pantalla de arranque nativa, y toda lectura posterior será inmediata.

Lo que **no** se hace hoy «para dejarlo listo» es introducir un `FutureBuilder` o
una ruta de carga. Eso es exactamente lo que N6 prohíbe.

### Los marcadores de posición viven en `core/router/`, no en `features/`

Un archivo desechable no ocupa el nombre definitivo de una pantalla real. Diez
`features/*/pages/*_page.dart` vacíos obligarían a cada tarea de T-015 en
adelante a sobrescribir un archivo en vez de crearlo, decidirían nombres de
pantalla antes de diseñarlas y, si alguna pestaña cambiara, quedarían como
archivos sin referencias (regla E7). Con un archivo y una clase
—`route_placeholder_page.dart`—, la limpieza es borrar el archivo, y el día que
deje de estar referenciado lo dice `tool/check_architecture.dart`.

---

## Decisión

**`go_router: ^18.0.0`, con el shell de cinco pestañas construido como
`StatefulShellRoute.indexedStack`, `builder:` en todas las rutas, pantalla de
error propia, ninguna ruta nombrada y una redirección inicial síncrona que solo
reescribe `/`.**

---

## Consecuencias

### Positivas

- **El shell queda cerrado.** De T-015 en adelante, agregar una pantalla es
  agregar una `GoRoute` dentro de la rama que ya existe, y agregar una subruta
  son dos líneas en `routes.dart` —segmento relativo y destino absoluto—. Nadie
  vuelve a tocar la estructura.
- **El estado por pestaña se paga con cinco pantallas vacías**, no con diez
  pantallas reales encima.
- **N6 queda cumplida por construcción y protegida por una prueba** que monta la
  app con un solo `pump` y comprueba que ya está en destino.
- **La duplicación `flutter/material` ↔ `material_ui` queda acotada** a dos
  archivos internos de `go_router` que la app no toca.
- **`routes.dart` es un catálogo cerrado**, con la misma lógica que
  `storage_keys.dart`: ninguna ruta se escribe como literal fuera de él.

### Negativas — las que hay que asumir

- **El plan maestro queda contradicho por escrito.** Quien lea el §23 y luego
  `app_router.dart` va a encontrar `StatefulShellRoute` donde el plan dice
  `ShellRoute`. La única mitigación es este ADR y la nota en el dartdoc.
- **El orden de las ramas y el de la barra de navegación tienen que coincidir, y
  el lenguaje no lo obliga.** Se defiende con un `assert` en `EiraShell` que
  compara las dos longitudes, pero un `assert` no corre en compilación de
  publicación y no detecta una permutación, solo un descuadre de cantidad. Es
  una regla sostenida por revisión.
- **`indexedStack` construye las cinco ramas y las mantiene vivas.** Es lo que
  conserva el estado, y también significa que cinco pantallas existen en memoria
  aunque solo una se vea. Con cinco pestañas es aceptable; el día que alguna
  cargue listas largas o gráficos, es lo primero que hay que mirar en un
  teléfono de gama media con Android 8 (RNF-09).
- **`go_router` rompe compatibilidad seguido.** Dos versiones mayores en menos
  de un año, y la 18.0.0 movió medio Material a otro paquete. Cada actualización
  hay que leerla, y por eso la restricción es `^18.0.0` y no `any`.
- **Cinco dependencias transitivas nuevas** que el proyecto no eligió y no
  controla, entre ellas dos copias de bibliotecas de interfaz. Aumentan el peso
  del APK y la superficie que hay que revisar si alguna cambia de licencia o de
  mantenedor.
- **La pantalla de error hay que mantenerla.** Es código de interfaz propio,
  escrito en T-010 sin el tema definitivo instalado: cuando entre el `ThemeData`
  del proyecto habrá que revisarla, y no hay nada que lo recuerde salvo esta
  línea.
- **Los marcadores de posición son código que se escribe para borrarse.** Diez
  entradas de `RoutePlaceholderPage` en `app_router.dart` y un archivo entero
  que desaparece. Mientras existan, la app enseña pantallas que no hacen nada, y
  cada tarea de T-015 en adelante tiene que acordarse de retirar la suya.
