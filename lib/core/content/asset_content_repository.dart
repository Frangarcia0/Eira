import 'dart:convert';

import 'package:eira/core/content/content_exception.dart';
import 'package:eira/core/content/content_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Implementación de [ContentRepository] que lee el contenido empaquetado en el
/// APK, bajo `assets/content/`.
///
/// Es la única implementación que existe hoy y la única prevista para el MVP:
/// `CLAUDE.md` regla 6 prohíbe la red y esta clase no la usa. Lee del bundle de
/// assets, que ya viene dentro de la aplicación instalada.
///
/// ## Resolución del identificador
///
/// ```
/// 'recipes'  →  assets/content/recipes.json
/// ```
///
/// La ruta se construye **aquí y solo aquí**. Es el detalle de implementación
/// que la interfaz oculta: quien llama pasa `'recipes'` y no sabe que existe un
/// archivo.
///
/// ## Por qué el bundle es inyectable
///
/// ```dart
/// final ContentRepository contenido = AssetContentRepository();          // producción
/// final ContentRepository contenido = AssetContentRepository(bundle: falso); // test
/// ```
///
/// Es la razón 3 del `PLAN_MAESTRO` §19: «hace testeable la lógica sin tocar el
/// almacenamiento real». Sin esto, probar el contrato exigiría crear archivos
/// JSON reales en `assets/`, y hoy no existe contenido curado que poner ahí
/// (C-001 en adelante todavía no ha producido ninguno). No es una dependencia
/// nueva: `AssetBundle` y `rootBundle` son parte de Flutter.
///
/// El valor por defecto no puede ir en la lista de parámetros porque
/// `rootBundle` no es una constante. De ahí el `AssetBundle?` con resolución en
/// la lista de inicializadores.
///
/// ## Estado del contenido hoy
///
/// `assets/content/` está vacía y **no está declarada en `pubspec.yaml`**:
/// declarar una carpeta sin archivos hace fallar la compilación de Flutter. La
/// declaración entra junto con el primer JSON real, en la tarea que lo cree.
/// Hasta entonces cualquier lectura lanza [ContentException], que es
/// exactamente lo que debe pasar, y no rompe nada porque ningún provider
/// consume esta clase todavía (T-023 en adelante).
class AssetContentRepository implements ContentRepository {
  AssetContentRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  /// Carpeta del bundle donde vive todo el contenido curado
  /// (`PLAN_MAESTRO` §25).
  static const String _carpeta = 'assets/content';

  final AssetBundle _bundle;

  @override
  Future<Map<String, Object?>> readObject(String contentId) async {
    final Object? decodificado = await _leerYDecodificar(contentId);
    if (decodificado is! Map<String, Object?>) {
      throw ContentException(
        contentId: contentId,
        reason: _seEsperaba('un objeto JSON', decodificado),
      );
    }
    return decodificado;
  }

  @override
  Future<List<Map<String, Object?>>> readObjectList(String contentId) async {
    final Object? decodificado = await _leerYDecodificar(contentId);
    if (decodificado is! List<Object?>) {
      throw ContentException(
        contentId: contentId,
        reason: _seEsperaba('un arreglo JSON', decodificado),
      );
    }
    // Se valida elemento por elemento en lugar de castear el arreglo completo:
    // un solo ítem mal formado en un JSON curado a mano debe nombrarse, no
    // reventar más tarde dentro del `fromJson` de la feature.
    final List<Map<String, Object?>> items = <Map<String, Object?>>[];
    for (final Object? elemento in decodificado) {
      if (elemento is! Map<String, Object?>) {
        throw ContentException(
          contentId: contentId,
          reason: 'el arreglo contiene un elemento que no es un objeto JSON '
              '(${elemento.runtimeType}).',
        );
      }
      items.add(elemento);
    }
    return items;
  }

  /// Ruta del asset que corresponde a [contentId].
  String _ruta(String contentId) => '$_carpeta/$contentId.json';

  /// Carga el asset y lo decodifica, traduciendo cualquiera de los dos fallos a
  /// [ContentException].
  Future<Object?> _leerYDecodificar(String contentId) async {
    final String fuente = await _cargar(contentId);
    try {
      return json.decode(fuente);
    } on FormatException catch (error) {
      throw ContentException(
        contentId: contentId,
        reason: 'el archivo "${_ruta(contentId)}" no contiene JSON válido.',
        cause: error,
      );
    }
  }

  /// Texto crudo del asset, o [ContentException] si no está.
  ///
  /// El `catch` se acota a `FlutterError` porque eso es **exactamente** lo que
  /// lanza `AssetBundle.loadString` cuando el asset no existe — verificado en
  /// runtime contra Flutter 3.47.2, no supuesto. `FlutterError` es un `Error`,
  /// no un `Exception`, así que un `on Exception` no lo atraparía: la
  /// traducción a [ContentException] es lo que hace este fallo capturable por
  /// la capa de arriba.
  ///
  /// Cualquier otro fallo se propaga tal cual, a propósito. Si el bundle
  /// revienta por un motivo que no es «el asset no está», eso es un defecto que
  /// debe verse, no envolverse en un mensaje que lo disfrace.
  ///
  /// El `catch` no está vacío —relanza con contexto—, de modo que la
  /// prohibición nº 1 de `CLAUDE.md` se respeta.
  Future<String> _cargar(String contentId) async {
    try {
      return await _bundle.loadString(_ruta(contentId));
    } on FlutterError catch (error) {
      throw ContentException(
        contentId: contentId,
        reason: 'no se encontró el archivo "${_ruta(contentId)}" en el bundle. '
            'O el contenido no se ha creado todavía, o falta declararlo en '
            'pubspec.yaml.',
        cause: error,
      );
    }
  }

  static String _seEsperaba(String esperado, Object? encontrado) =>
      'se esperaba $esperado y hay ${encontrado.runtimeType}.';
}
