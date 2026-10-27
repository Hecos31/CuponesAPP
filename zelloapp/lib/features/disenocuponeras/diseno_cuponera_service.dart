import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/diseno_lienzo.dart';
import '../../core/network/api_config.dart'; // Ajusta según tu ruta real

class DisenoCuponeraService {
  Future<void> guardarDiseno({
    required String cuponeraId,
    required DisenoLienzo diseno,
  }) async {
    // La URL asume que crearás un endpoint PUT/PATCH en FastAPI
    final uri = Uri.parse('${ApiConfig.baseUrl}/cuponeras/$cuponeraId/diseno');
    
    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(diseno.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al guardar el diseño de la cuponera');
    }
  }

  Future<DisenoLienzo> cargarDiseno(String cuponeraId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/cuponeras/$cuponeraId/diseno');
    
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return DisenoLienzo.fromJson(jsonResponse);
    } else {
      throw Exception('Error al cargar el diseño');
    }
  }
}