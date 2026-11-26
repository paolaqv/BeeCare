import '../../acceso/dominio/acceso.dart';
import '../datos/repositorio_monitoreo.dart';
import '../dominio/medicion.dart';

class ControladorMonitoreo {
  const ControladorMonitoreo(this.repositorio, this.usuario);
  final RepositorioMonitoreo repositorio;
  final UsuarioAcceso? usuario;
  Stream<Medicion?> observarMedicionActual() =>
      usuario?.puedeConsultarColmena == true
      ? repositorio.observarMedicionActual()
      : Stream.error(StateError('Acceso restringido.'));
}
