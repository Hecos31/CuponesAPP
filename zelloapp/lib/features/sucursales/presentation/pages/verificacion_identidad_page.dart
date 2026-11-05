import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zelloapp/core/network/sesion_usuario.dart';
import 'package:zelloapp/features/sucursales/data/datasources/sucursales_remote_data_source.dart';

class VerificacionIdentidadPage extends StatefulWidget {
  final Map<String, dynamic>? datosRegistro;

  const VerificacionIdentidadPage({super.key, this.datosRegistro});

  @override
  State<VerificacionIdentidadPage> createState() => _VerificacionIdentidadPageState();
}

class _VerificacionIdentidadPageState extends State<VerificacionIdentidadPage> {
  final _dataSource = SucursalesRemoteDataSource();

  // 1. Identificación Oficial (INE o Pasaporte)
  String _tipoIdentificacion = 'INE'; // 'INE' o 'PASAPORTE'
  bool _uploadingIdentificacion = false;
  String? _urlIdentificacion;
  String? _nombreArchivoIdentificacion;

  // 2. Comprobante de Domicilio
  bool _uploadingComprobante = false;
  String? _urlComprobante;
  String? _nombreArchivoComprobante;

  // 3. Documento Acreditativo del Local
  bool _uploadingDocLocal = false;
  String? _urlDocLocal;
  String? _nombreArchivoDocLocal;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _documentosCompletos =>
      _urlIdentificacion != null &&
      _urlIdentificacion!.isNotEmpty &&
      _urlComprobante != null &&
      _urlComprobante!.isNotEmpty &&
      _urlDocLocal != null &&
      _urlDocLocal!.isNotEmpty;

