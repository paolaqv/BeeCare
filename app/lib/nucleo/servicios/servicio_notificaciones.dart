import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../funcionalidades/acceso/dominio/acceso.dart';
import '../datos/repositorio_realtime_database.dart';

class NotificacionRecibida {
  const NotificacionRecibida(this.titulo, this.descripcion);
  final String titulo, descripcion;
}

class AperturaAlerta {
  const AperturaAlerta(this.idColmena, this.idAlerta);
  final String idColmena, idAlerta;
}

abstract class ServicioNotificaciones {
  Stream<AperturaAlerta> observarAperturas();
  Stream<NotificacionRecibida> configurarRecepcion(UsuarioAcceso usuario);
  Future<void> detenerRecepcion();
}

class ServicioNotificacionesFirebase implements ServicioNotificaciones {
  ServicioNotificacionesFirebase(this.mensajeria, this.baseDatos);
  final FirebaseMessaging mensajeria;
  final RepositorioRealtimeDatabase baseDatos;
  final _suscripciones = <StreamSubscription<dynamic>>[];
  static const String claveVapid = String.fromEnvironment(
    'FIREBASE_VAPID_KEY',
    defaultValue: '',
  );
  String? _rutaDispositivo;
  int _version = 0;
  bool _registroSolicitado = false;
  static const _canal = MethodChannel('beecare/notificaciones');

  @override
  Stream<AperturaAlerta> observarAperturas() {
    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    late StreamController<AperturaAlerta> salida;
    StreamSubscription<RemoteMessage>? suscripcion;

    void abrir(Map<Object?, Object?>? datos) {
      final colmena = datos?['idColmena'];
      final alerta = datos?['idAlerta'];
      if (!salida.isClosed &&
          colmena is String &&
          colmena.isNotEmpty &&
          alerta is String &&
          alerta.isNotEmpty) {
        salida.add(AperturaAlerta(colmena, alerta));
      }
    }

    salida = StreamController<AperturaAlerta>(
      onListen: () async {
        suscripcion = FirebaseMessaging.onMessageOpenedApp.listen(
          (mensaje) => abrir(mensaje.data),
          onError: salida.addError,
        );
        if (android) {
          _canal.setMethodCallHandler((llamada) async {
            if (llamada.method == 'abrir' && llamada.arguments is Map) {
              abrir(Map<Object?, Object?>.from(llamada.arguments as Map));
            }
          });
        }
        try {
          abrir((await mensajeria.getInitialMessage())?.data);
          if (android && !salida.isClosed) {
            abrir(
              await _canal.invokeMapMethod<Object?, Object?>('aperturaInicial'),
            );
          }
        } catch (error, traza) {
          if (!salida.isClosed) salida.addError(error, traza);
        }
      },
      onCancel: () async {
        if (android) _canal.setMethodCallHandler(null);
        await suscripcion?.cancel();
        unawaited(salida.close());
      },
    );
    return salida.stream;
  }

  @override
  Stream<NotificacionRecibida> configurarRecepcion(UsuarioAcceso usuario) {
    if (!usuario.puedeConsultarColmena) return const Stream.empty();
    late StreamController<NotificacionRecibida> controlador;
    final version = ++_version;
    Future<void> registrarDispositivo(String idInstalacion) async {
      if (version != _version) return;
      final clave = base64Url
          .encode(utf8.encode(idInstalacion))
          .replaceAll('=', '');
      final ruta = 'dispositivosNotificacion/${usuario.idUsuario}/$clave';
      await baseDatos.actualizar('', {
        if (_rutaDispositivo != null && _rutaDispositivo != ruta)
          _rutaDispositivo!: null,
        ruta: {
          'idInstalacion': idInstalacion,
          'fechaRegistro': DateTime.now().toUtc().toIso8601String(),
        },
      });
      _rutaDispositivo = ruta;
    }

    void recibir(RemoteMessage mensaje) {
      if (version != _version || controlador.isClosed) return;
      controlador.add(
        NotificacionRecibida(
          mensaje.notification?.title ??
              '${mensaje.data['titulo'] ?? 'Alerta de la colmena'}',
          mensaje.notification?.body ?? '${mensaje.data['descripcion'] ?? ''}',
        ),
      );
    }

    controlador = StreamController<NotificacionRecibida>(
      onListen: () async {
        try {
          // El objetivo del proyecto es movil. Web requiere service worker y VAPID propios.
          debugPrint('FCM: iniciando configuracion de notificaciones');

          final compatible = await mensajeria.isSupported();
          debugPrint('FCM: dispositivo compatible = $compatible');

          if (!compatible) {
            return;
          }

          debugPrint('FCM: solicitando permisos');

          final permiso = await mensajeria.requestPermission();

          debugPrint(
            'FCM: estado del permiso = ${permiso.authorizationStatus}',
          );
          if (version != _version ||
              permiso.authorizationStatus == AuthorizationStatus.denied) {
            return;
          }
          if (version != _version) return;
          _suscripciones.add(
            mensajeria.onRegistered.listen((idInstalacion) async {
              try {
                if (kDebugMode) {
                  debugPrint(
                    'FCM: ID de instalacion para envio de prueba: $idInstalacion',
                  );
                }
                await registrarDispositivo(idInstalacion);
              } catch (error, traza) {
                if (!controlador.isClosed) controlador.addError(error, traza);
              }
            }),
          );
          _suscripciones.add(
            FirebaseMessaging.onMessage.listen((mensaje) {
              recibir(mensaje);
              if (!kIsWeb &&
                  defaultTargetPlatform == TargetPlatform.android &&
                  version == _version &&
                  usuario.puedeConsultarColmena) {
                unawaited(
                  _canal
                      .invokeMethod<void>('mostrar', {
                        'idColmena': mensaje.data['idColmena'],
                        'idAlerta': mensaje.data['idAlerta'],
                        'etiqueta':
                            mensaje.data['etiqueta'] ?? mensaje.messageId,
                        'titulo':
                            mensaje.notification?.title ??
                            mensaje.data['titulo'] ??
                            'Alerta de la colmena',
                        'descripcion':
                            mensaje.notification?.body ??
                            mensaje.data['descripcion'] ??
                            '',
                      })
                      .catchError((Object error, StackTrace traza) {
                        if (!controlador.isClosed) {
                          controlador.addError(error, traza);
                        }
                      }),
                );
              }
            }),
          );
          _registroSolicitado = true;
          await mensajeria.register(
            vapidKey: kIsWeb && claveVapid.isNotEmpty ? claveVapid : null,
          );
        } catch (error, traza) {
          if (!controlador.isClosed) controlador.addError(error, traza);
        }
      },
      onCancel: detenerRecepcion,
    );
    return controlador.stream;
  }

  @override
  Future<void> detenerRecepcion() async {
    _version++;
    for (final suscripcion in List.of(_suscripciones)) {
      await suscripcion.cancel();
    }
    _suscripciones.clear();
    final ruta = _rutaDispositivo;
    _rutaDispositivo = null;
    try {
      if (ruta != null) await baseDatos.actualizar('', {ruta: null});
    } finally {
      if (_registroSolicitado) {
        _registroSolicitado = false;
        await mensajeria.unregister();
      }
    }
  }
}

class ServicioNotificacionesNoDisponible implements ServicioNotificaciones {
  const ServicioNotificacionesNoDisponible();
  @override
  Stream<AperturaAlerta> observarAperturas() => const Stream.empty();
  @override
  Stream<NotificacionRecibida> configurarRecepcion(UsuarioAcceso usuario) =>
      const Stream.empty();
  @override
  Future<void> detenerRecepcion() async {}
}
