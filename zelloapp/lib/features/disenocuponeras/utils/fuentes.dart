import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fuentes que ya trae el sistema (Windows / Web).
/// En Android no existen, así que el teléfono usa una parecida.
const Set<String> fuentesSistema = {
  'Arial',
  'Verdana',
  'Tahoma',
  'Times New Roman',
  'Georgia',
  'Courier New',
  'Trebuchet MS',
  'Impact',
};

/// Todas las tipografías que se ofrecen en el diseñador.
const List<String> tipografiasDisponibles = [
  // Sistema
  'Arial', 'Verdana', 'Tahoma', 'Times New Roman', 'Georgia',
  'Courier New', 'Trebuchet MS', 'Impact',
  // Google Fonts - normales
  'Roboto', 'Open Sans', 'Lato', 'Montserrat', 'Poppins', 'Inter', 'Ubuntu',
  'Nunito', 'Raleway', 'Quicksand', 'Rubik', 'Work Sans', 'PT Sans',
  'Noto Sans', 'Barlow', 'Cabin', 'Kanit', 'Josefin Sans', 'Exo 2',
  'Fredoka', 'Comfortaa',
  // Google Fonts - con serifa
  'Merriweather', 'Playfair Display', 'Lora', 'Bitter', 'Crimson Text',
  'Cinzel', 'Abril Fatface',
  // Google Fonts - títulos llamativos
  'Oswald', 'Bebas Neue', 'Anton', 'Righteous', 'Press Start 2P',
  // Google Fonts - manuscritas
  'Pacifico', 'Lobster', 'Dancing Script', 'Caveat', 'Satisfy',
  'Great Vibes', 'Indie Flower', 'Amatic SC', 'Shadows Into Light',
  'Permanent Marker',
];

/// Devuelve el estilo de texto para la tipografía elegida.
/// Si es del sistema la usa directo; si no, la pide a Google Fonts.
TextStyle estiloFuente(
  String familia, {
  double? fontSize,
  Color? color,
  FontWeight? fontWeight,
}) {
  final base = TextStyle(
    fontSize: fontSize,
    color: color,
    fontWeight: fontWeight,
  );

  if (fuentesSistema.contains(familia)) {
    return base.copyWith(
      fontFamily: familia,
      fontFamilyFallback: const ['sans-serif'],
    );
  }

  try {
    return GoogleFonts.getFont(familia, textStyle: base);
  } catch (_) {
    return base; // si la fuente no existe, usamos la normal
  }
}

