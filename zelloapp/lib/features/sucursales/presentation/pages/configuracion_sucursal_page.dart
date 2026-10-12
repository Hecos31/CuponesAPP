import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/datasources/sucursales_remote_data_source.dart';

class ConfiguracionSucursalPage extends StatefulWidget {
  final SucursalModel? sucursal;
  final String? sucursalId;

  const ConfiguracionSucursalPage({
    super.key,
    this.sucursal,
    this.sucursalId,
  });

  @override
  State<ConfiguracionSucursalPage> createState() => _ConfiguracionSucursalPageState();
}

class _ConfiguracionSucursalPageState extends State<ConfiguracionSucursalPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _logoUrlController;

  late bool _activo;
  bool _isLoading = false;
  bool _isFetching = false;
  String? _errorMessage;
  SucursalModel? _currentSucursal;

  final _dataSource = SucursalesRemoteDataSource();

  @override
  void initState() {
    super.initState();
    _currentSucursal = widget.sucursal;
    _nombreController = TextEditingController(text: _currentSucursal?.nombre ?? '');
    _logoUrlController = TextEditingController(text: _currentSucursal?.logoUrl ?? '');
    _activo = _currentSucursal?.activo ?? true;

    if (_currentSucursal == null && widget.sucursalId != null) {
      _cargarDetalle(widget.sucursalId!);
    }
  }

  Future<void> _cargarDetalle(String id) async {
    setState(() => _isFetching = true);
    try {
      final item = await _dataSource.getDetalleSucursal(id);
      setState(() {
        _currentSucursal = item;
        _nombreController.text = item.nombre;
        _logoUrlController.text = item.logoUrl ?? '';
        _activo = item.activo;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isFetching = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }

  Future<void> _guardarConfiguracion() async {
    if (!_formKey.currentState!.validate()) return;
    final id = _currentSucursal?.id ?? widget.sucursalId;
    if (id == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final actualizada = await _dataSource.actualizarConfiguracionSucursal(
        id,
        nombre: _nombreController.text.trim(),
        logoUrl: _logoUrlController.text.trim().isNotEmpty ? _logoUrlController.text.trim() : null,
        activo: _activo,
      );

      setState(() => _currentSucursal = actualizada);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración especial actualizada con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración Especial'),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.tune, color: Colors.amber.shade900, size: 36),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Ajustes especiales de la sucursal: Nombre visible, logo de marca y estado de operación.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (_currentSucursal != null) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Identificador / Slug'),
                  subtitle: Text(_currentSucursal!.slug, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Chip(
                    label: Text(_activo ? 'ACTIVA' : 'INACTIVA'),
                    backgroundColor: _activo ? Colors.green.shade100 : Colors.red.shade100,
                  ),
                ),
                const Divider(),
                const SizedBox(height: 10),
              ],

              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Sucursal',
                  prefixIcon: Icon(Icons.edit_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'El nombre no puede estar vacío' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _logoUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL del Logo o Imagen de Sucursal',
                  prefixIcon: Icon(Icons.image_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.shade100,
                ),
                child: SwitchListTile(
                  title: const Text('Estado Operativo (Activo / Inactivo)', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(_activo
                      ? 'La sucursal está abierta y puede emitir sellos'
                      : 'La sucursal está pausada y oculta para sellado'),
                  value: _activo,
                  onChanged: (val) => setState(() => _activo = val),
                ),
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
                  : ElevatedButton.icon(
                      onPressed: _guardarConfiguracion,
                      icon: const Icon(Icons.save),
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
