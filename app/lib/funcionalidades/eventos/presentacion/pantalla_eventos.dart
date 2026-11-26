import '../../monitoreo/presentacion/selector_colmena.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/componentes/interfaz.dart';
import '../../../nucleo/presentacion/navegacion.dart';
import '../../../nucleo/utilidades/fecha_bolivia.dart';
import '../../acceso/proveedores/proveedor_acceso.dart';
import '../../telemetria/dominio/interprete_eventos.dart';
import '../../telemetria/dominio/telemetria.dart';
import '../../telemetria/proveedores/proveedor_telemetria.dart';

enum _Filtro { todos, eventos, alertas, pendientes }

class PantallaEventos extends ConsumerStatefulWidget {
  const PantallaEventos({super.key});

  @override
  ConsumerState<PantallaEventos> createState() => _EstadoPantallaEventos();
}

class _EstadoPantallaEventos extends ConsumerState<PantallaEventos> {
  _Filtro filtro = _Filtro.todos;
  String busqueda = '';

  @override
  Widget build(BuildContext contexto) {
    if (ref.watch(proveedorUsuario).asData?.value?.puedeConsultarColmena !=
        true) {
      return const PantallaAccesoRestringido();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Eventos y alertas')),
      body: SafeArea(
        child: ref
            .watch(proveedorEventos)
            .when(
              skipLoadingOnReload: false,
              skipLoadingOnRefresh: false,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, traza) => Padding(
                padding: const EdgeInsets.all(24),
                child: MensajeDatos(
                  'No se pudieron consultar los eventos. Comprueba la conexion y los permisos de Firebase.',
                  reintentar: () => ref.invalidate(proveedorEventos),
                ),
              ),
              data: (registros) {
                final sinLeer = registros
                    .where((e) => e.idAlerta != null && !e.leida)
                    .length;
                final alertas = registros
                    .where((e) => e.idAlerta != null)
                    .length;
                final filtrados = registros.where((evento) {
                  final aceptaTipo = switch (filtro) {
                    _Filtro.todos => true,
                    _Filtro.eventos => evento.idAlerta == null,
                    _Filtro.alertas => evento.idAlerta != null,
                    _Filtro.pendientes =>
                      evento.idAlerta != null && !evento.leida,
                  };
                  if (!aceptaTipo) return false;
                  final contenido = InterpreteEventos.interpretar(evento);
                  final query = busqueda.trim().toLowerCase();
                  return query.isEmpty ||
                      '${contenido.titulo} ${contenido.resumen} ${contenido.categoria} ${evento.descripcion}'
                          .toLowerCase()
                          .contains(query);
                }).toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SelectorColmena(),
                            Text(
                              'Actividad de tu colmena',
                              style: Theme.of(contexto).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: tinta,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Consulta que ocurrio, cuando y que significa cada registro.',
                              style: TextStyle(color: Color(0xFF746B63)),
                            ),
                            const SizedBox(height: 18),
                            _ResumenActividad(
                              eventos: registros.length - alertas,
                              alertas: alertas,
                              sinLeer: sinLeer,
                            ),
                            const SizedBox(height: 18),
                            TextField(
                              onChanged: (texto) =>
                                  setState(() => busqueda = texto),
                              decoration: InputDecoration(
                                hintText:
                                    'Buscar por sensor, temperatura, bateria…',
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _filtroChip('Todos', _Filtro.todos),
                                _filtroChip('Eventos', _Filtro.eventos),
                                _filtroChip('Alertas', _Filtro.alertas),
                                _filtroChip(
                                  'Sin leer ($sinLeer)',
                                  _Filtro.pendientes,
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${filtrados.length} registros',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: tinta,
                                  ),
                                ),
                                const Text(
                                  'Mas recientes primero',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF746B63),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (filtrados.isEmpty)
                              const MensajeDatos(
                                'No hay registros que coincidan con los filtros.',
                              )
                            else
                              ...filtrados.map(
                                (evento) => _TarjetaEvento(
                                  key: ValueKey(evento.id),
                                  evento: evento,
                                  alAbrir: () =>
                                      _abrirDetalle(contexto, evento),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
      ),
    );
  }

  Widget _filtroChip(String texto, _Filtro candidato) => ChoiceChip(
    label: Text(texto),
    selected: filtro == candidato,
    selectedColor: miel.withValues(alpha: 0.27),
    onSelected: (_) => setState(() => filtro = candidato),
  );

  Future<void> _marcarLeida(EventoColmena evento) async {
    if (evento.idAlerta == null || evento.leida) return;
    try {
      await ref.read(proveedorControladorAlertas).marcarLeida(evento.idAlerta!);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(describirError(error))));
      }
    }
  }

  Future<void> _abrirDetalle(
    BuildContext contexto,
    EventoColmena evento,
  ) async {
    final descripcion = InterpreteEventos.interpretar(evento);
    final estilo = _estilo(evento, descripcion);
    await showModalBottomSheet<void>(
      context: contexto,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: crema,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modal) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            MediaQuery.viewInsetsOf(modal).bottom + 26,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(modal).height * 0.76,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(estilo.icono, color: estilo.color, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          descripcion.categoria.toUpperCase(),
                          style: TextStyle(
                            color: estilo.color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    descripcion.titulo,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: tinta,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    descripcion.resumen,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  if (descripcion.valorDestacado != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      descripcion.valorDestacado!,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: estilo.color,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    descripcion.detalle,
                    key: const ValueKey('interpretacion-evento'),
                    style: const TextStyle(height: 1.55),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 18, color: marron),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          formatearFechaBolivia(evento.fecha),
                          style: const TextStyle(color: Color(0xFF746B63)),
                        ),
                      ),
                    ],
                  ),
                  if (evento.idAlerta != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      evento.leida
                          ? 'Alerta leida'
                          : 'Alerta pendiente de lectura',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (!evento.leida) ...[
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: () async {
                          await _marcarLeida(evento);
                          if (modal.mounted) Navigator.pop(modal);
                        },
                        icon: const Icon(Icons.done_all),
                        label: const Text('Marcar como leida'),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResumenActividad extends StatelessWidget {
  const _ResumenActividad({
    required this.eventos,
    required this.alertas,
    required this.sinLeer,
  });
  final int eventos, alertas, sinLeer;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      _Metrica('Eventos', eventos, Icons.timeline_outlined),
      _Metrica('Alertas', alertas, Icons.notifications_outlined),
      _Metrica('Sin leer', sinLeer, Icons.mark_email_unread_outlined),
    ],
  );
}

class _Metrica extends StatelessWidget {
  const _Metrica(this.titulo, this.valor, this.icono);
  final String titulo;
  final int valor;
  final IconData icono;
  @override
  Widget build(BuildContext contexto) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFEDE5D5)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, color: marron, size: 20),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$valor',
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            Text(
              titulo,
              style: const TextStyle(fontSize: 12, color: Color(0xFF746B63)),
            ),
          ],
        ),
      ],
    ),
  );
}

