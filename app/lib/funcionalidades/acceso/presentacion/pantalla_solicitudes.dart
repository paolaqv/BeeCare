import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/presentacion/navegacion.dart';
import '../../../nucleo/componentes/interfaz.dart';
import '../dominio/acceso.dart';
import '../proveedores/proveedor_acceso.dart';

class PantallaSolicitudes extends ConsumerStatefulWidget {
  const PantallaSolicitudes({super.key});
  @override
  ConsumerState<PantallaSolicitudes> createState() =>
      _EstadoPantallaSolicitudes();
}

class _EstadoPantallaSolicitudes extends ConsumerState<PantallaSolicitudes> {
  String _filtro = 'pendiente';
  @override
  Widget build(BuildContext contexto) {
    if (!(ref
            .watch(proveedorUsuario)
            .asData
            ?.value
            ?.puedeGestionarSolicitudes ??
        false)) {
      return Scaffold(
        appBar: AppBar(),
        body: const ContenidoPagina(
          elementos: [
            MensajeDatos(
              'Esta seccion esta reservada al responsable de acceso.',
            ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: const BarraBeeCare(),
      drawer: const MenuAplicacion(),
      body: ContenidoPagina(
        elementos: [
          DropdownButtonFormField<String>(
            initialValue: _filtro,
            decoration: const InputDecoration(labelText: 'Solicitudes:'),
            items: const [
              DropdownMenuItem(value: 'pendiente', child: Text('Pendientes')),
              DropdownMenuItem(value: 'aceptada', child: Text('Aceptadas')),
              DropdownMenuItem(value: 'rechazada', child: Text('Rechazadas')),
              DropdownMenuItem(value: 'todas', child: Text('Todas')),
            ],
            onChanged: (v) => setState(() => _filtro = v!),
          ),
          const SizedBox(height: 22),
          ref
              .watch(proveedorSolicitudes)
              .when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => MensajeDatos(
                  'No se pudieron obtener las solicitudes.',
                  reintentar: () => ref.invalidate(proveedorSolicitudes),
                ),
                data: (solicitudes) {
                  final visibles = solicitudes
                      .where((r) => _filtro == 'todas' || r.estado == _filtro)
                      .toList();
                  if (visibles.isEmpty) {
                    return const MensajeDatos(
                      'No hay solicitudes en este estado.',
                    );
                  }
                  return Column(
                    children: visibles
                        .map(
                          (r) => TarjetaInformacion(
                            contenido: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      backgroundColor: Color(0xFFFFEAB4),
                                      child: Icon(
                                        Icons.person_outline,
                                        color: marron,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            r.nombre,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 17,
                                            ),
                                          ),
                                          Text(r.correo),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Text('Solicitado: ${formatearFecha(r.fecha)}'),
                                const SizedBox(height: 6),
                                Text('Estado: ${r.estado}'),
                                const SizedBox(height: 16),
                                OutlinedButton(
                                  onPressed: () => showDialog<void>(
                                    context: contexto,
                                    builder: (_) =>
                                        _DialogoSolicitud(solicitud: r),
                                  ),
                                  child: const Text('Ver solicitud'),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
        ],
      ),
    );
  }
}

class _DialogoSolicitud extends ConsumerStatefulWidget {
  const _DialogoSolicitud({required this.solicitud});
  final SolicitudAcceso solicitud;
  @override
  ConsumerState<_DialogoSolicitud> createState() => _EstadoDialogoSolicitud();
}

class _EstadoDialogoSolicitud extends ConsumerState<_DialogoSolicitud> {
  bool _ocupado = false;
  String? _error;
  Future<void> _resolver(bool aceptar) async {
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await ref
          .read(proveedorControladorSolicitudes)
          .responderSolicitud(widget.solicitud.idUsuario, aceptar);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            aceptar
                ? 'Solicitud aceptada. El usuario ya puede ingresar.'
                : 'Solicitud rechazada.',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _ocupado = false;
          _error = describirError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext contexto) {
    if (ref.watch(proveedorUsuario).asData?.value?.puedeGestionarSolicitudes !=
        true) {
      return const AlertDialog(content: Text('Acceso restringido.'));
    }
    final r = widget.solicitud;
    return PopScope(
      canPop: !_ocupado,
      child: AlertDialog(
        title: const Text('Solicitud de acceso'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.account_circle_outlined,
                size: 52,
                color: marron,
              ),
              const SizedBox(height: 18),
              Text('Nombres: ${r.nombres}'),
              const SizedBox(height: 10),
              Text('Apellidos: ${r.apellidos}'),
              const SizedBox(height: 10),
              Text('Correo: ${r.correo}'),
              const SizedBox(height: 10),
              Text('Solicitado: ${formatearFecha(r.fecha)}'),
              const SizedBox(height: 10),
              Text('Estado: ${r.estado}'),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              if (_ocupado)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _ocupado ? null : () => Navigator.pop(contexto),
            child: const Text('Cerrar'),
          ),
          if (r.estado == 'pendiente') ...[
            TextButton(
              onPressed: _ocupado ? null : () => _resolver(false),
              child: const Text(
                'Rechazar',
                style: TextStyle(color: Colors.red),
              ),
            ),
            FilledButton(
              onPressed: _ocupado ? null : () => _resolver(true),
              child: const Text('Aceptar'),
            ),
          ],
        ],
      ),
    );
  }
}
