import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/api_config.dart';

class SucursalService {
  // Consultar el estado real directamente desde la base de datos
  Future<Map<String, dynamic>> consultarEstadoSucursal(String usuarioId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/usuarios/$usuarioId/estado-sucursal');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al consultar el estado de la sucursal');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Map<String, dynamic>> solicitarAltaSucursal(String usuarioId, String nombreNegocio) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/usuarios/$usuarioId/simular-alta-sucursal?nombre_negocio=${Uri.encodeComponent(nombreNegocio)}',
      );

      final response = await http.post(url);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'Error al solicitar el alta como sucursal');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}