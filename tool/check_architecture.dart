// Verificador de las reglas estructurales del PLAN_MAESTRO §20 (E1–E7) y de la
// prohibición de red (CLAUDE.md regla 6, RNF-16).
//
// Existe porque el analizador de Dart no admite reglas de "import prohibido por
// carpeta" ni de "expresión prohibida por carpeta", y cubrirlas con custom_lint
// o DCM exigiría dependencias nuevas. La decisión completa, con sus
// consecuencias negativas, está en docs/decisions/ADR-007.
//
// Uso:
//   dart run tool/check_architecture.dart [raizLib] [raizTest]
//
// Sin argumentos verifica `lib` y usa `test` para resolver referencias. Los
// argumentos existen para poder apuntarlo a un directorio de fixtures con
// violaciones deliberadas y comprobar que detecta lo que dice detectar.
//
// Devuelve 0 si no hay violaciones, 1 si las hay, 2 si no pudo ejecutarse.

import 'dart:convert';
import 'dart:io';

/// Límite de la regla E3 para archivos de pantalla.
const int _limiteLineasPantalla = 300;

/// Única carpeta autorizada a importar `shared_preferences` (E4).
const String _carpetaStorage = 'core/storage/';

/// Única carpeta autorizada a contener colores literales (E5).
const String _carpetaTema = 'core/theme/';

/// Archivos exentos de E7 por ser puntos de entrada: nadie los importa por
/// definición.
const List<String> _exentosDeHuerfano = <String>['main.dart'];

/// Paquetes de red prohibidos por la regla 6 de CLAUDE.md.
const List<String> _importsDeRed = <String>[
  'package:http/',
  'package:dio/',
  'package:web/',
  'dart:html',
  'dart:js_interop',
];

/// Llamadas de red prohibidas, detectadas en el cuerpo del archivo.
const List<String> _llamadasDeRed = <String>[
  'Image.network(',
  'NetworkImage(',
  'HttpClient(',
];

class Violacion {
  const Violacion({
    required this.regla,
    required this.archivo,
    required this.linea,
    required this.problema,
    required this.arreglo,
  });

  final String regla;
  final String archivo;
  final int linea;
  final String problema;
  final String arreglo;
}

void main(List<String> argumentos) {
  final String rutaLib = argumentos.isNotEmpty ? argumentos[0] : 'lib';
  final String rutaTest = argumentos.length > 1 ? argumentos[1] : 'test';

  final Directory raizLib = Directory(rutaLib);
  if (!raizLib.existsSync()) {
    stderr.writeln('No encontré el directorio "$rutaLib".');
    stderr.writeln('Ejecuta el verificador desde la raíz del proyecto.');
    exitCode = 2;
    return;
  }

  final String paquete = _nombreDePaquete();
  final List<Violacion> violaciones = <Violacion>[];

  // E1 — no existe carpeta shared/.
  violaciones.addAll(_revisarCarpetaShared(raizLib));

  // Pasada 1: por archivo. Comprueba E3, E4, E5 y red, y de paso acumula el
  // grafo de referencias que la pasada 2 necesita para resolver E7.
  final List<File> archivosLib = _archivosDart(raizLib);
  final Set<String> referenciados = <String>{};

  for (final File archivo in archivosLib) {
    final String relativa = _relativa(archivo, raizLib);
    final String fuente = archivo.readAsStringSync();

    // Dos limpiezas distintas a propósito: la URI de una directiva vive dentro
    // de un string literal, así que para detectarla hay que conservar strings.
    final String sinComentarios = _limpiar(fuente, borrarStrings: false);
    final String sinComentariosNiStrings = _limpiar(
      fuente,
      borrarStrings: true,
    );

    violaciones.addAll(_revisarLargoDePantalla(relativa, fuente));
    violaciones.addAll(_revisarDirectivas(relativa, sinComentarios));
    violaciones.addAll(_revisarColores(relativa, sinComentariosNiStrings));
    violaciones.addAll(
      _revisarLlamadasDeRed(relativa, sinComentariosNiStrings),
    );

    referenciados.addAll(_referencias(sinComentarios, relativa, paquete));
  }

  // Los tests también cuentan como referencia: un archivo usado solo por un
  // test no es código muerto.
  final Directory raizTest = Directory(rutaTest);
  if (raizTest.existsSync()) {
    for (final File archivo in _archivosDart(raizTest)) {
      final String fuente = archivo.readAsStringSync();
      final String sinComentarios = _limpiar(fuente, borrarStrings: false);
      referenciados.addAll(
        _referencias(sinComentarios, _relativa(archivo, raizTest), paquete),
      );
    }
  }

  // Pasada 2: E7 — archivos que nadie importa.
  for (final File archivo in archivosLib) {
    final String relativa = _relativa(archivo, raizLib);
    if (_exentosDeHuerfano.contains(relativa)) {
      continue;
    }
    if (referenciados.contains(relativa)) {
      continue;
    }
    violaciones.add(
      Violacion(
        regla: 'E7',
        archivo: relativa,
        linea: 1,
        problema: 'ningún archivo del proyecto importa este archivo',
        arreglo: 'úsalo desde donde corresponda o bórralo',
      ),
    );
  }

  _informar(violaciones, rutaLib);
  exitCode = violaciones.isEmpty ? 0 : 1;
}

