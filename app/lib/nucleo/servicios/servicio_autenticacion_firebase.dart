import 'package:firebase_auth/firebase_auth.dart';

class IdentidadAutenticada {
  const IdentidadAutenticada(this.idUsuario, this.correo);
  final String idUsuario, correo;
}

abstract class ServicioAutenticacion {
  Stream<IdentidadAutenticada?> observarIdentidad();
  IdentidadAutenticada? get usuarioActual;
  Future<IdentidadAutenticada> iniciarSesion(String correo, String contrasena);
  Future<IdentidadAutenticada> crearCuenta(String correo, String contrasena);
  Future<void> eliminarCuentaRecienCreada();
  Future<void> cerrarSesion();
}

class ServicioAutenticacionFirebase implements ServicioAutenticacion {
  const ServicioAutenticacionFirebase(this.autenticacion);
  final FirebaseAuth autenticacion;
  IdentidadAutenticada? _identidad(User? usuario) => usuario == null
      ? null
      : IdentidadAutenticada(usuario.uid, usuario.email ?? '');
  @override
  IdentidadAutenticada? get usuarioActual =>
      _identidad(autenticacion.currentUser);
  @override
  Stream<IdentidadAutenticada?> observarIdentidad() =>
      autenticacion.authStateChanges().map(_identidad);
  @override
  Future<IdentidadAutenticada> iniciarSesion(
    String correo,
    String contrasena,
  ) async => _identidad(
    (await autenticacion.signInWithEmailAndPassword(
      email: correo,
      password: contrasena,
    )).user,
  )!;
  @override
  Future<IdentidadAutenticada> crearCuenta(
    String correo,
    String contrasena,
  ) async => _identidad(
    (await autenticacion.createUserWithEmailAndPassword(
      email: correo,
      password: contrasena,
    )).user,
  )!;
  @override
  Future<void> eliminarCuentaRecienCreada() async {
    await autenticacion.currentUser?.delete();
  }

  @override
  Future<void> cerrarSesion() => autenticacion.signOut();
}

class ServicioAutenticacionNoDisponible implements ServicioAutenticacion {
  const ServicioAutenticacionNoDisponible();
  @override
  IdentidadAutenticada? get usuarioActual => null;
  @override
  Stream<IdentidadAutenticada?> observarIdentidad() => Stream.value(null);
  @override
  Future<IdentidadAutenticada> iniciarSesion(
    String correo,
    String contrasena,
  ) async => throw StateError(
    'El servicio de acceso no esta disponible temporalmente.',
  );
  @override
  Future<IdentidadAutenticada> crearCuenta(
    String correo,
    String contrasena,
  ) async => throw StateError(
    'No fue posible enviar la solicitud. Intentalo mas tarde.',
  );
  @override
  Future<void> cerrarSesion() async {}
  @override
  Future<void> eliminarCuentaRecienCreada() async {}
}
