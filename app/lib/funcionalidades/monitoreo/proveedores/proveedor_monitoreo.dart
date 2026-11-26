import 'proveedor_colmenas.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/servicios/proveedores_servicios.dart';
import '../../acceso/proveedores/proveedor_acceso.dart';
import '../../energia/controladores/controlador_estado_energetico.dart';
import '../../energia/dominio/estado_energetico.dart';
import '../../soporte_ambiental/controladores/controlador_soporte_ambiental.dart';
import '../../soporte_ambiental/dominio/soporte_ambiental.dart';
import '../controladores/controlador_monitoreo.dart';
import '../datos/repositorio_monitoreo_firebase.dart';
import '../datos/repositorio_monitoreo.dart';
import '../dominio/medicion.dart';

final proveedorRepositorioMonitoreo = Provider<RepositorioMonitoreo>(
  (referencia) => RepositorioMonitoreoFirebase(
    referencia.watch(proveedorBaseDatos),
    idColmena: referencia.watch(proveedorColmenaSeleccionada).idColmena,
    idPrototipo: referencia.watch(proveedorColmenaSeleccionada).idPrototipo,
    soporteAmbientalHabilitado: referencia
        .watch(proveedorColmenaSeleccionada)
        .soporteAmbientalHabilitado,
  ),
);
final proveedorControladorMonitoreo = Provider(
  (referencia) => ControladorMonitoreo(
    referencia.watch(proveedorRepositorioMonitoreo),
    referencia.watch(proveedorUsuario).asData?.value,
  ),
);
final proveedorLecturaActualColmena = StreamProvider.autoDispose<Medicion?>(
  (referencia) =>
      referencia.watch(proveedorControladorMonitoreo).observarMedicionActual(),
);
final proveedorControladorEnergia = Provider(
  (referencia) => ControladorEstadoEnergetico(
    referencia.watch(proveedorRepositorioMonitoreo),
    referencia.watch(proveedorUsuario).asData?.value,
  ),
);
final proveedorEstadoEnergetico = StreamProvider.autoDispose<EstadoEnergetico?>(
  (referencia) =>
      referencia.watch(proveedorControladorEnergia).observarEstadoEnergetico(),
);
final proveedorControladorSoporte = Provider(
  (referencia) => ControladorSoporteAmbiental(
    referencia.watch(proveedorRepositorioMonitoreo),
    referencia.watch(proveedorUsuario).asData?.value,
  ),
);
final proveedorSoporteAmbiental = StreamProvider.autoDispose<SoporteAmbiental?>(
  (referencia) =>
      referencia.watch(proveedorControladorSoporte).observarEstadoSoporte(),
);
