import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';

class MisCuponerasPage extends StatefulWidget {
  const MisCuponerasPage({super.key});

  @override
  State<MisCuponerasPage> createState() => _MisCuponerasPageState();
}

class _MisCuponerasPageState extends State<MisCuponerasPage> {
  List<dynamic> _suscripciones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarSuscripciones();
  }

  Future<void> _cargarSuscripciones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getString('usuario_id');
      final token = prefs.getString('token');

      if (usuarioId == null) return;

      final url = Uri.parse('${ApiConfig.baseUrl}/cuponeras/mis-suscripciones/$usuarioId');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        setState(() => _suscripciones = jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Cuponeras')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _suscripciones.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.card_giftcard, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Aún no tienes cuponeras.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      TextButton(
                        onPressed: () => context.go('/descubrir'),
                        child: const Text('Explorar negocios'),
                      )
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _suscripciones.length,
                  itemBuilder: (context, index) {
                    final sub = _suscripciones[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.store, color: Colors.white)),
                        title: Text(sub['establecimiento_nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(sub['titulo_cuponera']),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${sub['sellos_acumulados']} / ${sub['total_sellos_requeridos']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                            const Text('Sellos', style: TextStyle(fontSize: 10)),
                          ],
                        ),
                        // Al tocar, enviamos el progreso_id para que el detalle sepa qué QR generar
                        onTap: () => context.push('/cuponeras/detalle', extra: sub),
                      ),
                    );
                  },
                ),
    );
  }
}