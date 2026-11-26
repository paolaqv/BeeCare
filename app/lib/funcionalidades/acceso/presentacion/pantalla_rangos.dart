import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/servicios/proveedores_servicios.dart';
import '../proveedores/proveedor_acceso.dart';

class PantallaRangos extends ConsumerStatefulWidget {
  const PantallaRangos({super.key});

  @override
  ConsumerState<PantallaRangos> createState() => _EstadoPantallaRangos();
}

class _EstadoPantallaRangos extends ConsumerState<PantallaRangos> {
  static const _ruta = 'rangosReferencia';
  static const _metricas = {
    'temperatura': 'Temperatura S1 (°C)',
    'humedad': 'Humedad S1 (%)',
  };
  static const _campos = ['valorMinimo', 'valorMaximo'];

  static const _unidades = {'temperatura': '°C', 'humedad': '%'};

  final _controladores = {
    for (final metrica in _metricas.keys)
      metrica: {for (final campo in _campos) campo: TextEditingController()},
  };
  final _variacionPeso = TextEditingController();
  bool _ocupado = true;
  bool _cargado = false;
  String? _mensaje;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    for (final grupo in _controladores.values) {
      for (final controlador in grupo.values) {
        controlador.dispose();
      }
    }
    _variacionPeso.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _ocupado = true;
      _mensaje = null;
    });
    try {
      final datos = await ref.read(proveedorBaseDatos).leer(_ruta);
      if (!mounted) return;
      for (final metrica in _metricas.keys) {
        final rango = datos is Map ? datos[metrica] : null;
        for (final campo in _campos) {
          final valor = rango is Map ? rango[campo] : null;
          _controladores[metrica]![campo]!.text = valor?.toString() ?? '';
        }
      }
      final peso = datos is Map ? datos['peso'] : null;
      final variacion = peso is Map ? peso['variacionPorcentaje'] : null;
      _variacionPeso.text = variacion?.toString() ?? '10';
      _cargado = true;
    } catch (_) {
      _mensaje = 'No se pudieron cargar los rangos de Firebase.';
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  double? _leer(String metrica, String campo) => double.tryParse(
    _controladores[metrica]![campo]!.text.trim().replaceAll(',', '.'),
  );

  Future<void> _guardar() async {
    final usuario = ref.read(proveedorUsuario).asData?.value;
    if (usuario == null || !usuario.puedeGestionarSolicitudes) return;
    final variacion = double.tryParse(
      _variacionPeso.text.trim().replaceAll(',', '.'),
    );
    if (variacion == null ||
        !variacion.isFinite ||
        variacion <= 0 ||
        variacion >= 100) {
      setState(
        () => _mensaje =
            'Ingresa una variación de peso mayor que 0 y menor que 100 %.',
      );
      return;
    }
    final datos = <String, Object?>{
      'peso': {'variacionPorcentaje': variacion, 'unidad': '%'},
    };
    for (final entrada in _metricas.entries) {
      final minimo = _leer(entrada.key, 'valorMinimo');
      final maximo = _leer(entrada.key, 'valorMaximo');
      if (minimo == null ||
          maximo == null ||
          !minimo.isFinite ||
          !maximo.isFinite ||
          minimo >= maximo ||
          (entrada.key == 'temperatura' && (minimo < -40 || maximo > 80)) ||
          (entrada.key == 'humedad' && (minimo < 0 || maximo > 100))) {
        setState(() => _mensaje = 'Revisa los límites de ${entrada.value}.');
        return;
      }
      datos['${entrada.key}/valorMinimo'] = minimo;
      datos['${entrada.key}/valorMaximo'] = maximo;
      datos['${entrada.key}/unidad'] = _unidades[entrada.key]!;
    }
    setState(() {
      _ocupado = true;
      _mensaje = null;
    });
    try {
      await ref.read(proveedorBaseDatos).actualizar(_ruta, datos);
      _mensaje = 'Rangos guardados.';
    } catch (_) {
      _mensaje = 'Firebase no confirmó el guardado.';
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final autorizado =
        ref.watch(proveedorUsuario).asData?.value?.puedeGestionarSolicitudes ==
        true;
    return Scaffold(
      appBar: AppBar(title: const Text('Rangos de monitoreo')),
      body: !autorizado
          ? const Center(child: Text('Sección reservada al jefe de seguridad.'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_ocupado) const LinearProgressIndicator(),
                if (_cargado) ...[
                  for (final entrada in _metricas.entries) ...[
                    const SizedBox(height: 20),
                    Text(
                      entrada.value,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    for (final campo in _campos)
                      TextField(
                        controller: _controladores[entrada.key]![campo],
                        enabled: !_ocupado,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: true,
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: campo == 'valorMinimo'
                              ? 'Mínimo'
                              : 'Máximo',
                        ),
                      ),
                  ],
                  const SizedBox(height: 20),
                  TextField(
                    controller: _variacionPeso,
                    enabled: !_ocupado,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Variación respecto al peso habitual (%)',
                      helperText: 'Se aplica a aumentos y disminuciones.',
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _ocupado ? null : _guardar,
                    child: const Text('Guardar rangos'),
                  ),
                ] else if (!_ocupado)
                  OutlinedButton(
                    onPressed: _cargar,
                    child: const Text('Reintentar'),
                  ),
                if (_mensaje != null) Text(_mensaje!),
              ],
            ),
    );
  }
}
