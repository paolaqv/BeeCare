import '../../acceso/dominio/acceso.dart';
import '../../monitoreo/datos/repositorio_monitoreo.dart';
import '../dominio/soporte_ambiental.dart';

class ControladorSoporteAmbiental {
  const ControladorSoporteAmbiental(this.repositorio, this.usuario);
  final RepositorioMonitoreo repositorio;
  final UsuarioAcceso? usuario;
  // El control y la escritura del soporte pertenecen al prototipo IoT (CU8).
  Stream<SoporteAmbiental?> observarEstadoSoporte() =>
      usuario?.puedeConsultarColmena == true
      ? repositorio.observarEstadoSoporte()
      : Stream.error(StateError('Acceso restringido.'));
}
