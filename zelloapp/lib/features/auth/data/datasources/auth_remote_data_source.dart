import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';

class AuthRemoteDataSource {
  Future<bool> registerUser(String email, String password) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/register');
    
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Error en el registro');
    }
  }
}
