import 'package:flutter/material.dart';

// Agregamos 'forma' al enum
enum TipoElemento { texto, svg, sello, botonQr, forma }

class ElementoDiseno {
  String id;
  TipoElemento tipo;
  double x;
  double y;
  double ancho;
  double alto;
  
  String texto;
  double tamanoFuente;
  String tipografia;
  bool negrita;
  bool cursiva;
  
  Color color; 
  
  Color colorFondo;
  Color colorBorde;
  double grosorBorde;
  double radioBorde;
  bool conSombra;
  
  String? svg;
  String? svgContenido; // Para almacenar el código XML del SVG de forma segura
  String icono;
  String forma; // 'cuadrado', 'circulo', 'triangulo'

  ElementoDiseno({
    required this.id,
    required this.tipo,
    required this.x,
    required this.y,
    required this.ancho,
    required this.alto,
    this.texto = 'Nuevo Texto',
    this.tamanoFuente = 20,
    this.tipografia = 'Roboto',
    this.negrita = false,
    this.cursiva = false,
    this.color = Colors.black,
    this.colorFondo = Colors.transparent,
    this.colorBorde = Colors.transparent,
    this.grosorBorde = 0,
    this.radioBorde = 0,
    this.conSombra = false,
    this.svg,
    this.svgContenido,
    this.icono = 'estrella',
    this.forma = 'cuadrado',
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
    Color parseColor(dynamic colorValue, Color colorPorDefecto) {
      if (colorValue == null) return colorPorDefecto;
      if (colorValue is int) return Color(colorValue);
      if (colorValue is String) {
        final int? parsed = int.tryParse(colorValue.replaceAll('#', '0xFF'));
        if (parsed != null) return Color(parsed);
      }
      return colorPorDefecto;
    }

    return ElementoDiseno(
      id: json['id'] ?? '',
      tipo: TipoElemento.values.firstWhere(
        (e) => e.name == json['tipo'],
        orElse: () => TipoElemento.sello,
      ),
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