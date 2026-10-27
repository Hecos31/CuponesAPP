import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';

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
    _verificarEstado();
  }

  Future<void> _verificarEstado() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final usuarioId = prefs.getString('usuario_id');

      if (usuarioId == null) return;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/establecimientos/usuario/$usuarioId/estado-sucursal'), 
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bool tieneSucursal = data['tiene_sucursal'] ?? false;
        
        if (tieneSucursal && mounted) {
          await prefs.setString('status_local', 'aprobado');
          await prefs.setBool('is_establecimiento', true);
          
          if (data['cuponera_id'] != null) {
            await prefs.setString('mi_cuponera_id', data['cuponera_id']);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Felicidades! Tu establecimiento ha sido aprobado.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          // En lugar de usar context.go (que rompe la pila de navegación), usamos replace
          context.pushReplacement('/editor_cuponera'); 
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
        title: const Text('Estado de Solicitud'),
        // Eliminamos el action de logout para que muestre la flecha de regreso "<-"
      ),
      body: RefreshIndicator(
        onRefresh: _verificarEstado,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            const Icon(Icons.hourglass_empty, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              'Revisión en proceso', 
              textAlign: TextAlign.center, 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 16),
            const Text(
              'Tu establecimiento está siendo evaluado por nuestro equipo. Desliza hacia abajo para comprobar si ya fuiste aprobado.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}