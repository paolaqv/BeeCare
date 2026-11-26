class SoporteAmbiental {
  const SoporteAmbiental({
    this.estado,
    this.modo,
    this.fechaUltimaActualizacion,
  });
  final String? estado, modo;
  final DateTime? fechaUltimaActualizacion;
  bool? get activo {
    final modoActual = modo?.toLowerCase();
    if (modoActual == 'apagado') return false;
    if (modoActual == 'calentando' ||
        modoActual == 'calentar' ||
        modoActual == 'enfriando' ||
        modoActual == 'enfriar') {
      return true;
    }
    return switch (estado?.toLowerCase()) {
      'activo' || 'activado' || 'encendido' => true,
      'inactivo' || 'desactivado' || 'apagado' => false,
      _ => null,
    };
  }

  factory SoporteAmbiental.desdeJson(Map<String, dynamic> datos) =>
      SoporteAmbiental(
        estado: datos['estado'] as String?,
        modo: datos['modo'] as String?,
        fechaUltimaActualizacion: DateTime.tryParse(
          '${datos['fechaUltimaActualizacion']}',
        ),
      );
}
