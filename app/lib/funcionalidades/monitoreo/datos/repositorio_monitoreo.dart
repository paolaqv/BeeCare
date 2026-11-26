import '../dominio/medicion.dart';
import '../../energia/dominio/estado_energetico.dart';
import '../../soporte_ambiental/dominio/soporte_ambiental.dart';

abstract class RepositorioMonitoreo {
  Stream<Medicion?> observarMedicionActual();
  Stream<EstadoEnergetico?> observarEstadoEnergetico();
  Stream<SoporteAmbiental?> observarEstadoSoporte();
}
