import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:zelloapp/core/network/api_config.dart';
import 'package:zelloapp/features/sucursales/data/datasources/sucursales_remote_data_source.dart';

class AdminSolicitudDetallePage extends StatefulWidget {
  final SolicitudModel solicitud;

  const AdminSolicitudDetallePage({
    super.key,
    required this.solicitud,
  });

  @override
  State<AdminSolicitudDetallePage> createState() =>
      _AdminSolicitudDetallePageState();
}

class _AdminSolicitudDetallePageState extends State<AdminSolicitudDetallePage> {
  final _dataSource = SucursalesRemoteDataSource();
  late SolicitudModel _solicitud;
  late TextEditingController _comentariosController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _solicitud = widget.solicitud;
    _comentariosController = TextEditingController(
      text: _solicitud.comentariosEvaluacion ?? '',
    );
  }

  @override
  void dispose() {
    _comentariosController.dispose();
    super.dispose();
  }

  String _construirUrlCompleta(String pathOrUrl) {
    final trimmed = pathOrUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final serverRoot = ApiConfig.baseUrl.replaceAll('/api/v1', '');
    if (trimmed.startsWith('/')) {
      return '$serverRoot$trimmed';
    }
    return '$serverRoot/$trimmed';
  }

  String _etiquetaTipoDocumento(int index, String docPath) {
    final lower = docPath.toLowerCase();
    if (lower.contains('logo_sucursal') || lower.contains('logo')) {
      return 'Logotipo Oficial de la Sucursal';
    }
    if (lower.contains('pasaporte')) {
      return '1. Identificación Oficial (Pasaporte)';
    }
    if (lower.contains('ine') || lower.contains('identificacion')) {
      return '1. Identificación Oficial (INE / IFE)';
    }
    if (lower.contains('comprobante')) {
      return '2. Comprobante de Domicilio';
    }
    if (lower.contains('documento_local') || lower.contains('rfc') || lower.contains('acta')) {
      return '3. Documento para Alta del Local';
    }
    switch (index) {
      case 0:
        return '1. Identificación Oficial';
      case 1:
        return '2. Comprobante de Domicilio';
      case 2:
        return '3. Documento para Alta del Local';
      default:
        return 'Documento Probatorio #${index + 1}';
    }
  }

  bool _esImagen(String docPath) {
    final lower = docPath.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg');
  }

  void _mostrarVistaPreviaDocumento(String titulo, String urlCompleta, bool esImg) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user_outlined, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(),
              if (esImg)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: InteractiveViewer(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        urlCompleta,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No se pudo previsualizar la imagen directamente.\nRuta: $urlCompleta',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.picture_as_pdf,
                        size: 54,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Documento PDF Verificado',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        urlCompleta,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: urlCompleta));
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Enlace del documento copiado al portapapeles'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copiar URL del documento'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _evaluarSolicitud(String nuevoEstado) async {
    final comentarios = _comentariosController.text.trim();

    if (nuevoEstado == 'RECHAZADA' && comentarios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor escribe los comentarios o correcciones para que el solicitante sepa qué debe corregir.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final actualizada = await _dataSource.actualizarEstadoSolicitud(
        _solicitud.id,
        nuevoEstado,
        comentariosEvaluacion: comentarios,
      );

      if (!mounted) return;

      setState(() => _solicitud = actualizada);

      final esAprobada = nuevoEstado == 'APROBADA';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            esAprobada
                ? 'Solicitud APROBADA. La sucursal y cuponera del solicitante ya están activas.'
                : 'Solicitud RECHAZADA. Se enviaron las correcciones al solicitante.',
          ),
          backgroundColor: esAprobada ? Colors.green.shade700 : Colors.red.shade700,
        ),
      );

      context.pop(true);
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final docs = _solicitud.listaDocumentos;
    final estadoUpper = _solicitud.estado.toUpperCase();
    final Color estadoColor = estadoUpper.contains('APROBAD')
        ? Colors.green.shade700
        : estadoUpper.contains('RECHAZAD')
            ? Colors.red.shade700
            : Colors.orange.shade800;

    final fechaStr =
        '${_solicitud.fechaSolicitud.day.toString().padLeft(2, '0')}/${_solicitud.fechaSolicitud.month.toString().padLeft(2, '0')}/${_solicitud.fechaSolicitud.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluación de Solicitud'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Encabezado con Estado Actual y Datos de la Sucursal
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: estadoColor.withValues(alpha: 0.12),
                            child: Icon(
                              Icons.storefront_rounded,
                              color: estadoColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _solicitud.nombreNegocio,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Fecha de solicitud: $fechaStr',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: estadoColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: estadoColor),
                            ),
                            child: Text(
                              _solicitud.estado,
                              style: TextStyle(
                                color: estadoColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.category_outlined,
                        'Tipo de Solicitud',
                        _solicitud.esCambioNombre
                            ? 'Cambio de Nombre Comercial de Sucursal'
                            : 'Alta de Nueva Sucursal',
                      ),
                      if (_solicitud.esCambioNombre &&
                          _solicitud.nombreAnterior != null &&
                          _solicitud.nombreAnterior!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          Icons.history,
                          'Nombre Registrado Anterior',
                          _solicitud.nombreAnterior!,
                        ),
                      ],
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        Icons.person_outline,
                        'Solicitante / Dueño',
                        (_solicitud.nombreSolicitante != null &&
                                _solicitud.nombreSolicitante!.isNotEmpty)
                            ? _solicitud.nombreSolicitante!
                            : 'Registrado en cuenta de usuario',
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        Icons.email_outlined,
                        'Correo del Solicitante',
                        (_solicitud.usuarioEmail != null &&
                                _solicitud.usuarioEmail!.isNotEmpty)
                            ? _solicitud.usuarioEmail!
                            : 'ID Usuario: ${_solicitud.usuarioId}',
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        Icons.location_on_outlined,
                        'Dirección del Local',
                        (_solicitud.direccion != null &&
                                _solicitud.direccion!.isNotEmpty)
                            ? _solicitud.direccion!
                            : 'Adjunta en comprobante domiciliario',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 2. Documentación Probatoria Subida para Revisión Manual
              const Text(
                'Documentación Probatoria Adjunta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Revisa cada uno de los documentos subidos por el solicitante para verificar su identidad y acreditar el local.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),

              if (docs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Esta solicitud no tiene documentos separados registrados.',
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...List.generate(docs.length, (index) {
                  final rawUrl = docs[index];
                  final fullUrl = _construirUrlCompleta(rawUrl);
                  final tituloDoc = _etiquetaTipoDocumento(index, rawUrl);
                  final esImg = _esImagen(rawUrl);
                  final fileName = rawUrl.split('/').last;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.blueGrey.shade100),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: esImg
                                    ? Colors.blue.shade50
                                    : Colors.red.shade50,
                                child: Icon(
                                  esImg ? Icons.image_outlined : Icons.picture_as_pdf,
                                  color: esImg ? Colors.blue.shade700 : Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tituloDoc,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Archivo: $fileName',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _mostrarVistaPreviaDocumento(
                                  tituloDoc,
                                  fullUrl,
                                  esImg,
                                ),
                                icon: const Icon(Icons.visibility_outlined, size: 18),
                                label: const Text('Inspeccionar'),
                              ),
                            ],
                          ),
                          if (esImg) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                height: 150,
                                width: double.infinity,
                                color: Colors.grey.shade100,
                                child: Image.network(
                                  fullUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Center(
                                    child: Text(
                                      'Vista previa disponible al inspeccionar ($fileName)',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 16),

              // 3. Apartado de Comentarios / Correcciones para el Solicitante
              const Text(
                'Comentarios o Correcciones para el Solicitante',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Si algún documento es ilegible, está vencido o requiere corrección, escribe aquí las indicaciones. El solicitante verá este mensaje en su pantalla de estado de validación.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _comentariosController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'Ej. El comprobante de domicilio no es legible o supera los 3 meses de vigencia. Por favor vuelve a subirlo...',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 56),
                    child: Icon(Icons.rate_review_outlined),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 4. Botones de Acción (Aprobar / Rechazar con correcciones)
              if (_isSubmitting)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _evaluarSolicitud('RECHAZADA'),
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text(
                              'Rechazar / Solicitar Corrección',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _evaluarSolicitud('APROBADA'),
                            icon: const Icon(Icons.check_circle_outline),
                            label: Text(
                              _solicitud.esCambioNombre
                                  ? 'Aprobar Cambio de Nombre'
                                  : 'Aprobar Alta de Sucursal',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (estadoUpper != 'PENDIENTE') ...[
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: () => _evaluarSolicitud('PENDIENTE'),
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Regresar estado a PENDIENTE de revisión'),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey.shade700),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
