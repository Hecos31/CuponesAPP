import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/auth/auth_session.dart';
import '../../../sucursales/data/datasources/sucursales_remote_data_source.dart';

class RegistroNegocioPage extends StatefulWidget {
  const RegistroNegocioPage({super.key});

  @override
  State<RegistroNegocioPage> createState() => _RegistroNegocioPageState();
}

class _RegistroNegocioPageState extends State<RegistroNegocioPage> {
  final _formKeyPaso2 = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  late final TextEditingController _usuarioIdController;

  final _dataSource = SucursalesRemoteDataSource();

  int _currentStep = 0;

  // 1. Identificación Oficial (INE o Pasaporte)
  String _tipoIdentificacion = 'INE'; // 'INE' o 'PASAPORTE'
  bool _uploadingIdentificacion = false;
  String? _urlIdentificacion;
  String? _nombreArchivoIdentificacion;

  // 2. Comprobante de Domicilio
  bool _uploadingComprobante = false;
  String? _urlComprobante;
  String? _nombreArchivoComprobante;

  // 3. Documento del Local (Licencia / RFC / Acta / Permiso)
  bool _uploadingDocLocal = false;
  String? _urlDocLocal;
  String? _nombreArchivoDocLocal;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _usuarioIdController = TextEditingController(text: AuthSession.instance.userId);
    _cargarUsuarioDePrefs();
  }

  Future<void> _cargarUsuarioDePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('user_id');
    if (savedId != null && savedId.isNotEmpty && mounted) {
      setState(() {
        _usuarioIdController.text = savedId;
      });
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _usuarioIdController.dispose();
    super.dispose();
  }

  bool get _paso1Completo =>
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
            content: Text('Documento "$tipoDocumento" (${file.name}) cargado de forma segura.'),
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

  Future<void> _enviarSolicitud() async {
    if (!_paso1Completo) {
      setState(() {
        _currentStep = 0;
        _errorMessage =
            'Debes subir los 3 documentos obligatorios (Identificación Oficial, Comprobante de Domicilio y Documento del Local) en el Paso 1.';
      });
      return;
    }

    if (!_formKeyPaso2.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Concatenamos las rutas seguras de los 3 documentos probatorios
      final docsConcatenados = [
        _urlIdentificacion!,
        _urlComprobante!,
        _urlDocLocal!,
      ].join(' | ');

      await _dataSource.crearSolicitud(
        usuarioId: _usuarioIdController.text.trim(),
        nombreNegocio: _nombreController.text.trim(),
        documentosUrl: docsConcatenados,
      );

      // Guardamos el estado en SharedPreferences para conectar con el flujo de Ale (ApprovalStatusPage)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('status_local', 'pendiente');
      await prefs.setBool('is_establecimiento', true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud y documentación enviadas a revisión.'),
            backgroundColor: Colors.green,
          ),
        );
        // Redirigimos a la vista "Estado de Aprobación" de Ale
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
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
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
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      cargado ? 'Archivo listo: $fileName' : subtitulo,
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
            const SizedBox(height: 10),
            headerExtra,
          ],
          const SizedBox(height: 10),
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
                    label: Text(cargado ? 'Reemplazar archivo' : 'Subir archivo (PDF/JPG/PNG)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cargado ? Colors.green.shade700 : Colors.blueGrey.shade800,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar Verificación y Alta de Local'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/novedades');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado informativo
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 38,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Conviértete en Propietario de Sucursal',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Paso 1: Verifica tu identidad y sube tu documentación oficial.\nPaso 2: Ingresa los datos de tu sucursal para enviar tu solicitud a revisión.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

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
                const SizedBox(height: 12),
              ],

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Stepper(
                  physics: const NeverScrollableScrollPhysics(),
                  currentStep: _currentStep,
                  onStepTapped: (step) {
                    if (step == 1 && !_paso1Completo) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Primero sube tu Identificación Oficial, Comprobante de Domicilio y Documento del Local en el Paso 1.',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    setState(() => _currentStep = step);
                  },
                  controlsBuilder: (context, details) {
                    if (details.stepIndex == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: ElevatedButton.icon(
                          onPressed: _paso1Completo ? () => setState(() => _currentStep = 1) : null,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Continuar a Datos de la Sucursal'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Row(
                          children: [
                            TextButton.icon(
                              onPressed: () => setState(() => _currentStep = 0),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Volver a Documentos'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _isSubmitting
                                  ? const Center(child: CircularProgressIndicator())
                                  : ElevatedButton.icon(
                                      onPressed: _enviarSolicitud,
                                      icon: const Icon(Icons.send_rounded),
                                      label: const Text('Enviar Solicitud a Revisión'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        backgroundColor: Colors.green.shade700,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  steps: [
                    // =========================================================
                    // PASO 1: VERIFICACIÓN DE IDENTIDAD Y DOCUMENTOS PROBATORIOS
                    // =========================================================
                    Step(
                      title: const Text(
                        'Paso 1: Verificación de Identidad y Documentación',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        _paso1Completo
                            ? '3 de 3 documentos probatorios cargados correctamente'
                            : 'Sube tu Identificación Oficial, Comprobante de Domicilio y Documento del Local',
                      ),
                      isActive: _currentStep >= 0,
                      state: _paso1Completo ? StepState.complete : StepState.indexed,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                            titulo: '2. Comprobante de Domicilio del Local *',
                            subtitulo: 'Recibo de luz, agua, teléfono o predial (no mayor a 3 meses)',
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
                            titulo: '3. Documento Acreditativo del Local *',
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
                        ],
                      ),
                    ),

                    // =========================================================
                    // PASO 2: DATOS PARA DAR DE ALTA LA SUCURSAL
                    // =========================================================
                    Step(
                      title: const Text(
                        'Paso 2: Datos para dar de alta la Sucursal',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Información comercial del establecimiento'),
                      isActive: _currentStep >= 1,
                      state: StepState.indexed,
                      content: Form(
                        key: _formKeyPaso2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.verified, color: Colors.green.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Documentación verificada ($_tipoIdentificacion, Comprobante de Domicilio y Documento del Local listos)',
                                      style: TextStyle(fontSize: 12, color: Colors.green.shade900),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nombreController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre Comercial del Negocio o Sucursal *',
                                hintText: 'Ej. Cafetería Central',
                                prefixIcon: Icon(Icons.storefront),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => (value == null || value.trim().isEmpty)
                                  ? 'Ingresa el nombre comercial del negocio'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _direccionController,
                              decoration: const InputDecoration(
                                labelText: 'Dirección o Ubicación de la Sucursal *',
                                hintText: 'Calle, Número, Colonia y Ciudad',
                                prefixIcon: Icon(Icons.location_on_outlined),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => (value == null || value.trim().isEmpty)
                                  ? 'Ingresa la dirección de la sucursal'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _usuarioIdController,
                              decoration: const InputDecoration(
                                labelText: 'ID de Usuario Solicitante',
                                prefixIcon: Icon(Icons.person_outline),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => (value == null || value.trim().isEmpty)
                                  ? 'Ingresa el ID de usuario'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
