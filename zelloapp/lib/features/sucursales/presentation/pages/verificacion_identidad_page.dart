import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_session.dart';
import '../../data/datasources/sucursales_remote_data_source.dart';

class VerificacionIdentidadPage extends StatefulWidget {
  const VerificacionIdentidadPage({super.key});

  @override
  State<VerificacionIdentidadPage> createState() => _VerificacionIdentidadPageState();
}

class _VerificacionIdentidadPageState extends State<VerificacionIdentidadPage> {
  final _formKeyPaso2 = GlobalKey<FormState>();
  final _nombreNegocioController = TextEditingController();
  late final TextEditingController _usuarioIdController;

  final _dataSource = SucursalesRemoteDataSource();

  int _currentStep = 0;
  String _tipoDocumentoSeleccionado = 'INE'; // 'INE' o 'PASAPORTE'

  bool _isUploadingFile = false;
  bool _isSubmitting = false;

  String? _uploadedDocumentUrl;
  String? _selectedFileName;
  String? _uploadError;
  String? _submitMessage;
  bool _submitSuccess = false;

  @override
  void initState() {
    super.initState();
    _usuarioIdController = TextEditingController(text: AuthSession.instance.userId);
  }

  @override
  void dispose() {
    _nombreNegocioController.dispose();
    _usuarioIdController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // PASO 1: Subir documento de identidad (INE o Pasaporte)
  // ---------------------------------------------------------------------------
  Future<void> _subirDocumentoIdentidad() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );

      if (files.isEmpty) return;

