import 'package:flutter/material.dart';
import '../models/diseno_lienzo.dart';
import '../models/elemento_diseno.dart';

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
        
        // Ajustamos los índices visuales por la lista invertida
        final int realOldIndex = diseno.elementos.length - 1 - viejoIndice;
        int realNewIndex = diseno.elementos.length - 1 - nuevoIndice;
        
        final elemento = diseno.elementos.removeAt(realOldIndex);
        diseno.elementos.insert(realNewIndex, elemento);
        alCambiar();
      },
      itemBuilder: (context, index) {
        final e = diseno.elementos[diseno.elementos.length - 1 - index];
        
        IconData iconoCapa = Icons.verified;
        if (e.tipo == TipoElemento.texto) iconoCapa = Icons.text_fields;
        if (e.tipo == TipoElemento.svg) iconoCapa = Icons.image;
        if (e.tipo == TipoElemento.forma) {
          iconoCapa = e.forma == 'circulo' ? Icons.circle : (e.forma == 'triangulo' ? Icons.change_history : Icons.square);
        }

        return ListTile(
          key: ValueKey(e.id),
          leading: Icon(iconoCapa),
          title: Text(e.tipo.name.toUpperCase() + (e.tipo == TipoElemento.forma ? ' (${e.forma})' : '')),
          subtitle: Text(e.texto.isNotEmpty && e.tipo == TipoElemento.texto ? e.texto : 'ID: ${e.id.substring(0, 4)}'),
          selected: e.id == seleccionadoId,
          selectedTileColor: Colors.blue.withOpacity(0.1),
          onTap: () => alSeleccionar(e.id),
          trailing: const Icon(Icons.drag_handle),
        );
      },
    );
  }
}