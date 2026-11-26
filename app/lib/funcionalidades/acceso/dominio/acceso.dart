class UsuarioAcceso {
  const UsuarioAcceso(
    this.idUsuario,
    this.nombre,
    this.correo,
    this.rol,
    this.estado,
  );
  final String idUsuario, nombre, correo, rol, estado;
  bool get aprobado => estado == 'aceptada';
  bool get esApicultor => rol == 'apicultor';
  // El documento usa Responsable de acceso; el usuario lo denomina Jefe de seguridad.
  bool get esJefeSeguridad => const [
    'jefe_seguridad',
    'jefe de seguridad',
    'responsable',
    'responsable_acceso',
  ].contains(rol);
  bool get puedeConsultarColmena => aprobado && esApicultor;
  bool get puedeGestionarSolicitudes => aprobado && esJefeSeguridad;
}

class SolicitudAcceso {
  const SolicitudAcceso(
    this.idUsuario,
    this.nombres,
    this.apellidos,
    this.correo,
    this.fecha,
    this.estado,
  );
  final String idUsuario, nombres, apellidos, correo, estado;
  final DateTime fecha;
  String get nombre => '$nombres $apellidos';
}

abstract class RepositorioAcceso {
  Stream<UsuarioAcceso?> observarUsuario();
  Future<void> iniciarSesion(String correo, String contrasena);
  Future<void> registrar(
    String nombres,
    String apellidos,
    String correo,
    String contrasena,
  );
  Future<void> cerrarSesion();
  Stream<List<SolicitudAcceso>> observarSolicitudes();
  Future<void> resolverSolicitud(String idUsuario, bool aceptar);
  void dispose() {}
}
