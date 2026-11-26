class EstadoEnergetico {
  const EstadoEnergetico({
    this.porcentajeBateria,
    this.estadoEnergia,
    this.cargaSolar,
    this.voltajeBateria,
    this.fechaHora,
  });
  final double? porcentajeBateria, voltajeBateria;
  final String? estadoEnergia;
  final bool? cargaSolar;
  final DateTime? fechaHora;
  factory EstadoEnergetico.desdeJson(Map<String, dynamic> datos) =>
      EstadoEnergetico(
        porcentajeBateria: (datos['porcentajeBateria'] as num?)?.toDouble(),
        estadoEnergia: datos['estadoEnergia'] as String?,
        cargaSolar: datos['cargaSolar'] as bool?,
        voltajeBateria: (datos['voltajeBateria'] as num?)?.toDouble(),
        fechaHora: DateTime.tryParse('${datos['fechaHora']}'),
      );
}
