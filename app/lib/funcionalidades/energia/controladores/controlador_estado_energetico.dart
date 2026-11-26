import '../../acceso/dominio/acceso.dart';
import '../../monitoreo/datos/repositorio_monitoreo.dart';
import '../dominio/estado_energetico.dart';

class ControladorEstadoEnergetico {
  const ControladorEstadoEnergetico(this.repositorio, this.usuario);
  final RepositorioMonitoreo repositorio;
  final UsuarioAcceso? usuario;
  Stream<EstadoEnergetico?> observarEstadoEnergetico() =>
      usuario?.puedeConsultarColmena == true
      ? repositorio.observarEstadoEnergetico()
      : Stream.error(StateError('Acceso restringido.'));
}
