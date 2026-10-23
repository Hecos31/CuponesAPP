import 'package:flutter/material.dart';

class BarraAgregar extends StatelessWidget {
  const BarraAgregar({
    super.key,
    required this.alAgregarTexto,
    required this.alAgregarSvg,
  });

  final VoidCallback alAgregarTexto;
  final VoidCallback alAgregarSvg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FilledButton.tonalIcon(
            onPressed: alAgregarTexto,
            icon: const Icon(Icons.text_fields),
            label: const Text('Agregar Texto'),
          ),
          FilledButton.tonalIcon(
            onPressed: alAgregarSvg,
            icon: const Icon(Icons.image_outlined),
            label: const Text('Agregar Gráfico'),
          ),
        ],
      ),
    );
  }
}