import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zelloapp/core/network/sesion_usuario.dart';
import 'package:zelloapp/features/configuracion/services/sucursal_service.dart';

class ConfiguracionPage extends StatefulWidget {
  const ConfiguracionPage({super.key});

  @override
  State<ConfiguracionPage> createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends State<ConfiguracionPage> {
  final SucursalService _sucursalService = SucursalService();
  bool _cargando = true;
  bool _esSucursal = false;
  String? _cuponeraIdReal;
  bool _tieneSolicitud = false;
  String? _estadoSolicitud;
  String? _comentariosEvaluacion;

  @override
  void initState() {
    super.initState();
    _verificarEstadoEnBaseDeDatos();
  }

  // Consultamos la BD en tiempo real al abrir la pantalla
  Future<void> _verificarEstadoEnBaseDeDatos() async {
    String? usuarioId = SesionUsuario().usuarioId;
    if (usuarioId == null || usuarioId.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      usuarioId = prefs.getString('usuario_id');
      if (usuarioId != null && usuarioId.isNotEmpty) {
        SesionUsuario().usuarioId = usuarioId;
      }
    }

    if (usuarioId == null || usuarioId.isEmpty) {
      if (mounted) setState(() => _cargando = false);
      return;
    }

    try {
      final estado = await _sucursalService.consultarEstadoSucursal(usuarioId);
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final bool esSucursal = estado['es_sucursal'] ?? false;
      final String? estadoSol = estado['estado_solicitud']?.toString().toLowerCase();

      if (esSucursal) {
        await prefs.setBool('is_establecimiento', true);
        await prefs.setString('status_local', 'aprobado');
      } else if (estadoSol != null && estadoSol.isNotEmpty) {
        await prefs.setString('status_local', estadoSol);
      }

      setState(() {
        _esSucursal = esSucursal;
        _cuponeraIdReal = estado['cuponera_id'];
        _tieneSolicitud = estado['tiene_solicitud'] ?? false;
        _estadoSolicitud = estadoSol;
        _comentariosEvaluacion = estado['comentarios_evaluacion']?.toString();
        if (estado['rol'] != null) {
          SesionUsuario().rol = estado['rol']; // Sincronizamos rol real
        }
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text(
                  'Mi Cuenta',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Perfil de Usuario'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/perfil'),
                ),

                const Divider(height: 32),

                const Text(
                  'Zona para Comercios',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // LÓGICA DINÁMICA SEGÚN EL ESTADO DE LA SUCURSAL EN LA BD
                if (!_esSucursal) ...[
                  ListTile(
                    leading: const Icon(Icons.storefront, color: Colors.blue),
                    title: const Text('Registrar mi Local'),
                    subtitle: const Text('Crea tu cuponera y atrae clientes'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      // 1. Abre la pantalla de datos del local + propietario -> 2. Subida de 3 documentos -> 3. Pantalla de espera de validación
                      await context.push('/registro-negocio');
                      _verificarEstadoEnBaseDeDatos();
                    },
                  ),
                  if (_tieneSolicitud)
                    ListTile(
                      leading: Icon(
                        _estadoSolicitud == 'rechazada'
                            ? Icons.cancel_outlined
                            : Icons.hourglass_top_rounded,
                        color: _estadoSolicitud == 'rechazada' ? Colors.red : Colors.orange,
                      ),
                      title: Text(
                        'Estado de Validación: ${(_estadoSolicitud ?? "pendiente").toUpperCase()}',
                      ),
                      subtitle: Text(
                        (_comentariosEvaluacion != null && _comentariosEvaluacion!.trim().isNotEmpty)
                            ? 'Observaciones del administrador: $_comentariosEvaluacion'
                            : 'Ver pantalla de estado de validación y observaciones',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await context.push('/revision_local');
                        _verificarEstadoEnBaseDeDatos();
                      },
                    ),
                ] else ...[
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings, color: Colors.green),
                    title: const Text('Administrar mi Local'),
                    subtitle: const Text('Edita tu cuponera y escanea QR'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Pasamos el ID real de la cuponera al editor mediante state.extra
                      context.push('/editor_cuponera', extra: _cuponeraIdReal);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.store_mall_directory_outlined, color: Colors.indigo),
                    title: const Text('Administración de Sucursales'),
                    subtitle: const Text('Configuración especial de sucursales y nuevas altas'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await context.push('/sucursales/administracion');
                      _verificarEstadoEnBaseDeDatos();
                    },
                  ),
                  if (_tieneSolicitud && _estadoSolicitud != 'aprobada' && _estadoSolicitud != 'aprobado')
                    ListTile(
                      leading: Icon(
                        _estadoSolicitud == 'rechazada'
                            ? Icons.cancel_outlined
                            : Icons.hourglass_top_rounded,
                        color: _estadoSolicitud == 'rechazada' ? Colors.red : Colors.orange,
                      ),
                      title: Text(
                        'Solicitud en Revisión: ${(_estadoSolicitud ?? "pendiente").toUpperCase()}',
                      ),
                      subtitle: Text(
                        (_comentariosEvaluacion != null && _comentariosEvaluacion!.trim().isNotEmpty)
                            ? 'Observaciones del administrador: $_comentariosEvaluacion'
                            : 'Ver estado de tu nueva sucursal o cambio de nombre',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await context.push('/revision_local');
                        _verificarEstadoEnBaseDeDatos();
                      },
                    ),
                ],

                const SizedBox(height: 16),

                // Botón del escáner (Solo visible si ya cuenta con sucursal aprobada)
                if (_esSucursal)
                  OutlinedButton.icon(
                    onPressed: () {
                      final miUsuarioId = SesionUsuario().usuarioId;

                      if (_cuponeraIdReal != null && miUsuarioId != null) {
                        context.push(
                          '/escaner',
                          extra: {
                            'cuponeraId': _cuponeraIdReal,
                            'emisorId': miUsuarioId,
                          },
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No se pudieron obtener los datos de la cuponera.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Escanear QR de Cliente'),
                  ),

                const Divider(height: 32),

                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
                    SesionUsuario().usuarioId = null;
                    SesionUsuario().rol = null;
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            ),
    );
  }
}
