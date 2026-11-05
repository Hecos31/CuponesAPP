import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zelloapp/core/network/api_config.dart';
import 'package:zelloapp/core/theme/app_theme.dart';
import 'package:zelloapp/core/widgets/zello_logo.dart';

class MisCuponerasPage extends StatefulWidget {
  const MisCuponerasPage({super.key});

  @override
  State<MisCuponerasPage> createState() => _MisCuponerasPageState();
}

class _MisCuponerasPageState extends State<MisCuponerasPage> {
  List<dynamic> _suscripciones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarSuscripciones();
  }

  Future<void> _cargarSuscripciones() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getString('usuario_id');
      final token = prefs.getString('token');

      if (usuarioId == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/cuponeras/mis-suscripciones/$usuarioId');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        setState(() => _suscripciones = jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: ZelloAmbientBackground(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ZelloHeaderBanner(
                eyebrow: 'ZELLO',
                title: 'Mis Cuponeras (${_suscripciones.length})',
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
                    onPressed: _cargarSuscripciones,
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
              sliver: _isLoading
                  ? const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _suscripciones.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(22),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primarySoft,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.card_giftcard_rounded,
                                    size: 56,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Aún no tienes cuponeras activas',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.darkInk,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Explora los negocios afiliados y únete para empezar a acumular sellos.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppTheme.mutedSlate, fontSize: 13),
                                ),
                                const SizedBox(height: 18),
                                ElevatedButton.icon(
                                  onPressed: () => context.go('/descubrir'),
                                  icon: const Icon(Icons.explore_rounded),
                                  label: const Text('Explorar negocios'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final sub = _suscripciones[index];
                              final int acumulados = sub['sellos_acumulados'] ?? 0;
                              final int requeridos =
                                  (sub['total_sellos_requeridos'] ?? 6) > 0
                                      ? sub['total_sellos_requeridos']
                                      : 6;
                              final double progreso =
                                  (acumulados / requeridos).clamp(0.0, 1.0);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryDeep.withValues(alpha: 0.08),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(24),
                                    onTap: () => context.push('/cuponeras/detalle', extra: sub),
                                    child: Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  gradient: AppTheme.brandGradient,
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: const Icon(
                                                  Icons.storefront_rounded,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      sub['establecimiento_nombre'] ?? 'Comercio',
                                                      style: const TextStyle(
                                                        fontSize: 17,
                                                        fontWeight: FontWeight.w800,
                                                        color: AppTheme.darkInk,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      sub['titulo_cuponera'] ?? '',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: AppTheme.mutedSlate,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.accentSoft,
                                                  borderRadius: BorderRadius.circular(14),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      '$acumulados / $requeridos',
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w900,
                                                        color: AppTheme.accentDeep,
                                                      ),
                                                    ),
                                                    const Text(
                                                      'SELLOS',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w800,
                                                        color: AppTheme.accentDeep,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: LinearProgressIndicator(
                                              value: progreso,
                                              minHeight: 8,
                                              backgroundColor: AppTheme.primarySoft,
                                              valueColor: const AlwaysStoppedAnimation<Color>(
                                                AppTheme.primaryColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  progreso >= 1.0
                                                      ? '¡Beneficio listo para canjear!'
                                                      : 'Faltan ${requeridos - acumulados} sello(s) para completar',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: progreso >= 1.0
                                                        ? AppTheme.successColor
                                                        : AppTheme.mutedSlate,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  gradient: AppTheme.accentGradient,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.qr_code_2_rounded,
                                                      size: 15,
                                                      color: Colors.white,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Generar QR',
                                                      style: TextStyle(
                                                        fontSize: 11.5,
                                                        fontWeight: FontWeight.w800,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: _suscripciones.length,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
