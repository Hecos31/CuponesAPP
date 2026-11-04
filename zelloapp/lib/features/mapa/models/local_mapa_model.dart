import 'package:flutter/material.dart';
import '../../cuponeras/models/cuponera_lista_model.dart';

/// Modelo que representa un local comercial con su ubicación y promoción activa
/// tanto para la vista "Sugerencias Cercanas" como para el Mapa Interactivo.
class LocalMapaModel {
  final String id;
  final String nombre;
  final String categoria;
  final String direccion;
  final String horario;
  final double distanciaKm;
  final double calificacion;
  final String tituloPromocion;
  final String descripcionPremio;
  final int totalSellosRequeridos;

  /// Posición normalizada (0.1 a 0.9) dentro del lienzo del mapa interactivo
  final Offset posicionMapa;

  final IconData icono;
  final Color colorCategoria;
  final Map<String, dynamic>? diseno;

  const LocalMapaModel({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.direccion,
    required this.horario,
    required this.distanciaKm,
    required this.calificacion,
    required this.tituloPromocion,
    required this.descripcionPremio,
    this.totalSellosRequeridos = 6,
    required this.posicionMapa,
    required this.icono,
    required this.colorCategoria,
    this.diseno,
  });

  /// Formatea la distancia en metros o kilómetros de forma legible.
  String get distanciaFormateada {
    if (distanciaKm < 1.0) {
      return '${(distanciaKm * 1000).round()} m';
    }
    return '${distanciaKm.toStringAsFixed(1)} km';
  }

  /// Convierte el local al mapa que espera `CuponeraDetailPage` (`/cuponeras/detalle`).
  Map<String, dynamic> toCuponeraDetailMap() {
    return {
      'id': id,
      'establecimiento_nombre': nombre,
      'titulo_cuponera': tituloPromocion,
      'descripcion_premio': descripcionPremio,
      'total_sellos_requeridos': totalSellosRequeridos,
      'configuracion_ui': diseno,
    };
  }

  /// Crea un `LocalMapaModel` a partir de una cuponera real del backend,
  /// asignándole coordenadas y metadatos de cercanía consistentes.
  factory LocalMapaModel.fromCuponeraReal(
    CuponeraListaModel cuponera,
    int index,
  ) {
    final categorias = ['Cafeterías', 'Restaurantes', 'Postres', 'Tiendas'];
    final iconos = [
      Icons.local_cafe_rounded,
      Icons.restaurant_rounded,
      Icons.icecream_rounded,
      Icons.storefront_rounded,
    ];
    final colores = [
      const Color(0xFF6D4C41),
      const Color(0xFFE53935),
      const Color(0xFFD81B60),
      const Color(0xFF1E88E5),
    ];
    final direcciones = [
      'Av. Principal #124, Centro',
      'Calle Morelos #45, Zona Norte',
      'Blvd. Reforma #890, Local 4',
      'Av. Universidad #310, Plaza Sur',
      'Calle Independencia #78, Centro',
    ];
    final posiciones = [
      const Offset(0.38, 0.36),
      const Offset(0.64, 0.42),
      const Offset(0.46, 0.66),
      const Offset(0.28, 0.58),
      const Offset(0.72, 0.28),
      const Offset(0.56, 0.24),
    ];

    final catIndex = index % categorias.length;
    final pos = posiciones[index % posiciones.length];
    final distancia = 0.25 + (index * 0.35);
    final rating = 4.5 + ((index % 5) * 0.1);

    return LocalMapaModel(
      id: cuponera.id,
      nombre: cuponera.establecimientoNombre,
      categoria: categorias[catIndex],
      direccion: direcciones[index % direcciones.length],
      horario: 'Abierto · Cierra a las 21:00',
      distanciaKm: double.parse(distancia.toStringAsFixed(2)),
      calificacion: double.parse(rating.toStringAsFixed(1)),
      tituloPromocion: cuponera.titulo,
      descripcionPremio: cuponera.descripcionPremio,
      totalSellosRequeridos: cuponera.totalSellosRequeridos,
      posicionMapa: pos,
      icono: iconos[catIndex],
      colorCategoria: colores[catIndex],
      diseno: cuponera.diseno,
    );
  }
}

