import 'package:firebase_database/firebase_database.dart';

/// Acceso compartido a RTDB del C4 nivel 4. No contiene decisiones de interfaz.
abstract class RepositorioRealtimeDatabase {
  Stream<Object?> observar(
    String ruta, {
    bool ultimo = false,
    DateTime? inicio,
    DateTime? fin,
    int? limite,
  });
  Future<Object?> leer(String ruta);
  Future<void> guardar(String ruta, Map<String, Object?> datos);
  Future<void> actualizar(String ruta, Map<String, Object?> datos);
}

class RepositorioRealtimeDatabaseFirebase
    implements RepositorioRealtimeDatabase {
  const RepositorioRealtimeDatabaseFirebase(this.baseDatos);

  final FirebaseDatabase baseDatos;

  @override
  Stream<Object?> observar(
    String ruta, {
    bool ultimo = false,
    DateTime? inicio,
    DateTime? fin,
    int? limite,
  }) {
    Query consulta = baseDatos.ref(ruta);
    if (ultimo || inicio != null || fin != null || limite != null) {
      consulta = consulta.orderByChild('fechaHora');
    }
    if (inicio != null) {
      consulta = consulta.startAt(inicio.toUtc().toIso8601String());
    }
    if (fin != null) consulta = consulta.endAt(fin.toUtc().toIso8601String());
    if (ultimo || limite != null) {
      consulta = consulta.limitToLast(ultimo ? 1 : limite!);
    }
    return consulta.onValue.map((evento) {
      if (!ultimo) return evento.snapshot.value;
      return evento.snapshot.exists
          ? evento.snapshot.children.first.value
          : null;
    });
  }

  @override
  Future<Object?> leer(String ruta) async =>
      (await baseDatos.ref(ruta).get()).value;

  @override
  Future<void> guardar(String ruta, Map<String, Object?> datos) =>
      baseDatos.ref(ruta).set(datos);

  @override
  Future<void> actualizar(String ruta, Map<String, Object?> datos) {
    final referencia = ruta.isEmpty ? baseDatos.ref() : baseDatos.ref(ruta);
    return referencia.update(datos);
  }
}

class RepositorioRealtimeDatabaseNoDisponible
    implements RepositorioRealtimeDatabase {
  const RepositorioRealtimeDatabaseNoDisponible();

  @override
  Stream<Object?> observar(
    String ruta, {
    bool ultimo = false,
    DateTime? inicio,
    DateTime? fin,
    int? limite,
  }) => Stream.error(StateError('Datos no disponibles temporalmente.'));

  @override
  Future<Object?> leer(String ruta) async =>
      throw StateError('Servicio no disponible temporalmente.');

  @override
  Future<void> guardar(String ruta, Map<String, Object?> datos) async =>
      throw StateError('Servicio no disponible temporalmente.');

  @override
  Future<void> actualizar(String ruta, Map<String, Object?> datos) async =>
      throw StateError('Servicio no disponible temporalmente.');
}

Map<String, dynamic> mapaDatos(Object? valor) =>
    Map<String, dynamic>.from(valor as Map? ?? {});
