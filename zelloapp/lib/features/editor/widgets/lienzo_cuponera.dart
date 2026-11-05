import 'package:flutter/material.dart';
import '../models/diseno_lienzo.dart';
import '../models/elemento_diseno.dart';
import 'elemento_vista.dart';

class LienzoCuponera extends StatefulWidget {
  const LienzoCuponera({
    super.key,
    required this.diseno,
    required this.seleccionadoId,
    required this.alSeleccionar,
    required this.alCambiar,
    required this.alAbrirEditor,
    required this.mostrarCuadricula,
    required this.imanActivado,
  });

  final DisenoLienzo diseno;
  final String? seleccionadoId;
  final ValueChanged<String?> alSeleccionar;
  final VoidCallback alCambiar;
  final ValueChanged<String> alAbrirEditor;
  final bool mostrarCuadricula;
  final bool imanActivado;

  @override
  State<LienzoCuponera> createState() => _LienzoCuponeraState();
}

class _LienzoCuponeraState extends State<LienzoCuponera> {
  static const double _tamanoMinimo = 25;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final escala = constraints.maxHeight / DisenoLienzo.alto;
        final anchoLienzo = DisenoLienzo.ancho * escala;
        final altoLienzo = DisenoLienzo.alto * escala;

        return GestureDetector(
          onTap: () => widget.alSeleccionar(null),
          child: Container(
            width: anchoLienzo,
            height: altoLienzo,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: widget.diseno.fondo,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)
              ]
            ),
            child: CustomPaint(
              foregroundPainter: widget.mostrarCuadricula ? _CuadriculaPainter() : null,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final e in widget.diseno.elementos)
                    _elementoEnLienzo(e, escala, anchoLienzo, altoLienzo)
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _elementoEnLienzo(ElementoDiseno e, double escala, double anchoLienzo, double altoLienzo) {
    final seleccionado = e.id == widget.seleccionadoId;

    return Positioned(
      left: e.x * escala,
      top: e.y * escala,
      width: e.ancho * escala,
      height: e.alto * escala,
      child: GestureDetector(
        onTap: () => widget.alSeleccionar(e.id),
        onPanStart: (_) => widget.alSeleccionar(e.id),
        onPanUpdate: (detalles) {
          double nuevaX = e.x + detalles.delta.dx / escala;
          double nuevaY = e.y + detalles.delta.dy / escala;

          if (widget.imanActivado) {
            nuevaX = (nuevaX / 15).round() * 15.0;
            nuevaY = (nuevaY / 15).round() * 15.0;
          }

          // 🟢 SOLUCIÓN MATEMÁTICA: Límites estrictos para que nunca salgan del lienzo
          e.x = nuevaX.clamp(0.0, DisenoLienzo.ancho - e.ancho);
          e.y = nuevaY.clamp(0.0, DisenoLienzo.alto - e.alto);

          // 🟢 SOLUCIÓN RENDIMIENTO: Solo redibuja el lienzo localmente. (Adiós al lag)
          setState(() {});
        },
        onPanEnd: (_) {
          // Solo notificamos a la pantalla principal cuando el usuario SUELTA el objeto
          widget.alCambiar();
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: ElementoVista(elemento: e, escala: escala)),
            if (seleccionado) ...[
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blueAccent, width: 2.5),
                      borderRadius: BorderRadius.circular(4)
                    )
                  )
                )
              ),
              Positioned(
                left: -12,
                top: -12,
                child: GestureDetector(
                  onTap: () => widget.alAbrirEditor(e.id),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                    child: const Icon(Icons.edit, color: Colors.blueAccent, size: 18)
                  )
                )
              ),
              Positioned(
                right: -12,
                bottom: -12,
                child: GestureDetector(
                  onPanUpdate: (d) {
                    double nA = e.ancho + d.delta.dx / escala;
                    double nAlt = e.alto + d.delta.dy / escala;
                    
                    if (widget.imanActivado) {
                      nA = (nA / 15).round() * 15.0;
                      nAlt = (nAlt / 15).round() * 15.0;
                    }

                    // Limitar crecimiento para que no desborde la pantalla
                    double maxAncho = DisenoLienzo.ancho - e.x;
                    double maxAlto = DisenoLienzo.alto - e.y;

                    e.ancho = nA.clamp(_tamanoMinimo, maxAncho);
                    e.alto = nAlt.clamp(_tamanoMinimo, maxAlto);
                    
                    setState(() {});
                  },
                  onPanEnd: (_) => widget.alCambiar(),
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)])
                  )
                )
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
    final paint = Paint()..color = Colors.blue.withOpacity(0.15)..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 15) canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    for (double i = 0; i < size.height; i += 15) canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}