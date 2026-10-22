import 'package:flutter/material.dart';

import '../models/elemento_diseno.dart';
import '../utils/fuentes.dart';
import 'selector_color.dart';

/// Panel para editar el elemento seleccionado.
/// Muestra opciones distintas según si es texto, SVG o sello.
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
        if (elemento.tipo == TipoElemento.texto) ..._opcionesTexto(),
        if (elemento.tipo == TipoElemento.svg) ..._opcionesSvg(),
        if (elemento.tipo == TipoElemento.sello) ..._opcionesSello(),
        const Divider(height: 24),
        _botonesCapa(),
      ],
    );
  }

  List<Widget> _opcionesTexto() {
    return [
      TextFormField(
        // La key hace que el campo se reinicie al seleccionar otro texto.
        key: ValueKey('texto-${elemento.id}'),
        initialValue: elemento.texto,
        decoration: const InputDecoration(
          labelText: 'Texto',
          border: OutlineInputBorder(),
        ),
        onChanged: (valor) {
          elemento.texto = valor;
          alCambiar();
        },
      ),
      const SizedBox(height: 12),
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
              child: Text(fuente, style: estiloFuente(fuente)),
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
        value: elemento.tamanoFuente.clamp(8, 80),
        min: 8,
        max: 80,
        divisions: 72,
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

  List<Widget> _opcionesSvg() {
    return [
      const Text(
        'Arrastra la imagen para moverla y usa el círculo de la esquina '
        'para cambiar su tamaño. Archivos .svg de hasta 2 MB.',
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: alCambiarSvg,
        icon: const Icon(Icons.upload_file),
        label: const Text('Cambiar imagen SVG'),
      ),
    ];
  }

  List<Widget> _opcionesSello() {
    return [
      const Text('Icono del sello'),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final entrada in iconosSello.entries)
            ChoiceChip(
              label: Icon(entrada.value, size: 20),
              selected: elemento.icono == entrada.key,
              onSelected: (_) {
                elemento.icono = entrada.key;
                alCambiar();
              },
            ),
        ],
      ),
      const SizedBox(height: 8),
      SelectorColor(
        titulo: 'Color del sello',
        color: elemento.color,
        alCambiar: (color) {
          elemento.color = color;
          alCambiar();
        },
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