// ─────────────────────────────────────────────────────────────────────────────
// Comprobaciones
// ─────────────────────────────────────────────────────────────────────────────

List<Violacion> _revisarCarpetaShared(Directory raiz) {
  final List<Violacion> encontradas = <Violacion>[];
  for (final FileSystemEntity entidad in raiz.listSync(recursive: true)) {
    if (entidad is! Directory) {
      continue;
    }
    final String relativa = _relativaDeRuta(entidad.path, raiz.path);
    if (relativa.split('/').last == 'shared') {
      encontradas.add(
        Violacion(
          regla: 'E1',
          archivo: relativa,
          linea: 0,
          problema: 'existe una carpeta shared/',
          arreglo:
              'mueve cada archivo a la feature que lo usa, o a core/widgets/ '
              'si lo usan 3 o más features',
        ),
      );
    }
  }
  return encontradas;
}

List<Violacion> _revisarLargoDePantalla(String relativa, String fuente) {
  if (!relativa.contains('pages/')) {
    return const <Violacion>[];
  }
  final int total = const LineSplitter().convert(fuente).length;
  if (total <= _limiteLineasPantalla) {
    return const <Violacion>[];
  }
  return <Violacion>[
    Violacion(
      regla: 'E3',
      archivo: relativa,
      linea: total,
      problema:
          'la pantalla tiene $total líneas, el límite es $_limiteLineasPantalla',
      arreglo: 'extrae widgets a la carpeta widgets/ de la misma feature',
    ),
  ];
}

/// Detecta E4 y los imports de red. Trabaja sobre el texto sin comentarios pero
/// con los strings intactos, porque la URI de la directiva es un string.
List<Violacion> _revisarDirectivas(String relativa, String sinComentarios) {
  final List<Violacion> encontradas = <Violacion>[];
  final List<String> lineas = const LineSplitter().convert(sinComentarios);

  for (int i = 0; i < lineas.length; i++) {
    final RegExpMatch? coincidencia = _patronDirectiva.firstMatch(lineas[i]);
    if (coincidencia == null) {
      continue;
    }
    final String uri = coincidencia.group(2)!;

    if (uri.startsWith('package:shared_preferences') &&
        !relativa.startsWith(_carpetaStorage)) {
      encontradas.add(
        Violacion(
          regla: 'E4',
          archivo: relativa,
          linea: i + 1,
          problema: 'importa shared_preferences fuera de $_carpetaStorage',
          arreglo: 'usa LocalStorage; es el único camino de persistencia',
        ),
      );
    }

    for (final String prohibido in _importsDeRed) {
      if (uri.startsWith(prohibido)) {
        encontradas.add(
          Violacion(
            regla: 'RED',
            archivo: relativa,
            linea: i + 1,
            problema: 'importa "$uri", y la app funciona 100 % sin conexión',
            arreglo: 'todo el contenido vive en assets/ y en el dispositivo',
          ),
        );
      }
    }
  }
  return encontradas;
}

/// Detecta E5 sobre el texto sin comentarios ni contenido de strings, para que
/// mencionar un color literal en un comentario no cuente como violación.
List<Violacion> _revisarColores(String relativa, String limpio) {
  if (relativa.startsWith(_carpetaTema)) {
    return const <Violacion>[];
  }

  final List<Violacion> encontradas = <Violacion>[];
  final List<String> lineas = const LineSplitter().convert(limpio);

  for (int i = 0; i < lineas.length; i++) {
    for (final MapEntry<RegExp, String> patron in _patronesDeColor.entries) {
      if (patron.key.hasMatch(lineas[i])) {
        encontradas.add(
          Violacion(
            regla: 'E5',
            archivo: relativa,
            linea: i + 1,
            problema: '${patron.value} fuera de $_carpetaTema',
            arreglo: 'toma el color de AppColors; el tema es la única fuente',
          ),
        );
      }
    }
  }
  return encontradas;
}

