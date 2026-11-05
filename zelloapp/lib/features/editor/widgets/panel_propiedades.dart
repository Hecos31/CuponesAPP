import 'package:flutter/material.dart';
import '../models/elemento_diseno.dart';
import 'selector_color.dart';

const tipografiasDisponibles = ['Roboto', 'Lato', 'Oswald', 'Montserrat', 'Pacifico', 'Poppins', 'Bebas Neue', 'Playfair Display'];

class PanelPropiedades extends StatelessWidget {
  const PanelPropiedades({super.key, required this.elemento, required this.alCambiar, required this.alCambiarSvg, required this.alDuplicar, required this.alEliminar, required this.alTraerAlFrente, required this.alEnviarAtras});
  
  final ElementoDiseno elemento;
  final VoidCallback alCambiar, alCambiarSvg, alDuplicar, alEliminar, alTraerAlFrente, alEnviarAtras;

  Widget _buildCard(String title, List<Widget> children) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueGrey)), const SizedBox(height: 12), ...children]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (elemento.tipo == TipoElemento.texto || elemento.tipo == TipoElemento.botonQr) _buildCard('Tipografía y Contenido', _opcionesTexto()),
        if (elemento.tipo == TipoElemento.svg) _buildCard('Gráfico SVG', _opcionesSvg()),
        if (elemento.tipo == TipoElemento.sello) _buildCard('Diseño del Sello', _opcionesSello()),
        _buildCard('Apariencia de Caja', _opcionesCaja()),
        _botonesCapa(),
      ],
    );
  }

  List<Widget> _opcionesTexto() => [
    if (elemento.tipo != TipoElemento.botonQr) TextFormField(initialValue: elemento.texto, decoration: InputDecoration(labelText: 'Contenido', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), onChanged: (v) { elemento.texto = v; alCambiar(); }),
    if (elemento.tipo != TipoElemento.botonQr) const SizedBox(height: 12),
    DropdownButtonFormField<String>(
      initialValue: tipografiasDisponibles.contains(elemento.tipografia) ? elemento.tipografia : 'Roboto',
      decoration: InputDecoration(labelText: 'Fuente', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
      items: tipografiasDisponibles.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
      onChanged: (v) { if (v != null) { elemento.tipografia = v; alCambiar(); } },
    ),
    const SizedBox(height: 12),
    Row(children: [const Icon(Icons.format_size, size: 20, color: Colors.grey), Expanded(child: Slider(value: elemento.tamanoFuente.clamp(8, 100), min: 8, max: 100, onChanged: (v) { elemento.tamanoFuente = v; alCambiar(); }))]),
    SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Negrita', style: TextStyle(fontSize: 14)), value: elemento.negrita, onChanged: (v) { elemento.negrita = v; alCambiar(); }),
    SelectorColor(titulo: 'Color del texto', color: elemento.color, alCambiar: (c) { elemento.color = c; alCambiar(); }),
  ];

  List<Widget> _opcionesCaja() => [
    SelectorColor(titulo: 'Fondo', color: elemento.colorFondo, alCambiar: (c) { elemento.colorFondo = c; alCambiar(); }),
    SelectorColor(titulo: 'Borde', color: elemento.colorBorde, alCambiar: (c) { elemento.colorBorde = c; alCambiar(); }),
    Row(children: [const Text('Grosor', style: TextStyle(fontSize: 13)), Expanded(child: Slider(value: elemento.grosorBorde.clamp(0, 20), min: 0, max: 20, onChanged: (v) { elemento.grosorBorde = v; alCambiar(); }))]),
    Row(children: [const Text('Radio', style: TextStyle(fontSize: 13)), Expanded(child: Slider(value: elemento.radioBorde.clamp(0, 100), min: 0, max: 100, onChanged: (v) { elemento.radioBorde = v; alCambiar(); }))]),
    SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Sombra', style: TextStyle(fontSize: 14)), value: elemento.conSombra, onChanged: (v) { elemento.conSombra = v; alCambiar(); }),
  ];

  List<Widget> _opcionesSvg() => [OutlinedButton.icon(onPressed: alCambiarSvg, icon: const Icon(Icons.image_search), label: const Text('Reemplazar SVG'))];
  
  List<Widget> _opcionesSello() => [
    DropdownButtonFormField<String>(initialValue: tipografiasDisponibles.contains(elemento.tipografia) ? elemento.tipografia : 'Roboto', decoration: InputDecoration(labelText: 'Fuente', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), items: tipografiasDisponibles.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(), onChanged: (v) { if (v != null) { elemento.tipografia = v; alCambiar(); } }),
    Row(children: [const Icon(Icons.format_size, size: 20, color: Colors.grey), Expanded(child: Slider(value: elemento.tamanoFuente.clamp(8, 80), min: 8, max: 80, onChanged: (v) { elemento.tamanoFuente = v; alCambiar(); }))]),
    SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Negrita', style: TextStyle(fontSize: 14)), value: elemento.negrita, onChanged: (v) { elemento.negrita = v; alCambiar(); }),
    SelectorColor(titulo: 'Color del número', color: elemento.color, alCambiar: (c) { elemento.color = c; alCambiar(); }),
  ];

  Widget _botonesCapa() => Wrap(
    spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
    children: [
      ActionChip(avatar: const Icon(Icons.flip_to_front, size: 16), label: const Text('Subir'), onPressed: alTraerAlFrente),
      ActionChip(avatar: const Icon(Icons.flip_to_back, size: 16), label: const Text('Bajar'), onPressed: alEnviarAtras),
      ActionChip(avatar: const Icon(Icons.copy, size: 16), label: const Text('Clonar'), onPressed: alDuplicar),
      ActionChip(avatar: const Icon(Icons.delete, size: 16, color: Colors.white), label: const Text('Borrar', style: TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent, onPressed: alEliminar),
    ],
  );
}