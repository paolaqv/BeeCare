/// Los eventos de BeeCare se registran en UTC (fechaHora terminada en Z).
/// Bolivia usa UTC-04:00 todo el ano, sin horario de verano.
/// La conversion no depende de la zona horaria del navegador.
DateTime fechaBolivia(DateTime fecha) =>
    fecha.toUtc().subtract(const Duration(hours: 4));

String formatearFechaBolivia(DateTime fecha, {bool incluirZona = true}) {
  final local = fechaBolivia(fecha);
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(local.day)}/${dos(local.month)}/${local.year} · '
      '${dos(local.hour)}:${dos(local.minute)}'
      '${incluirZona ? ' (Bolivia, UTC−4)' : ''}';
}
