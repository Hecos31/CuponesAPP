import 'package:flutter/material.dart';

import '../models/elemento_diseno.dart';

/// Lista de capas: el de arriba es el que se ve hasta adelante.
/// Tocar una capa selecciona ese elemento.
class PanelCapas extends StatelessWidget {
  const PanelCapas({
    super.key,
    required this.elementos,
    required this.seleccionadoId,
    required this.alSeleccionar,
  });

  final List<ElementoDiseno> elementos;
  final String? seleccionadoId;
  final ValueChanged<String> alSeleccionar;

  IconData _icono(TipoElemento tipo) {
    switch (tipo) {
      case TipoElemento.texto:
        return Icons.text_fields;
      case TipoElemento.svg:
        return Icons.image_outlined;
      case TipoElemento.sello:
        return Icons.verified_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (elementos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text('No hay elementos. Agrega uno con los botones de arriba.'),
      );
    }

    // Al revés para que el que está al frente salga primero.
    final capas = elementos.reversed.toList();

    return Column(
      children: [
        for (final e in capas)
          ListTile(
            dense: true,
            selected: e.id == seleccionadoId,
            leading: Icon(_icono(e.tipo)),
            title: Text(e.nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => alSeleccionar(e.id),
          ),
      ],
    );
  }
}

