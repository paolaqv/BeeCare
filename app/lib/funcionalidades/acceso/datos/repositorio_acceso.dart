import 'dart:async';

import '../../../nucleo/datos/repositorio_realtime_database.dart';
import '../../../nucleo/servicios/servicio_autenticacion_firebase.dart';
import '../dominio/acceso.dart';

class RepositorioAccesoFirebase extends RepositorioAcceso {
  RepositorioAccesoFirebase(this.autenticacion, this.baseDatos);
  final ServicioAutenticacion autenticacion;
  final RepositorioRealtimeDatabase baseDatos;
  UsuarioAcceso _perfil(IdentidadAutenticada identidad, Object? valor) {
    final datos = mapaDatos(valor);
    return UsuarioAcceso(
      identidad.idUsuario,
      '${datos['nombre'] ?? ''} ${datos['apellido'] ?? ''}'.trim(),
      identidad.correo,
      datos['rol'] as String? ?? '',
      datos['estadoAcceso'] as String? ?? 'pendiente',
    );
  }

  @override
  Stream<UsuarioAcceso?> observarUsuario() {
    late StreamController<UsuarioAcceso?> controlador;
    StreamSubscription<IdentidadAutenticada?>? suscripcionIdentidad;
    StreamSubscription<Object?>? suscripcionPerfil;
    var version = 0;
    controlador = StreamController<UsuarioAcceso?>(
      onListen: () {
        suscripcionIdentidad = autenticacion.observarIdentidad().listen((
          identidad,
        ) async {
          final actual = ++version;
          await suscripcionPerfil?.cancel();
          if (controlador.isClosed || actual != version) return;
          if (identidad == null) {
            controlador.add(null);
            return;
          }
          suscripcionPerfil = baseDatos
              .observar('usuarios/${identidad.idUsuario}')
              .listen((valor) {
                if (!controlador.isClosed && actual == version) {
                  controlador.add(_perfil(identidad, valor));
                }
              }, onError: controlador.addError);
        }, onError: controlador.addError);
      },
      onCancel: () async {
        version++;
        await suscripcionIdentidad?.cancel();
        await suscripcionPerfil?.cancel();
      },
    );
    return controlador.stream;
  }

  @override
  Future<void> iniciarSesion(String correo, String contrasena) async {
    final identidad = await autenticacion.iniciarSesion(correo, contrasena);
    try {
      final usuario = _perfil(
        identidad,
        await baseDatos.leer('usuarios/${identidad.idUsuario}'),
      );
      if (!usuario.aprobado) {
        throw StateError(
          usuario.estado == 'rechazada'
              ? 'Tu solicitud fue rechazada. Comunicate con el jefe de seguridad.'
              : 'Tu solicitud de acceso aun no ha sido aprobada.',
        );
      }
      if (!usuario.esApicultor && !usuario.esJefeSeguridad) {
        throw StateError('Tu cuenta no tiene un rol autorizado.');
      }
    } catch (_) {
      await autenticacion.cerrarSesion();
      rethrow;
    }
  }

  @override
  Future<void> registrar(
    String nombres,
    String apellidos,
    String correo,
    String contrasena,
  ) async {
    final identidad = await autenticacion.crearCuenta(correo, contrasena);
    final fecha = DateTime.now().toUtc().toIso8601String();
    try {
      await baseDatos.actualizar('', {
        'usuarios/${identidad.idUsuario}': {
          'nombre': nombres,
          'apellido': apellidos,
          'correo': correo,
          'rol': 'apicultor',
          'estadoAcceso': 'pendiente',
          'fechaRegistro': fecha,
        },
        'solicitudesAcceso/${identidad.idUsuario}': {
          'nombre': nombres,
          'apellido': apellidos,
          'correo': correo,
          'estadoSolicitud': 'pendiente',
          'fechaSolicitud': fecha,
        },
      });
    } catch (_) {
      await autenticacion.eliminarCuentaRecienCreada();
      rethrow;
    } finally {
      await autenticacion.cerrarSesion();
    }
  }

  @override
  Future<void> cerrarSesion() => autenticacion.cerrarSesion();
  Future<UsuarioAcceso> _exigirJefe() async {
    final identidad = autenticacion.usuarioActual;
    if (identidad == null) throw StateError('Acceso restringido.');
    final usuario = _perfil(
      identidad,
      await baseDatos.leer('usuarios/${identidad.idUsuario}'),
    );
    if (!usuario.puedeGestionarSolicitudes) {
      throw StateError('Acceso restringido.');
    }
    return usuario;
  }

  @override
  Stream<List<SolicitudAcceso>> observarSolicitudes() async* {
    await _exigirJefe();
    yield* baseDatos
        .observar('solicitudesAcceso')
        .map(
          (valor) =>
              mapaDatos(valor).entries.map((entrada) {
                final datos = mapaDatos(entrada.value);
                return SolicitudAcceso(
                  entrada.key,
                  datos['nombre'] as String,
                  datos['apellido'] as String,
                  datos['correo'] as String,
                  DateTime.parse(datos['fechaSolicitud'] as String),
                  datos['estadoSolicitud'] as String,
                );
              }).toList()..sort(
                (primera, segunda) => segunda.fecha.compareTo(primera.fecha),
              ),
        );
  }

  @override
  Future<void> resolverSolicitud(String idUsuario, bool aceptar) async {
    final jefe = await _exigirJefe();
    final solicitud = mapaDatos(
      await baseDatos.leer('solicitudesAcceso/$idUsuario'),
    );
    if (solicitud['estadoSolicitud'] != 'pendiente') {
      throw StateError('La solicitud ya fue resuelta.');
    }
    final estado = aceptar ? 'aceptada' : 'rechazada';
    await baseDatos.actualizar('', {
      'solicitudesAcceso/$idUsuario/estadoSolicitud': estado,
      'solicitudesAcceso/$idUsuario/fechaRespuesta': DateTime.now()
          .toUtc()
          .toIso8601String(),
      'solicitudesAcceso/$idUsuario/idUsuarioResponsable': jefe.idUsuario,
      'usuarios/$idUsuario/estadoAcceso': estado,
    });
  }
}
