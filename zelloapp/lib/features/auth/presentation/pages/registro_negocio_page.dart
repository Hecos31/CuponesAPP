import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_config.dart';

class RegistroNegocioPage extends StatefulWidget {
  const RegistroNegocioPage({super.key});

  @override
  State<RegistroNegocioPage> createState() => _RegistroNegocioPageState();
}

class _RegistroNegocioPageState extends State<RegistroNegocioPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  bool _isLoading = false;
  bool _documentoCargado = false;

  Future<void> _simularCargaDocumento() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isLoading = false;
      _documentoCargado = true;
    });
  }

  Future<void> _enviarSolicitud() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_documentoCargado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes adjuntar tus documentos de validación')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getString('usuario_id');
      final token = prefs.getString('token');

      if (usuarioId == null) throw Exception("No hay sesión activa");

      final url = Uri.parse('${ApiConfig.baseUrl}/establecimientos/solicitudes');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'usuario_id': usuarioId,
          'nombre_negocio': _nombreController.text.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await prefs.setString('status_local', 'pendiente');
        if (mounted) context.go('/revision_local');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Error al enviar solicitud');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar mi Local')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.store, size: 64, color: Colors.blue),
                const SizedBox(height: 16),
                const Text('Únete a nuestra red', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text('Para proteger a nuestros usuarios, necesitamos validar la identidad de tu negocio.', textAlign: TextAlign.center),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre Comercial del Negocio', border: OutlineInputBorder()),
                  validator: (value) => value!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text('Sube tu Identificación Oficial y Comprobante (PDF/JPG)', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _documentoCargado ? null : _simularCargaDocumento,
                        icon: Icon(_documentoCargado ? Icons.check_circle : Icons.upload_file),
                        label: Text(_documentoCargado ? 'Documentos Adjuntos' : 'Adjuntar Archivos'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _documentoCargado ? Colors.green : Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _enviarSolicitud,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Enviar Solicitud a Revisión', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}