import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/componentes/interfaz.dart';
import '../../../nucleo/presentacion/navegacion.dart';
import '../../../nucleo/utilidades/fecha_bolivia.dart';
import '../../acceso/proveedores/proveedor_acceso.dart';
import '../proveedores/proveedor_monitoreo.dart';
import '../proveedores/proveedor_colmenas.dart';
import 'selector_colmena.dart';

class PantallaMonitoreo extends ConsumerWidget {
  const PantallaMonitoreo({super.key});
  @override
  Widget build(BuildContext contexto, WidgetRef referencia) {
    if (referencia
            .watch(proveedorUsuario)
            .asData
            ?.value
            ?.puedeConsultarColmena !=
        true) {
      return const PantallaAccesoRestringido();
    }
    final colmena = referencia.watch(proveedorColmenaSeleccionada);
    final medicion = referencia.watch(proveedorLecturaActualColmena);
    final energia = referencia.watch(proveedorEstadoEnergetico);
    final soporte = referencia.watch(proveedorSoporteAmbiental);
    final dato =
        !medicion.isLoading &&
            medicion.asData?.value?.idColmena == colmena.idColmena
        ? medicion.asData?.value
        : null;
    String? avisoSensor(String sensor) =>
        switch (dato?.estadosSensores[sensor]) {
          'NO_RESPONDE' => 'El sensor no responde',
          'ERROR_LECTURA' => 'Error de lectura',
          'PESO_NEGATIVO' => 'Lectura negativa descartada',
          'FUERA_DE_RANGO' => 'Lectura fuera del rango del sensor',
          'LECTURA_PARCIAL' => 'Lectura parcial',
          'SIN_LECTURA' => 'Sensor sin lectura',
          'DESHABILITADO' => 'Monitor deshabilitado',
          _ => null,
        };
    final estadoEnergetico = energia.isLoading ? null : energia.asData?.value;
    final voltajeBateria = estadoEnergetico?.voltajeBateria;
    final porcentajeBateria = estadoEnergetico?.porcentajeBateria;
    final textoBateria = [
      if (estadoEnergetico?.estadoEnergia == 'SIN_LECTURA')
        avisoSensor('SensorBateria') ?? 'Sin lectura'
      else if (estadoEnergetico?.estadoEnergia case final String estado)
        estado,
      if (voltajeBateria != null) '${voltajeBateria.toStringAsFixed(2)} V',
      if (porcentajeBateria != null)
        '${porcentajeBateria.toStringAsFixed(0)} %',
    ];
    final estadoSoporte = soporte.isLoading ? null : soporte.asData?.value;
    final fase = estadoSoporte?.estado?.toUpperCase();
    final nombreFase = colmena.soporteAmbientalHabilitado == false
        ? 'Soporte no instalado'
        : switch (fase) {
            'INICIO' => 'Inicio',
            'NORMAL' => 'Normal',
            'VIGILANCIA' => 'Vigilancia',
            'INTERVENCION' => 'Intervención',
            'REPOSO' => 'Reposo',
            'FALLO' => 'Fallo',
            _ =>
              soporte.isLoading ? 'Cargando estado…' : 'Estado no disponible',
          };
    final intervaloClima = switch (fase) {
      'INICIO' => '1 min',
      'NORMAL' => '5 min',
      'VIGILANCIA' || 'REPOSO' || 'FALLO' => '30 s',
      'INTERVENCION' => '5 s',
      _ => null,
    };
    final fechaMedicion = dato == null
        ? null
        : formatearFechaBolivia(dato.fechaHora, incluirZona: false);
    final textoMedicion = fechaMedicion != null
        ? 'Última medición recibida $fechaMedicion'
        : medicion.isLoading
        ? 'Cargando última medición…'
        : medicion.hasError
        ? 'No se pudo consultar la última medición.'
        : 'Sin mediciones disponibles';
    String? numero(double? valor, String unidad) =>
        valor != null && valor.isFinite
        ? '${valor.toStringAsFixed(1)} $unidad'
        : null;
    final sensores = [
      ('S1', 'Centro del marco 5', dato?.temperaturaS1, dato?.humedadS1),
      ('S2', 'Lateral del marco 5', dato?.temperaturaS2, dato?.humedadS2),
      ('S3', 'Lateral del marco 1', dato?.temperaturaS3, dato?.humedadS3),
    ];
    return Scaffold(
      appBar: const BarraBeeCare(),
      drawer: const MenuAplicacion(),
      body: ContenidoPagina(
        elementos: [
          const SelectorColmena(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _AccesoSeccion(
                  'Monitoreo',
                  Icons.hive_outlined,
                  seleccionado: true,
                  alPulsar: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AccesoSeccion(
                  'Historico de datos',
                  Icons.show_chart,
                  alPulsar: () => abrirPantalla(
                    contexto,
                    referencia,
                    DestinoAplicacion.historico,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AccesoSeccion(
                  'Eventos',
                  Icons.notifications_outlined,
                  alPulsar: () => abrirPantalla(
                    contexto,
                    referencia,
                    DestinoAplicacion.eventos,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          TarjetaInformacion(
            contenido: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado de la colmena · $nombreFase',
                  style: Theme.of(contexto).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    if (intervaloClima != null) 'Clima cada $intervaloClima',
                    textoMedicion,
                  ].join(' · '),
                  key: const ValueKey('ultima-lectura'),
                  style: const TextStyle(color: marron),
                ),
                if (estadoSoporte?.activo case final bool activo)
                  Text(activo ? 'Peltier activa' : 'Peltier apagada'),
                if (avisoSensor('NTC') case final String aviso)
                  Text('NTC: $aviso'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (contexto, limites) {
              final ancho = limites.maxWidth >= 720
                  ? (limites.maxWidth - 24) / 3
                  : limites.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 0,
                children: [
                  for (final s in sensores)
                    SizedBox(
                      width: ancho,
                      child: TarjetaInformacion(
                        key: ValueKey('sensor-${s.$1}'),
                        color: const Color(0xFFF5E5AC),
                        contenido: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.sensors_outlined,
                                  color: marron,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  s.$1,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 19,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(s.$2, style: const TextStyle(color: marron)),
                            if (avisoSensor(s.$1) case final String aviso)
                              Text(
                                aviso,
                                style: const TextStyle(color: marron),
                              ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _Medida(
                                    'Temperatura ${s.$1}',
                                    numero(s.$3, '°C'),
                                    Icons.thermostat_outlined,
                                    cargando: medicion.isLoading,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _Medida(
                                    'Humedad ${s.$1}',
                                    numero(s.$4, '%'),
                                    Icons.water_drop_outlined,
                                    cargando: medicion.isLoading,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          TarjetaInformacion(
            color: const Color(0xFFF8EDBE),
            contenido: _Medida(
              'Peso de la colmena',
              numero(dato?.peso, 'kg') ??
                  (dato?.ultimoPesoValido != null
                      ? '${numero(dato?.ultimoPesoValido, 'kg')} (último válido)'
                      : avisoSensor('Peso')),
              Icons.scale_outlined,
              cargando: medicion.isLoading,
            ),
          ),
          TarjetaInformacion(
            color: const Color(0xFFF8EDBE),
            contenido: _Medida(
              'Batería',
              textoBateria.isEmpty ? null : textoBateria.join('\n'),
              estadoEnergetico?.cargaSolar == true
                  ? Icons.solar_power_outlined
                  : Icons.battery_std_outlined,
              cargando: energia.isLoading,
              descripcionAccesible: estadoEnergetico?.cargaSolar == true
                  ? 'Carga solar activa'
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccesoSeccion extends StatelessWidget {
  const _AccesoSeccion(
    this.titulo,
    this.icono, {
    required this.alPulsar,
    this.seleccionado = false,
  });
  final String titulo;
  final IconData icono;
  final VoidCallback alPulsar;
  final bool seleccionado;
  @override
  Widget build(BuildContext contexto) => Material(
    color: seleccionado ? const Color(0xFFFFD979) : const Color(0xFFE6DDC8),
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: alPulsar,
      child: SizedBox(
        height: 128,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, size: 32, color: tinta),
              const SizedBox(height: 12),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Medida extends StatelessWidget {
  const _Medida(
    this.etiqueta,
    this.valor,
    this.icono, {
    this.cargando = false,
    this.descripcionAccesible,
  });
  final String etiqueta;
  final String? valor, descripcionAccesible;
  final IconData icono;
  final bool cargando;
  @override
  Widget build(BuildContext contexto) => Semantics(
    label: descripcionAccesible,
    child: Column(
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 118),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF5),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Icon(icono, size: 32, color: tinta),
              const SizedBox(height: 12),
              if (cargando)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  valor ?? 'Dato no disponible',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: valor == null ? 14 : 19,
                    fontWeight: FontWeight.w600,
                    color: valor == null ? const Color(0xFFB34037) : tinta,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(etiqueta, textAlign: TextAlign.center),
      ],
    ),
  );
}