List<Violacion> _revisarLlamadasDeRed(String relativa, String limpio) {
  final List<Violacion> encontradas = <Violacion>[];
  final List<String> lineas = const LineSplitter().convert(limpio);

  for (int i = 0; i < lineas.length; i++) {
    for (final String llamada in _llamadasDeRed) {
      if (lineas[i].contains(llamada)) {
        encontradas.add(
          Violacion(
            regla: 'RED',
            archivo: relativa,
            linea: i + 1,
            problema: 'llama a $llamada, y la app funciona 100 % sin conexión',
            arreglo: 'usa un asset local con Image.asset',
          ),
        );
      }
    }
  }
  return encontradas;
}

// ─────────────────────────────────────────────────────────────────────────────
// Grafo de referencias (E7)
// ─────────────────────────────────────────────────────────────────────────────

/// Rutas, relativas a la raíz, que este archivo referencia por `import`,
/// `export` o `part`.
Set<String> _referencias(
  String sinComentarios,
  String relativaDelArchivo,
  String paquete,
) {
  final Set<String> destinos = <String>{};
  final String prefijo = 'package:$paquete/';

  for (final String linea in const LineSplitter().convert(sinComentarios)) {
    final RegExpMatch? coincidencia = _patronDirectiva.firstMatch(linea);
    if (coincidencia == null) {
      continue;
    }
    final String uri = coincidencia.group(2)!;

    if (uri.startsWith(prefijo)) {
      destinos.add(uri.substring(prefijo.length));
      continue;
    }
    if (uri.contains(':')) {
      continue; // dart: y paquetes de terceros
    }
    // `part`, y cualquier import relativo que sobreviva a
    // always_use_package_imports.
    destinos.add(_resolverRelativa(relativaDelArchivo, uri));
  }
  return destinos;
}

String _resolverRelativa(String desde, String uri) {
  final List<String> partes = desde.split('/')..removeLast();
  for (final String segmento in uri.split('/')) {
    if (segmento == '.') {
      continue;
    }
    if (segmento == '..') {
      if (partes.isNotEmpty) {
        partes.removeLast();
      }
      continue;
    }
    partes.add(segmento);
  }
  return partes.join('/');
}

// ─────────────────────────────────────────────────────────────────────────────
// Pre-paso léxico
// ─────────────────────────────────────────────────────────────────────────────

/// Sustituye por espacios los comentarios y, si [borrarStrings] es cierto, el
/// contenido de los literales de string. Conserva los saltos de línea, así que
/// los números de línea del resultado coinciden con los del original.
///
/// Sin esto, un comentario que documente la regla haría fallar el verificador.
String _limpiar(String fuente, {required bool borrarStrings}) {
  final StringBuffer salida = StringBuffer();
  int i = 0;

  while (i < fuente.length) {
    final String caracter = fuente[i];

    if (caracter == '/' && _hay(fuente, i + 1, '/')) {
      while (i < fuente.length && fuente[i] != '\n') {
        salida.write(' ');
        i++;
      }
      continue;
    }

    if (caracter == '/' && _hay(fuente, i + 1, '*')) {
      i = _saltarComentarioDeBloque(fuente, i, salida);
      continue;
    }

    if (caracter == _comillaSimple || caracter == _comillaDoble) {
      i = _saltarString(fuente, i, salida, borrarStrings: borrarStrings);
      continue;
    }

    if (caracter == 'r' &&
        i + 1 < fuente.length &&
        (fuente[i + 1] == _comillaSimple || fuente[i + 1] == _comillaDoble)) {
      salida.write('r');
      i = _saltarString(
        fuente,
        i + 1,
        salida,
        borrarStrings: borrarStrings,
        crudo: true,
      );
      continue;
    }

    salida.write(caracter);
    i++;
  }
  return salida.toString();
}

/// Dart permite anidar comentarios de bloque, así que se lleva la cuenta.
int _saltarComentarioDeBloque(String fuente, int inicio, StringBuffer salida) {
  int i = inicio;
  int profundidad = 0;

  while (i < fuente.length) {
    if (fuente[i] == '/' && _hay(fuente, i + 1, '*')) {
      profundidad++;
      salida.write('  ');
      i += 2;
      continue;
    }
    if (fuente[i] == '*' && _hay(fuente, i + 1, '/')) {
      profundidad--;
      salida.write('  ');
      i += 2;
      if (profundidad == 0) {
        return i;
      }
      continue;
    }
    salida.write(fuente[i] == '\n' ? '\n' : ' ');
    i++;
  }
  return i;
}

