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
  bool _documentoSimuladoCargado = false; // Bandera para la carga simulada

  Future<void> _simularCargaDocumento() async {
    setState(() => _isLoading = true);
    // Simulamos el tiempo que tardaría en abrir el selector y cargar un PDF
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isLoading = false;
      _documentoSimuladoCargado = true;
    });
  }

  Future<void> _enviarSolicitud() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_documentoSimuladoCargado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes adjuntar tus documentos de validación')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Obtenemos tu ID de usuario logueado (en un caso real, el backend lo lee del Token JWT)
      // Para esta prueba, usaremos el UUID de tu cuenta directamente. 
      // IMPORTANTE: Cambia este ID por el tuyo.
      const String miUsuarioId = "37a5e625-e063-4f3d-8183-d6e1e613cf3d"; 

      final url = Uri.parse('${ApiConfig.baseUrl}/admin/solicitudes'); // Ajusta la ruta según tu router en FastAPI
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usuario_id': miUsuarioId,
          'nombre_negocio': _nombreController.text.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Guardamos el estado temporal para atraparlo en la revisión
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('status_local', 'pendiente');
        
        if (mounted) {
          context.go('/revision_local');
        }
      } else {
        throw Exception('Error al enviar solicitud: ${response.statusCode}');
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
                const Text(
                  'Únete a nuestra red',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Para proteger a nuestros usuarios, necesitamos validar la identidad de tu negocio.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Comercial del Negocio',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text('Sube tu Identificación Oficial y Comprobante de Domicilio (PDF o JPG)'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _documentoSimuladoCargado ? null : _simularCargaDocumento,
                        icon: Icon(_documentoSimuladoCargado ? Icons.check_circle : Icons.upload_file),
                        label: Text(_documentoSimuladoCargado ? 'Documentos Adjuntos' : 'Adjuntar Archivos'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _documentoSimuladoCargado ? Colors.green : Colors.blue,
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
                      ? const CircularProgressIndicator(color: Colors.white) 
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