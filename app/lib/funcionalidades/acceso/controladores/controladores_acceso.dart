import '../dominio/acceso.dart';
import '../../../nucleo/servicios/servicio_notificaciones.dart';

class ControladorAutenticacion {
  const ControladorAutenticacion(this.repositorio, this.notificaciones);
  final ServicioNotificaciones notificaciones;
  final RepositorioAcceso repositorio;
  Stream<UsuarioAcceso?> obtenerUsuarioActual() =>
      repositorio.observarUsuario();
  Future<void> iniciarSesion(String correo, String contrasena) =>
      repositorio.iniciarSesion(correo, contrasena);
  Future<void> cerrarSesion() async {
    try {
      await notificaciones.detenerRecepcion();
    } finally {
      await repositorio.cerrarSesion();
    }
  }
}

class ControladorSolicitudes {
  const ControladorSolicitudes(this.repositorio, this.usuario);
  final RepositorioAcceso repositorio;
  final UsuarioAcceso? usuario;
  Future<void> registrarSolicitud(
    String nombres,
    String apellidos,
    String correo,
    String contrasena,
  ) => repositorio.registrar(nombres, apellidos, correo, contrasena);
  Stream<List<SolicitudAcceso>> listarSolicitudes() =>
      usuario?.puedeGestionarSolicitudes == true
      ? repositorio.observarSolicitudes()
      : Stream.error(StateError('Acceso restringido.'));
  Future<void> responderSolicitud(String idUsuario, bool aceptar) async {
    if (usuario?.puedeGestionarSolicitudes != true) {
      throw StateError('Acceso restringido.');
    }
    await repositorio.resolverSolicitud(idUsuario, aceptar);
  }
}
