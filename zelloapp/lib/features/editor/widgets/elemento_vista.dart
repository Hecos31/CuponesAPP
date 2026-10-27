import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      return GoogleFonts.getFont(elemento.tipografia, textStyle: baseStyle);
    } catch (e) {
      return baseStyle.copyWith(fontFamily: 'Roboto');
    }
  }

  BoxDecoration _decoracionBase() {
    final bool esCirculo = elemento.tipo == TipoElemento.forma && elemento.forma == 'circulo';
    final bool esTriangulo = elemento.tipo == TipoElemento.forma && elemento.forma == 'triangulo';

    return BoxDecoration(
      color: esTriangulo ? Colors.transparent : elemento.colorFondo,
      shape: esCirculo ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: esCirculo ? null : BorderRadius.circular(elemento.radioBorde * escala),
      border: (elemento.grosorBorde > 0 && !esTriangulo)
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
        if (elemento.svgContenido != null && elemento.svgContenido!.isNotEmpty) {
          return SvgPicture.string(
            elemento.svgContenido!,
            fit: BoxFit.contain,
            colorFilter: ColorFilter.mode(elemento.color, BlendMode.srcIn),
          );
        }
        return const Icon(Icons.image, color: Colors.grey);
      case TipoElemento.forma:
        if (elemento.forma == 'triangulo') {
          return CustomPaint(
            painter: _TrianguloPainter(color: elemento.colorFondo),
            size: Size.infinite,
          );
        }
        return const SizedBox.shrink(); 
    }
  }
}

class _TrianguloPainter extends CustomPainter {
  final Color color;
  _TrianguloPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}