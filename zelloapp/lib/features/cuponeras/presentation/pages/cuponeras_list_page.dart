import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';

class CuponerasListPage extends StatefulWidget {
  const CuponerasListPage({super.key});

  @override
  State<CuponerasListPage> createState() => _CuponerasListPageState();
}

class _CuponerasListPageState extends State<CuponerasListPage> {
  List<dynamic> _cuponerasPublicas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarFeedCuponeras();
  }

  Future<void> _cargarFeedCuponeras() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/cuponeras/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          _cuponerasPublicas = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Error cargando feed público: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _unirseCuponera(String cuponeraId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getString('usuario_id');
      final token = prefs.getString('token');

      if (usuarioId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, inicia sesión para unirte.'), backgroundColor: Colors.orange),
        );
        return;
      }

      // Mostramos un indicador de carga visual rápido
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Suscribiendo...')));

      final url = Uri.parse('${ApiConfig.baseUrl}/cuponeras/$cuponeraId/unirse?usuario_id=$usuarioId');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['mensaje'] ?? '¡Te has suscrito exitosamente!'), backgroundColor: Colors.green),
        );
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['detail'] ?? 'Error al suscribirse'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error de conexión: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Descubrir Cuponeras'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cuponerasPublicas.isEmpty
              ? const Center(child: Text('No hay cuponeras públicas por el momento.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cuponerasPublicas.length,
                  itemBuilder: (context, index) {
                    final cuponera = _cuponerasPublicas[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.store, color: Colors.white)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cuponera['establecimiento_nombre'] ?? 'Negocio', 
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Text(
                                        'Se requieren ${cuponera['total_sellos_requeridos']} sellos', 
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              cuponera['titulo'] ?? 'Cuponera de Fidelidad', 
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(cuponera['descripcion_premio'] ?? ''),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _unirseCuponera(cuponera['id']),
                                icon: const Icon(Icons.add_circle_outline),
                                label: const Text('Quiero esta cuponera'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}