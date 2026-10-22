import 'package:flutter/material.dart';

/// Convierte un color de Flutter a texto tipo "#1A2B3C" para guardarlo.
String colorAHex(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// Convierte "#1A2B3C" a Color. Si el valor no sirve, regresa [porDefecto].
Color colorDesdeHex(dynamic valor, Color porDefecto) {
  if (valor is! String) return porDefecto;

  var hex = valor.trim().replaceAll('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return porDefecto;

  final numero = int.tryParse(hex, radix: 16);
  return numero == null ? porDefecto : Color(numero);
}