      final file = files.first;
      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        setState(() {
          _uploadError = 'El archivo seleccionado está vacío.';
        });
        return;
      }

      setState(() {
        _isUploadingFile = true;
        _selectedFileName = file.name;
        _uploadError = null;
      });

      final url = await _dataSource.uploadDocumento(
        bytes,
        file.name,
        tipoDocumento: _tipoDocumentoSeleccionado,
      );

      setState(() {
        _uploadedDocumentUrl = url;
        _uploadError = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$_tipoDocumentoSeleccionado cargado de forma segura. Continúa al Paso 2 para los datos de tu sucursal.',
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _uploadError = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isUploadingFile = false);
    }
  }

  // ---------------------------------------------------------------------------
  // PASO 2: Enviar solicitud con los datos de la sucursal
  // ---------------------------------------------------------------------------
  Future<void> _enviarSolicitudAlta() async {
    if (_uploadedDocumentUrl == null || _uploadedDocumentUrl!.isEmpty) {
      setState(() {
        _currentStep = 0;
        _uploadError = 'Primero debes subir tu INE o Pasaporte en el Paso 1.';
      });
      return;
    }

    if (!_formKeyPaso2.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _submitMessage = null;
    });

    try {
      final solicitud = await _dataSource.crearSolicitud(
        usuarioId: _usuarioIdController.text.trim(),
        nombreNegocio: _nombreNegocioController.text.trim(),
        documentosUrl: _uploadedDocumentUrl,
      );

      setState(() {
        _submitSuccess = true;
        _submitMessage =
            'Solicitud enviada correctamente para "${solicitud.nombreNegocio}" con documento $_tipoDocumentoSeleccionado adjunto.';
        _nombreNegocioController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud de verificación y alta registrada con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _submitSuccess = false;
        _submitMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool identidadLista = _uploadedDocumentUrl != null && _uploadedDocumentUrl!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación de Identidad'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner explicativo del flujo
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
                      color: Theme.of(context).colorScheme.primary,
                      size: 36,
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verificación de Identidad para Alta de Sucursal',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Paso 1: Verifica tu identidad subiendo tu INE o Pasaporte.\nPaso 2: Captura los datos para dar de alta tu sucursal.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stepper de 2 pasos: 1. Verificación de Identidad -> 2. Datos de la Sucursal
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Stepper(
                physics: const NeverScrollableScrollPhysics(),
                currentStep: _currentStep,
                onStepTapped: (step) {
                  if (step == 1 && !identidadLista) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Primero sube tu INE o Pasaporte en el Paso 1.'),
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
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: identidadLista
                                  ? () => setState(() => _currentStep = 1)
                                  : null,
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('Continuar a Datos de Sucursal'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
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
                            label: const Text('Volver a Identidad'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _isSubmitting
                                ? const Center(child: CircularProgressIndicator())
                                : ElevatedButton.icon(
                                    onPressed: _enviarSolicitudAlta,
                                    icon: const Icon(Icons.send_rounded),
                                    label: const Text('Registrar Solicitud de Alta'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
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
                  // ===========================================================
                  // PASO 1: VERIFICACIÓN DE IDENTIDAD (INE O PASAPORTE)
                  // ===========================================================
                  Step(
                    title: const Text(
                      'Paso 1: Verificación de Identidad',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      identidadLista
                          ? 'Documento ($_tipoDocumentoSeleccionado) cargado correctamente'
                          : 'Selecciona INE o Pasaporte y sube tu archivo oficial',
                    ),
                    isActive: _currentStep >= 0,
                    state: identidadLista ? StepState.complete : StepState.indexed,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Selecciona tu documento oficial de identidad:',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.badge_outlined, size: 18),
                                    SizedBox(width: 6),
                                    Text('INE / IFE'),
                                  ],
                                ),
                                selected: _tipoDocumentoSeleccionado == 'INE',
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _tipoDocumentoSeleccionado = 'INE');
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ChoiceChip(
                                label: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.menu_book_outlined, size: 18),
                                    SizedBox(width: 6),
                                    Text('Pasaporte'),
                                  ],
                                ),
                                selected: _tipoDocumentoSeleccionado == 'PASAPORTE',
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _tipoDocumentoSeleccionado = 'PASAPORTE');
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: identidadLista ? Colors.green : Colors.grey.shade400,
                              width: identidadLista ? 1.5 : 1.0,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: identidadLista ? Colors.green.shade50 : Colors.grey.shade50,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                identidadLista ? Icons.check_circle : Icons.cloud_upload_outlined,
                                size: 46,
                                color: identidadLista ? Colors.green.shade700 : Colors.blueGrey,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                identidadLista
                                    ? '$_tipoDocumentoSeleccionado listo: $_selectedFileName'
                                    : 'Subir $_tipoDocumentoSeleccionado (PDF, JPG o PNG máx. 10MB)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: identidadLista ? Colors.green.shade900 : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _isUploadingFile
                                  ? const CircularProgressIndicator()
                                  : ElevatedButton.icon(
                                      onPressed: _subirDocumentoIdentidad,
                                      icon: const Icon(Icons.upload_file),
                                      label: Text(
                                        identidadLista
                                            ? 'Cambiar archivo de $_tipoDocumentoSeleccionado'
                                            : 'Seleccionar $_tipoDocumentoSeleccionado del dispositivo',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueGrey.shade800,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                            ],
                          ),
                        ),

                        if (_uploadError != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _uploadError!,
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ===========================================================
                  // PASO 2: DATOS PARA DAR DE ALTA LA SUCURSAL
                  // ===========================================================
                  Step(
                    title: const Text(
                      'Paso 2: Datos para dar de alta la Sucursal',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Ingresa la información de la sucursal a registrar'),
                    isActive: _currentStep >= 1,
                    state: _submitSuccess ? StepState.complete : StepState.indexed,
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
                                    'Identidad verificada con $_tipoDocumentoSeleccionado (${_selectedFileName ?? "documento adjunto"})',
                                    style: TextStyle(fontSize: 12, color: Colors.green.shade900),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nombreNegocioController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre de la Sucursal o Establecimiento *',
                              hintText: 'Ej. Cafetería Central Sucursal Norte',
                              prefixIcon: Icon(Icons.storefront),
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) => (val == null || val.trim().isEmpty)
                                ? 'Ingresa el nombre de la sucursal'
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
                            validator: (val) => (val == null || val.trim().isEmpty)
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

            if (_submitMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _submitSuccess ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _submitSuccess ? Colors.green : Colors.red),
                ),
                child: Row(
                  children: [
                    Icon(
                      _submitSuccess ? Icons.check_circle : Icons.error_outline,
                      color: _submitSuccess ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _submitMessage!,
                        style: TextStyle(
                          color: _submitSuccess ? Colors.green.shade900 : Colors.red.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
