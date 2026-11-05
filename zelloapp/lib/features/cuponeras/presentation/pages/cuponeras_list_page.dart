import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zelloapp/core/network/api_config.dart';
import 'package:zelloapp/core/theme/app_theme.dart';
import 'package:zelloapp/core/widgets/zello_logo.dart';

import '../../models/cuponera_lista_model.dart';
import '../../services/cuponeras_service.dart';

class CuponerasListPage extends StatefulWidget {
  const CuponerasListPage({super.key});

  @override
  State<CuponerasListPage> createState() => _CuponerasListPageState();
}

class _CuponerasListPageState extends State<CuponerasListPage> {
  final CuponerasService _cuponerasService = CuponerasService();
  late Future<List<CuponeraListaModel>> _futureCuponeras;

  @override
  void initState() {
    super.initState();
    _cargarCuponeras();
  }

  void _cargarCuponeras() {
    setState(() {
      _futureCuponeras = _cuponerasService.obtenerCuponerasDisponibles();
    });
  }

  Future<void> _unirseCuponera(String cuponeraId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getString('usuario_id');
      final token = prefs.getString('token');

      if (usuarioId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, inicia sesión para unirte.'),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Suscribiendo a la cuponera...'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/cuponeras/$cuponeraId/unirse?usuario_id=$usuarioId',
      );
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['mensaje'] ?? '¡Te has suscrito exitosamente!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _cargarCuponeras();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['detail'] ?? 'Error al suscribirse'),
            backgroundColor: AppTheme.dangerColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión: $e'),
          backgroundColor: AppTheme.dangerColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: ZelloAmbientBackground(
        child: CustomScrollView(
          slivers: [
            // Encabezado moderno Zello con gradiente y logo SVG oficial
            SliverToBoxAdapter(
              child: ZelloHeaderBanner(
                eyebrow: 'ZELLO',
                title: 'Descubre Cuponeras',
                trailing: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    tooltip: 'Actualizar',
                    onPressed: _cargarCuponeras,
                  ),
                ),
                bottomChild: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: AppTheme.accentBright,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Únete a tus comercios favoritos, acumula sellos digitales y desbloquea beneficios exclusivos.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Contenido dinámico de cuponeras
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
              sliver: FutureBuilder<List<CuponeraListaModel>>(
                future: _futureCuponeras,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_off_rounded,
                                size: 56,
                                color: AppTheme.mutedSlate.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No se pudieron cargar las cuponeras.\nVerifica tu conexión.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppTheme.mutedSlate),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: _cargarCuponeras,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final cuponeras = snapshot.data ?? [];

                  if (cuponeras.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'No hay cuponeras disponibles por el momento.',
                          style: TextStyle(
                            color: AppTheme.mutedSlate,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final cuponera = cuponeras[index];
                        return _CuponeraCardReal(
                          cuponera: cuponera,
                          onTapCard: () {
                            final Map<String, dynamic> cuponeraMap = {
                              'id': cuponera.id,
                              'establecimiento_nombre': cuponera.establecimientoNombre,
                              'titulo_cuponera': cuponera.titulo,
                              'descripcion_premio': cuponera.descripcionPremio,
                              'total_sellos_requeridos': cuponera.totalSellosRequeridos,
                              'configuracion_ui': cuponera.diseno,
                            };
                            context.push('/cuponeras/detalle', extra: cuponeraMap);
                          },
                          onTapUnirse: () => _unirseCuponera(cuponera.id),
                        );
                      },
                      childCount: cuponeras.length,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CuponeraCardReal extends StatelessWidget {
  const _CuponeraCardReal({
    required this.cuponera,
    required this.onTapCard,
    required this.onTapUnirse,
  });

  final CuponeraListaModel cuponera;
  final VoidCallback onTapCard;
  final VoidCallback onTapUnirse;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDeep.withValues(alpha: 0.09),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTapCard,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Lado izquierdo: Información del comercio y botón de suscripción
                  Expanded(
                    flex: 7,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primarySoft,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${cuponera.totalSellosRequeridos} SELLOS',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.primaryColor,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                cuponera.establecimientoNombre,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.darkInk,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                cuponera.titulo,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.redeem_rounded,
                                    size: 15,
                                    color: AppTheme.accentColor,
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      cuponera.descripcionPremio,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.mutedSlate,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 40,
                            width: double.infinity,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: AppTheme.brandGradient,
                                borderRadius: BorderRadius.circular(13),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: onTapUnirse,
                                icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 17,
                                  color: AppTheme.accentBright,
                                ),
                                label: const Text(
                                  'Quiero esta cuponera',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Talón derecho estilo boleto Zello
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: AppTheme.brandGradient,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            right: -20,
                            bottom: -20,
                            child: Icon(
                              Icons.confirmation_num_rounded,
                              size: 90,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.confirmation_num_rounded,
                                  color: AppTheme.accentBright,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'VER CUPÓN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
