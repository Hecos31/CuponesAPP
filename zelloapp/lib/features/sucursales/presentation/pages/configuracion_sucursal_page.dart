import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zelloapp/features/sucursales/data/datasources/sucursales_remote_data_source.dart';

class ConfiguracionSucursalPage extends StatefulWidget {
  final SucursalModel? sucursal;

  const ConfiguracionSucursalPage({super.key, this.sucursal});

  @override
  State<ConfiguracionSucursalPage> createState() => _ConfiguracionSucursalPageState();
}

class _ConfiguracionSucursalPageState extends State<ConfiguracionSucursalPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _logoUrlController;
  bool _activo = true;
  bool _isSaving = false;

  final _dataSource = SucursalesRemoteDataSource();

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.sucursal?.nombre ?? '');
    _logoUrlController = TextEditingController(text: widget.sucursal?.logoUrl ?? '');
    _activo = widget.sucursal?.activo ?? true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }

  Future<void> _guardarConfiguracion() async {
    if (!_formKey.currentState!.validate()) return;
    final sucursalId = widget.sucursal?.id ?? '';
    if (sucursalId.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final actualizada = await _dataSource.actualizarConfiguracionSucursal(
        sucursalId,
        nombre: _nombreController.text.trim(),
        logoUrl: _logoUrlController.text.trim(),
        activo: _activo,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Configuración de "${actualizada.nombre}" guardada correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración Especial de Sucursal'),
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
                color: Colors.amber.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.amber.shade300),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.tune, color: Colors.amber, size: 32),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Panel de ajustes operativos de la sucursal: modifica identidad visual, nombre comercial y disponibilidad en tiempo real.',
                          style: TextStyle(fontSize: 13),
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
                  labelText: 'Nombre Comercial de la Sucursal *',
                  prefixIcon: Icon(Icons.storefront),
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Ingresa el nombre de la sucursal' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _logoUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL del Logotipo Oficial',
                  prefixIcon: Icon(Icons.image),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _activo ? Colors.green : Colors.red),
                  color: _activo ? Colors.green.shade50 : Colors.red.shade50,
                ),
                child: SwitchListTile(
                  title: Text(
                    _activo ? 'Estado: Sucursal Operativa (Activa)' : 'Estado: Sucursal Suspendida (Inactiva)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _activo ? Colors.green.shade900 : Colors.red.shade900,
                    ),
                  ),
                  subtitle: Text(
                    _activo
                        ? 'Los clientes pueden ver la sucursal y acumular sellos.'
                        : 'La sucursal está oculta temporalmente para nuevos canjes.',
                  ),
                  value: _activo,
                  onChanged: (val) => setState(() => _activo = val),
                ),
              ),
              const SizedBox(height: 28),
              _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _guardarConfiguracion,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Guardar Configuración Especial', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
