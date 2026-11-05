import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zelloapp/core/network/api_config.dart';

class ApprovalStatusPage extends StatefulWidget {
  const ApprovalStatusPage({super.key});

  @override
  State<ApprovalStatusPage> createState() => _ApprovalStatusPageState();
}

class _ApprovalStatusPageState extends State<ApprovalStatusPage> {
  bool _isLoading = false;
  String _estadoSolicitud = 'pendiente';
  String? _comentariosEvaluacion;
  String? _nombreLocal;
  String? _tipoSolicitud;

  @override
  void initState() {
    super.initState();
    _verificarEstado();
  }

  Future<void> _verificarEstado() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final usuarioId = prefs.getString('usuario_id');

      if (usuarioId == null) return;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/establecimientos/usuario/$usuarioId/estado-sucursal'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bool tieneSucursal = data['tiene_sucursal'] ?? false;
        final bool tieneSolicitud = data['tiene_solicitud'] ?? false;
        final String estadoSol =
            (data['estado_solicitud'] ?? (tieneSucursal ? 'aprobada' : 'pendiente'))
                .toString()
                .toLowerCase();
        final String? comentarios = data['comentarios_evaluacion']?.toString();
        final String? nombreSol = data['nombre_negocio_solicitud']?.toString();
        final String? tipoSol = data['tipo_solicitud']?.toString();
        final establecimiento = data['establecimiento'];

        if (mounted) {
          setState(() {
            _estadoSolicitud = estadoSol;
            _comentariosEvaluacion = comentarios;
            _tipoSolicitud = tipoSol;
            if (nombreSol != null && nombreSol.isNotEmpty) {
              _nombreLocal = nombreSol;
            } else if (establecimiento != null && establecimiento['nombre'] != null) {
              _nombreLocal = establecimiento['nombre'].toString();
            }
          });
        }

        await prefs.setString('status_local', estadoSol);

        // Solo se considera aprobada la última solicitud si NO está en estado 'pendiente' ni 'rechazada'
        final bool solicitudYaAprobada = tieneSolicitud
            ? (estadoSol == 'aprobada' || estadoSol == 'aprobado')
            : tieneSucursal;

        if (solicitudYaAprobada && tieneSucursal) {
          await prefs.setString('status_local', 'aprobado');
          await prefs.setBool('is_establecimiento', true);

          if (data['cuponera_id'] != null) {
            await prefs.setString('mi_cuponera_id', data['cuponera_id']);
          }

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _tipoSolicitud == 'CAMBIO_NOMBRE'
                    ? '¡El cambio de nombre de tu sucursal ha sido aprobado!'
                    : '¡Felicidades! Tu establecimiento ha sido aprobado.',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          context.pushReplacement('/editor_cuponera');
        }
      }
    } catch (e) {
      debugPrint('Error verificando estado: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool esRechazada = _estadoSolicitud.contains('rechazad');
    final bool esCambioNombre = (_tipoSolicitud ?? '').toUpperCase() == 'CAMBIO_NOMBRE';
    final bool tieneComentarios =
        _comentariosEvaluacion != null && _comentariosEvaluacion!.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          esCambioNombre ? 'Revisión de Cambio de Nombre' : 'Estado de Solicitud',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Comprobar estado',
            onPressed: _verificarEstado,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _verificarEstado,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.08),
            Icon(
              esRechazada ? Icons.error_outline_rounded : Icons.hourglass_empty_rounded,
              size: 84,
              color: esRechazada ? Colors.red.shade600 : Colors.orange,
            ),
            const SizedBox(height: 20),
            Text(
              esRechazada
                  ? 'Solicitud con Observaciones (Rechazada)'
                  : (esCambioNombre
                      ? 'Cambio de Nombre en Revisión'
                      : 'Revisión en proceso'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: esRechazada ? Colors.red.shade800 : Colors.black87,
              ),
            ),
            if (_nombreLocal != null && _nombreLocal!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                esCambioNombre
                    ? 'Nuevo nombre solicitado: $_nombreLocal'
                    : _nombreLocal!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              esRechazada
                  ? 'El administrador evaluó tu solicitud y señaló correcciones necesarias.'
                  : (esCambioNombre
                      ? 'El cambio de nombre registrado de tu sucursal está en espera de aprobación por parte del administrador. Tu sucursal sigue operando mientras se valida.'
                      : 'Tu nueva sucursal y su documentación están siendo evaluadas manualmente por el administrador. Desliza hacia abajo o presiona actualizar para comprobar si ya fue aprobada.'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),

            if (tieneComentarios) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: esRechazada ? Colors.red.shade50 : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: esRechazada ? Colors.red.shade300 : Colors.amber.shade400,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.comment_bank_outlined,
                          color: esRechazada ? Colors.red.shade800 : Colors.amber.shade900,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Comentarios / Correcciones del Administrador:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: esRechazada ? Colors.red.shade900 : Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _comentariosEvaluacion!,
                      style: TextStyle(
                        fontSize: 14,
                        color: esRechazada ? Colors.red.shade900 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              if (esRechazada && !esCambioNombre)
                ElevatedButton.icon(
                  onPressed: () => context.pushReplacement('/registro-negocio'),
                  icon: const Icon(Icons.upload_file),
                  label: const Text(
                    'Corregir Datos y Volver a Subir Documentos',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              if (esRechazada && esCambioNombre)
                ElevatedButton.icon(
                  onPressed: () => context.pushReplacement('/sucursales/administracion'),
                  icon: const Icon(Icons.store_mall_directory_outlined),
                  label: const Text(
                    'Volver a Administración de Sucursales',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _verificarEstado,
                icon: const Icon(Icons.refresh),
                label: const Text('Comprobar Estado Ahora'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
