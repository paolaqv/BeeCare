import 'dart:async';

import '../../../nucleo/configuracion.dart';
import '../../../nucleo/datos/repositorio_realtime_database.dart';
import '../../monitoreo/datos/conversor_lectura.dart';
import '../../monitoreo/dominio/medicion.dart';
import '../dominio/telemetria.dart';

class RepositorioTelemetriaFirebase implements RepositorioTelemetria {
  const RepositorioTelemetriaFirebase(
    this.baseDatos, {
    this.idColmena = ConfiguracionAplicacion.idColmena,
    this.idPrototipo = ConfiguracionAplicacion.idPrototipo,
  });
  final String idColmena, idPrototipo;
  final RepositorioRealtimeDatabase baseDatos;
  @override
  Stream<List<Medicion>> observarHistorico(DateTime inicio, DateTime fin) =>
      baseDatos
          .observar(
            'mediciones/$idColmena',
            inicio: inicio,
            fin: fin,
            limite: 2000,
          )
          .map(
            (valor) =>
                mapaDatos(valor).entries
                    .map(
                      (entrada) => medicionDesdeJson(
                        mapaDatos(entrada.value),
                        idMedicion: entrada.key,
                        idColmena: idColmena,
                      ),
                    )
                    .toList()
                  ..sort(
                    (primera, segunda) =>
                        primera.fechaHora.compareTo(segunda.fechaHora),
                  ),
          );
  @override
  Stream<List<EventoColmena>> observarEventos(String idUsuario) {
    late StreamController<List<EventoColmena>> controlador;
    final suscripciones = <StreamSubscription<Object?>>[];
    final grupos = <String, Map<String, dynamic>>{};
    final rutaEventos = 'eventosSistema/$idPrototipo';
    final rutaAlertas = 'alertas/$idColmena';
    final rutaLeidas = 'alertasLeidas/$idUsuario';

    void emitir() {
      if (controlador.isClosed ||
          !grupos.containsKey(rutaEventos) ||
          !grupos.containsKey(rutaAlertas) ||
          !grupos.containsKey(rutaLeidas)) {
        return;
      }
      final resultado = <EventoColmena>[];
      for (final ruta in [rutaEventos, rutaAlertas]) {
        for (final entrada in (grupos[ruta] ?? {}).entries) {
          try {
            final datos = mapaDatos(entrada.value);
            final fecha = DateTime.tryParse('${datos['fechaHora'] ?? ''}');
            if (fecha == null) continue;
            final esAlerta = ruta == rutaAlertas;
            final nivel = '${datos['nivel'] ?? ''}'.toLowerCase();
            final valor = datos['valorRegistrado'];
            final descripcion =
                '${datos['descripcion'] ?? datos['motivo'] ?? ''}';
            resultado.add(
              EventoColmena(
                '$ruta/${entrada.key}',
                '${datos['categoria'] ?? (esAlerta ? 'alerta' : 'sistema')}',
                '${datos['tipoEvento'] ?? datos['tipoAlerta'] ?? 'Evento del sistema'}',
                '$descripcion${valor == null ? '' : '\n$valor ${datos['unidad'] ?? ''}'}',
                fecha,
                nivel == 'critico' || nivel == 'critico',
                idAlerta: esAlerta ? entrada.key : null,
                datos: datos,
                leida:
                    esAlerta &&
                    mapaDatos(grupos[rutaLeidas]?[entrada.key])['leida'] ==
                        true,
              ),
            );
          } catch (_) {
            // Un registro antiguo mal formado no oculta los demas eventos.
          }
        }
      }
      resultado.sort((a, b) => b.fecha.compareTo(a.fecha));
      controlador.add(resultado);
    }

    controlador = StreamController<List<EventoColmena>>(
      onListen: () {
        for (final ruta in [rutaEventos, rutaAlertas, rutaLeidas]) {
          suscripciones.add(
            baseDatos
                .observar(ruta, limite: ruta == rutaLeidas ? null : 100)
                .listen(
                  (valor) {
                    grupos[ruta] = mapaDatos(valor);
                    emitir();
                  },
                  onError: (Object error, StackTrace traza) {
                    if (ruta == rutaLeidas) {
                      // Si aun no hay reglas para lectura de marcas,
                      // los eventos deben seguir visibles.
                      grupos[ruta] = {};
                      emitir();
                    } else if (!controlador.isClosed) {
                      controlador.addError(error, traza);
                    }
                  },
                ),
          );
        }
      },
      onCancel: () async {
        for (final suscripcion in suscripciones) {
          await suscripcion.cancel();
        }
      },
    );
    return controlador.stream;
  }

  @override
  Future<void> marcarLeida(String idUsuario, String idAlerta) =>
      baseDatos.guardar('alertasLeidas/$idUsuario/$idAlerta', {
        'leida': true,
        'fechaLectura': DateTime.now().toUtc().toIso8601String(),
      });
}
