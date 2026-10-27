import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Descubrir Cuponeras'),
        actions: [
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'No se pudieron cargar las cuponeras.\nVerifica tu conexión.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            );
          }

          final cuponeras = snapshot.data ?? [];

          if (cuponeras.isEmpty) {
            return const Center(
              child: Text('No hay cuponeras disponibles por el momento.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cuponeras.length,
            itemBuilder: (context, index) {
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
                    // 🔑 ENVIAMOS EL DISEÑO COMPLETO PARA QUE EL DETALLE LO PROCESE PERFECTAMENTE
                    'configuracion_ui': cuponera.diseno,
                  };
                  context.push('/cuponeras/detalle', extra: cuponeraMap);
                },
                onTapUnirse: () => _unirseCuponera(cuponera.id),
              );
            },
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