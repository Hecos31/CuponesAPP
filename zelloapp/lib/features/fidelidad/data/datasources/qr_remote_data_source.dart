import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';

class QrRemoteDataSource {
  Future<String> generarQrCliente(String usuarioId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/canjes/generar-qr-cliente?usuario_id=$usuarioId');
    
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['token'];
    } else {
      throw Exception('Error al generar el token QR: ${response.statusCode}');
    }
  }
}