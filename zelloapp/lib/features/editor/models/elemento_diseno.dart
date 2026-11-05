import 'package:flutter/material.dart';

enum TipoElemento { texto, svg, sello, botonQr, forma }

class ElementoDiseno {
  String id;
  TipoElemento tipo;
  double x, y, ancho, alto;
  String texto, tipografia, icono, forma;
  double tamanoFuente, grosorBorde, radioBorde;
  bool negrita, cursiva, conSombra;
  Color color, colorFondo, colorBorde;
  String? svg, svgContenido;

  ElementoDiseno({
    required this.id, required this.tipo, required this.x, required this.y, required this.ancho, required this.alto,
    this.texto = 'Nuevo Texto', this.tamanoFuente = 20, this.tipografia = 'Roboto',
    this.negrita = false, this.cursiva = false, this.conSombra = false,
    this.color = Colors.black, this.colorFondo = Colors.transparent, this.colorBorde = Colors.transparent,
    this.grosorBorde = 0, this.radioBorde = 0,
    this.svg, this.svgContenido, this.icono = 'estrella', this.forma = 'cuadrado',
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'tipo': tipo.name, 'x': x, 'y': y, 'ancho': ancho, 'alto': alto,
    'texto': texto, 'tamanoFuente': tamanoFuente, 'tipografia': tipografia,
    'negrita': negrita, 'cursiva': cursiva, 'color': color.value,
    'colorFondo': colorFondo.value, 'colorBorde': colorBorde.value,
    'grosorBorde': grosorBorde, 'radioBorde': radioBorde, 'conSombra': conSombra,
    'svg': svg, 'svgContenido': svgContenido, 'icono': icono, 'forma': forma,
  };

  factory ElementoDiseno.fromJson(Map<String, dynamic> json) {
    Color parseColor(dynamic colorValue, Color defaultColor) {
      if (colorValue == null) return defaultColor;
      if (colorValue is int) return Color(colorValue);
      if (colorValue is String) {
        final parsed = int.tryParse(colorValue.replaceAll('#', '0xFF'));
        if (parsed != null) return Color(parsed);
      }
      return defaultColor;
    }

    return ElementoDiseno(
      id: json['id'] ?? '',
      tipo: TipoElemento.values.firstWhere((e) => e.name == json['tipo'], orElse: () => TipoElemento.sello),
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      ancho: (json['ancho'] as num?)?.toDouble() ?? 50.0,
      alto: (json['alto'] as num?)?.toDouble() ?? 50.0,
      texto: json['texto'] ?? 'Texto',
      tamanoFuente: (json['tamanoFuente'] as num?)?.toDouble() ?? 20.0,
      tipografia: json['tipografia'] ?? 'Roboto',
      negrita: json['negrita'] ?? false,
      cursiva: json['cursiva'] ?? false,
      color: parseColor(json['color'], Colors.black),
      colorFondo: parseColor(json['colorFondo'], Colors.transparent),
      colorBorde: parseColor(json['colorBorde'], Colors.transparent),
      grosorBorde: (json['grosorBorde'] as num?)?.toDouble() ?? 0.0,
      radioBorde: (json['radioBorde'] as num?)?.toDouble() ?? 0.0,
      conSombra: json['conSombra'] ?? false,
      svg: json['svg'],
      svgContenido: json['svgContenido'],
      icono: json['icono'] ?? 'estrella',
      forma: json['forma'] ?? 'cuadrado',
    );
  }
}