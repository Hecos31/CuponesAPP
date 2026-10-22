import 'package:flutter/material.dart';

import '../utils/colores.dart';

/// Los tipos de piezas que se pueden poner en la cuponera.
enum TipoElemento { texto, svg, sello }

/// Iconos que se pueden usar en un sello.
const Map<String, IconData> iconosSello = {
  'estrella': Icons.star,
  'corazon': Icons.favorite,
  'cafe': Icons.local_cafe,
  'regalo': Icons.card_giftcard,
  'verificado': Icons.verified,
  'fuego': Icons.local_fire_department,
  'premio': Icons.workspace_premium,
  'pizza': Icons.local_pizza,
};

int _contadorIds = 0;

/// Genera un id único para cada elemento nuevo.
String nuevoIdElemento() {
  _contadorIds++;
  return '${DateTime.now().microsecondsSinceEpoch}_$_contadorIds';
}

double _numero(dynamic valor, double porDefecto) {
  return valor is num ? valor.toDouble() : porDefecto;
}

/// Una pieza del diseño (como en Canva): un texto, una imagen SVG o un sello.
/// Cada una tiene su propia posición, tamaño y estilo.
class ElementoDiseno {
  ElementoDiseno({
    required this.id,
    required this.tipo,
    this.x = 20,
    this.y = 20,
    this.ancho = 160,
    this.alto = 50,
    this.texto = 'Texto',
    this.color = Colors.white,
    this.tipografia = 'Roboto',
    this.tamanoFuente = 20,
    this.negrita = false,
    this.svg,
    this.icono = 'estrella',
  });

  final String id;
  final TipoElemento tipo;

  // Posición y tamaño dentro del lienzo (en puntos del lienzo, no de pantalla)
  double x;
  double y;
  double ancho;
  double alto;

  // Usados por texto y sello
  Color color;

  // Solo texto
  String texto;
  String tipografia;
  double tamanoFuente;
  bool negrita;

  // Solo SVG
  String? svg;

  // Solo sello
  String icono;

  /// Nombre corto para mostrar en la lista de capas.
  String get nombre {
    switch (tipo) {
      case TipoElemento.texto:
        return texto.isEmpty ? 'Texto vacío' : texto;
      case TipoElemento.svg:
        return 'Imagen SVG';
      case TipoElemento.sello:
        return 'Sello';
    }
  }

  /// Crea una copia un poco desplazada (para "Duplicar").
  ElementoDiseno copiar() {
    return ElementoDiseno(
      id: nuevoIdElemento(),
      tipo: tipo,
      x: x + 15,
      y: y + 15,
      ancho: ancho,
      alto: alto,
      texto: texto,
      color: color,
      tipografia: tipografia,
      tamanoFuente: tamanoFuente,
      negrita: negrita,
      svg: svg,
      icono: icono,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo.name,
      'x': x,
      'y': y,
      'ancho': ancho,
      'alto': alto,
      'color': colorAHex(color),
      if (tipo == TipoElemento.texto) ...{
        'texto': texto,
        'tipografia': tipografia,
        'tamano_fuente': tamanoFuente,
        'negrita': negrita,
      },
      if (tipo == TipoElemento.svg) 'svg': svg,
      if (tipo == TipoElemento.sello) 'icono': icono,
    };
  }

  factory ElementoDiseno.desdeJson(Map<String, dynamic> json) {
    final tipo = TipoElemento.values.firstWhere(
      (t) => t.name == json['tipo'],
      orElse: () => TipoElemento.texto,
    );

    return ElementoDiseno(
      id: json['id'] is String ? json['id'] as String : nuevoIdElemento(),
      tipo: tipo,
      x: _numero(json['x'], 20),
      y: _numero(json['y'], 20),
      ancho: _numero(json['ancho'], 160),
      alto: _numero(json['alto'], 50),
      color: colorDesdeHex(json['color'], Colors.white),
      texto: json['texto'] is String ? json['texto'] as String : 'Texto',
      tipografia: json['tipografia'] is String
          ? json['tipografia'] as String
          : 'Roboto',
      tamanoFuente: _numero(json['tamano_fuente'], 20),
      negrita: json['negrita'] == true,
      svg: json['svg'] is String ? json['svg'] as String : null,
      icono: iconosSello.containsKey(json['icono'])
          ? json['icono'] as String
          : 'estrella',
    );
  }
}

