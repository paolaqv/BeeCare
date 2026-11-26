class ColmenaDisponible {
  const ColmenaDisponible({
    required this.idColmena,
    required this.idPrototipo,
    required this.nombre,
    this.ubicacion = '',
    this.soporteAmbientalHabilitado,
  });
  final String idColmena, idPrototipo, nombre, ubicacion;
  final bool? soporteAmbientalHabilitado;
}

/// Solo admite dispositivos registrados y relaciones no ambiguas entre los nodos.
List<ColmenaDisponible> colmenasDesdeCatalogo(
  Object? prototipos,
  Object? colmenas,
) {
  Map<String, dynamic> mapa(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : {};
  final fichas = mapa(colmenas);
  final candidatas = <ColmenaDisponible>[];
  for (final entrada in mapa(prototipos).entries) {
    final p = mapa(entrada.value);
    final id = p['idColmena'];
    if (id is! String ||
        id.isEmpty ||
        p['uidDispositivo'] is! String ||
        (p['uidDispositivo'] as String).isEmpty ||
        !fichas.containsKey(id)) {
      continue;
    }
    final ficha = mapa(fichas[id]);
    final vinculo = ficha['idPrototipo'];
    if (vinculo != null && vinculo != entrada.key) continue;
    final nombre = ficha['nombre'];
    final capacidad = p['soporteAmbientalHabilitado'];
    candidatas.add(
      ColmenaDisponible(
        idColmena: id,
        idPrototipo: entrada.key,
        nombre: nombre is String && nombre.trim().isNotEmpty
            ? nombre.trim()
            : id.replaceAll('_', ' '),
        ubicacion: ficha['ubicacion'] is String
            ? ficha['ubicacion'] as String
            : '',
        soporteAmbientalHabilitado: capacidad is bool ? capacidad : null,
      ),
    );
  }
  final resultado = candidatas
      .where(
        (c) =>
            candidatas.where((otra) => otra.idColmena == c.idColmena).length ==
            1,
      )
      .toList();
  resultado.sort((a, b) => a.idColmena.compareTo(b.idColmena));
  return resultado;
}
