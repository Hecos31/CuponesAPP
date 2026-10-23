import 'package:flutter/material.dart';

const List<String> tipografiasDisponibles = ['Roboto', 'Arial', 'Courier'];

const Map<String, IconData> iconosSello = {
  'estrella': Icons.star,
  'check': Icons.check_circle,
  'cafe': Icons.local_cafe,
  'regalo': Icons.card_giftcard,
};

TextStyle estiloFuente(String fuente, {double? fontSize, Color? color, FontWeight? fontWeight}) {
  return TextStyle(
    fontFamily: fuente,
    fontSize: fontSize,
    color: color,
    fontWeight: fontWeight,
  );
}