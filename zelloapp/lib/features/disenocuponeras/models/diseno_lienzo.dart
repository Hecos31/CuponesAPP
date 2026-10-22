import 'package:flutter/material.dart';

import '../utils/colores.dart';
import 'elemento_diseno.dart';

/// El diseño completo de una cuponera: el color de fondo
/// y la lista de elementos. El orden de la lista es el orden de las capas:
/// el primero queda hasta atrás y el último hasta adelante.
class DisenoLienzo {
  DisenoLienzo({required this.fondo, required this.elementos});

  /// Tamaño fijo del lienzo. En pantalla se escala para que quepa,
  /// así el diseño se ve igual en cualquier celular.
  static const double ancho = 360;
  static const double alto = 220;

  Color fondo;
  final List<ElementoDiseno> elementos;

  /// Diseño inicial cuando la cuponera todavía no tiene uno.
  factory DisenoLienzo.porDefecto() {
    return DisenoLienzo(
      fondo: const Color(0xFF172554),
      elementos: [
        ElementoDiseno(
          id: nuevoIdElemento(),
          tipo: TipoElemento.texto,
          texto: 'MI CUPONERA',
          x: 30,
          y: 20,
          ancho: 300,
          alto: 45,
          tamanoFuente: 26,
          negrita: true,
        ),
        ElementoDiseno(
          id: nuevoIdElemento(),
          tipo: TipoElemento.texto,
          texto: 'Tus beneficios favoritos',
          x: 55,
          y: 65,
          ancho: 250,
          alto: 30,
          tamanoFuente: 15,
        ),
        ElementoDiseno(
          id: nuevoIdElemento(),
          tipo: TipoElemento.sello,
          x: 145,
          y: 115,
          ancho: 70,
          alto: 70,
          color: const Color(0xFFFBBF24),
        ),
      ],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': 2,
      'color_fondo': colorAHex(fondo),
      'elementos': elementos.map((e) => e.toJson()).toList(),
    };
  }

  /// Lee el diseño que viene del backend.
  /// También entiende el formato viejo (antes de los elementos separados)
  /// para no perder los diseños que ya estaban guardados.
  factory DisenoLienzo.desdeJson(
    Map<String, dynamic> config, {
    String? svgAnterior,
  }) {
    final fondo = colorDesdeHex(config['color_fondo'], const Color(0xFF172554));
    final lista = config['elementos'];

    if (lista is List) {
      return DisenoLienzo(
        fondo: fondo,
        elementos: lista
            .whereType<Map>()
            .map((m) => ElementoDiseno.desdeJson(Map<String, dynamic>.from(m)))
            .toList(),
      );
    }

    // ---- Formato viejo: lo convertimos a elementos ----
    final diseno = DisenoLienzo.porDefecto()..fondo = fondo;
    final colorTexto = colorDesdeHex(config['color_texto'], Colors.white);
    final colorSello = colorDesdeHex(config['color_sello'], const Color(0xFFFBBF24));
    final fuente = config['tipografia'] is String
        ? config['tipografia'] as String
        : 'Roboto';

    for (final elemento in diseno.elementos) {
      if (elemento.tipo == TipoElemento.texto) {
        elemento.color = colorTexto;
        elemento.tipografia = fuente;
      } else if (elemento.tipo == TipoElemento.sello) {
        elemento.color = colorSello;
      }
    }

    if (svgAnterior != null && svgAnterior.isNotEmpty) {
      diseno.elementos.add(
        ElementoDiseno(
          id: nuevoIdElemento(),
          tipo: TipoElemento.svg,
          x: 250,
          y: 110,
          ancho: 100,
          alto: 100,
          svg: svgAnterior,
        ),
      );
    }

    return diseno;
  }
}

