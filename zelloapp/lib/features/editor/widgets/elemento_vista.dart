import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/elemento_diseno.dart';

class ElementoVista extends StatelessWidget {
  const ElementoVista({super.key, required this.elemento, required this.escala});

  final ElementoDiseno elemento;
  final double escala;

  TextStyle _estilo() {
    final baseStyle = TextStyle(
      fontSize: elemento.tamanoFuente * escala,
      color: elemento.color,
      fontWeight: elemento.negrita ? FontWeight.bold : FontWeight.normal,
    );
    try {
      // Intenta cargar la fuente de Google
      return GoogleFonts.getFont(elemento.tipografia, textStyle: baseStyle);
    } catch (e) {
      // Fallback si la fuente no existe o no hay internet en el emulador
      return baseStyle.copyWith(fontFamily: 'Roboto');
    }
  }

  // Contenedor base que aplica fondo, bordes y sombras a cualquier componente
  BoxDecoration _decoracionBase() {
    return BoxDecoration(
      color: elemento.colorFondo,
      borderRadius: BorderRadius.circular(elemento.radioBorde * escala),
      border: elemento.grosorBorde > 0 
          ? Border.all(color: elemento.colorBorde, width: elemento.grosorBorde * escala) 
          : null,
      boxShadow: elemento.conSombra 
          ? [BoxShadow(color: Colors.black38, blurRadius: 6 * escala, offset: Offset(0, 3 * escala))] 
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: elemento.ancho * escala,
      height: elemento.alto * escala,
      decoration: _decoracionBase(),
      child: Center(
        child: _contenidoInterno(),
      ),
    );
  }

  Widget _contenidoInterno() {
    switch (elemento.tipo) {
      case TipoElemento.texto:
      case TipoElemento.botonQr:
      case TipoElemento.sello:
        return Text(elemento.texto, style: _estilo(), textAlign: TextAlign.center);
      case TipoElemento.svg:
        return const Icon(Icons.image, color: Colors.grey);
    }
  }
}