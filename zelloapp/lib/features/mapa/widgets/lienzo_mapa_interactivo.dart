import 'package:flutter/material.dart';
import '../models/local_mapa_model.dart';

/// Lienzo cartográfico interactivo con soporte de zoom, arrastre, pines
/// seleccionables, indicador de ubicación del usuario y trazo de ruta.
class LienzoMapaInteractivo extends StatelessWidget {
  final TransformationController transformationController;
  final List<LocalMapaModel> locales;
  final LocalMapaModel? localSeleccionado;
  final ValueChanged<LocalMapaModel> onPinTap;
  final VoidCallback onFondoTap;

  /// Tamaño base del plano cartográfico virtual.
  static const double anchoMapa = 1000;
  static const double altoMapa = 900;

  /// Posición normalizada del usuario (centro del mapa).
  static const Offset posicionUsuario = Offset(0.50, 0.50);

  const LienzoMapaInteractivo({
    super.key,
    required this.transformationController,
    required this.locales,
    required this.localSeleccionado,
    required this.onPinTap,
    required this.onFondoTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onFondoTap,
      child: InteractiveViewer(
        transformationController: transformationController,
        constrained: false,
        minScale: 0.55,
        maxScale: 2.6,
        boundaryMargin: const EdgeInsets.all(220),
        child: SizedBox(
          width: anchoMapa,
          height: altoMapa,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Capa cartográfica (manzanas, parques, avenidas, radio y ruta)
              Positioned.fill(
                child: CustomPaint(
                  painter: _PintorCartografiaUrbana(
                    posicionUsuario: posicionUsuario,
                    posicionDestino: localSeleccionado?.posicionMapa,
                    colorRuta:
                        localSeleccionado?.colorCategoria ??
                        Colors.blue.shade700,
                  ),
                ),
              ),

              // 2. Marcador de ubicación actual del usuario
              Positioned(
                left: (posicionUsuario.dx * anchoMapa) - 36,
                top: (posicionUsuario.dy * altoMapa) - 36,
                child: const _MarcadorUsuarioActual(),
              ),

              // 3. Pines interactivos de cada local
              for (final local in locales)
                _construirPinLocal(
                  local: local,
                  seleccionado: localSeleccionado?.id == local.id,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirPinLocal({
    required LocalMapaModel local,
    required bool seleccionado,
  }) {
    final double x = local.posicionMapa.dx * anchoMapa;
    final double y = local.posicionMapa.dy * altoMapa;

    return Positioned(
      left: x - 70,
      top: y - (seleccionado ? 76 : 64),
      width: 140,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onPinTap(local),
        child: AnimatedScale(
          scale: seleccionado ? 1.14 : 1.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Etiqueta flotante con nombre y distancia
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: seleccionado
                      ? const Color(0xFF0F172A)
                      : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  local.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: seleccionado
                        ? Colors.white
                        : const Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Cuerpo del pin
              Container(
                width: seleccionado ? 44 : 38,
                height: seleccionado ? 44 : 38,
                decoration: BoxDecoration(
                  color: local.colorCategoria,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: seleccionado ? 3.5 : 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: local.colorCategoria.withValues(alpha: 0.45),
                      blurRadius: seleccionado ? 12 : 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  local.icono,
                  color: Colors.white,
                  size: seleccionado ? 22 : 18,
                ),
              ),
              // Sombra en el suelo
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 10,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarcadorUsuarioActual extends StatelessWidget {
  const _MarcadorUsuarioActual();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withValues(alpha: 0.16),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2563EB),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.45),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Tú estás aquí',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PintorCartografiaUrbana extends CustomPainter {
  final Offset posicionUsuario;
  final Offset? posicionDestino;
  final Color colorRuta;

  const _PintorCartografiaUrbana({
    required this.posicionUsuario,
    required this.posicionDestino,
    required this.colorRuta,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Fondo base de ciudad
    final fondoPaint = Paint()..color = const Color(0xFFEEF2F6);
    canvas.drawRect(Offset.zero & size, fondoPaint);

    // 2. Áreas verdes (parques urbanos)
    final parquePaint = Paint()..color = const Color(0xFFD9F2DF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(160, 140, 210, 150),
        const Radius.circular(18),
      ),
      parquePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(640, 520, 230, 170),
        const Radius.circular(18),
      ),
      parquePaint,
    );

    // 3. Manzanas edificadas
    final manzanaPaint = Paint()..color = const Color(0xFFE2E8F0);
    for (double x = 60; x < size.width - 80; x += 140) {
      for (double y = 60; y < size.height - 80; y += 130) {
        if ((x > 140 && x < 360 && y > 120 && y < 280) ||
            (x > 620 && x < 860 && y > 500 && y < 680)) {
          continue;
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, 105, 95),
            const Radius.circular(12),
          ),
          manzanaPaint,
        );
      }
    }

    // 4. Calles secundarias
    final callePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    for (double x = 180; x < size.width; x += 140) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), callePaint);
    }
    for (double y = 170; y < size.height; y += 130) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), callePaint);
    }

    // 5. Avenidas principales
    final avenidaPaint = Paint()
      ..color = const Color(0xFFFEF9C3)
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke;
    final bordeAvenidaPaint = Paint()
      ..color = const Color(0xFFFDE047)
      ..strokeWidth = 26
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, size.height * 0.50),
      Offset(size.width, size.height * 0.50),
      bordeAvenidaPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.50),
      Offset(size.width, size.height * 0.50),
      avenidaPaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.50, 0),
      Offset(size.width * 0.50, size.height),
      bordeAvenidaPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.50, 0),
      Offset(size.width * 0.50, size.height),
      avenidaPaint,
    );

    // 6. Círculos de radio de cercanía (500 m y 1.2 km)
    final centroUsuario = Offset(
      posicionUsuario.dx * size.width,
      posicionUsuario.dy * size.height,
    );
    final radioPaint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    canvas.drawCircle(centroUsuario, 160, radioPaint);
    canvas.drawCircle(centroUsuario, 310, radioPaint);

    // 7. Si hay un local seleccionado, dibujamos la línea punteada de ruta
    if (posicionDestino != null) {
      final destino = Offset(
        posicionDestino!.dx * size.width,
        posicionDestino!.dy * size.height,
      );
      _dibujarRutaPunteada(canvas, centroUsuario, destino, colorRuta);
    }
  }

  void _dibujarRutaPunteada(
    Canvas canvas,
    Offset inicio,
    Offset fin,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final distanciaTotal = (fin - inicio).distance;
    if (distanciaTotal <= 0) return;

    const double largoTrazo = 10;
    const double espacio = 8;
    final direccion = (fin - inicio) / distanciaTotal;

    double avanzado = 0;
    while (avanzado < distanciaTotal) {
      final p1 = inicio + direccion * avanzado;
      final p2 =
          inicio +
          direccion * (avanzado + largoTrazo).clamp(0.0, distanciaTotal);
      canvas.drawLine(p1, p2, paint);
      avanzado += largoTrazo + espacio;
    }
  }

  @override
  bool shouldRepaint(covariant _PintorCartografiaUrbana oldDelegate) {
    return oldDelegate.posicionDestino != posicionDestino ||
        oldDelegate.colorRuta != colorRuta;
  }
}

