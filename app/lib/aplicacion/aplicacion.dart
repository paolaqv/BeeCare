import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../nucleo/componentes/interfaz.dart';
import '../nucleo/servicios/proveedor_notificaciones.dart';
import '../nucleo/presentacion/navegacion.dart';
import '../funcionalidades/acceso/presentacion/pantalla_solicitudes.dart';
import '../funcionalidades/acceso/presentacion/pantallas_acceso.dart';
import '../funcionalidades/acceso/proveedores/proveedor_acceso.dart';
import '../funcionalidades/monitoreo/presentacion/pantalla_monitoreo.dart';

class AplicacionBeeCare extends StatefulWidget {
  const AplicacionBeeCare({super.key});

  @override
  State<AplicacionBeeCare> createState() => _AplicacionBeeCareState();
}

class _AplicacionBeeCareState extends State<AplicacionBeeCare> {
  final _navegador = GlobalKey<NavigatorState>();
  @override
  Widget build(BuildContext contexto) => MaterialApp(
    title: 'BeeCare',
    navigatorKey: _navegador,
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: miel).copyWith(
        primary: marron,
        onPrimary: Colors.white,
        secondary: miel,
        surface: crema,
        onSurface: tinta,
      ),
      scaffoldBackgroundColor: crema,
      appBarTheme: const AppBarTheme(
        backgroundColor: crema,
        foregroundColor: tinta,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8F5ED),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE5DDCD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE5DDCD)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: crema,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    ),
    builder: (contexto, contenido) => ObservadorNotificaciones(
      navegador: _navegador,
      contenido: contenido ?? const SizedBox.shrink(),
    ),
    home: const _ControlAcceso(),
  );
}

class _ControlAcceso extends ConsumerWidget {
  const _ControlAcceso();
  @override
  Widget build(BuildContext contexto, WidgetRef referencia) => referencia
      .watch(proveedorUsuario)
      .when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, s) => Scaffold(
          body: SafeArea(
            child: ContenidoPagina(
              elementos: [
                MensajeDatos(
                  'No se pudo verificar el acceso. Revisa la conexion y la configuracion de Firebase.',
                  reintentar: () => referencia.invalidate(proveedorUsuario),
                ),
                TextButton(
                  onPressed: () => referencia
                      .read(proveedorControladorAutenticacion)
                      .cerrarSesion(),
                  child: const Text('Volver al inicio'),
                ),
              ],
            ),
          ),
        ),
        data: (usuario) {
          if (usuario == null) return const PantallaBienvenida();
          if (usuario.puedeGestionarSolicitudes) {
            return const PantallaSolicitudes();
          }
          if (usuario.puedeConsultarColmena) return const PantallaMonitoreo();
          if (usuario.aprobado) return const PantallaAccesoRestringido();
          return Scaffold(
            appBar: AppBar(title: const Text('BeeCare')),
            body: ContenidoPagina(
              elementos: [
                const SizedBox(height: 40),
                const Icon(
                  Icons.hourglass_top_rounded,
                  color: marron,
                  size: 64,
                ),
                const SizedBox(height: 24),
                EncabezadoSeccion(
                  usuario.estado == 'rechazada'
                      ? 'Solicitud rechazada'
                      : 'Solicitud en revision',
                  usuario.estado == 'rechazada'
                      ? 'Contacta al responsable para conocer el estado de tu solicitud.'
                      : 'El responsable debe aprobar tu acceso. Esta pantalla se actualizara al recibir una respuesta.',
                ),
                Text(usuario.correo, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => referencia
                      .read(proveedorControladorAutenticacion)
                      .cerrarSesion(),
                  child: const Text('Volver al inicio'),
                ),
              ],
            ),
          );
        },
      );
}
