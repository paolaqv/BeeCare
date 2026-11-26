import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../proveedores/proveedor_colmenas.dart';

class SelectorColmena extends ConsumerWidget {
  const SelectorColmena({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actual = ref.watch(proveedorColmenaSeleccionada);
    final catalogo = ref.watch(proveedorCatalogoColmenas);
    final opciones = catalogo.asData?.value ?? [];
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (opciones.length > 1)
            DropdownButtonFormField<String>(
              key: ValueKey('selector-colmena-${actual.idColmena}'),
              initialValue: actual.idColmena,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Colmena'),
              items: opciones
                  .map(
                    (c) => DropdownMenuItem(
                      value: c.idColmena,
                      child: Text(
                        c.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (id) {
                if (id != null) {
                  ref.read(proveedorSeleccionColmena.notifier).seleccionar(id);
                }
              },
            )
          else
            Text(
              actual.nombre,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          const SizedBox(height: 6),
          Text(
            [
              actual.ubicacion,
              actual.idPrototipo,
            ].where((s) => s.isNotEmpty).join(' · '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (catalogo.hasError) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Catalogo de dispositivos no disponible. Se mantiene la instalacion configurada.',
                  ),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(proveedorCatalogoColmenas),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
