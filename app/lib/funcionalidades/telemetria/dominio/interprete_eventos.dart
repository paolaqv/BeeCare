import 'telemetria.dart';

/// Presentacion legible de los codigos tecnicos recibidos desde Firebase.
/// No altera ni reescribe los registros historicos.
class InterpretacionEvento {
  const InterpretacionEvento({
    required this.titulo,
    required this.resumen,
    required this.detalle,
    required this.categoria,
    required this.simbolo,
    this.valorDestacado,
  });
  final String titulo, resumen, detalle, categoria, simbolo;
  final String? valorDestacado;
}

class InterpreteEventos {
  const InterpreteEventos._();

  static InterpretacionEvento interpretar(EventoColmena evento) {
    final datos = evento.datos;
    final codigo = (datos['tipoEvento'] ?? datos['tipoAlerta'] ?? evento.titulo)
        .toString()
        .toUpperCase();
    final sensor = (datos['sensorId'] ?? 'S1').toString().toUpperCase();
    final ubicacion = _ubicacion(sensor);
    final temperatura = _numero(datos['temperaturaS1']);
    final temperaturaSalida = _numero(datos['temperaturaSalida']);
    final voltaje = _numero(datos['voltajeBateria']);
    final nivel = (datos['nivel'] ?? '').toString();
    final motivo = (datos['motivo'] ?? '').toString();
    final esAlerta = evento.idAlerta != null;

    switch (codigo) {
      case 'TEMPERATURA_BAJA':
        return InterpretacionEvento(
          titulo: 'Temperatura por debajo de la referencia',
          resumen: temperatura == null
              ? 'S1 registro una temperatura inferior al umbral configurado.'
              : 'El sensor S1 registro ${_decimal(temperatura)} °C, por debajo de la referencia de 32 °C.',
          detalle:
              'Ubicacion: centro del marco 5. '
              'Este registro compara la lectura con el umbral configurado; '
              'por si solo no significa que exista una emergencia apicola. '
              '${temperaturaSalida == null ? '' : 'Temperatura NTC de salida: ${_decimal(temperaturaSalida)} °C.'}',
          categoria: 'Temperatura',
          simbolo: 'baja',
          valorDestacado: temperatura == null
              ? null
              : '${_decimal(temperatura)} °C',
        );
      case 'TEMPERATURA_ALTA':
        return InterpretacionEvento(
          titulo: 'Temperatura elevada en S1',
          resumen: temperatura == null
              ? 'La temperatura central supero el limite configurado.'
              : 'S1 alcanzo ${_decimal(temperatura)} °C, por encima de la referencia configurada.',
          detalle: 'Sensor S1, centro del marco 5. Revisa la evolucion de la temperatura y el contexto de la prueba.',
          categoria: 'Temperatura',
          simbolo: 'alta',
          valorDestacado: temperatura == null
              ? null
              : '${_decimal(temperatura)} °C',
        );
      case 'TEMPERATURA_RECUPERADA':
        return const InterpretacionEvento(
          titulo: 'Temperatura recuperada',
          resumen: 'S1 volvio a cumplir la referencia termica configurada.',
          detalle: 'El controlador registro el retorno de la condicion de temperatura.',
          categoria: 'Temperatura',
          simbolo: 'recuperado',
        );
      case 'FALLO_SENSOR':
        return InterpretacionEvento(
          titulo: 'Sin lecturas validas de $sensor',
          resumen: 'El sensor $sensor dejo de proporcionar mediciones validas.',
          detalle:
              'Ubicacion: $ubicacion. Revisa alimentacion, cable de datos y conexiones. '
              'La deteccion puede requerir varias lecturas fallidas.',
          categoria: 'Sensores',
          simbolo: 'sensor',
        );
      case 'SENSOR_RECUPERADO':
        return InterpretacionEvento(
          titulo: 'Sensor $sensor recuperado',
          resumen: '$sensor volvio a entregar mediciones validas.',
          detalle:
              'Ubicacion: $ubicacion. Verifica que los datos continuen estables.',
          categoria: 'Sensores',
          simbolo: 'recuperado',
        );
      case 'CAMBIO_ESTADO':
        final anterior = _estado(datos['estadoAnterior']);
        final nuevo = _estado(datos['estadoSoporte']);
        return InterpretacionEvento(
          titulo: 'Cambio de estado del soporte',
          resumen: 'El controlador paso de $anterior a $nuevo.',
          detalle: motivo.isEmpty
              ? 'Cambio registrado por el controlador ambiental.'
              : 'Motivo tecnico: ${_motivo(motivo)}.',
          categoria: 'Soporte ambiental',
          simbolo: 'estado',
        );
      case 'FALLO_TERMICO':
        return InterpretacionEvento(
          titulo: 'Proteccion termica activada',
          resumen: 'El controlador informo una condicion de seguridad termica.',
          detalle:
              'Comprueba el NTC, los actuadores y el estado fisico del soporte antes de volver a intervenir.'
              '${motivo.isEmpty ? '' : ' Motivo: ${_motivo(motivo)}.'}',
          categoria: 'Soporte ambiental',
          simbolo: 'critico',
        );
      case 'BATERIA_BAJA':
      case 'BATERIA_CRITICA':
        final critica = codigo == 'BATERIA_CRITICA';
        return InterpretacionEvento(
          titulo: critica
              ? 'Nivel de bateria critico'
              : 'Nivel de bateria bajo',
          resumen: critica
              ? 'La alimentacion del prototipo requiere atencion.'
              : 'Se detecto un nivel de bateria inferior al umbral de advertencia.',
          detalle: voltaje == null
              ? 'Consulta el estado energetico para revisar la alimentacion.'
              : 'Voltaje registrado: ${_decimal(voltaje)} V. Consulta el estado energetico.',
          categoria: 'Energia',
          simbolo: critica ? 'critico' : 'energia',
          valorDestacado: voltaje == null ? null : '${_decimal(voltaje)} V',
        );
      case 'BATERIA_RECUPERADA':
        return const InterpretacionEvento(
          titulo: 'Bateria recuperada',
          resumen: 'El sistema volvio a registrar un estado energetico normal.',
          detalle: 'Comprueba la evolucion del voltaje y la alimentacion.',
          categoria: 'Energia',
          simbolo: 'recuperado',
        );
      default:
        final original =
            (datos['descripcion'] ?? datos['motivo'] ?? evento.descripcion)
                .toString();
        final texto = original.isEmpty
            ? 'Registro generado por el prototipo BeeCare.'
            : _motivo(original);
        return InterpretacionEvento(
          titulo: _motivo(codigo),
          resumen: texto,
          detalle:
              'Categoria original: ${evento.categoria}. ${nivel.isEmpty ? '' : 'Nivel: $nivel.'}',
          categoria: _motivo(evento.categoria),
          simbolo: esAlerta ? 'alerta' : 'estado',
        );
    }
  }

  static String _ubicacion(String sensor) => switch (sensor) {
    'S1' => 'centro del marco 5',
    'S2' => 'costado del marco 5',
    'S3' => 'costado del marco 1',
    _ => 'ubicacion no especificada',
  };
  static String _estado(dynamic estado) => switch ('$estado'.toUpperCase()) {
    'INICIO' => 'inicializacion',
    'NORMAL' => 'monitoreo normal',
    'VIGILANCIA' => 'vigilancia',
    'INTERVENCION' => 'intervencion termica',
    'REPOSO' => 'reposo',
    'FALLO' => 'fallo de seguridad',
    _ => _motivo('$estado'),
  };
  static double? _numero(dynamic valor) =>
      valor is num ? valor.toDouble() : double.tryParse('$valor');
  static String _decimal(double valor) =>
      valor.toStringAsFixed(1).replaceAll('.', ',');
  static String _motivo(String valor) {
    final limpio = valor.replaceAll('_', ' ').trim().toLowerCase();
    if (limpio.isEmpty) return 'Evento del sistema';
    return limpio[0].toUpperCase() + limpio.substring(1);
  }
}