int _saltarString(
  String fuente,
  int inicio,
  StringBuffer salida, {
  required bool borrarStrings,
  bool crudo = false,
}) {
  final String comilla = fuente[inicio];
  final bool triple =
      _hay(fuente, inicio + 1, comilla) && _hay(fuente, inicio + 2, comilla);
  final String delimitador = triple ? comilla * 3 : comilla;

  salida.write(delimitador);
  int i = inicio + delimitador.length;

  while (i < fuente.length) {
    if (!crudo && fuente[i] == _barra && i + 1 < fuente.length) {
      _rellenar(salida, fuente.substring(i, i + 2), borrar: borrarStrings);
      i += 2;
      continue;
    }
    if (fuente.startsWith(delimitador, i)) {
      salida.write(delimitador);
      return i + delimitador.length;
    }
    if (!triple && fuente[i] == '\n') {
      // String sin cerrar: se corta en el salto de línea para no comerse el
      // resto del archivo.
      salida.write('\n');
      return i + 1;
    }
    _rellenar(salida, fuente[i], borrar: borrarStrings);
    i++;
  }
  return i;
}

void _rellenar(StringBuffer salida, String texto, {required bool borrar}) {
  if (!borrar) {
    salida.write(texto);
    return;
  }
  for (int i = 0; i < texto.length; i++) {
    salida.write(texto[i] == '\n' ? '\n' : ' ');
  }
}

bool _hay(String fuente, int indice, String caracter) =>
    indice < fuente.length && fuente[indice] == caracter;

// ─────────────────────────────────────────────────────────────────────────────
// Utilidades y salida
// ─────────────────────────────────────────────────────────────────────────────

List<File> _archivosDart(Directory raiz) {
  final List<File> archivos = <File>[];
  for (final FileSystemEntity entidad in raiz.listSync(recursive: true)) {
    if (entidad is File && entidad.path.endsWith('.dart')) {
      archivos.add(entidad);
    }
  }
  archivos.sort((File a, File b) => a.path.compareTo(b.path));
  return archivos;
}

String _relativa(File archivo, Directory raiz) =>
    _relativaDeRuta(archivo.path, raiz.path);

String _relativaDeRuta(String ruta, String raiz) {
  final String normalizada = ruta.replaceAll(_barra, '/');
  final String base = raiz.replaceAll(_barra, '/');
  final String prefijo = base.endsWith('/') ? base : '$base/';
  return normalizada.startsWith(prefijo)
      ? normalizada.substring(prefijo.length)
      : normalizada;
}

String _nombreDePaquete() {
  final File pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    return 'eira';
  }
  for (final String linea in pubspec.readAsLinesSync()) {
    final RegExpMatch? coincidencia = _patronNombre.firstMatch(linea);
    if (coincidencia != null) {
      return coincidencia.group(1)!;
    }
  }
  return 'eira';
}

void _informar(List<Violacion> violaciones, String raiz) {
  if (violaciones.isEmpty) {
    stdout.writeln('Reglas estructurales E1-E7: sin violaciones en "$raiz".');
    return;
  }

  final Map<String, List<Violacion>> porRegla = <String, List<Violacion>>{};
  for (final Violacion violacion in violaciones) {
    porRegla.putIfAbsent(violacion.regla, () => <Violacion>[]).add(violacion);
  }

  stdout.writeln(
    'Reglas estructurales E1-E7: ${violaciones.length} violación(es) '
    'en "$raiz".',
  );

  final List<String> reglas = porRegla.keys.toList()..sort();
  for (final String regla in reglas) {
    stdout.writeln();
    stdout.writeln('[$regla]');
    for (final Violacion violacion in porRegla[regla]!) {
      final String ubicacion = violacion.linea > 0
          ? '${violacion.archivo}:${violacion.linea}'
          : violacion.archivo;
      stdout.writeln('  $ubicacion');
      stdout.writeln('    qué pasa · ${violacion.problema}');
      stdout.writeln('    qué hacer · ${violacion.arreglo}');
    }
  }

  stdout.writeln();
  stdout.writeln('Consulta docs/PLAN_MAESTRO.md §20 y docs/decisions/ADR-007.');
}

// ─────────────────────────────────────────────────────────────────────────────
// Patrones
// ─────────────────────────────────────────────────────────────────────────────

const String _comillaSimple = "'";
const String _comillaDoble = '"';
const String _barra = r'\';

/// `import`, `export` o `part` seguidos de la URI entrecomillada.
final RegExp _patronDirectiva = RegExp(
  r'''^\s*(?:import|export|part)\s+r?(['"])([^'"]+)\1''',
);

final RegExp _patronNombre = RegExp(r'^name:\s*(\S+)');

final Map<RegExp, String> _patronesDeColor = <RegExp, String>{
  RegExp(r'Color\(\s*0x'): 'usa un literal Color(0x…)',
  RegExp(r'Color\.fromARGB\('): 'usa Color.fromARGB(…)',
  RegExp(r'Color\.fromRGBO\('): 'usa Color.fromRGBO(…)',
  RegExp(r'\bColors\.'): 'usa la paleta Colors.* de Material',
};
