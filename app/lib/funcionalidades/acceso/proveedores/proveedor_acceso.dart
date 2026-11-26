import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/servicios/proveedores_servicios.dart';
import '../../../nucleo/servicios/proveedor_notificaciones.dart';
import '../datos/repositorio_acceso.dart';
import '../dominio/acceso.dart';
import '../controladores/controladores_acceso.dart';

final proveedorRepositorioAcceso = Provider<RepositorioAcceso>(
  (referencia) => RepositorioAccesoFirebase(
    referencia.watch(proveedorServicioAutenticacion),
    referencia.watch(proveedorBaseDatos),
  ),
);
final proveedorControladorAutenticacion = Provider(
  (referencia) => ControladorAutenticacion(
    referencia.watch(proveedorRepositorioAcceso),
    referencia.watch(proveedorServicioNotificaciones),
  ),
);
final proveedorUsuario = StreamProvider<UsuarioAcceso?>(
  (referencia) => referencia
      .watch(proveedorControladorAutenticacion)
      .obtenerUsuarioActual(),
);
final proveedorControladorSolicitudes = Provider(
  (referencia) => ControladorSolicitudes(
    referencia.watch(proveedorRepositorioAcceso),
    referencia.watch(proveedorUsuario).asData?.value,
  ),
);
final proveedorSolicitudes = StreamProvider.autoDispose<List<SolicitudAcceso>>(
  (referencia) =>
      referencia.watch(proveedorControladorSolicitudes).listarSolicitudes(),
);
