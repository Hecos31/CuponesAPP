import 'package:flutter/material.dart';
import 'elemento_diseno.dart';

class DisenoLienzo {
  static const double ancho = 360.0;
  static const double alto = 220.0;
  
  Color fondo;
  List<ElementoDiseno> elementos;

  DisenoLienzo({
    this.fondo = Colors.white,
    List<ElementoDiseno>? elementos,
  }) : elementos = elementos ?? [];

  Map<String, dynamic> toJson() {
    return {
      'fondo': fondo.value,
      'elementos': elementos.map((e) => e.toJson()).toList(),
    };
  }

  factory DisenoLienzo.fromJson(Map<String, dynamic> json) {
    return DisenoLienzo(
      fondo: Color(json['fondo'] ?? 0xFFFFFFFF),
      elementos: (json['elementos'] as List<dynamic>?)
              ?.map((e) => ElementoDiseno.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}