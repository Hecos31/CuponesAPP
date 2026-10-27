import 'package:flutter/material.dart';

import '../models/elemento_diseno.dart';
import 'selector_color.dart';

// Lista ampliada para Google Fonts
const tipografiasDisponibles = [
  'Roboto', 'Lato', 'Oswald', 'Montserrat', 
  'Pacifico', 'Poppins', 'Bebas Neue', 'Playfair Display'
];

/// Panel para editar el elemento seleccionado.
/// Muestra opciones de texto, sello y estilos de caja.
class PanelPropiedades extends StatelessWidget {
  const PanelPropiedades({
    super.key,
    required this.elemento,
    required this.alCambiar,
    required this.alCambiarSvg,
    required this.alDuplicar,
    required this.alEliminar,
    required this.alTraerAlFrente,
    required this.alEnviarAtras,
  });

  final ElementoDiseno elemento;
  final VoidCallback alCambiar;
  final VoidCallback alCambiarSvg;
  final VoidCallback alDuplicar;
  final VoidCallback alEliminar;
  final VoidCallback alTraerAlFrente;
  final VoidCallback alEnviarAtras;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (elemento.tipo == TipoElemento.texto || elemento.tipo == TipoElemento.botonQr) ..._opcionesTexto(),
        if (elemento.tipo == TipoElemento.svg) ..._opcionesSvg(),
        if (elemento.tipo == TipoElemento.sello) ..._opcionesSello(),
        const Divider(height: 32),
        ..._opcionesCaja(), // Nuevas propiedades visuales de fondo y bordes
        const Divider(height: 32),
        _botonesCapa(),
      ],
    );
  }

  List<Widget> _opcionesTexto() {
    return [
      const Text('Texto y Tipografía', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 12),
      if (elemento.tipo != TipoElemento.botonQr) // El botón QR tiene texto fijo
        TextFormField(
          key: ValueKey('texto-${elemento.id}'),
          initialValue: elemento.texto,
          decoration: const InputDecoration(
            labelText: 'Contenido del texto',
            border: OutlineInputBorder(),
          ),
          onChanged: (valor) {
            elemento.texto = valor;
            alCambiar();
          },
        ),
      if (elemento.tipo != TipoElemento.botonQr) const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        key: ValueKey('fuente-${elemento.id}'),
        initialValue: tipografiasDisponibles.contains(elemento.tipografia)
            ? elemento.tipografia
            : 'Roboto',
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Tipografía',
          border: OutlineInputBorder(),
        ),
        items: [
          for (final fuente in tipografiasDisponibles)
            DropdownMenuItem(
              value: fuente,
              child: Text(fuente), // Se removió estiloFuente temporal para evitar crasheos si no hay internet
            ),
        ],
        onChanged: (valor) {
          if (valor == null) return;
          elemento.tipografia = valor;
          alCambiar();
        },
      ),
      const SizedBox(height: 8),
      Text('Tamaño de letra: ${elemento.tamanoFuente.round()}'),
      Slider(
        value: elemento.tamanoFuente.clamp(8, 100),
        min: 8,
        max: 100,
        divisions: 92,
        label: elemento.tamanoFuente.round().toString(),
        onChanged: (valor) {
          elemento.tamanoFuente = valor;
          alCambiar();
        },
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Negrita'),
        value: elemento.negrita,
        onChanged: (valor) {
          elemento.negrita = valor;
          alCambiar();
        },
      ),
      SelectorColor(
        titulo: 'Color del texto',
        color: elemento.color,
        alCambiar: (color) {
          elemento.color = color;
          alCambiar();
        },
      ),
    ];
  }

  List<Widget> _opcionesCaja() {
    return [
      const Text('Fondo y Bordes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 12),
      SelectorColor(
        titulo: 'Color de Fondo',
        color: elemento.colorFondo,
        alCambiar: (color) {
          elemento.colorFondo = color;
          alCambiar();
        },
      ),
      SelectorColor(
        titulo: 'Color del Borde',
        color: elemento.colorBorde,
        alCambiar: (color) {
          elemento.colorBorde = color;
          alCambiar();
        },
      ),
      const SizedBox(height: 8),
      Text('Grosor del borde: ${elemento.grosorBorde.round()}'),
      Slider(
        value: elemento.grosorBorde.clamp(0, 20),
        min: 0,
        max: 20,
        divisions: 20,
        onChanged: (valor) {
          elemento.grosorBorde = valor;
          alCambiar();
        },
      ),
      Text('Redondeo de esquinas: ${elemento.radioBorde.round()}'),
      Slider(
        value: elemento.radioBorde.clamp(0, 100),
        min: 0,
        max: 100,
        divisions: 100,
        onChanged: (valor) {
          elemento.radioBorde = valor;
          alCambiar();
        },
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Aplicar Sombra'),
        value: elemento.conSombra,
        onChanged: (valor) {
          elemento.conSombra = valor;
          alCambiar();
        },
      ),
    ];
  }

  List<Widget> _opcionesSvg() {
    return [
      const Text(
        'Arrastra la imagen para moverla y usa el círculo de la esquina '
        'para cambiar su tamaño.',
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: alCambiarSvg,
        icon: const Icon(Icons.image_outlined),
        label: const Text('Cambiar gráfico SVG'),
      ),
    ];
  }

  List<Widget> _opcionesSello() {
    return [
      const Text('Configuración Visual del Sello', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        key: ValueKey('fuente-${elemento.id}'),
        initialValue: tipografiasDisponibles.contains(elemento.tipografia) ? elemento.tipografia : 'Roboto',
        decoration: const InputDecoration(labelText: 'Tipografía del número', border: OutlineInputBorder()),
        items: [
          for (final fuente in tipografiasDisponibles)
            DropdownMenuItem(value: fuente, child: Text(fuente)),
        ],
        onChanged: (valor) {
          if (valor != null) { elemento.tipografia = valor; alCambiar(); }
        },
      ),
      const SizedBox(height: 12),
      Text('Tamaño del número interno: ${elemento.tamanoFuente.round()}'),
      Slider(
        value: elemento.tamanoFuente.clamp(8, 80),
        min: 8, max: 80, divisions: 72,
        onChanged: (valor) { elemento.tamanoFuente = valor; alCambiar(); },
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Número en negrita'),
        value: elemento.negrita,
        onChanged: (valor) { elemento.negrita = valor; alCambiar(); },
      ),
      SelectorColor(
        titulo: 'Color del número',
        color: elemento.color,
        alCambiar: (color) { elemento.color = color; alCambiar(); },
      ),
    ];
  }

  Widget _botonesCapa() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: alTraerAlFrente,
          icon: const Icon(Icons.flip_to_front),
          label: const Text('Al frente'),
        ),
        OutlinedButton.icon(
          onPressed: alEnviarAtras,
          icon: const Icon(Icons.flip_to_back),
          label: const Text('Atrás'),
        ),
        OutlinedButton.icon(
          onPressed: alDuplicar,
          icon: const Icon(Icons.copy),
          label: const Text('Duplicar'),
        ),
        OutlinedButton.icon(
          onPressed: alEliminar,
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Eliminar'),
        ),
      ],
    );
  }
}