import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zelloapp/core/network/sesion_usuario.dart';
import 'package:zelloapp/core/theme/app_theme.dart';
import 'package:zelloapp/core/widgets/zello_logo.dart';
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
          SesionUsuario().rol = estado['rol'];
        }
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDeep.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppTheme.darkInk,
          ),
        ),
        subtitle: subtitle != null
            ? Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.mutedSlate,
                  ),
                ),
              )
            : null,
        trailing: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AppTheme.primaryColor,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: ZelloAmbientBackground(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: ZelloHeaderBanner(
                      eyebrow: _esSucursal ? 'ZELLO COMERCIO' : 'ZELLO',
                      title: 'Configuración',
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            'MI CUENTA',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: AppTheme.mutedSlate,
                            ),
                          ),
                        ),
                        _buildOptionTile(
                          icon: Icons.person_outline_rounded,
                          iconColor: AppTheme.primaryColor,
                          iconBg: AppTheme.primarySoft,
                          title: 'Perfil de Usuario',
                          subtitle: 'Consulta y actualiza tus datos personales',
                          onTap: () => context.push('/perfil'),
                        ),

                        const SizedBox(height: 18),
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            'ZONA PARA COMERCIOS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: AppTheme.mutedSlate,
                            ),
                          ),
                        ),

                        if (!_esSucursal) ...[
                          _buildOptionTile(
                            icon: Icons.storefront_rounded,
                            iconColor: AppTheme.accentColor,
                            iconBg: AppTheme.accentSoft,
                            title: 'Registrar mi Local',
                            subtitle: 'Crea tu cuponera digital y fideliza clientes',
                            onTap: () async {
                              await context.push('/registro-negocio');
                              _verificarEstadoEnBaseDeDatos();
                            },
                          ),
                          if (_tieneSolicitud)
                            _buildOptionTile(
                              icon: _estadoSolicitud == 'rechazada'
                                  ? Icons.cancel_outlined
                                  : Icons.hourglass_top_rounded,
                              iconColor: _estadoSolicitud == 'rechazada'
                                  ? AppTheme.dangerColor
                                  : AppTheme.accentColor,
                              iconBg: _estadoSolicitud == 'rechazada'
                                  ? AppTheme.dangerColor.withValues(alpha: 0.12)
                                  : AppTheme.accentSoft,
                              title:
                                  'Estado de Validación: ${(_estadoSolicitud ?? "pendiente").toUpperCase()}',
                              subtitle: (_comentariosEvaluacion != null &&
                                      _comentariosEvaluacion!.trim().isNotEmpty)
                                  ? 'Observaciones del administrador: $_comentariosEvaluacion'
                                  : 'Ver pantalla de estado de validación y observaciones',
                              onTap: () async {
                                await context.push('/revision_local');
                                _verificarEstadoEnBaseDeDatos();
                              },
                            ),
                        ] else ...[
                          _buildOptionTile(
                            icon: Icons.auto_awesome_mosaic_rounded,
                            iconColor: AppTheme.successColor,
                            iconBg: AppTheme.successColor.withValues(alpha: 0.12),
                            title: 'Administrar mi Local',
                            subtitle: 'Personaliza el diseño de tu cuponera en el editor visual',
                            onTap: () {
                              context.push('/editor_cuponera', extra: _cuponeraIdReal);
                            },
                          ),
                          _buildOptionTile(
                            icon: Icons.store_mall_directory_rounded,
                            iconColor: AppTheme.primaryColor,
                            iconBg: AppTheme.primarySoft,
                            title: 'Administración de Sucursales',
                            subtitle: 'Sube tu logo, solicita cambio de nombre o da de alta otra sucursal',
                            onTap: () async {
                              await context.push('/sucursales/administracion');
                              _verificarEstadoEnBaseDeDatos();
                            },
                          ),
                          if (_tieneSolicitud &&
                              _estadoSolicitud != 'aprobada' &&
                              _estadoSolicitud != 'aprobado')
                            _buildOptionTile(
                              icon: _estadoSolicitud == 'rechazada'
                                  ? Icons.cancel_outlined
                                  : Icons.hourglass_top_rounded,
                              iconColor: _estadoSolicitud == 'rechazada'
                                  ? AppTheme.dangerColor
                                  : AppTheme.accentColor,
                              iconBg: _estadoSolicitud == 'rechazada'
                                  ? AppTheme.dangerColor.withValues(alpha: 0.12)
                                  : AppTheme.accentSoft,
                              title:
                                  'Solicitud en Revisión: ${(_estadoSolicitud ?? "pendiente").toUpperCase()}',
                              subtitle: (_comentariosEvaluacion != null &&
                                      _comentariosEvaluacion!.trim().isNotEmpty)
                                  ? 'Observaciones del administrador: $_comentariosEvaluacion'
                                  : 'Ver estado de tu nueva sucursal o cambio de nombre',
                              onTap: () async {
                                await context.push('/revision_local');
                                _verificarEstadoEnBaseDeDatos();
                              },
                            ),
                        ],

                        if (_esSucursal) ...[
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              gradient: AppTheme.brandGradient,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.28),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
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
                                      content: Text(
                                        'No se pudieron obtener los datos de la cuponera.',
                                      ),
                                      backgroundColor: AppTheme.dangerColor,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              icon: const Icon(
                                Icons.qr_code_scanner_rounded,
                                color: AppTheme.accentBright,
                              ),
                              label: const Text(
                                'Escanear QR de Cliente',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                        _buildOptionTile(
                          icon: Icons.logout_rounded,
                          iconColor: AppTheme.dangerColor,
                          iconBg: AppTheme.dangerColor.withValues(alpha: 0.12),
                          title: 'Cerrar Sesión',
                          subtitle: 'Salir de tu cuenta en este dispositivo',
                          onTap: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.clear();
                            SesionUsuario().usuarioId = null;
                            SesionUsuario().rol = null;
                            if (context.mounted) context.go('/login');
                          },
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
