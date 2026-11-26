import '../../../nucleo/configuracion.dart';
import '../../../nucleo/datos/repositorio_realtime_database.dart';
import '../../energia/dominio/estado_energetico.dart';
import '../../soporte_ambiental/dominio/soporte_ambiental.dart';
import '../dominio/medicion.dart';
import 'repositorio_monitoreo.dart';
import 'conversor_lectura.dart';

class RepositorioMonitoreoFirebase implements RepositorioMonitoreo {
  const RepositorioMonitoreoFirebase(
    this.baseDatos, {
    this.idColmena = ConfiguracionAplicacion.idColmena,
    this.idPrototipo = ConfiguracionAplicacion.idPrototipo,
    this.soporteAmbientalHabilitado,
  });
  final String idColmena, idPrototipo;
  final bool? soporteAmbientalHabilitado;
  final RepositorioRealtimeDatabase baseDatos;
  @override
  Stream<Medicion?> observarMedicionActual() => baseDatos
      .observar('mediciones/$idColmena', ultimo: true)
      .map(
        (valor) => valor == null
            ? null
            : medicionDesdeJson(mapaDatos(valor), idColmena: idColmena),
      );
  @override
  Stream<EstadoEnergetico?> observarEstadoEnergetico() => baseDatos
      .observar('estadoEnergetico/$idPrototipo')
      .map(
        (valor) =>
            valor == null ? null : EstadoEnergetico.desdeJson(mapaDatos(valor)),
      );
  @override
  Stream<SoporteAmbiental?> observarEstadoSoporte() =>
      soporteAmbientalHabilitado == false
      ? Stream.value(null)
      : baseDatos
            .observar('soporteAmbiental/$idPrototipo')
            .map(
              (valor) => valor == null
                  ? null
                  : SoporteAmbiental.desdeJson(mapaDatos(valor)),
            );
}
