/// Entidad Medicion del UML: las lecturas de los tres sensores se conservan en datos.
/// Cada sensor conserva su temperatura y humedad; los datos ausentes no se sustituyen.
class Medicion {
  const Medicion({
    required this.idMedicion,
    required this.idColmena,
    required this.temperaturaS1,
    required this.humedadS1,
    this.temperaturaS2,
    this.humedadS2,
    this.temperaturaS3,
    this.humedadS3,
    required this.peso,
    this.ultimoPesoValido,
    required this.fechaHora,
    this.estadosSensores = const {},
  });
  final String idMedicion, idColmena;
  final double? temperaturaS1,
      humedadS1,
      temperaturaS2,
      humedadS2,
      temperaturaS3,
      humedadS3,
      peso,
      ultimoPesoValido;
  final DateTime fechaHora;
  final Map<String, String> estadosSensores;
}
