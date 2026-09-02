import 'package:eira/core/models/health_condition.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verificación de [HealthCondition] (T-014).
///
/// El criterio de aceptación del backlog es una sola frase —«`both` es valor
/// propio»— y el último grupo la escribe como test. Los otros tres cubren lo
/// que sostiene esa frase en el tiempo: que el catálogo no crezca sin que
/// nadie lo note, y que el formato de almacenamiento no dependa de cómo se
/// llamen las constantes en Dart.
///
/// ## Lo que estos tests están defendiendo
///
/// El grupo «Codificación en JSON» es el que importa dentro de un año. Fija
/// las tres cadenas contra el día en que alguien renombre un valor en Dart:
/// ese renombre **no** debe poner rojo ningún test, porque no toca los datos
/// guardados; cambiar la cadena **sí** debe ponerlo, porque invalida los
/// perfiles de todos los dispositivos y obliga a evaluar una migración (§22).
///
/// ## Lo que no se prueba, y por qué
///
/// **No hay ningún test que verifique la ausencia de `isDiabetes`.** Se
/// evaluó y se descartó: nada que se pueda escribir aquí falla el día que
/// alguien agregue ese getter, así que sería un test que afirma lo que no
/// comprueba. La prohibición vive donde puede sostenerse —`CLAUDE.md`, el
/// dartdoc de [HealthCondition] y la revisión de código—, y lo que sí se
/// prueba es su consecuencia observable: que `both` sea atómico y no se
/// obtenga combinando los otros dos valores.
///
/// Tampoco hay tests de etiquetas legibles ni de orden de presentación: no
/// existen por decisión, y todo texto sobre la condición que vea una persona
/// es de T-017. La resolución de contenido por condición es de T-025 y
/// necesita contenido que todavía no existe.
void main() {
  group('Catálogo de valores', () {
    test('son exactamente tres', () {
      // Un cuarto valor obligaría a decidir qué significa frente a `both`, y
      // esa decisión no puede pasar inadvertida en un diff.
      expect(HealthCondition.values, hasLength(3));
    });

    test('son diabetes, hypertension y both', () {
      // Se comprueba la pertenencia, no el orden: el índice no se persiste
      // —se guarda `jsonValue`—, así que reordenar las constantes es
      // inofensivo, y convertir el orden en contrato sería inventar una regla
      // que nadie pidió.
      expect(
        HealthCondition.values,
        containsAll(<HealthCondition>[
          HealthCondition.diabetes,
          HealthCondition.hypertension,
          HealthCondition.both,
        ]),
      );
    });
  });

  group('Codificación en JSON', () {
    test('cada valor tiene su cadena exacta', () {
      // Estas tres líneas son el formato de almacenamiento del proyecto.
      // Cambiar una invalida los perfiles ya guardados en los dispositivos.
      expect(HealthCondition.diabetes.jsonValue, 'diabetes');
      expect(HealthCondition.hypertension.jsonValue, 'hypertension');
      expect(HealthCondition.both.jsonValue, 'both');
    });

    test('toda cadena vuelve a su valor de origen', () {
      // Recorre `values` y no una lista escrita a mano: un valor nuevo queda
      // cubierto sin que nadie tenga que acordarse de agregarlo aquí.
      for (final HealthCondition condicion in HealthCondition.values) {
        expect(
          HealthCondition.tryParse(condicion.jsonValue),
          condicion,
          reason: 'la cadena "${condicion.jsonValue}" no volvió a $condicion',
        );
      }
    });

    test('ninguna cadena se repite entre valores', () {
      // Dos valores con la misma cadena harían que `tryParse` devolviera
      // siempre el primero, y un perfil guardado se leería como otra
      // condición.
      final Set<String> cadenas = HealthCondition.values
          .map((HealthCondition condicion) => condicion.jsonValue)
          .toSet();

      expect(cadenas, hasLength(HealthCondition.values.length));
    });
  });

  group('tryParse — lo que no reconoce', () {
    test('un valor desconocido devuelve null', () {
      expect(HealthCondition.tryParse('prediabetes'), isNull);
    });

    test('la ausencia del campo devuelve null', () {
      // `json['condition']` vale null cuando la clave no estaba. Se acepta
      // para que el sitio de la llamada no necesite una rama aparte.
      expect(HealthCondition.tryParse(null), isNull);
    });

    test('la cadena vacía devuelve null', () {
      expect(HealthCondition.tryParse(''), isNull);
    });

    test('distingue mayúsculas', () {
      // Estricto a propósito: estas cadenas las escribe la app, no una
      // persona. Aceptar variantes daría dos codificaciones válidas del mismo
      // valor, que es lo que ADR-009 rechazó.
      expect(HealthCondition.tryParse('Diabetes'), isNull);
      expect(HealthCondition.tryParse('DIABETES'), isNull);
    });

    test('no recorta espacios', () {
      expect(HealthCondition.tryParse(' diabetes'), isNull);
      expect(HealthCondition.tryParse('diabetes '), isNull);
    });

    test('nada desconocido cae en un valor por defecto', () {
      // La comprobación que impide que alguien "arregle" tryParse haciéndolo
      // devolver diabetes ante lo desconocido. Inventar una condición sería
      // la app afirmando algo sobre la salud de una persona (ADR-003).
      const List<String> desconocidos = <String>[
        'prediabetes',
        'dm2',
        'hta',
        'ambas',
        'null',
        '0',
      ];

      for (final String entrada in desconocidos) {
        expect(
          HealthCondition.tryParse(entrada),
          isNull,
          reason: '"$entrada" no debería resolverse a ninguna condición',
        );
      }
    });
  });

  group('«both» es valor propio', () {
    test('es un valor distinto de los otros dos', () {
      expect(HealthCondition.both, isNot(HealthCondition.diabetes));
      expect(HealthCondition.both, isNot(HealthCondition.hypertension));
    });

    test('su cadena es atómica, no una combinación', () {
      // Si fuera "diabetes+hypertension", el contenido de doble condición se
      // podría resolver concatenando listas y partiendo la cadena. Es un
      // valor atómico justamente para que no se pueda.
      expect(HealthCondition.both.jsonValue, 'both');
      expect(HealthCondition.both.jsonValue, isNot(contains('diabetes')));
      expect(HealthCondition.both.jsonValue, isNot(contains('hypertension')));
    });

    test('no se obtiene combinando las cadenas de los otros dos', () {
      // El §27 exige que `both` no degrade a la suma de listas. Ninguna de
      // estas formas existe en el vocabulario y ninguna debe resolverse.
      expect(HealthCondition.tryParse('diabetes,hypertension'), isNull);
      expect(HealthCondition.tryParse('diabetes+hypertension'), isNull);
      expect(HealthCondition.tryParse('diabetes hypertension'), isNull);
      expect(HealthCondition.tryParse('hypertension,diabetes'), isNull);
    });
  });
}
