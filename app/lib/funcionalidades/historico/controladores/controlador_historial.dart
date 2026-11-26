import '../../acceso/dominio/acceso.dart';
import '../../monitoreo/dominio/medicion.dart';
import '../../telemetria/dominio/telemetria.dart';

class ControladorHistorial {
  const ControladorHistorial(this.repositorio, this.usuario);
  final RepositorioTelemetria repositorio;
  final UsuarioAcceso? usuario;
  Stream<List<Medicion>> consultarHistorial(DateTime inicio, DateTime fin) {
    if (usuario?.puedeConsultarColmena != true) {
      return Stream.error(StateError('Acceso restringido.'));
    }
    if (fin.isBefore(inicio)) {
      return Stream.error(ArgumentError('Periodo no valido.'));
    }
    return repositorio.observarHistorico(inicio, fin);
  }
}
