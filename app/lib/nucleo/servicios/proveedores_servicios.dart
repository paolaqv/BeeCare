import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../configuracion.dart';
import '../datos/repositorio_realtime_database.dart';
import 'servicio_autenticacion_firebase.dart';

final proveedorBaseDatos = Provider<RepositorioRealtimeDatabase>(
  (referencia) => ConfiguracionAplicacion.firebaseHabilitado
      ? RepositorioRealtimeDatabaseFirebase(FirebaseDatabase.instance)
      : const RepositorioRealtimeDatabaseNoDisponible(),
);
final proveedorServicioAutenticacion = Provider<ServicioAutenticacion>(
  (referencia) => ConfiguracionAplicacion.firebaseHabilitado
      ? ServicioAutenticacionFirebase(FirebaseAuth.instance)
      : const ServicioAutenticacionNoDisponible(),
);
