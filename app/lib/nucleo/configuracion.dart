import 'package:firebase_core/firebase_core.dart';

class ConfiguracionAplicacion {
  static const notificacionesHabilitadas = bool.fromEnvironment('PUSH_ENABLED');
  static const firebaseHabilitado = bool.fromEnvironment('FIREBASE_ENABLED');
  static const idColmena = String.fromEnvironment(
    'HIVE_ID',
    defaultValue: 'colmena_01',
  );
  static const idPrototipo = String.fromEnvironment(
    'DEVICE_ID',
    defaultValue: 'prototipo_01',
  );
  static FirebaseOptions get firebase => const FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    databaseURL: String.fromEnvironment('FIREBASE_DATABASE_URL'),
    authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
  );
}
