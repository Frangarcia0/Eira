// Tests de T-009 · AssetContentRepository.
//
// Protegen sobre todo UNA regla, que es la que separa a esta capa de
// LocalStorage: contenido ausente = excepción, siempre. Nunca lista vacía.
//
// Los fixtures viven en test/fixtures/content/ y NO en assets/content/, por dos
// razones: no hay contenido curado todavía (C-001 en adelante) y un JSON de
// prueba no debe viajar dentro del APK. Su contenido es deliberadamente
// neutro —«Ítem de prueba A»— y no afirma nada sobre salud: CLAUDE.md prohíbe
// inventar contenido clínico, también en un fixture.

import 'dart:convert';
import 'dart:io';

import 'package:eira/core/content/asset_content_repository.dart';
import 'package:eira/core/content/content_exception.dart';
import 'package:eira/core/content/content_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // rootBundle necesita el binding de servicios inicializado.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('lectura correcta', () {
    test('una colección llega como lista de objetos, en orden', () async {
      final ContentRepository repositorio = _conArchivos(<String, String>{
        'assets/content/lista_de_prueba.json': _fixture('lista_de_prueba.json'),
      });

      final List<Map<String, Object?>> items =
          await repositorio.readObjectList('lista_de_prueba');

      expect(items, hasLength(2));
      expect(items.first['id'], 'demo-1');
      expect(items.last['id'], 'demo-2');
      expect(items.last['conditions'], <String>['both']);
    });

    test('un ítem individual llega como mapa', () async {
      final ContentRepository repositorio = _conArchivos(<String, String>{
        'assets/content/objeto_de_prueba.json':
            _fixture('objeto_de_prueba.json'),
      });

      final Map<String, Object?> item =
          await repositorio.readObject('objeto_de_prueba');

      expect(item['id'], 'demo-objeto');
      expect(item['items'], 2);
    });

    test('un arreglo vacío es una respuesta válida, no un fallo', () async {
      // El archivo existe y no tiene ítems. Es distinto de que falte el
      // archivo, y por eso este caso NO lanza.
      final ContentRepository repositorio = _conArchivos(<String, String>{
        'assets/content/vacio.json': '[]',
      });

      expect(await repositorio.readObjectList('vacio'), isEmpty);
    });

    test('el identificador lógico se resuelve a assets/content/<id>.json',
        () async {
      // Esta es la traducción que la interfaz oculta y que una implementación
      // remota haría de otra forma. Si alguien cambia la carpeta o la
      // extensión, este test lo dice.
      final _BundleFalso bundle = _BundleFalso(<String, String>{
        'assets/content/lista_de_prueba.json': _fixture('lista_de_prueba.json'),
      });

      await AssetContentRepository(bundle: bundle)
          .readObjectList('lista_de_prueba');

      expect(
        bundle.consultados,
        <String>['assets/content/lista_de_prueba.json'],
      );
    });
  });

  group('contenido ausente', () {
    test('readObjectList lanza en vez de devolver lista vacía', () async {
      final ContentRepository repositorio = _conArchivos(<String, String>{});

      await expectLater(
        repositorio.readObjectList('no_existe'),
        throwsA(
          isA<ContentException>().having(
            (ContentException error) => error.contentId,
            'contentId',
            'no_existe',
          ),
        ),
      );
    });

    test('readObject lanza en vez de devolver un mapa vacío', () async {
      final ContentRepository repositorio = _conArchivos(<String, String>{});

      await expectLater(
        repositorio.readObject('no_existe'),
        throwsA(isA<ContentException>()),
      );
    });

    test('el FlutterError del bundle queda traducido y conservado', () async {
      // FlutterError es un Error, no un Exception: sin esta traducción, un
      // `on Exception` en un provider no lo atraparía. Se comprueban las dos
      // mitades — que el fallo ya es capturable como Exception y que la causa
      // original no se perdió.
      final ContentRepository repositorio = _conArchivos(<String, String>{});

      Object? capturado;
      try {
        await repositorio.readObjectList('no_existe');
      } on Exception catch (error) {
        capturado = error;
      }

      expect(capturado, isA<ContentException>());
      expect(capturado, isNot(isA<Error>()));
      expect((capturado! as ContentException).cause, isA<FlutterError>());
    });

    test('con el bundle real de la app el resultado es el mismo', () async {
      // Sin inyección: usa rootBundle. Prueba la traducción contra el bundle
      // de verdad, no solo contra el falso. Hoy assets/content/ está vacía, así
      // que cualquier identificador falta.
      await expectLater(
        AssetContentRepository().readObjectList('todavia_no_existe'),
        throwsA(isA<ContentException>()),
      );
    });
  });

  group('JSON inválido o con forma inesperada', () {
    test('un archivo que no es JSON lanza, con la causa original', () async {
      final ContentRepository repositorio = _conArchivos(<String, String>{
        'assets/content/roto.json': '{"id": "demo-1",',
      });

      await expectLater(
        repositorio.readObjectList('roto'),
        throwsA(
          isA<ContentException>().having(
            (ContentException error) => error.cause,
            'cause',
            isA<FormatException>(),
          ),
        ),
      );
    });

    test('readObject sobre un arreglo lanza', () async {
      final ContentRepository repositorio = _conArchivos(<String, String>{
        'assets/content/lista_de_prueba.json': _fixture('lista_de_prueba.json'),
      });

      await expectLater(
        repositorio.readObject('lista_de_prueba'),
        throwsA(isA<ContentException>()),
      );
    });

    test('readObjectList sobre un objeto lanza', () async {
      final ContentRepository repositorio = _conArchivos(<String, String>{
        'assets/content/objeto_de_prueba.json':
            _fixture('objeto_de_prueba.json'),
      });

      await expectLater(
        repositorio.readObjectList('objeto_de_prueba'),
        throwsA(isA<ContentException>()),
      );
    });

    test('un elemento del arreglo que no es objeto lanza', () async {
      final ContentRepository repositorio = _conArchivos(<String, String>{
        'assets/content/mixto.json': '[{"id": "demo-1"}, 42]',
      });

      await expectLater(
        repositorio.readObjectList('mixto'),
        throwsA(isA<ContentException>()),
      );
    });
  });
}

/// Repositorio que lee de [archivos] en vez del bundle real.
ContentRepository _conArchivos(Map<String, String> archivos) =>
    AssetContentRepository(bundle: _BundleFalso(archivos));

/// Texto de un fixture. La ruta es relativa a la raíz del paquete, que es el
/// directorio desde el que `flutter test` ejecuta.
String _fixture(String nombre) =>
    File('test/fixtures/content/$nombre').readAsStringSync();

/// Bundle en memoria que imita a `PlatformAssetBundle`, incluido su fallo:
/// un asset ausente lanza `FlutterError`, verificado en Flutter 3.47.2. Si el
/// falso lanzara otra cosa, el test pasaría y la app fallaría.
class _BundleFalso extends CachingAssetBundle {
  _BundleFalso(this._archivos);

  final Map<String, String> _archivos;

  /// Claves pedidas, en orden. Es lo que permite verificar la resolución de
  /// rutas sin abrir la implementación.
  final List<String> consultados = <String>[];

  @override
  Future<ByteData> load(String key) async {
    consultados.add(key);
    final String? contenido = _archivos[key];
    if (contenido == null) {
      throw FlutterError('Unable to load asset: "$key".');
    }
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(contenido)));
  }
}
