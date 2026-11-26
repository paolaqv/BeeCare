import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../funcionalidades/acceso/proveedores/proveedor_acceso.dart';
import '../../funcionalidades/monitoreo/proveedores/proveedor_colmenas.dart';
import '../../funcionalidades/telemetria/proveedores/proveedor_telemetria.dart';
import '../presentacion/navegacion.dart';
import '../configuracion.dart';
import 'proveedores_servicios.dart';
import 'servicio_notificaciones.dart';

final proveedorServicioNotificaciones = Provider<ServicioNotificaciones>(
  (referencia) =>
      ConfiguracionAplicacion.firebaseHabilitado &&
          ConfiguracionAplicacion.notificacionesHabilitadas
      ? ServicioNotificacionesFirebase(
          FirebaseMessaging.instance,
          referencia.watch(proveedorBaseDatos),
        )
      : const ServicioNotificacionesNoDisponible(),
);
final proveedorNotificaciones =
    StreamProvider.autoDispose<NotificacionRecibida>((referencia) {
      final usuario = referencia.watch(proveedorUsuario).asData?.value;
      if (usuario?.puedeConsultarColmena != true) return const Stream.empty();
      return referencia
          .watch(proveedorServicioNotificaciones)
          .configurarRecepcion(usuario!);
    });

final proveedorAperturasNotificaciones =
    StreamProvider.autoDispose<AperturaAlerta>(
      (ref) => ref.watch(proveedorServicioNotificaciones).observarAperturas(),
    );

class ObservadorNotificaciones extends ConsumerStatefulWidget {
  const ObservadorNotificaciones({
    super.key,
    required this.contenido,
    required this.navegador,
  });
  final Widget contenido;
  final GlobalKey<NavigatorState> navegador;

  @override
  ConsumerState<ObservadorNotificaciones> createState() =>
      _ObservadorNotificacionesState();
}

class _ObservadorNotificacionesState
    extends ConsumerState<ObservadorNotificaciones> {
  AperturaAlerta? _pendiente;
  String? _ultima;
  bool _programado = false;
  bool _dialogoVisible = false;

  void _programar() {
    if (_programado || _dialogoVisible || _pendiente == null) return;
    _programado = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _programado = false;
      if (!mounted || _dialogoVisible) return;
      final usuario = ref.read(proveedorUsuario).asData?.value;
      final contexto = widget.navegador.currentState?.overlay?.context;
      final apertura = _pendiente;
      if (usuario?.puedeConsultarColmena != true ||
          contexto == null ||
          apertura == null) {
        return;
      }
      if (ref.read(proveedorColmenaSeleccionada).idColmena !=
          apertura.idColmena) {
        ref
            .read(proveedorSeleccionColmena.notifier)
            .seleccionar(apertura.idColmena);
        if (ref.read(proveedorColmenaSeleccionada).idColmena !=
            apertura.idColmena) {
          return;
        }
      }
      _pendiente = null;
      _ultima = '${apertura.idColmena}/${apertura.idAlerta}';
      _dialogoVisible = true;
      try {
        final abrir = await showDialog<bool>(
          context: contexto,
          builder: (_) => _DialogoAlerta(idUsuario: usuario!.idUsuario),
        );
        if (abrir == true && mounted && contexto.mounted) {
          abrirPantalla(contexto, ref, DestinoAplicacion.eventos);
        }
      } finally {
        _dialogoVisible = false;
        if (mounted) _programar();
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext contexto) {
    ref.listen(proveedorAperturasNotificaciones, (_, actual) {
      final apertura = actual.asData?.value;
      if (apertura != null &&
          _ultima != '${apertura.idColmena}/${apertura.idAlerta}') {
        _pendiente = apertura;
        _programar();
      }
    });
    ref.listen(proveedorUsuario, (_, _) => _programar());
    ref.listen(proveedorColmenaSeleccionada, (_, _) => _programar());
    ref.listen(proveedorCatalogoColmenas, (_, _) => _programar());
    ref.listen(proveedorNotificaciones, (anterior, actual) {
      if (actual.hasError) {
        debugPrint('FCM: no se pudo completar la recepcion: ${actual.error}');
      }
    });
    return widget.contenido;
  }
}

class _DialogoAlerta extends ConsumerWidget {
  const _DialogoAlerta({required this.idUsuario});
  final String idUsuario;

  @override
  Widget build(BuildContext contexto, WidgetRef ref) {
    final usuario = ref.watch(proveedorUsuario).asData?.value;
    final permitido =
        usuario?.puedeConsultarColmena == true &&
        usuario?.idUsuario == idUsuario;
    final conteo = permitido
        ? ref
              .watch(proveedorEventos)
              .when(
                data: (eventos) {
                  final pendientes = eventos
                      .where(
                        (evento) => evento.idAlerta != null && !evento.leida,
                      )
                      .length;
                  return switch (pendientes) {
                    0 => 'No tienes alertas sin leer.',
                    1 => 'Tienes 1 alerta sin leer.',
                    _ => 'Tienes $pendientes alertas sin leer.',
                  };
                },
                loading: () => 'Consultando alertas sin leer…',
                error: (_, _) => 'No se pudo consultar el conteo.',
              )
        : 'Inicia sesión como apicultor para consultar tus alertas.';
    return AlertDialog(
      icon: const Icon(Icons.notifications_active_outlined),
      title: const Text('Alertas de BeeCare'),
      content: Text(
        permitido
            ? 'Revisa la sección Eventos y alertas de tu colmena.\n\n$conteo'
            : conteo,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(contexto),
          child: const Text('Cerrar'),
        ),
        if (permitido)
          FilledButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Ver eventos y alertas'),
          ),
      ],
    );
  }
}