  Future<void> _seleccionarYSubirArchivo({
    required String tipoDocumento,
    required void Function(bool) setUploading,
    required void Function(String url, String fileName) onSuccess,
  }) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );

      if (files.isEmpty) return;

      final file = files.first;
      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        setState(() => _errorMessage = 'El archivo seleccionado está vacío.');
        return;
      }

      setState(() {
        setUploading(true);
        _errorMessage = null;
      });

      final url = await _dataSource.uploadDocumento(
        bytes,
        file.name,
        tipoDocumento: tipoDocumento,
      );

      if (mounted) {
        setState(() {
          onSuccess(url, file.name);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Documento "$tipoDocumento" (${file.name}) subido de forma segura.'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => setUploading(false));
      }
    }
  }

  Future<void> _enviarSolicitudYPasarARevision() async {
    if (!_documentosCompletos) {
      setState(() {
        _errorMessage =
            'Debes subir los 3 documentos probatorios (Identificación Oficial, Comprobante de Domicilio y Documento del Local) para continuar.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Obtenemos el usuarioId desde la sesión o desde los datos enviados por la pantalla anterior
      String? usuarioId = widget.datosRegistro?['usuarioId']?.toString() ?? SesionUsuario().usuarioId;
      if (usuarioId == null || usuarioId.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        usuarioId = prefs.getString('usuario_id');
      }

      if (usuarioId == null || usuarioId.isEmpty) {
        throw Exception('No se encontró el usuario en la sesión activa.');
      }

      final String nombreLocal = (widget.datosRegistro?['nombreLocal'] ?? 'Mi Establecimiento').toString();
      final String direccion = (widget.datosRegistro?['direccion'] ?? '').toString();
      final String nombreSolicitante = (widget.datosRegistro?['nombreSolicitante'] ?? '').toString();

      final docsConcatenados = [
        _urlIdentificacion!,
        _urlComprobante!,
        _urlDocLocal!,
      ].join(' | ');

      await _dataSource.crearSolicitud(
        usuarioId: usuarioId,
        nombreNegocio: nombreLocal,
        documentosUrl: docsConcatenados,
        direccion: direccion,
        nombreSolicitante: nombreSolicitante,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('status_local', 'pendiente');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documentación verificada y solicitud enviada a revisión.'),
            backgroundColor: Colors.green,
          ),
        );
        // Redirigimos a la pantalla de espera de validación
        context.go('/revision_local');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildDocumentUploadCard({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required bool isUploading,
    required String? uploadedUrl,
    required String? fileName,
    required VoidCallback onUploadPressed,
    Widget? headerExtra,
  }) {
    final bool cargado = uploadedUrl != null && uploadedUrl.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cargado ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cargado ? Colors.green.shade600 : Colors.grey.shade300,
          width: cargado ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                cargado ? Icons.check_circle : icono,
                color: cargado ? Colors.green.shade700 : Colors.blueGrey.shade700,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cargado ? 'Archivo cargado: $fileName' : subtitulo,
                      style: TextStyle(
                        fontSize: 12,
                        color: cargado ? Colors.green.shade900 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (headerExtra != null) ...[
            const SizedBox(height: 12),
            headerExtra,
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: isUploading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : ElevatedButton.icon(
                    onPressed: onUploadPressed,
                    icon: Icon(cargado ? Icons.sync : Icons.upload_file, size: 18),
                    label: Text(cargado ? 'Reemplazar archivo' : 'Subir archivo (PDF / JPG / PNG)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cargado ? Colors.green.shade700 : Colors.blueGrey.shade800,
                      foregroundColor: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombreLocal = widget.datosRegistro?['nombreLocal']?.toString() ?? '';
    final direccion = widget.datosRegistro?['direccion']?.toString() ?? '';
    final nombreSolicitante = widget.datosRegistro?['nombreSolicitante']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación de Identidad'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Resumen de los datos capturados en el paso anterior (sin mostrar el ID del usuario)
              if (nombreLocal.isNotEmpty)
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.storefront, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                nombreLocal,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        if (direccion.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('Dirección: $direccion', style: const TextStyle(fontSize: 13)),
                        ],
                        if (nombreSolicitante.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Solicitante / Dueño: $nombreSolicitante', style: const TextStyle(fontSize: 13)),
                        ],
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),
              const Text(
                'Carga de Documentos Probatorios',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Adjunta los 3 documentos oficiales requeridos para validar tu identidad y dar de alta tu sucursal.',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 16),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 1. Identificación Oficial (INE o Pasaporte)
              _buildDocumentUploadCard(
                titulo: '1. Identificación Oficial ($_tipoIdentificacion) *',
                subtitulo: 'Sube tu INE/IFE vigente o Pasaporte oficial',
                icono: Icons.badge_outlined,
                isUploading: _uploadingIdentificacion,
                uploadedUrl: _urlIdentificacion,
                fileName: _nombreArchivoIdentificacion,
                headerExtra: Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('INE / IFE'),
                        selected: _tipoIdentificacion == 'INE',
                        onSelected: (s) {
                          if (s) setState(() => _tipoIdentificacion = 'INE');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Pasaporte'),
                        selected: _tipoIdentificacion == 'PASAPORTE',
                        onSelected: (s) {
                          if (s) setState(() => _tipoIdentificacion = 'PASAPORTE');
                        },
                      ),
                    ),
                  ],
                ),
                onUploadPressed: () => _seleccionarYSubirArchivo(
                  tipoDocumento: _tipoIdentificacion,
                  setUploading: (val) => _uploadingIdentificacion = val,
                  onSuccess: (url, name) {
                    _urlIdentificacion = url;
                    _nombreArchivoIdentificacion = name;
                  },
                ),
              ),

              // 2. Comprobante de Domicilio
              _buildDocumentUploadCard(
                titulo: '2. Comprobante de Domicilio *',
                subtitulo: 'Recibo de luz, agua, teléfono o predial del local (no mayor a 3 meses)',
                icono: Icons.home_work_outlined,
                isUploading: _uploadingComprobante,
                uploadedUrl: _urlComprobante,
                fileName: _nombreArchivoComprobante,
                onUploadPressed: () => _seleccionarYSubirArchivo(
                  tipoDocumento: 'COMPROBANTE_DOMICILIO',
                  setUploading: (val) => _uploadingComprobante = val,
                  onSuccess: (url, name) {
                    _urlComprobante = url;
                    _nombreArchivoComprobante = name;
                  },
                ),
              ),

              // 3. Documento para dar de alta el local
              _buildDocumentUploadCard(
                titulo: '3. Documento para Alta del Local *',
                subtitulo: 'Constancia de Situación Fiscal (RFC), Licencia de Funcionamiento o Acta',
                icono: Icons.fact_check_outlined,
                isUploading: _uploadingDocLocal,
                uploadedUrl: _urlDocLocal,
                fileName: _nombreArchivoDocLocal,
                onUploadPressed: () => _seleccionarYSubirArchivo(
                  tipoDocumento: 'DOCUMENTO_LOCAL',
                  setUploading: (val) => _uploadingDocLocal = val,
                  onSuccess: (url, name) {
                    _urlDocLocal = url;
                    _nombreArchivoDocLocal = name;
                  },
                ),
              ),

              const SizedBox(height: 12),

              _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _documentosCompletos ? _enviarSolicitudYPasarARevision : null,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text(
                        'Enviar Documentación y Solicitar Validación',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
