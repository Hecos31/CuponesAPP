import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zelloapp/core/network/sesion_usuario.dart';

class RegistroNegocioPage extends StatefulWidget {
  const RegistroNegocioPage({super.key});

  @override
  State<RegistroNegocioPage> createState() => _RegistroNegocioPageState();
}

class _RegistroNegocioPageState extends State<RegistroNegocioPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreLocalController = TextEditingController();
  final _direccionController = TextEditingController();
  final _nombreDuenoController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nombreLocalController.dispose();
    _direccionController.dispose();
    _nombreDuenoController.dispose();
    super.dispose();
  }

  Future<void> _continuarASubidaDocumentos() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Obtenemos el ID del solicitante directamente del inicio de sesión (sin mostrarlo en pantalla)
      String? usuarioId = SesionUsuario().usuarioId;
      if (usuarioId == null || usuarioId.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        usuarioId = prefs.getString('usuario_id');
        if (usuarioId != null && usuarioId.isNotEmpty) {
          SesionUsuario().usuarioId = usuarioId;
        }
      }

      if (usuarioId == null || usuarioId.isEmpty) {
        throw Exception('No se encontró una sesión activa. Por favor inicia sesión de nuevo.');
      }

      if (!mounted) return;

      // Enviamos los datos capturados a la vista maquetada de Verificación de Identidad (subida de documentos)
      context.push(
        '/sucursales/verificacion',
        extra: {
          'usuarioId': usuarioId,
          'nombreLocal': _nombreLocalController.text.trim(),
          'direccion': _direccionController.text.trim(),
          'nombreSolicitante': _nombreDuenoController.text.trim(),
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar mi Local'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.storefront_rounded, size: 68, color: Colors.blue),
                const SizedBox(height: 16),
                const Text(
                  'Datos de tu Establecimiento',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ingresa la información de tu local y del propietario para continuar con la verificación de identidad y subida de documentos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 32),

                // 1. Nombre del Local
                TextFormField(
                  controller: _nombreLocalController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Local o Establecimiento *',
                    hintText: 'Ej. Cafetería Central',
                    prefixIcon: Icon(Icons.store_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Ingresa el nombre del local'
                      : null,
                ),
                const SizedBox(height: 20),

                // 2. Dirección del Local
                TextFormField(
                  controller: _direccionController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Dirección del Local *',
                    hintText: 'Calle, Número, Colonia, Ciudad y C.P.',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Ingresa la dirección del local'
                      : null,
                ),
                const SizedBox(height: 20),

                // 3. Nombre completo del solicitante o dueño
                TextFormField(
                  controller: _nombreDuenoController,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _continuarASubidaDocumentos(),
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo del Solicitante o Dueño *',
                    hintText: 'Ej. Juan Pérez García',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Ingresa el nombre completo del solicitante o dueño'
                      : null,
                ),
                const SizedBox(height: 32),

                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _continuarASubidaDocumentos,
                  icon: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward),
                  label: const Text(
                    'Continuar a Verificación de Identidad',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
