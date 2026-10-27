import 'dart:convert';
import 'package:flutter/foundation.dart'; // ✅ Importado para usar debugPrint
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_config.dart';
import '../models/cuponera_lista_model.dart';

class CuponerasService {
  // 1. Obtener la lista de cuponeras disponibles (excluyendo las ya suscritas por el usuario)
  Future<List<CuponeraListaModel>> obtenerCuponerasDisponibles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getString('usuario_id') ?? '';

      debugPrint('🔎 [FILTRO CUPONERAS] Consultando feed para usuario_id: "$usuarioId"');

      // Enviamos el usuario_id como parámetro para que el backend filtre las ya adquiridas
      final url = Uri.parse('${ApiConfig.baseUrl}/cuponeras/?usuario_id=$usuarioId');
      final response = await http.get(url);

      debugPrint('🌐 [API] Status code cuponeras: ${response.statusCode}');
      debugPrint('📦 [API] Respuesta del servidor: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CuponeraListaModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar las cuponeras: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [ERROR] en obtenerCuponerasDisponibles: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // 2. Guardar o actualizar el diseño visual y reglas de la cuponera
  Future<void> guardarDisenoCuponera({
    required String cuponeraId,
    required Map<String, dynamic> disenoJson,
    int? totalVisitas,
    String? premiosIntermedios,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/cuponeras/$cuponeraId/diseno');
      
      final bodyData = {
        'diseno_json': disenoJson,
        if (totalVisitas != null) 'total_visitas': totalVisitas,
        if (premiosIntermedios != null) 'premios_intermedios': premiosIntermedios,
      };

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(bodyData),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Error al guardar el diseño');
      }
    } catch (e) {
      throw Exception('Error al guardar: $e');
    }
  }

  Future<Map<String, dynamic>> obtenerCuponeraDetalle(String cuponeraId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/cuponeras/$cuponeraId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Error al cargar el detalle de la cuponera');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}