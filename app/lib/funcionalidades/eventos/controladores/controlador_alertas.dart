import '../../acceso/dominio/acceso.dart';
import '../../telemetria/dominio/telemetria.dart';

class ControladorAlertas {
  const ControladorAlertas(this.repositorio, this.usuario);
  final RepositorioTelemetria repositorio;
  final UsuarioAcceso? usuario;
  Stream<List<EventoColmena>> listarAlertas() =>
      usuario?.puedeConsultarColmena == true
      ? repositorio.observarEventos(usuario!.idUsuario)
      : Stream.error(StateError('Acceso restringido.'));
  Future<void> marcarLeida(String idAlerta) async {
    if (usuario?.puedeConsultarColmena != true) {
      throw StateError('Acceso restringido.');
    }
    await repositorio.marcarLeida(usuario!.idUsuario, idAlerta);
  }
}
