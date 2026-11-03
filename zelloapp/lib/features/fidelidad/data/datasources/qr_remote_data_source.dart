import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';

class QrRemoteDataSource {
  Future<String> generarQrCliente(String usuarioId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/canjes/generar-qr-cliente?usuario_id=$usuarioId');
    final response = await http.post(uri, headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['token'];
    } else {
      throw Exception('Error al generar el token QR: ${response.statusCode}');
    }
  }

  // 🔑 NUEVO: Función para consultar el progreso en tiempo real
  Future<int> consultarProgreso(String usuarioId, String cuponeraId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/canjes/progreso/$cuponeraId?usuario_id=$usuarioId');
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['sellos_acumulados'] ?? 0;
    }
    return 0;
  }
}