import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zelloapp/core/network/api_config.dart';
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
  late String _nombreOriginal;
  bool _activo = true;
  bool _isSaving = false;
  bool _isUploadingLogo = false;
  String? _nombreArchivoLogo;

  final _dataSource = SucursalesRemoteDataSource();

  @override
  void initState() {
    super.initState();
    _nombreOriginal = (widget.sucursal?.nombre ?? '').trim();
    _nombreController = TextEditingController(text: _nombreOriginal);
    _logoUrlController = TextEditingController(text: widget.sucursal?.logoUrl ?? '');
    _activo = widget.sucursal?.activo ?? true;
    _nombreController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }

  bool get _nombreCambiado {
    final nuevo = _nombreController.text.trim();
    return nuevo.isNotEmpty && nuevo != _nombreOriginal;
  }

  String? _construirUrlImagenCompleta(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final trimmed = rawUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final serverRoot = ApiConfig.baseUrl.replaceAll('/api/v1', '');
    if (trimmed.startsWith('/')) {
      return '$serverRoot$trimmed';
    }
    return '$serverRoot/$trimmed';
  }

  Future<void> _seleccionarYSubirLogo() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg'],
      );

      if (files.isEmpty) return;

      final file = files.first;
      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El archivo de imagen seleccionado está vacío.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isUploadingLogo = true);

      final uploadedPath = await _dataSource.uploadDocumento(
        bytes,
        file.name,
        tipoDocumento: 'LOGO_SUCURSAL',
      );

      if (!mounted) return;
      setState(() {
        _logoUrlController.text = uploadedPath;
        _nombreArchivoLogo = file.name;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logotipo "${file.name}" cargado correctamente.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploadingLogo = false);
    }
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

      if (actualizada.requiereAprobacionNombre) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('status_local', 'pendiente');

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              actualizada.mensaje ??
                  'El cambio de nombre fue enviado a revisión del administrador.',
            ),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 4),
          ),
        );
        context.pushReplacement('/revision_local');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            actualizada.mensaje ??
                'Configuración de "${actualizada.nombre}" guardada correctamente.',
          ),
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
    final fullLogoUrl = _construirUrlImagenCompleta(_logoUrlController.text);

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
                          'Panel de ajustes operativos de la sucursal: sube o actualiza tu logotipo oficial, administra la disponibilidad y solicita cambios de nombre comercial.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 1. Subida y Vista Previa del Logotipo Oficial
              const Text(
                'Logotipo Oficial de la Sucursal',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sube una imagen (PNG o JPG) desde tu dispositivo. El cambio de logotipo se aplica de inmediato sin requerir revisión.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.blue.shade50,
                          backgroundImage: fullLogoUrl != null
                              ? NetworkImage(fullLogoUrl)
                              : null,
                          child: fullLogoUrl == null
                              ? Icon(
                                  Icons.storefront_rounded,
                                  size: 36,
                                  color: Colors.blue.shade700,
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nombreArchivoLogo != null
                                    ? 'Archivo listo: $_nombreArchivoLogo'
                                    : (fullLogoUrl != null
                                        ? 'Logotipo configurado actualmente'
                                        : 'Sin logotipo personalizado'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _isUploadingLogo
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2.5),
                                    )
                                  : ElevatedButton.icon(
                                      onPressed: _seleccionarYSubirLogo,
                                      icon: const Icon(Icons.upload_file, size: 18),
                                      label: const Text('Subir Imagen de Logo (PNG / JPG)'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueGrey.shade800,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _logoUrlController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Ruta o URL del Logotipo (opcional)',
                        prefixIcon: Icon(Icons.link),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Nombre Comercial de la Sucursal (requiere aprobación solo si se modifica)
              const Text(
                'Nombre Registrado de la Sucursal',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
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
              if (_nombreCambiado) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade900),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Has modificado el nombre registrado ("$_nombreOriginal" → "${_nombreController.text.trim()}"). Al guardar, este cambio de nombre pasará por aprobación del administrador.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // 3. Estado Operativo
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _activo ? Colors.green : Colors.red),
                  color: _activo ? Colors.green.shade50 : Colors.red.shade50,
                ),
                child: SwitchListTile(
                  title: Text(
                    _activo
                        ? 'Estado: Sucursal Operativa (Activa)'
                        : 'Estado: Sucursal Suspendida (Inactiva)',
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
                      icon: Icon(
                        _nombreCambiado ? Icons.send_rounded : Icons.save_outlined,
                      ),
                      label: Text(
                        _nombreCambiado
                            ? 'Guardar Logo y Enviar Cambio de Nombre a Aprobación'
                            : 'Guardar Configuración Especial',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _nombreCambiado ? Colors.orange.shade800 : null,
                        foregroundColor: _nombreCambiado ? Colors.white : null,
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
