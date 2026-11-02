import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/datasources/sucursales_remote_data_source.dart';

class AltaSucursalPage extends StatefulWidget {
  const AltaSucursalPage({super.key});

  @override
  State<AltaSucursalPage> createState() => _AltaSucursalPageState();
}

class _AltaSucursalPageState extends State<AltaSucursalPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _slugController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _propietarioIdController = TextEditingController(text: 'TU-UUID-DE-PROPIETARIO-AQUI'); // Reemplaza con el UUID real del propietario

  bool _activo = true;
  bool _isLoading = false;
  String? _errorMessage;

  final _dataSource = SucursalesRemoteDataSource();

  @override
  void dispose() {
    _nombreController.dispose();
    _slugController.dispose();
    _logoUrlController.dispose();
    _propietarioIdController.dispose();
    super.dispose();
  }

  Future<void> _guardarSucursal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sucursal = await _dataSource.darDeAltaSucursal(
        propietarioId: _propietarioIdController.text.trim(),
        nombre: _nombreController.text.trim(),
        slug: _slugController.text.trim().isNotEmpty ? _slugController.text.trim() : null,
        logoUrl: _logoUrlController.text.trim().isNotEmpty ? _logoUrlController.text.trim() : null,
        activo: _activo,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sucursal "${sucursal.nombre}" dada de alta con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true); // Regresa a administración con resultado exitoso
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alta de Nueva Sucursal'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 0,
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.add_business, color: Colors.blue.shade700, size: 36),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Registra los datos operativos de tu nueva sucursal o local comercial.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Sucursal *',
                  hintText: 'Ej. Sucursal Plaza Mayor',
                  prefixIcon: Icon(Icons.store),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Ingresa el nombre de la sucursal' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _slugController,
                decoration: const InputDecoration(
                  labelText: 'Slug / Identificador URL (Opcional)',
                  hintText: 'Ej. sucursal-plaza-mayor (se autogenera si se omite)',
                  prefixIcon: Icon(Icons.alternate_email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _logoUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL del Logo o Imagen (Opcional)',
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.image_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _propietarioIdController,
                decoration: const InputDecoration(
                  labelText: 'ID del Propietario *',
                  hintText: 'UUID del usuario propietario',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Ingresa el ID del propietario' : null,
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sucursal Activa para Operaciones', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Podrá emitir sellos y cupones de fidelidad'),
                value: _activo,
                onChanged: (val) => setState(() => _activo = val),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade900)),
                ),
                const SizedBox(height: 20),
              ],

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _guardarSucursal,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Dar de Alta Sucursal', style: TextStyle(fontSize: 16)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
