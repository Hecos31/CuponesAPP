import 'package:flutter/material.dart';

/// Botones para agregar elementos nuevos al lienzo.
class BarraAgregar extends StatelessWidget {
  const BarraAgregar({
    super.key,
    required this.alAgregarTexto,
    required this.alAgregarSvg,
    required this.alAgregarSello,
  });

  final VoidCallback alAgregarTexto;
  final VoidCallback alAgregarSvg;
  final VoidCallback alAgregarSello;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        FilledButton.tonalIcon(
          onPressed: alAgregarTexto,
          icon: const Icon(Icons.text_fields),
          label: const Text('Texto'),
        ),
        FilledButton.tonalIcon(
          onPressed: alAgregarSvg,
          icon: const Icon(Icons.image_outlined),
          label: const Text('SVG'),
        ),
        FilledButton.tonalIcon(
          onPressed: alAgregarSello,
          icon: const Icon(Icons.verified_outlined),
          label: const Text('Sello'),
        ),
      ],
    );
  }
}

