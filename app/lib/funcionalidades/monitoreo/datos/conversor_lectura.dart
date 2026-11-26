import '../dominio/medicion.dart';

Medicion medicionDesdeJson(
  Map<String, dynamic> datos, {
  String idMedicion = '',
  String idColmena = '',
}) {
  double? numero(String nombre, [String? alternativa, String? generica]) {
    final valor = datos[nombre] ?? datos[alternativa] ?? datos[generica];
    return valor is num && valor.isFinite ? valor.toDouble() : null;
  }

  final original = datos['fechaHora'];
  final fecha = original is num
      ? DateTime.fromMillisecondsSinceEpoch(original.toInt(), isUtc: true)
      : DateTime.tryParse('$original');
  if (fecha == null) {
    throw const FormatException('Medicion sin fechaHora valida.');
  }
  return Medicion(
    idMedicion: idMedicion,
    idColmena: idColmena,
    temperaturaS1: numero(
      'temperaturaS1',
      'temperaturaInternaSuperior',
      'temperatura',
    ),
    humedadS1: numero('humedadS1', 'humedadInternaSuperior', 'humedad'),
    temperaturaS2: numero('temperaturaS2', 'temperaturaInternaInferior'),
    humedadS2: numero('humedadS2', 'humedadInternaInferior'),
    temperaturaS3: numero('temperaturaS3', 'temperaturaExterna'),
    humedadS3: numero('humedadS3', 'humedadExterna'),
    peso: numero('peso'),
    ultimoPesoValido: numero('ultimoPesoValido'),
    fechaHora: fecha,
    estadosSensores: {
      for (final sensor in ['S1', 'S2', 'S3', 'Peso', 'NTC', 'SensorBateria'])
        if (datos['estado$sensor'] case final String estado) sensor: estado,
    },
  );
}
