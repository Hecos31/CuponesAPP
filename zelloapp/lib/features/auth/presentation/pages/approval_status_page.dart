import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zelloapp/core/network/api_config.dart';

class ApprovalStatusPage extends StatefulWidget {
  const ApprovalStatusPage({super.key});

  @override
  State<ApprovalStatusPage> createState() => _ApprovalStatusPageState();
}

class _ApprovalStatusPageState extends State<ApprovalStatusPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Verificación silenciosa apenas entra a la pantalla
    _verificarEstado();
  }
Future<void> _verificarEstado() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Consultamos el endpoint para obtener el estado actual del usuario
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/usuarios/me'), 
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final nuevoEstado = data['establishment_status'] ?? 'pendiente';
        
        await prefs.setString('status_local', nuevoEstado);

        if (nuevoEstado == 'aprobado' && mounted) {
          // 1. Mostramos el mensaje de celebración al usuario
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '¡Felicidades! Tu establecimiento ha sido aprobado.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating, // Hace que flote sobre la UI
              duration: Duration(seconds: 4),
            ),
          );

          // 2. Lo redirigimos automáticamente a la vista de cuponeras
          context.go('/cuponeras');
        }
      }
    } catch (e) {
      debugPrint('Error verificando estado: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estado de Aprobación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (context.mounted) context.go('/login');
            },
          )
        ],
      ),
      // RefreshIndicator crea el efecto profesional de "deslizar para actualizar"
      body: RefreshIndicator(
        onRefresh: _verificarEstado,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            const Icon(Icons.hourglass_empty, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              'Revisión en proceso',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tu establecimiento está siendo evaluado por nuestro equipo. Desliza hacia abajo para comprobar si ya fuiste aprobado.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}