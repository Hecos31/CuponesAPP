import 'package:flutter/material.dart';
import '../models/diseno_lienzo.dart';
import '../models/elemento_diseno.dart';
import 'elemento_vista.dart';

class LienzoCuponera extends StatelessWidget {
  const LienzoCuponera({
    super.key,
    required this.diseno,
    required this.seleccionadoId,
    required this.alSeleccionar,
    required this.alCambiar,
    required this.alAbrirEditor,
    required this.mostrarCuadricula,
    required this.imanActivado, // <-- Nuevo parámetro
  });

  final DisenoLienzo diseno;
  final String? seleccionadoId;
  final ValueChanged<String?> alSeleccionar;
  final VoidCallback alCambiar;
  final ValueChanged<String> alAbrirEditor;
  final bool mostrarCuadricula;
  final bool imanActivado;

  static const double _tamanoMinimo = 30; // Evita que se hagan invisibles

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final escala = constraints.maxHeight / DisenoLienzo.alto;
        final anchoLienzo = DisenoLienzo.ancho * escala;
        final altoLienzo = DisenoLienzo.alto * escala;

        return GestureDetector(
          onTap: () => alSeleccionar(null),
          child: Container(
            width: anchoLienzo,
            height: altoLienzo,
            clipBehavior: Clip.hardEdge, 
            decoration: BoxDecoration(color: diseno.fondo, border: Border.all(color: Colors.grey.shade300)),
            child: CustomPaint(
              foregroundPainter: mostrarCuadricula ? _CuadriculaPainter() : null,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  for (final e in diseno.elementos)
                    _elementoEnLienzo(e, escala, anchoLienzo, altoLienzo),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _elementoEnLienzo(ElementoDiseno e, double escala, double anchoLienzo, double altoLienzo) {
    final seleccionado = e.id == seleccionadoId;

    return Positioned(
      left: e.x * escala,
      top: e.y * escala,
      width: e.ancho * escala,
      height: e.alto * escala,
      child: GestureDetector(
        onTap: () => alSeleccionar(e.id),
        onPanStart: (_) => alSeleccionar(e.id),
        onPanUpdate: (detalles) {
          double nuevaX = e.x + detalles.delta.dx / escala;
          double nuevaY = e.y + detalles.delta.dy / escala;

          // LÓGICA DEL IMÁN (Snap to grid de 20px)
          if (imanActivado) {
            nuevaX = (nuevaX / 20).round() * 20.0;
            nuevaY = (nuevaY / 20).round() * 20.0;
          }

          e.x = nuevaX.clamp(-e.ancho / 2, DisenoLienzo.ancho - e.ancho / 2);
          e.y = nuevaY.clamp(-e.alto / 2, DisenoLienzo.alto - e.alto / 2);
          alCambiar();
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: ElementoVista(elemento: e, escala: escala)),
            if (seleccionado) ...[
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(border: Border.all(color: Colors.blueAccent, width: 2)),
                  ),
                ),
              ),
              // BOTÓN EDITAR MÁS GRANDE
              Positioned(
                left: -16, top: -16,
                child: GestureDetector(
                  onTap: () => alAbrirEditor(e.id),
                  child: Container(
                    padding: const EdgeInsets.all(10), // Más área táctil
                    decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                    child: const Icon(Icons.edit, color: Colors.white, size: 22),
                  ),
                ),
              ),
              // BOTÓN REDIMENSIONAR MÁS GRANDE Y CON ICONO
              Positioned(
                right: -16, bottom: -16,
                child: GestureDetector(
                  onPanUpdate: (detalles) {
                    double nuevoAncho = e.ancho + detalles.delta.dx / escala;
                    double nuevoAlto = e.alto + detalles.delta.dy / escala;
                    
                    if (imanActivado) {
                      nuevoAncho = (nuevoAncho / 20).round() * 20.0;
                      nuevoAlto = (nuevoAlto / 20).round() * 20.0;
                    }
                    
                    e.ancho = nuevoAncho.clamp(_tamanoMinimo, DisenoLienzo.ancho * 2);
                    e.alto = nuevoAlto.clamp(_tamanoMinimo, DisenoLienzo.alto * 2);
                    alCambiar();
                  },
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.blue, width: 2), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                    child: const Icon(Icons.open_in_full, size: 16, color: Colors.blue),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CuadriculaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.grey.withOpacity(0.4)..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 20) canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    for (double i = 0; i < size.height; i += 20) canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}