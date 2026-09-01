import 'package:eira/core/content/content_exception.dart';

/// Acceso de **solo lectura** al contenido curado de la app: hábitos, recetas,
/// ejercicios, artículos educativos, recomendaciones.
///
/// Es la contraparte de `LocalStorage` para el otro tipo de dato que distingue
/// el `PLAN_MAESTRO` §19. La diferencia de diseño es la diferencia de
/// naturaleza:
///
/// | | Contenido (esta clase) | Datos del usuario (`LocalStorage`) |
/// |---|---|---|
/// | Origen | Assets JSON, o fuente remota futura | Generados en el dispositivo |
/// | Mutabilidad | **Solo lectura. No hay `write`** | Lectura y escritura |
/// | Sensibilidad | Pública | Sensible (salud) |
/// | Ausencia del dato | Error de construcción | Estado normal |
///
/// **Esta interfaz no expone ningún método de escritura, y nunca lo hará.** El
/// contenido se corrige cambiando un JSON, no desde la app.
///
/// ## Qué NO sabe esta interfaz
///
/// **Nada del dominio.** No sabe qué es una receta ni un hábito, no recibe
/// `HealthCondition` y no filtra nada. Devuelve mapas, igual que `LocalStorage`
/// devuelve mapas; construir `Recipe` a partir de uno y aplicar la regla de que
/// `both` es un valor propio —y no la suma de `diabetes` e `hypertension`— es
/// trabajo del repositorio de cada feature.
///
/// El criterio «genérico, no por dominio», sus tres razones y sus consecuencias
/// negativas están en `docs/decisions/ADR-009`, escrito para `LocalStorage`.
/// Aquí aplica igual, con un motivo extra: una implementación remota con caché
/// local guarda JSON crudo. Si esta interfaz devolviera modelos ya construidos,
/// esa caché tendría que volver a serializarlos para guardarlos.
///
/// ## El parámetro es un identificador lógico, no una ruta
///
/// `readObjectList('recipes')`, **nunca**
/// `readObjectList('assets/content/recipes.json')`.
///
/// Aquí es donde se cumple el criterio de aceptación de T-009 («interfaz lista
/// para fuente remota futura») y la razón 2 del §19 («cero reescritura»). Cada
/// implementación resuelve el identificador a su manera —una a un archivo del
/// bundle, otra a un recurso remoto con caché— y quien llama no se entera. Si
/// el parámetro fuera una ruta de asset, la implementación de assets se
/// filtraría a través de la interfaz hasta los providers, y cambiar de fuente
/// obligaría a tocar cada sitio de uso.
///
/// Mientras exista una sola implementación, el identificador se escribe como
/// literal en cada feature. Un catálogo cerrado equivalente a `StorageKeys`
/// está en el backlog; **no** forma parte de esta tarea.
///
/// ## Por qué es asíncrona
///
/// `LocalStorage` lee sincrónico porque `SharedPreferences` mantiene el almacén
/// en memoria. Aquí no hay copia en memoria que valga: leer un asset es
/// asíncrono, y una fuente remota lo sería por definición. Una interfaz
/// sincrónica haría imposible implementar `RemoteContentRepository` sin
/// cambiarla, que es exactamente lo que esta tarea debe evitar.
///
/// ## Contrato de lectura
///
/// | Situación | Comportamiento |
/// |---|---|
/// | El contenido no existe | Lanza [ContentException]. **Nunca lista vacía** |
/// | El JSON es inválido | Lanza [ContentException] |
/// | El JSON no tiene la forma pedida | Lanza [ContentException] |
///
/// Un arreglo vacío sí es una respuesta válida: significa que el archivo existe
/// y no tiene ítems. Es distinto de que el archivo falte.
abstract interface class ContentRepository {
  /// Un ítem de contenido individual, identificado por [contentId].
  ///
  /// Lanza [ContentException] si el contenido no existe, si no es JSON válido o
  /// si el JSON no describe un objeto.
  Future<Map<String, Object?>> readObject(String contentId);

  /// Una colección de ítems de contenido, identificada por [contentId]. Es la
  /// forma habitual: el catálogo de recetas, la lista de hábitos.
  ///
  /// Lanza [ContentException] si el contenido no existe, si no es JSON válido,
  /// si el JSON no describe un arreglo o si algún elemento no es un objeto.
  Future<List<Map<String, Object?>>> readObjectList(String contentId);
}
