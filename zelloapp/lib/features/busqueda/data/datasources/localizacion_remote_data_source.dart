import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zelloapp/core/network/api_config.dart';

class LocalCercanoModel {
  final String establecimientoId;
  final String nombre;
  final String slug;
  final String? logoUrl;
  final String? direccion;
  final double latitud;
  final double longitud;
  final double distanciaKm;
  final int distanciaMetros;
  final bool tieneCuponera;
  final String? cuponeraId;
  final String? tituloCuponera;
  final String? descripcionPremio;
  final int? totalSellosRequeridos;
  final Map<String, dynamic>? configuracionUi;

  LocalCercanoModel({
    required this.establecimientoId,
    required this.nombre,
    required this.slug,
    this.logoUrl,
    this.direccion,
    required this.latitud,
    required this.longitud,
    required this.distanciaKm,
    required this.distanciaMetros,
    required this.tieneCuponera,
    this.cuponeraId,
    this.tituloCuponera,
    this.descripcionPremio,
    this.totalSellosRequeridos,
    this.configuracionUi,
  });

  factory LocalCercanoModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? uiMap;
    if (json['configuracion_ui'] is Map<String, dynamic>) {
      uiMap = json['configuracion_ui'] as Map<String, dynamic>;
    }

    return LocalCercanoModel(
      establecimientoId: (json['establecimiento_id'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      logoUrl: json['logo_url']?.toString(),
      direccion: json['direccion']?.toString(),
      latitud: (json['latitud'] as num?)?.toDouble() ?? 19.4326,
      longitud: (json['longitud'] as num?)?.toDouble() ?? -99.1332,
      distanciaKm: (json['distancia_km'] as num?)?.toDouble() ?? 0.0,
      distanciaMetros: (json['distancia_metros'] as num?)?.toInt() ?? 0,
      tieneCuponera: json['tiene_cuponera'] == true,
      cuponeraId: json['cuponera_id']?.toString(),
      tituloCuponera: json['titulo_cuponera']?.toString(),
      descripcionPremio: json['descripcion_premio']?.toString(),
      totalSellosRequeridos: (json['total_sellos_requeridos'] as num?)?.toInt(),
      configuracionUi: uiMap,
    );
  }
}

class LocalizacionRemoteDataSource {
  // Tarea 990 (FG): Consultar coordenadas y distancias de todos los locales
  Future<List<LocalCercanoModel>> consultarCoordenadasYDistancias({
    required double latitud,
    required double longitud,
    String? busqueda,
  }) async {
    final queryParams = <String, String>{
      'latitud': latitud.toString(),
      'longitud': longitud.toString(),
    };
    if (busqueda != null && busqueda.trim().isNotEmpty) {
      queryParams['busqueda'] = busqueda.trim();
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/localizacion/coordenadas')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => LocalCercanoModel.fromJson(e)).toList();
    } else {
      throw Exception('Error al consultar coordenadas y distancias (${response.statusCode})');
    }
  }

  // Tarea 800 & 850 (FG): Filtrar locales cercanos por radio en km e integrar en vista
  Future<List<LocalCercanoModel>> obtenerSugerenciasCercanasPorRadio({
    required double latitud,
    required double longitud,
    required double radioKm,
    String? busqueda,
  }) async {
    final queryParams = <String, String>{
      'latitud': latitud.toString(),
      'longitud': longitud.toString(),
      'radio_km': radioKm.toString(),
    };
    if (busqueda != null && busqueda.trim().isNotEmpty) {
      queryParams['busqueda'] = busqueda.trim();
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/localizacion/cercanos')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final Map<String, dynamic> body = json.decode(response.body);
      final List localesJson = (body['locales'] as List?) ?? [];
      return localesJson.map((e) => LocalCercanoModel.fromJson(e)).toList();
    } else {
      throw Exception('Error al filtrar locales por radio (${response.statusCode})');
    }
  }
}
