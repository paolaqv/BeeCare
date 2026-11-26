import '../../monitoreo/presentacion/selector_colmena.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../nucleo/presentacion/navegacion.dart';
import '../../acceso/proveedores/proveedor_acceso.dart';
import '../../../nucleo/componentes/interfaz.dart';
import '../../monitoreo/dominio/medicion.dart';
import '../../telemetria/proveedores/proveedor_telemetria.dart';

class PantallaHistorico extends ConsumerStatefulWidget {
  const PantallaHistorico({super.key});
  @override
  ConsumerState<PantallaHistorico> createState() => _EstadoPantallaHistorico();
}

class _EstadoPantallaHistorico extends ConsumerState<PantallaHistorico> {
  late DateTime _inicio, _fin;
  String _variable = 'Todas';
  late Map<String, ({DateTime inicio, DateTime fin})> _periodos;
  @override
  void initState() {
    super.initState();
    final ahora = DateTime.now();
    _inicio = DateTime(ahora.year, ahora.month, ahora.day);
    _fin = _inicio
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));
    _periodos = {
      for (final variable in ['Temperatura', 'Humedad', 'Peso'])
        variable: (inicio: _inicio, fin: _fin),
    };
  }

  @override
  Widget build(BuildContext contexto) {
    if (ref.watch(proveedorUsuario).asData?.value?.puedeConsultarColmena !=
        true) {
      return const PantallaAccesoRestringido();
    }
    Widget grafica(
      String variable,
      String unidad,
      Color color,
      List<double? Function(Medicion)> valores,
    ) {
      final periodo = _periodos[variable]!;
      return ref
          .watch(proveedorHistorico(periodo))
          .when(
            skipLoadingOnReload: false,
            skipLoadingOnRefresh: false,
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, traza) => MensajeDatos(
              'Los datos de $variable no estan disponibles temporalmente.',
              reintentar: () => ref.invalidate(proveedorHistorico(periodo)),
            ),
            data: (registros) => registros.isEmpty
                ? MensajeDatos(
                    '$variable: datos no disponibles para el periodo seleccionado.',
                  )
                : _TarjetaGrafica(
                    variable == 'Peso'
                        ? 'Grafica de peso'
                        : 'Grafica de ${variable.toLowerCase()}',
                    unidad,
                    color,
                    registros,
                    valores,
                  ),
          );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Historico de datos')),
      body: ContenidoPagina(
        elementos: [
          const SelectorColmena(),
          Wrap(
            spacing: 20,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filtrar por:'),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(
                      '${formatearFecha(_inicio).split(' · ').first} al ${formatearFecha(_fin).split(' · ').first}',
                    ),
                    onPressed: () async {
                      final periodo = await showDateRangePicker(
                        context: contexto,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: DateTimeRange(
                          start: _inicio,
                          end: _fin,
                        ),
                      );
                      if (periodo == null || !mounted) return;
                      setState(() {
                        _inicio = periodo.start;
                        _fin = periodo.end
                            .add(const Duration(days: 1))
                            .subtract(const Duration(milliseconds: 1));
                        for (final variable in _periodos.keys) {
                          if (_variable == 'Todas' || variable == _variable) {
                            _periodos[variable] = (inicio: _inicio, fin: _fin);
                          }
                        }
                      });
                    },
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Aplicar en:'),
                  DropdownButton<String>(
                    value: _variable,
                    items: ['Todas', 'Temperatura', 'Humedad', 'Peso']
                        .map(
                          (variable) => DropdownMenuItem(
                            value: variable,
                            child: Text(variable),
                          ),
                        )
                        .toList(),
                    onChanged: (valor) => setState(() => _variable = valor!),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          grafica('Temperatura', '°C', const Color(0xFFC5758A), [
            (medicion) => medicion.temperaturaS1,
            (medicion) => medicion.temperaturaS2,
            (medicion) => medicion.temperaturaS3,
          ]),
          grafica('Humedad', '%', const Color(0xFF329DAB), [
            (medicion) => medicion.humedadS1,
            (medicion) => medicion.humedadS2,
            (medicion) => medicion.humedadS3,
          ]),
          grafica('Peso', 'kg', const Color(0xFF588957), [
            (medicion) => medicion.peso,
          ]),
        ],
      ),
    );
  }
}

class _TarjetaGrafica extends StatelessWidget {
  const _TarjetaGrafica(
    this.titulo,
    this.unidad,
    this.color,
    this.registros,
    this.valores,
  );
  final String titulo, unidad;
  final Color color;
  final List<Medicion> registros;
  final List<double? Function(Medicion)> valores;
  @override
  Widget build(BuildContext contexto) {
    final colores = valores.length == 1
        ? [color]
        : const [Color(0xFFC05263), Color(0xFF007F89), Color(0xFF7253A3)];
    final base = registros.first.fechaHora.millisecondsSinceEpoch;
    final series = valores
        .map(
          (valor) => registros.map((registro) {
            final lectura = valor(registro);
            return lectura?.isFinite == true
                ? FlSpot(
                    (registro.fechaHora.millisecondsSinceEpoch - base) / 60000,
                    lectura!,
                  )
                : FlSpot.nullSpot;
          }).toList(),
        )
        .toList();
    final puntosValidos = series
        .expand((serie) => serie)
        .where((punto) => !punto.isNull())
        .toList();
    if (puntosValidos.isEmpty) {
      return MensajeDatos('$titulo: dato no disponible.');
    }
    final minimo = puntosValidos
        .map((punto) => punto.y)
        .reduce((a, b) => a < b ? a : b);
    final maximo = puntosValidos
        .map((punto) => punto.y)
        .reduce((a, b) => a > b ? a : b);
    final margen = (maximo - minimo).abs() < .1 ? .1 : (maximo - minimo) * .2;
    final duracion =
        (registros.last.fechaHora.millisecondsSinceEpoch - base) / 60000;
    return TarjetaInformacion(
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$titulo · $unidad',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          if (valores.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  for (var indice = 0; indice < valores.length; indice++)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 10, color: colores[indice]),
                        const SizedBox(width: 6),
                        Text(
                          'S${indice + 1}${series[indice].every((punto) => punto.isNull()) ? ' · sin datos' : ''}',
                        ),
                      ],
                    ),
                ],
              ),
            ),
          const SizedBox(height: 26),
          Semantics(
            label:
                '$titulo: minimo ${minimo.toStringAsFixed(2)}, maximo ${maximo.toStringAsFixed(2)} $unidad',
            child: SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: minimo - margen,
                  maxY: maximo + margen,
                  minX: 0,
                  maxX: duracion <= 0 ? 1 : duracion,
                  gridData: const FlGridData(drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        getTitlesWidget: (v, meta) => Text(
                          v.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: duracion > 0 ? duracion / 3 : 1,
                        getTitlesWidget: (v, meta) {
                          final hora = DateTime.fromMillisecondsSinceEpoch(
                            base + (v * 60000).round(),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (puntos) => puntos
                          .map(
                            (punto) => LineTooltipItem(
                              '${valores.length > 1 ? 'S${punto.barIndex + 1}: ' : ''}${punto.y.toStringAsFixed(1)} $unidad',
                              TextStyle(
                                color: colores[punto.barIndex],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  lineBarsData: [
                    for (var indice = 0; indice < series.length; indice++)
                      LineChartBarData(
                        spots: series[indice],
                        color: colores[indice],
                        barWidth: 3,
                        isCurved: false,
                        dotData: FlDotData(show: series[indice].length < 12),
                        belowBarData: BarAreaData(show: false),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
