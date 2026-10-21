
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/network/api_config.dart';

class DisenoCuponeraService {
  DisenoCuponeraService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  // Debe coincidir con las rutas que registra tu backend.
  String _url(String cuponeraId) {
    final id = Uri.encodeComponent(cuponeraId);
    return '${ApiConfig.baseUrl}/cuponeras/$id/diseno';
  }

  Map<String, dynamic> _leerRespuesta(http.Response response) {
    final dynamic body;

    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw Exception(
        'La API respondió con contenido que no es JSON válido.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final mensaje = body is Map
          ? (body['detail'] ?? body['message'] ?? 'Error de la API')
          : 'Error de la API';

      throw Exception('$mensaje (HTTP ${response.statusCode})');
    }

    if (body is! Map<String, dynamic>) {
      throw Exception('La respuesta de la API tiene un formato inesperado.');
    }

    return body;
  }

  Future<Map<String, dynamic>> obtener(String cuponeraId) async {
    final response = await _client.get(
      Uri.parse(_url(cuponeraId)),
      headers: const {'Accept': 'application/json'},
    );

    return _leerRespuesta(response);
  }

  Future<Map<String, dynamic>> guardar({
    required String cuponeraId,
    required Map<String, dynamic> configuracion,
    String? svgMarkup,
    bool eliminarSvg = false,
  }) async {
    final response = await _client.put(
      Uri.parse(_url(cuponeraId)),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode({
        'configuracion_ui': configuracion,
        'svg_markup': svgMarkup,
        'eliminar_svg': eliminarSvg,
      }),
    );

    return _leerRespuesta(response);
  }

  void cerrar() {
    _client.close();
  }
}
