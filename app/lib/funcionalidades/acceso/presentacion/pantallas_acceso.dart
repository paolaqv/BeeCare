import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../../nucleo/componentes/interfaz.dart';
import '../proveedores/proveedor_acceso.dart';

const _amarilloAcceso = Color(0xFFFBE6AC);

class PantallaBienvenida extends StatefulWidget {
  const PantallaBienvenida({super.key});
  @override
  State<PantallaBienvenida> createState() => _EstadoBienvenida();
}

class _EstadoBienvenida extends State<PantallaBienvenida>
    with SingleTickerProviderStateMixin {
  late final _movimiento = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  bool _abriendo = false;

  Future<void> _abrir(bool registrar) async {
    if (_abriendo) return;
    setState(() => _abriendo = true);
    final reducir = MediaQuery.disableAnimationsOf(context);
    if (!reducir) await _movimiento.forward();
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        transitionDuration: Duration(milliseconds: reducir ? 0 : 220),
        reverseTransitionDuration: Duration(milliseconds: reducir ? 0 : 220),
        pageBuilder: (_, animacion, secundaria) =>
            FormularioAcceso(registrar: registrar),
        transitionsBuilder: (_, animacion, secundaria, contenido) =>
            FadeTransition(opacity: animacion, child: contenido),
      ),
    );
    if (!mounted) return;
    await _movimiento.reverse();
    if (mounted) setState(() => _abriendo = false);
  }

  @override
  void dispose() {
    _movimiento.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext contexto) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (contexto, limites) {
          final alto = limites.maxHeight;
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: alto),
              child: Column(
                children: [
                  SizedBox(
                    height: alto * .50,
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        const Text(
                          'BeeCare',
                          style: TextStyle(fontSize: 28, color: tinta),
                        ),
                        const Expanded(child: Center(child: MarcaAbeja())),
                      ],
                    ),
                  ),
                  SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: Offset.zero,
                          end: const Offset(0, 1),
                        ).animate(
                          CurvedAnimation(
                            parent: _movimiento,
                            curve: Curves.easeInCubic,
                          ),
                        ),
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(minHeight: alto * .50),
                      padding: EdgeInsets.fromLTRB(
                        24,
                        42,
                        24,
                        36 + MediaQuery.paddingOf(contexto).bottom,
                      ),
                      decoration: const BoxDecoration(
                        color: _amarilloAcceso,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(44),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Bienvenido',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Consulta el microambiente, el peso y la energia de tu colmena desde un solo lugar.',
                            style: TextStyle(
                              fontSize: 17,
                              height: 1.5,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 44),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: _abriendo
                                      ? null
                                      : () => _abrir(false),
                                  child: const Text('Iniciar sesion'),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _abriendo
                                      ? null
                                      : () => _abrir(true),
                                  child: const Text('Registrarse'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

/// Logo animado local de la pantalla de bienvenida.
class MarcaAbeja extends StatelessWidget {
  const MarcaAbeja({super.key});
  @override
  Widget build(BuildContext contexto) => Semantics(
    label: 'Abeja BeeCare',
    image: true,
    child: SizedBox(
      width: 250,
      height: 250,
      child: Lottie.asset(
        'assets/animaciones/abeja_beecare.json',
        fit: BoxFit.contain,
        animate: !MediaQuery.disableAnimationsOf(contexto),
        repeat: true,
      ),
    ),
  );
}

class FormularioAcceso extends ConsumerStatefulWidget {
  const FormularioAcceso({super.key, required this.registrar});
  final bool registrar;
  @override
  ConsumerState<FormularioAcceso> createState() => _EstadoFormularioAcceso();
}

class _EstadoFormularioAcceso extends ConsumerState<FormularioAcceso>
    with SingleTickerProviderStateMixin {
  late final _entrada = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (MediaQuery.disableAnimationsOf(context)) {
          _entrada.value = 1;
        } else {
          _entrada.forward();
        }
      }
    });
  }

  final _claveFormulario = GlobalKey<FormState>();
  final _nombres = TextEditingController(),
      _apellidos = TextEditingController(),
      _correo = TextEditingController(),
      _contrasena = TextEditingController();
  bool _ocupado = false, _oculta = true;
  String? _error;
  @override
  void dispose() {
    _entrada.dispose();
    for (final c in [_nombres, _apellidos, _correo, _contrasena]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validarNombre(String? valor) =>
      RegExp(r"^[a-zA-ZÀ-ÿ\s'-]{2,}$").hasMatch(valor?.trim() ?? '')
      ? null
      : 'Ingresa al menos dos letras.';
  Future<void> _mensaje(String titulo, String contenido) => showDialog<void>(
    context: context,
    builder: (dialogo) => AlertDialog(
      title: Text(titulo),
      content: Text(contenido),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogo),
          child: const Text('Aceptar'),
        ),
      ],
    ),
  );
  Future<void> _enviar() async {
    if (!_claveFormulario.currentState!.validate()) {
      if (widget.registrar) {
        await _mensaje(
          'Datos no validos',
          'Los datos ingresados en los campos no son validos. Corrigelos e intentalo nuevamente.',
        );
      }
      return;
    }
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      final solicitudes = ref.read(proveedorControladorSolicitudes);
      if (widget.registrar) {
        await solicitudes.registrarSolicitud(
          _nombres.text.trim(),
          _apellidos.text.trim(),
          _correo.text.trim(),
          _contrasena.text,
        );
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (contexto) => AlertDialog(
            icon: const Icon(
              Icons.mark_email_read_outlined,
              size: 42,
              color: marron,
            ),
            title: const Text('Solicitud enviada'),
            content: const Text(
              'Tu solicitud de acceso ha sido enviada. Espera la aprobacion del jefe de seguridad para iniciar sesion.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(contexto),
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      } else {
        await ref
            .read(proveedorControladorAutenticacion)
            .iniciarSesion(_correo.text.trim(), _contrasena.text);
        if (mounted) {
          await _mensaje(
            'Inicio de sesion exitoso',
            'Has ingresado correctamente.',
          );
        }
      }
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e, stackTrace) {
      debugPrint('Error de autenticacion o registro: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        setState(() => _error = describirError(e));
        await _mensaje('No se pudo ingresar', _error!);
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext contexto) {
    final registrar = widget.registrar;
    return Scaffold(
      backgroundColor: _amarilloAcceso,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (contexto, limites) {
            return CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 20, 0),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: 'Volver',
                              onPressed: _ocupado
                                  ? null
                                  : () => Navigator.maybePop(contexto),
                              icon: const Icon(Icons.arrow_back, size: 30),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: _ocupado
                                  ? null
                                  : () => Navigator.pushReplacement(
                                      contexto,
                                      PageRouteBuilder<void>(
                                        pageBuilder:
                                            (_, animacion, secundaria) =>
                                                FormularioAcceso(
                                                  registrar: !registrar,
                                                ),
                                        transitionsBuilder:
                                            (
                                              _,
                                              animacion,
                                              secundaria,
                                              contenido,
                                            ) => FadeTransition(
                                              opacity: animacion,
                                              child: contenido,
                                            ),
                                      ),
                                    ),
                              child: Text(
                                registrar ? 'Iniciar sesion' : 'Registrate',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              registrar ? 'Registrate' : 'Iniciar sesion',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              registrar
                                  ? 'Envia tu solicitud de acceso para consultar el estado de tu colmena.'
                                  : 'Ingresa con tu cuenta autorizada para consultar tu colmena.',
                              style: const TextStyle(
                                fontSize: 17,
                                height: 1.5,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _entrada,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: Container(
                      padding: EdgeInsets.fromLTRB(
                        36,
                        64,
                        36,
                        36 + MediaQuery.paddingOf(contexto).bottom,
                      ),
                      decoration: const BoxDecoration(
                        color: crema,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(44),
                        ),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Theme(
                            data: Theme.of(contexto).copyWith(
                              inputDecorationTheme: InputDecorationTheme(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 18,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(32),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(32),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(32),
                                  borderSide: const BorderSide(
                                    color: marron,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            child: Form(
                              key: _claveFormulario,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (widget.registrar) ...[
                                    TextFormField(
                                      controller: _nombres,
                                      textInputAction: TextInputAction.next,
                                      validator: _validarNombre,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      decoration: const InputDecoration(
                                        labelText: 'Nombres',
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    TextFormField(
                                      controller: _apellidos,
                                      textInputAction: TextInputAction.next,
                                      validator: _validarNombre,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      decoration: const InputDecoration(
                                        labelText: 'Apellidos',
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                  ],
                                  TextFormField(
                                    controller: _correo,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.email],
                                    validator: (s) =>
                                        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                            .hasMatch(s?.trim() ?? '')
                                        ? null
                                        : 'Ingresa un correo valido.',
                                    decoration: const InputDecoration(
                                      labelText: 'Correo electronico',
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  TextFormField(
                                    controller: _contrasena,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) {
                                      if (!_ocupado) _enviar();
                                    },
                                    obscureText: _oculta,
                                    autofillHints: [
                                      widget.registrar
                                          ? AutofillHints.newPassword
                                          : AutofillHints.password,
                                    ],
                                    validator: (s) {
                                      final p = s ?? '';
                                      if (!widget.registrar) {
                                        return p.isEmpty
                                            ? 'Ingresa tu contrasena.'
                                            : null;
                                      }
                                      return p.length >= 12 &&
                                              RegExp('[A-Z]').hasMatch(p) &&
                                              RegExp('[a-z]').hasMatch(p) &&
                                              RegExp('[0-9]').hasMatch(p) &&
                                              RegExp(r'[^a-zA-Z0-9]')
                                                  .hasMatch(p)
                                          ? null
                                          : 'Usa 12 caracteres, mayuscula, minuscula, numero y simbolo.';
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Contrasena',
                                      errorMaxLines: 3,
                                      suffixIcon: IconButton(
                                        tooltip: _oculta
                                            ? 'Mostrar contrasena'
                                            : 'Ocultar contrasena',
                                        onPressed: () =>
                                            setState(() => _oculta = !_oculta),
                                        icon: Icon(
                                          _oculta
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (widget.registrar)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 12),
                                      child: Text(
                                        'Minimo 12 caracteres con mayuscula, minuscula, numero y simbolo.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF746B63),
                                        ),
                                      ),
                                    ),
                                  if (_error != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 18),
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 28),
                                  FilledButton(
                                    onPressed: _ocupado ? null : _enviar,
                                    child: _ocupado
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            widget.registrar
                                                ? 'Continuar'
                                                : 'Iniciar sesion',
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
