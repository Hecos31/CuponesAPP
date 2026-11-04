import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';

import '../../../mapa/models/local_mapa_model.dart';
import '../../models/cuponera_lista_model.dart';
import '../../services/cuponeras_service.dart';
import '../widgets/carrusel_banners_minimalista.dart';
import '../widgets/sugerencias_cercanas_section.dart';

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

  // 🎟️ Función para suscribirse y refrescar el feed automáticamente
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
            backgroundColor: Colors.orange,
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
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // 🔑 RECARGAMOS EL FEED PARA QUE LA CUPONERA SUSCRITA DESAPAREZCA DE INMEDIATO
        _cargarCuponeras();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['detail'] ?? 'Error al suscribirse'),
            backgroundColor: Colors.red,
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
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<BannerPromocionalItem> _construirBanners(
    BuildContext context,
    List<CuponeraListaModel> cuponeras,
  ) {
    return [
      BannerPromocionalItem(
        etiqueta: 'Destacado de hoy',
        titulo: cuponeras.isNotEmpty
            ? cuponeras.first.establecimientoNombre
            : '2x1 en Sellos de Bienvenida',
        subtitulo: cuponeras.isNotEmpty
            ? 'Premio: ${cuponeras.first.descripcionPremio}'
            : 'Únete hoy a tus cafeterías favoritas y suma tu primer sello.',
        textoAccion: cuponeras.isNotEmpty ? 'Ver beneficio' : 'Explorar',
        icono: Icons.local_cafe_rounded,
        colorFondo: const Color(0xFFEFF6FF),
        colorAcento: const Color(0xFF2563EB),
        onTap: () {
          if (cuponeras.isNotEmpty) {
            final c = cuponeras.first;
            context.push(
              '/cuponeras/detalle',
              extra: {
                'id': c.id,
                'establecimiento_nombre': c.establecimientoNombre,
                'titulo_cuponera': c.titulo,
                'descripcion_premio': c.descripcionPremio,
                'total_sellos_requeridos': c.totalSellosRequeridos,
                'configuracion_ui': c.diseno,
              },
            );
          }
        },
      ),
      BannerPromocionalItem(
        etiqueta: 'Cerca de ti',
        titulo: 'Locales aliados en tu zona',
        subtitulo:
            'Explora el mapa interactivo y encuentra recompensas a pocos metros.',
        textoAccion: 'Abrir mapa',
        icono: Icons.map_rounded,
        colorFondo: const Color(0xFFF0FDF4),
        colorAcento: const Color(0xFF16A34A),
        onTap: () => context.go('/mapa'),
      ),
      BannerPromocionalItem(
        etiqueta: 'Recompensas VIP',
        titulo: 'Acumula sellos con QR',
        subtitulo:
            'Muestra tu código en caja en cada visita y desbloquea premios gratis.',
        textoAccion: 'Mis cuponeras',
        icono: Icons.qr_code_rounded,
        colorFondo: const Color(0xFFFFF7ED),
        colorAcento: const Color(0xFFEA580C),
        onTap: () => context.go('/mis-cuponeras'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Descubrir Cuponeras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Mapa de locales',
            onPressed: () => context.go('/mapa'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _cargarCuponeras,
          ),
        ],
        elevation: 0,
      ),
      body: FutureBuilder<List<CuponeraListaModel>>(
        future: _futureCuponeras,
        builder: (context, snapshot) {
          final cargando = snapshot.connectionState == ConnectionState.waiting;
          final hayError = snapshot.hasError;
          final cuponeras = snapshot.data ?? <CuponeraListaModel>[];
          final localesCercanos = construirListaLocalesCercanos(cuponeras);

          return RefreshIndicator(
            onRefresh: () async => _cargarCuponeras(),
            child: CustomScrollView(
              slivers: [
                // 1. Carrusel de banners promocionales minimalistas
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 18),
                    child: CarruselBannersMinimalista(
                      banners: _construirBanners(context, cuponeras),
                    ),
                  ),
                ),

                // 2. Vista maquetada "Sugerencias Cercanas"
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: SugerenciasCercanasSection(
                      locales: localesCercanos,
                      onVerMapaCompleto: () => context.go('/mapa'),
                      onUbicarEnMapa: (local) {
                        context.go('/mapa', extra: local.id);
                      },
                      onTapLocal: (local) {
                        context.push(
                          '/cuponeras/detalle',
                          extra: local.toCuponeraDetailMap(),
                        );
                      },
                    ),
                  ),
                ),

                // 3. Encabezado del catálogo general de cuponeras
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Todas las Cuponeras',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (cuponeras.isNotEmpty)
                          Text(
                            '${cuponeras.length} disponibles',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // 4. Estado de carga, error o lista de cuponeras del servidor
                if (cargando)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (hayError)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'No se pudieron sincronizar las cuponeras del servidor.\nExplora las sugerencias cercanas o el mapa interactivo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ),
                  )
                else if (cuponeras.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'No hay cuponeras nuevas por suscribir en este momento.',
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final cuponera = cuponeras[index];
                        return _CuponeraCardReal(
                          cuponera: cuponera,
                          onTapCard: () {
                            final Map<String, dynamic> cuponeraMap = {
                              'id': cuponera.id,
                              'establecimiento_nombre':
                                  cuponera.establecimientoNombre,
                              'titulo_cuponera': cuponera.titulo,
                              'descripcion_premio': cuponera.descripcionPremio,
                              'total_sellos_requeridos':
                                  cuponera.totalSellosRequeridos,
                              'configuracion_ui': cuponera.diseno,
                            };
                            context.push(
                              '/cuponeras/detalle',
                              extra: cuponeraMap,
                            );
                          },
                          onTapUnirse: () => _unirseCuponera(cuponera.id),
                        );
                      }, childCount: cuponeras.length),
                    ),
                  ),
              ],
            ),
          );
        },
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTapCard,
        child: SizedBox(
          height: 135,
          child: Row(
            children: [
              Expanded(
                flex: 6,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cuponera.establecimientoNombre,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cuponera.titulo,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Premio: ${cuponera.descripcionPremio}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 32,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: onTapUnirse,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text(
                            'Quiero esta cuponera',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  color: const Color(0xFF374151),
                  child: const Center(
                    child: Icon(
                      Icons.confirmation_num_rounded,
                      color: Colors.amberAccent,
                      size: 42,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
