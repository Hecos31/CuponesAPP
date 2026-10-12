import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/datasources/sucursales_remote_data_source.dart';

class VerificacionIdentidadPage extends StatefulWidget {
  const VerificacionIdentidadPage({super.key});

  @override
  State<VerificacionIdentidadPage> createState() => _VerificacionIdentidadPageState();
}

class _VerificacionIdentidadPageState extends State<VerificacionIdentidadPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreNegocioController = TextEditingController();
  final _documentoUrlController = TextEditingController();
  final _usuarioIdController = TextEditingController(text: '4cffbabf-436d-4ce0-b304-964f5eefa63e');

  final _dataSource = SucursalesRemoteDataSource();

  bool _isLoading = false;
  bool _isUploadingFile = false;
  String? _uploadedDocumentUrl;
  String? _selectedFileName;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _nombreNegocioController.dispose();
    _documentoUrlController.dispose();
    _usuarioIdController.dispose();
    super.dispose();
  }

  Future<void> _subirDocumentoProbatorio() async {
    try {
      // Abrir el explorador de archivos nativo
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );

      if (files.isEmpty) {
        // Usuario canceló la selección
        return;
      }

      final file = files.first;
      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        setState(() {
          _statusMessage = 'El archivo seleccionado está vacío.';
        });
        return;
      }

      setState(() {
        _isUploadingFile = true;
        _selectedFileName = file.name;
        _statusMessage = null;
      });

      final url = await _dataSource.uploadDocumento(bytes, file.name);

      setState(() {
        _uploadedDocumentUrl = url;
        _documentoUrlController.text = url;
        _statusMessage = '¡Archivo "${file.name}" cargado de forma segura!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error al subir documento: ${e.toString().replaceAll('Exception: ', '')}';
      });
    } finally {
      if (mounted) setState(() => _isUploadingFile = false);
    }
  }

  Future<void> _enviarSolicitud() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final docUrl = _documentoUrlController.text.trim();
      final solicitud = await _dataSource.crearSolicitud(
        usuarioId: _usuarioIdController.text.trim(),
        nombreNegocio: _nombreNegocioController.text.trim(),
        documentosUrl: docUrl.isNotEmpty ? docUrl : null,
      );

      setState(() {
        _isSuccess = true;
        _statusMessage = 'Solicitud #${solicitud.id.substring(0, 8)} registrada en estado "${solicitud.estado}".';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud enviada con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _statusMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación de Identidad'),
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
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.verified_user_outlined, color: Theme.of(context).colorScheme.primary, size: 36),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Sube tus documentos probatorios para validar y registrar tu sucursal o establecimiento.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nombreNegocioController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Negocio o Sucursal *',
                  hintText: 'Ej. Cafetería Central',
                  prefixIcon: Icon(Icons.storefront),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Ingresa el nombre del negocio' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _usuarioIdController,
                decoration: const InputDecoration(
                  labelText: 'ID de Usuario Solicitante',
                  hintText: 'UUID del usuario',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Ingresa el ID del usuario' : null,
              ),
              const SizedBox(height: 24),

              // Área de subida de archivos
              const Text(
                'Documento Probatorio (Acta, Identificación o RFC)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  children: [
                    Icon(
                      _uploadedDocumentUrl != null ? Icons.check_circle : Icons.cloud_upload_outlined,
                      size: 48,
                      color: _uploadedDocumentUrl != null ? Colors.green : Colors.blueGrey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _uploadedDocumentUrl != null
                          ? 'Archivo listo: ${_selectedFileName ?? _uploadedDocumentUrl!.split('/').last}'
                          : 'Cargar archivo (PDF o Imagen máx. 10MB)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _uploadedDocumentUrl != null ? Colors.green.shade800 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _isUploadingFile
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                            onPressed: _subirDocumentoProbatorio,
                            icon: const Icon(Icons.upload_file),
                            label: Text(_uploadedDocumentUrl != null ? 'Reemplazar Archivo' : 'Subir Documento Seguro'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey.shade800,
                              foregroundColor: Colors.white,
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _documentoUrlController,
                decoration: const InputDecoration(
                  labelText: 'Ruta o URL del Documento Probatorio',
                  hintText: 'Se autocompleta al subir archivo o escribe URL',
                  prefixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              if (_statusMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _isSuccess ? Colors.green : Colors.red),
                  ),
                  child: Row(
                    children: [
                      Icon(_isSuccess ? Icons.check_circle : Icons.error, color: _isSuccess ? Colors.green : Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(color: _isSuccess ? Colors.green.shade900 : Colors.red.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _enviarSolicitud,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Enviar Solicitud de Verificación', style: TextStyle(fontSize: 16)),
                    ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push('/sucursales/administracion'),
                child: const Text('Ir a Administración de Sucursales'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
