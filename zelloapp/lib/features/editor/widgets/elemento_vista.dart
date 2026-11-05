import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/elemento_diseno.dart';

class ElementoVista extends StatelessWidget {
  const ElementoVista({super.key, required this.elemento, required this.escala, this.onTapQr, this.isLoading = false});
  final ElementoDiseno elemento;
  final double escala;
  final VoidCallback? onTapQr;
  final bool isLoading;

  TextStyle _estilo() {
    final baseStyle = TextStyle(fontSize: elemento.tamanoFuente * escala, color: elemento.color, fontWeight: elemento.negrita ? FontWeight.bold : FontWeight.normal);
    try { return GoogleFonts.getFont(elemento.tipografia, textStyle: baseStyle); } catch (e) { return baseStyle.copyWith(fontFamily: 'Roboto'); }
  }

  BoxDecoration _decoracionBase() {
    final esCirculo = elemento.tipo == TipoElemento.forma && elemento.forma == 'circulo';
    final esTriangulo = elemento.tipo == TipoElemento.forma && elemento.forma == 'triangulo';
    return BoxDecoration(
      color: esTriangulo ? Colors.transparent : elemento.colorFondo,
      shape: esCirculo ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: esCirculo ? null : BorderRadius.circular(elemento.radioBorde * escala),
      border: (elemento.grosorBorde > 0 && !esTriangulo) ? Border.all(color: elemento.colorBorde, width: elemento.grosorBorde * escala) : null,
      boxShadow: elemento.conSombra ? [BoxShadow(color: Colors.black26, blurRadius: 8 * escala, offset: Offset(0, 4 * escala))] : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: elemento.tipo == TipoElemento.botonQr && !isLoading ? onTapQr : null,
      child: Container(width: elemento.ancho * escala, height: elemento.alto * escala, decoration: _decoracionBase(), child: Center(child: _contenidoInterno())),
    );
  }

  Widget _contenidoInterno() {
    switch (elemento.tipo) {
      case TipoElemento.texto:
      case TipoElemento.sello: return Text(elemento.texto, style: _estilo(), textAlign: TextAlign.center);
      case TipoElemento.botonQr: return isLoading ? SizedBox(width: 24 * escala, height: 24 * escala, child: CircularProgressIndicator(color: elemento.color, strokeWidth: 2.5 * escala)) : Text(elemento.texto, style: _estilo(), textAlign: TextAlign.center);
      case TipoElemento.svg: return (elemento.svgContenido != null && elemento.svgContenido!.isNotEmpty) ? SvgPicture.string(elemento.svgContenido!, fit: BoxFit.contain, colorFilter: ColorFilter.mode(elemento.color, BlendMode.srcIn)) : const Icon(Icons.image, color: Colors.grey);
      case TipoElemento.forma: return elemento.forma == 'triangulo' ? CustomPaint(painter: _TrianguloPainter(color: elemento.colorFondo), size: Size.infinite) : const SizedBox.shrink();
    }
  }
}

class _TrianguloPainter extends CustomPainter {
  final Color color;
  _TrianguloPainter({required this.color});
  @override void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(size.width / 2, 0)..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}