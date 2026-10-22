import 'package:flutter/material.dart';

import '../models/diseno_lienzo.dart';
import '../models/elemento_diseno.dart';
import 'elemento_vista.dart';

/// El lienzo donde se acomodan los elementos, como en Canva:
/// - Tocar un elemento lo selecciona.
/// - Arrastrarlo lo mueve.
/// - El cuadrito de la esquina inferior derecha cambia su tamaño.
/// - Tocar el fondo quita la selección.
class LienzoCuponera extends StatelessWidget {
  const LienzoCuponera({
    super.key,
    required this.diseno,
    required this.seleccionadoId,
    required this.alSeleccionar,
    required this.alCambiar,
  });

  final DisenoLienzo diseno;
  final String? seleccionadoId;
  final ValueChanged<String?> alSeleccionar;

  /// Se llama cada vez que algo se mueve o cambia de tamaño.
  final VoidCallback alCambiar;

  static const double _tamanoMinimo = 20;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // El lienzo mide 360 x 220 "puntos"; aquí calculamos cuánto
        // hay que agrandarlo para que llene el ancho disponible.
        final escala = constraints.maxWidth / DisenoLienzo.ancho;

        return GestureDetector(
          onTap: () => alSeleccionar(null),
          child: Container(
            width: DisenoLienzo.ancho * escala,
            height: DisenoLienzo.alto * escala,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: diseno.fondo,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Stack(
              children: [
                for (final elemento in diseno.elementos)
                  _elementoEnLienzo(elemento, escala),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _elementoEnLienzo(ElementoDiseno e, double escala) {
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
          // Dividimos entre la escala para convertir de pantalla a lienzo.
          // Se deja salir la mitad del elemento por las orillas, como en Canva.
          e.x = (e.x + detalles.delta.dx / escala)
              .clamp(-e.ancho / 2, DisenoLienzo.ancho - e.ancho / 2);
          e.y = (e.y + detalles.delta.dy / escala)
              .clamp(-e.alto / 2, DisenoLienzo.alto - e.alto / 2);
          alCambiar();
        },
        child: Stack(
          children: [
            Positioned.fill(child: ElementoVista(elemento: e, escala: escala)),
            if (seleccionado) ...[
              // Marco azul de selección
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.lightBlueAccent, width: 2),
                    ),
                  ),
                ),
              ),
              // Cuadrito para cambiar tamaño
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onPanUpdate: (detalles) {
                    e.ancho = (e.ancho + detalles.delta.dx / escala)
                        .clamp(_tamanoMinimo, DisenoLienzo.ancho * 2);
                    e.alto = (e.alto + detalles.delta.dy / escala)
                        .clamp(_tamanoMinimo, DisenoLienzo.alto * 2);
                    alCambiar();
                  },
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.lightBlueAccent, width: 3),
                    ),
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

