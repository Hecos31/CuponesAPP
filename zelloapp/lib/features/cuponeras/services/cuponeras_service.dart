import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/api_config.dart';
import '../models/cuponera_lista_model.dart';

class CuponerasService {
  // 1. Obtener la lista de cuponeras disponibles
  Future<List<CuponeraListaModel>> obtenerCuponerasDisponibles() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/cuponeras/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CuponeraListaModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar las cuponeras: ${response.statusCode}');
      }
    } catch (e) {
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