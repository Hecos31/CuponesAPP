import 'package:flutter/material.dart';
import '../models/diseno_lienzo.dart';
import '../models/elemento_diseno.dart';

class PanelCapas extends StatelessWidget {
  final DisenoLienzo diseno;
  final VoidCallback alCambiar;
  final ValueChanged<String?> alSeleccionar;
  final String? seleccionadoId;

  const PanelCapas({super.key, required this.diseno, required this.alCambiar, required this.alSeleccionar, this.seleccionadoId});

  @override
  Widget build(BuildContext context) {
    if (diseno.elementos.isEmpty) {
      return Center(child: Text('Lienzo vacío', style: TextStyle(color: Colors.grey.shade600)));
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: diseno.elementos.length,
      onReorder: (viejo, nuevo) {
        if (nuevo > viejo) nuevo -= 1;
        final realOld = diseno.elementos.length - 1 - viejo;
        final realNew = diseno.elementos.length - 1 - nuevo;
        final elemento = diseno.elementos.removeAt(realOld);
        diseno.elementos.insert(realNew, elemento);
        alCambiar();
      },
      itemBuilder: (context, index) {
        final e = diseno.elementos[diseno.elementos.length - 1 - index];
        IconData icono = e.tipo == TipoElemento.texto ? Icons.title : e.tipo == TipoElemento.svg ? Icons.image : e.tipo == TipoElemento.sello ? Icons.verified : Icons.category;
        
        return Card(
          key: ValueKey(e.id),
          elevation: e.id == seleccionadoId ? 4 : 0,
          color: e.id == seleccionadoId ? Colors.blue.shade50 : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: e.id == seleccionadoId ? Colors.blueAccent : Colors.grey.shade200)),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.grey.shade100, child: Icon(icono, color: Colors.blueGrey)),
            title: Text(e.tipo.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text(e.texto.isNotEmpty && e.tipo == TipoElemento.texto ? e.texto : 'ID: ${e.id.substring(0, 4)}', maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => alSeleccionar(e.id),
            trailing: const Icon(Icons.drag_indicator, color: Colors.grey),
          ),
        );
      },
    );
  }
}