class _TarjetaEvento extends StatelessWidget {
  const _TarjetaEvento({
    super.key,
    required this.evento,
    required this.alAbrir,
  });
  final EventoColmena evento;
  final VoidCallback alAbrir;
  @override
  Widget build(BuildContext contexto) {
    final interpretacion = InterpreteEventos.interpretar(evento);
    final estilo = _estilo(evento, interpretacion);
    final esAlerta = evento.idAlerta != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: alAbrir,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFEDE5D5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: estilo.color.withValues(alpha: .12),
                  child: Icon(estilo.icono, color: estilo.color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            interpretacion.categoria.toUpperCase(),
                            style: TextStyle(
                              color: estilo.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            esAlerta
                                ? evento.critico
                                      ? '· CRITICA'
                                      : '· ALERTA'
                                : '· REGISTRO',
                            style: TextStyle(
                              color: estilo.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (esAlerta && !evento.leida)
                            const Text(
                              '● SIN LEER',
                              style: TextStyle(
                                color: Color(0xFFBD4B3F),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        interpretacion.titulo,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: tinta,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        interpretacion.resumen,
                        style: const TextStyle(
                          height: 1.45,
                          color: Color(0xFF605952),
                        ),
                      ),
                      if (interpretacion.valorDestacado != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          interpretacion.valorDestacado!,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: estilo.color,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 14,
                            color: Color(0xFF746B63),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              formatearFechaBolivia(evento.fecha),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF746B63),
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: marron),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

({IconData icono, Color color}) _estilo(
  EventoColmena evento,
  InterpretacionEvento interpretacion,
) {
  if (evento.critico) {
    return (
      icono: Icons.report_gmailerrorred_outlined,
      color: const Color(0xFFBD4B3F),
    );
  }
  return switch (interpretacion.simbolo) {
    'baja' => (icono: Icons.thermostat_outlined, color: marron),
    'alta' => (
      icono: Icons.device_thermostat_outlined,
      color: const Color(0xFFB65B39),
    ),
    'sensor' => (
      icono: Icons.sensors_off_outlined,
      color: const Color(0xFFB65B39),
    ),
    'recuperado' => (
      icono: Icons.check_circle_outline,
      color: const Color(0xFF477A57),
    ),
    'energia' => (icono: Icons.battery_alert_outlined, color: marron),
    'critico' => (
      icono: Icons.warning_amber_rounded,
      color: const Color(0xFFBD4B3F),
    ),
    'estado' => (icono: Icons.autorenew_outlined, color: marron),
    _ => (icono: Icons.notifications_outlined, color: marron),
  };
}
