import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../funcionalidades/acceso/proveedores/proveedor_acceso.dart';
import '../../funcionalidades/acceso/presentacion/pantalla_solicitudes.dart';
import '../../funcionalidades/acceso/presentacion/pantalla_rangos.dart';
import '../../funcionalidades/monitoreo/presentacion/pantalla_monitoreo.dart';
import '../../funcionalidades/historico/presentacion/pantalla_historico.dart';
import '../../funcionalidades/eventos/presentacion/pantalla_eventos.dart';
import '../componentes/interfaz.dart';

enum DestinoAplicacion { solicitudes, monitoreo, historico, eventos, rangos }

bool puedeAbrir(WidgetRef referencia, DestinoAplicacion destino) {
  final usuario = referencia.read(proveedorUsuario).asData?.value;
  return (destino == DestinoAplicacion.solicitudes || destino == DestinoAplicacion.rangos)
      ? usuario?.puedeGestionarSolicitudes == true
      : usuario?.puedeConsultarColmena == true;
}

void abrirPantalla(
  BuildContext contexto,
  WidgetRef referencia,
  DestinoAplicacion destino,
) {
  if (!puedeAbrir(referencia, destino)) return;
  Navigator.push(
    contexto,
    PageRouteBuilder<void>(
      transitionDuration: Duration(
        milliseconds: MediaQuery.disableAnimationsOf(contexto) ? 0 : 360,
      ),
      reverseTransitionDuration: Duration(
        milliseconds: MediaQuery.disableAnimationsOf(contexto) ? 0 : 280,
      ),
      transitionsBuilder: (_, animacion, secundaria, contenido) {
        final curva = CurvedAnimation(
          parent: animacion,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curva,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(.08, .04),
              end: Offset.zero,
            ).animate(curva),
            child: contenido,
          ),
        );
      },
      pageBuilder: (_, animacion, secundaria) => switch (destino) {
        DestinoAplicacion.monitoreo => const PantallaMonitoreo(),
        DestinoAplicacion.historico => const PantallaHistorico(),
        DestinoAplicacion.eventos => const PantallaEventos(),
        DestinoAplicacion.rangos => const PantallaRangos(),
        DestinoAplicacion.solicitudes => const PantallaSolicitudes(),
      },
    ),
  );
}

class PantallaAccesoRestringido extends StatelessWidget {
  const PantallaAccesoRestringido({super.key});
  @override
  Widget build(BuildContext contexto) => const Scaffold(
    body: SafeArea(
      child: Center(
        child: Text('No tienes autorizacion para acceder a esta seccion.'),
      ),
    ),
  );
}

Future<void> confirmarCierreSesion(
  BuildContext contexto,
  WidgetRef referencia,
) async {
  final confirmado = await showDialog<bool>(
    context: contexto,
    builder: (dialogo) => AlertDialog(
      title: const Text('¿Cerrar sesion?'),
      content: const Text('Confirma que deseas finalizar tu sesion.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogo, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogo, true),
          child: const Text('Aceptar'),
        ),
      ],
    ),
  );
  if (confirmado != true || !contexto.mounted) return;
  try {
    await referencia.read(proveedorControladorAutenticacion).cerrarSesion();
    if (contexto.mounted) {
      Navigator.of(contexto).popUntil((ruta) => ruta.isFirst);
    }
  } catch (error) {
    if (contexto.mounted) {
      ScaffoldMessenger.of(contexto)
          .showSnackBar(SnackBar(content: Text(describirError(error))));
    }
  }
}

class MenuAplicacion extends ConsumerWidget {
  const MenuAplicacion({super.key});
  @override
  Widget build(BuildContext contexto, WidgetRef referencia) {
    final usuario = referencia.watch(proveedorUsuario).asData?.value;
    void abrir(DestinoAplicacion destino) {
      Navigator.pop(contexto);
      abrirPantalla(contexto, referencia, destino);
    }

    return Drawer(
      backgroundColor: crema,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'BeeCare',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar menu',
                  onPressed: () => Navigator.pop(contexto),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (usuario?.puedeConsultarColmena == true) ...[
              ListTile(
                leading: const Icon(Icons.hive_outlined),
                title: const Text('Monitoreo'),
                onTap: () => abrir(DestinoAplicacion.monitoreo),
              ),
              ListTile(
                leading: const Icon(Icons.show_chart),
                title: const Text('Historico de datos'),
                onTap: () => abrir(DestinoAplicacion.historico),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Eventos'),
                onTap: () => abrir(DestinoAplicacion.eventos),
              ),
            ],
            if (usuario?.puedeGestionarSolicitudes == true)
              ListTile(
                leading: const Icon(Icons.how_to_reg_outlined),
                title: const Text('Solicitudes de acceso'),
                onTap: () => abrir(DestinoAplicacion.solicitudes),
              ),
            if (usuario?.puedeGestionarSolicitudes == true)
              ListTile(
                leading: const Icon(Icons.tune),
                title: const Text('Rangos de monitoreo'),
                onTap: () => abrir(DestinoAplicacion.rangos),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesion'),
              onTap: () => confirmarCierreSesion(contexto, referencia),
            ),
          ],
        ),
      ),
    );
  }
}

class BarraBeeCare extends ConsumerWidget implements PreferredSizeWidget {
  const BarraBeeCare({super.key});
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext contexto, WidgetRef referencia) {
    final usuario = referencia.watch(proveedorUsuario).asData?.value;
    return AppBar(
      title: const Text('BeeCare'),
      centerTitle: true,
      actions: [
        if (usuario?.puedeConsultarColmena == true)
          IconButton(
            tooltip: 'Alertas',
            onPressed: () =>
                abrirPantalla(contexto, referencia, DestinoAplicacion.eventos),
            icon: const Icon(Icons.notifications_none),
          ),
        IconButton(
          tooltip: 'Mi perfil',
          icon: const Icon(Icons.account_circle_outlined),
          onPressed: () => showDialog<void>(
            context: contexto,
            builder: (dialogo) => AlertDialog(
              title: const Text('Mi perfil'),
              content: Text(
                '${usuario?.nombre ?? ''}\n${usuario?.correo ?? ''}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogo),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
