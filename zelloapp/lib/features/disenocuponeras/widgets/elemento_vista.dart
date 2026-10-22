import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/elemento_diseno.dart';
import '../utils/fuentes.dart';

/// Dibuja UN elemento (texto, SVG o sello). No sabe nada de arrastrar
/// ni de seleccionar; eso lo hace el lienzo.
class ElementoVista extends StatelessWidget {
  const ElementoVista({
    super.key,
    required this.elemento,
    required this.escala,
  });

  final ElementoDiseno elemento;

  /// Cuánto se agranda el lienzo en pantalla (para que el texto crezca igual).
  final double escala;

  @override
  Widget build(BuildContext context) {
    switch (elemento.tipo) {
      case TipoElemento.texto:
        return _texto();
      case TipoElemento.svg:
        return _svg();
      case TipoElemento.sello:
        return _sello();
    }
  }

  Widget _texto() {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown, // si no cabe, se achica en vez de cortarse
        child: Text(
          elemento.texto,
          textAlign: TextAlign.center,
          style: estiloFuente(
            elemento.tipografia,
            fontSize: elemento.tamanoFuente * escala,
            color: elemento.color,
            fontWeight: elemento.negrita ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _svg() {
    final svg = elemento.svg;
    if (svg == null || svg.isEmpty) {
      return const Icon(Icons.image_not_supported_outlined, color: Colors.white54);
    }

    return SvgPicture.string(
      svg,
      fit: BoxFit.contain,
      placeholderBuilder: (_) => const Center(
        child: Icon(Icons.image_outlined, color: Colors.white54),
      ),
    );
  }

  Widget _sello() {
    return Center(
      child: AspectRatio(
        aspectRatio: 1, // siempre redondo aunque la caja no sea cuadrada
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: elemento.color, width: 3 * escala),
          ),
          child: FittedBox(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                iconosSello[elemento.icono] ?? Icons.star,
                color: elemento.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

