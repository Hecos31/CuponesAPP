import 'package:flutter/material.dart';
import '../models/diseno_lienzo.dart';

class PanelCapas extends StatelessWidget {
  final DisenoLienzo diseno;
  final VoidCallback alCambiar;
  final ValueChanged<String?> alSeleccionar;
  final String? seleccionadoId;

  const PanelCapas({
    super.key,
    required this.diseno,
    required this.alCambiar,
    required this.alSeleccionar,
    this.seleccionadoId,
  });

  @override
  Widget build(BuildContext context) {
    if (diseno.elementos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No hay capas en el lienzo.'),
      );
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: diseno.elementos.length,
      onReorder: (viejoIndice, nuevoIndice) {
        if (nuevoIndice > viejoIndice) nuevoIndice -= 1;
        final elemento = diseno.elementos.removeAt(viejoIndice);
        diseno.elementos.insert(nuevoIndice, elemento);
        alCambiar();
      },
      itemBuilder: (context, index) {
        // Invertimos la lista visualmente para que el elemento superior esté arriba en la lista
        final e = diseno.elementos[diseno.elementos.length - 1 - index];
        return ListTile(
          key: ValueKey(e.id),
          leading: Icon(
            e.tipo.name == 'texto' ? Icons.text_fields :
            e.tipo.name == 'svg' ? Icons.image : Icons.verified,
          ),
          title: Text(e.tipo.name.toUpperCase()),
          subtitle: Text(e.texto.isNotEmpty ? e.texto : 'ID: ${e.id.substring(0, 4)}'),
          selected: e.id == seleccionadoId,
          selectedTileColor: Colors.blue.withOpacity(0.1),
          onTap: () => alSeleccionar(e.id),
          trailing: const Icon(Icons.drag_handle),
        );
      },
    );
  }
}