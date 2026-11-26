import '../../monitoreo/proveedores/proveedor_colmenas.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/servicios/proveedores_servicios.dart';
import '../../acceso/proveedores/proveedor_acceso.dart';
import '../../historico/controladores/controlador_historial.dart';
import '../../eventos/controladores/controlador_alertas.dart';
import '../../monitoreo/dominio/medicion.dart';
import '../datos/repositorio_telemetria.dart';
import '../dominio/telemetria.dart';

final proveedorRepositorioTelemetria = Provider<RepositorioTelemetria>(
  (referencia) => RepositorioTelemetriaFirebase(
    referencia.watch(proveedorBaseDatos),
    idColmena: referencia.watch(proveedorColmenaSeleccionada).idColmena,
    idPrototipo: referencia.watch(proveedorColmenaSeleccionada).idPrototipo,
  ),
);
final proveedorControladorHistorial = Provider(
  (referencia) => ControladorHistorial(
    referencia.watch(proveedorRepositorioTelemetria),
    referencia.watch(proveedorUsuario).asData?.value,
  ),
);
final proveedorHistorico = StreamProvider.autoDispose
    .family<List<Medicion>, ({DateTime inicio, DateTime fin})>(
      (referencia, periodo) => referencia
          .watch(proveedorControladorHistorial)
          .consultarHistorial(periodo.inicio, periodo.fin),
    );
final proveedorControladorAlertas = Provider(
  (referencia) => ControladorAlertas(
    referencia.watch(proveedorRepositorioTelemetria),
    referencia.watch(proveedorUsuario).asData?.value,
  ),
);
final proveedorEventos = StreamProvider.autoDispose<List<EventoColmena>>(
  (referencia) => referencia.watch(proveedorControladorAlertas).listarAlertas(),
);
