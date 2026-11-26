import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/configuracion.dart';
import '../../../nucleo/servicios/proveedores_servicios.dart';
import '../../acceso/proveedores/proveedor_acceso.dart';
import '../dominio/colmena_disponible.dart';

final proveedorCatalogoColmenas =
    StreamProvider.autoDispose<List<ColmenaDisponible>>((ref) {
      final usuario = ref.watch(proveedorUsuario);
      if (usuario.isLoading ||
          usuario.asData?.value?.puedeConsultarColmena != true) {
        return Stream.value(const []);
      }
      final db = ref.watch(proveedorBaseDatos);
      final datos = <String, Object?>{};
      final suscripciones = <StreamSubscription<Object?>>[];
      late StreamController<List<ColmenaDisponible>> salida;
      salida = StreamController<List<ColmenaDisponible>>(
        onListen: () {
          for (final ruta in ['prototipos', 'colmenas']) {
            suscripciones.add(
              db
                  .observar(ruta)
                  .listen(
                    (valor) {
                      datos[ruta] = valor;
                      if (datos.length == 2 && !salida.isClosed) {
                        salida.add(
                          colmenasDesdeCatalogo(
                            datos['prototipos'],
                            datos['colmenas'],
                          ),
                        );
                      }
                    },
                    onError: (Object e, StackTrace s) {
                      if (!salida.isClosed) salida.addError(e, s);
                    },
                  ),
            );
          }
        },
        onCancel: () async {
          for (final s in suscripciones) {
            await s.cancel();
          }
        },
      );
      return salida.stream;
    });

class SeleccionColmena extends Notifier<String?> {
  @override
  String? build() {
    ref.watch(proveedorUsuario.select((u) => u.asData?.value?.idUsuario));
    return null;
  }

  void seleccionar(String id) {
    final disponibles = ref.read(proveedorCatalogoColmenas).asData?.value ?? [];
    if (disponibles.any((c) => c.idColmena == id)) state = id;
  }
}

final proveedorSeleccionColmena = NotifierProvider<SeleccionColmena, String?>(
  SeleccionColmena.new,
);
final proveedorColmenaSeleccionada = Provider<ColmenaDisponible>((ref) {
  final catalogo = ref.watch(proveedorCatalogoColmenas).asData?.value ?? [];
  final elegida =
      ref.watch(proveedorSeleccionColmena) ?? ConfiguracionAplicacion.idColmena;
  for (final c in catalogo) {
    if (c.idColmena == elegida) return c;
  }
  if (catalogo.isNotEmpty) return catalogo.first;
  // Compatibilidad con la instalacion existente cuando falta el catalogo o sus permisos.
  return const ColmenaDisponible(
    idColmena: ConfiguracionAplicacion.idColmena,
    idPrototipo: ConfiguracionAplicacion.idPrototipo,
    nombre: ConfiguracionAplicacion.idColmena,
  );
});
