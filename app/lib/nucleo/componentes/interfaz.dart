import 'package:flutter/material.dart';

const miel = Color(0xFFF2B51D);
const crema = Color(0xFFFFFBF0);
const tinta = Color(0xFF382B34);
const marron = Color(0xFF805B17);

class ContenidoPagina extends StatelessWidget {
  const ContenidoPagina({super.key, required this.elementos});
  final List<Widget> elementos;
  @override
  Widget build(BuildContext contexto) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: elementos,
        ),
      ),
    ),
  );
}

class EncabezadoSeccion extends StatelessWidget {
  const EncabezadoSeccion(this.titulo, this.subtitulo, {super.key});
  final String titulo, subtitulo;
  @override
  Widget build(BuildContext contexto) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitulo,
          style: const TextStyle(color: Color(0xFF746B63), height: 1.5),
        ),
      ],
    ),
  );
}

class TarjetaInformacion extends StatelessWidget {
  const TarjetaInformacion({
    super.key,
    required this.contenido,
    this.color = Colors.white,
  });
  final Widget contenido;
  final Color color;
  @override
  Widget build(BuildContext contexto) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFEDE5D5)),
    ),
    child: contenido,
  );
}

class MensajeDatos extends StatelessWidget {
  const MensajeDatos(this.mensaje, {super.key, this.reintentar});
  final String mensaje;
  final VoidCallback? reintentar;
  @override
  Widget build(BuildContext contexto) => TarjetaInformacion(
    contenido: Column(
      children: [
        const Icon(Icons.cloud_off_outlined, size: 40, color: marron),
        const SizedBox(height: 14),
        Text(mensaje, textAlign: TextAlign.center),
        if (reintentar != null)
          TextButton.icon(
            onPressed: reintentar,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
      ],
    ),
  );
}

String formatearFecha(DateTime valor) {
  final d = valor.toLocal();
  String dosDigitos(int n) => n.toString().padLeft(2, '0');
  return '${dosDigitos(d.day)}/${dosDigitos(d.month)}/${d.year} · ${dosDigitos(d.hour)}:${dosDigitos(d.minute)}';
}

String describirError(Object error) {
  final s = error.toString();
  if (s.contains('invalid-credential') ||
      s.contains('wrong-password') ||
      s.contains('user-not-found')) {
    return 'Correo o contrasena incorrectos.';
  }
  if (s.contains('email-already-in-use')) {
    return 'Ya existe una cuenta con este correo.';
  }
  if (s.contains('network-request-failed')) {
    return 'Sin conexion. Revisa tu acceso a internet.';
  }
  if (s.contains('permission-denied')) {
    return 'No tienes permiso para realizar esta accion.';
  }
  if (s.contains('too-many-requests')) {
    return 'Demasiados intentos. Intentalo mas tarde.';
  }
  if (s.contains('StateError') || s.contains('Bad state')) {
    return s.replaceFirst('Bad state: ', '');
  }
  return 'No fue posible completar la operacion. Intentalo nuevamente.';
}
