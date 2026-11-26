import '../../monitoreo/dominio/medicion.dart';

class EventoColmena {
  const EventoColmena(
    this.id,
    this.categoria,
    this.titulo,
    this.descripcion,
    this.fecha,
    this.critico, {
    this.idAlerta,
    this.leida = false,
    this.datos = const {},
  });
  final String id, categoria, titulo, descripcion;
  final DateTime fecha;
  final bool critico, leida;
  final String? idAlerta;
  final Map<String, dynamic> datos;
}

abstract class RepositorioTelemetria {
  Stream<List<Medicion>> observarHistorico(DateTime inicio, DateTime fin);
  Stream<List<EventoColmena>> observarEventos(String idUsuario);
  Future<void> marcarLeida(String idUsuario, String idAlerta);
}
