import 'package:flutter/material.dart';

enum TipoElemento { texto, svg, sello }

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
  
  Color color;
  String? svg;
  String icono;

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
    this.color = Colors.black,
    this.svg,
    this.icono = 'estrella',
  });

  // Convierte el objeto a JSON para enviarlo a FastAPI
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo.name, // Guarda 'texto', 'svg' o 'sello'
      'x': x,
      'y': y,
      'ancho': ancho,
      'alto': alto,
      'texto': texto,
      'tamanoFuente': tamanoFuente,
      'tipografia': tipografia,
      'negrita': negrita,
      'color': color.value, 
      'svg': svg,
      'icono': icono,
    };
  }

  // Reconstruye el objeto cuando FastAPI devuelve el JSON
  factory ElementoDiseno.fromJson(Map<String, dynamic> json) {
    return ElementoDiseno(
      id: json['id'] as String,
      tipo: TipoElemento.values.firstWhere((e) => e.name == json['tipo']),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      ancho: (json['ancho'] as num).toDouble(),
      alto: (json['alto'] as num).toDouble(),
      texto: json['texto'] ?? '',
      tamanoFuente: (json['tamanoFuente'] as num?)?.toDouble() ?? 20,
      tipografia: json['tipografia'] ?? 'Roboto',
      negrita: json['negrita'] ?? false,
      color: Color(json['color'] ?? 0xFF000000),
      svg: json['svg'],
      icono: json['icono'] ?? 'estrella',
    );
  }
}