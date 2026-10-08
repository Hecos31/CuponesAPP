import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zelloapp/core/network/api_config.dart';

class SelloRemoteDataSource {
  Future<Map<String, dynamic>> otorgarSello({
    required String tokenCliente,
    required String cuponeraId,
    required String emisorId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/canjes/otorgar-sello');
    
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'token_cliente': tokenCliente,
        'cuponera_id': cuponeraId,
        'emisor_id': emisorId,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['detail'] ?? 'Error al otorgar el sello');
    }
  }
} 