/// Catálogo base de locales cercanos para garantizar que las vistas de
/// "Sugerencias Cercanas" y "Mapa Interactivo" siempre tengan datos de prueba
/// combinables con las cuponeras reales del servidor.
const List<LocalMapaModel> localesCercanosDemostracion = [
  LocalMapaModel(
    id: 'demo-local-1',
    nombre: 'Café Aurora Especialidad',
    categoria: 'Cafeterías',
    direccion: 'Av. Juárez #214, Centro Histórico',
    horario: 'Abierto · 08:00 - 21:30',
    distanciaKm: 0.25,
    calificacion: 4.9,
    tituloPromocion: 'Ruta del Café Artesanal',
    descripcionPremio: '1 Cold Brew o Latte Grande gratis',
    totalSellosRequeridos: 6,
    posicionMapa: Offset(0.42, 0.38),
    icono: Icons.local_cafe_rounded,
    colorCategoria: Color(0xFF6D4C41),
  ),
  LocalMapaModel(
    id: 'demo-local-2',
    nombre: 'Pizzería Napoli Forno',
    categoria: 'Restaurantes',
    direccion: 'Calle Hidalgo #88, Col. Americana',
    horario: 'Abierto · 13:00 - 23:00',
    distanciaKm: 0.55,
    calificacion: 4.8,
    tituloPromocion: 'Club Amantes de la Pizza',
    descripcionPremio: 'Pizza Margarita mediana artesanal',
    totalSellosRequeridos: 8,
    posicionMapa: Offset(0.65, 0.45),
    icono: Icons.local_pizza_rounded,
    colorCategoria: Color(0xFFE53935),
  ),
  LocalMapaModel(
    id: 'demo-local-3',
    nombre: 'Gelato & Co. Artesanal',
    categoria: 'Postres',
    direccion: 'Paseo de la Reforma #120, Local B',
    horario: 'Abierto · 11:00 - 20:30',
    distanciaKm: 0.80,
    calificacion: 4.7,
    tituloPromocion: 'Dulce Fidelidad',
    descripcionPremio: 'Helado doble en cono de waffle',
    totalSellosRequeridos: 5,
    posicionMapa: Offset(0.32, 0.62),
    icono: Icons.icecream_rounded,
    colorCategoria: Color(0xFFD81B60),
  ),
  LocalMapaModel(
    id: 'demo-local-4',
    nombre: 'Boulangerie Montmartre',
    categoria: 'Cafeterías',
    direccion: 'Calle Allende #52, Zona Centro',
    horario: 'Abierto · 07:30 - 20:00',
    distanciaKm: 1.15,
    calificacion: 4.9,
    tituloPromocion: 'Mañanas de Croissant',
    descripcionPremio: 'Combo Croissant + Capuccino',
    totalSellosRequeridos: 6,
    posicionMapa: Offset(0.58, 0.68),
    icono: Icons.bakery_dining_rounded,
    colorCategoria: Color(0xFF8D6E63),
  ),
  LocalMapaModel(
    id: 'demo-local-5',
    nombre: 'Tacos & Grill El Pastorcito',
    categoria: 'Restaurantes',
    direccion: 'Av. Insurgentes #402, Esq. Zaragoza',
    horario: 'Abierto · 14:00 - 00:00',
    distanciaKm: 1.40,
    calificacion: 4.6,
    tituloPromocion: 'Taquero Frecuente',
    descripcionPremio: 'Orden de 5 tacos + bebida gratis',
    totalSellosRequeridos: 7,
    posicionMapa: Offset(0.24, 0.34),
    icono: Icons.restaurant_rounded,
    colorCategoria: Color(0xFFF4511E),
  ),
  LocalMapaModel(
    id: 'demo-local-6',
    nombre: 'Librería & Concept Store Lumina',
    categoria: 'Tiendas',
    direccion: 'Av. Vallarta #915, Plaza Cultural',
    horario: 'Abierto · 10:00 - 21:00',
    distanciaKm: 1.75,
    calificacion: 4.8,
    tituloPromocion: 'Lectores Frecuentes',
    descripcionPremio: '25% de descuento + separador edición especial',
    totalSellosRequeridos: 5,
    posicionMapa: Offset(0.75, 0.28),
    icono: Icons.storefront_rounded,
    colorCategoria: Color(0xFF1E88E5),
  ),
];

/// Combina las cuponeras reales del backend con los locales de demostración
/// y los ordena por cercanía.
List<LocalMapaModel> construirListaLocalesCercanos(
  List<CuponeraListaModel> cuponerasReales,
) {
  final reales = <LocalMapaModel>[
    for (int i = 0; i < cuponerasReales.length; i++)
      LocalMapaModel.fromCuponeraReal(cuponerasReales[i], i),
  ];

  // Si hay cuponeras reales, las mostramos primero y completamos con sugerencias
  final nombresReales = reales.map((e) => e.nombre.toLowerCase()).toSet();
  final demosSinDuplicar = localesCercanosDemostracion
      .where((d) => !nombresReales.contains(d.nombre.toLowerCase()))
      .toList();

  final combinados = [...reales, ...demosSinDuplicar];
  combinados.sort((a, b) => a.distanciaKm.compareTo(b.distanciaKm));
  return combinados;
}

