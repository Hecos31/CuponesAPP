import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zelloapp/core/network/api_config.dart';
import 'package:zelloapp/features/busqueda/data/datasources/localizacion_remote_data_source.dart';

class BusquedaPage extends StatefulWidget {
  const BusquedaPage({super.key});

  @override
  State<BusquedaPage> createState() => _BusquedaPageState();
}

class _BusquedaPageState extends State<BusquedaPage> {
  final _dataSource = LocalizacionRemoteDataSource();
  final _searchController = TextEditingController();

  // Ubicación base por defecto (CDMX Centro) o editable para simular movimiento del usuario
  double _miLatitud = 19.432608;
  double _miLongitud = -99.133209;
  double _radioKm = 5.0; // Radio de búsqueda en km
  bool _filtrarPorRadio = true;

  List<LocalCercanoModel> _sugerencias = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarSugerenciasCercanas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarSugerenciasCercanas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final termino = _searchController.text.trim();
      List<LocalCercanoModel> lista;

      if (_filtrarPorRadio) {
        // Consume GET /api/v1/localizacion/cercanos (Tarea 800 y 850)
        lista = await _dataSource.obtenerSugerenciasCercanasPorRadio(
          latitud: _miLatitud,
          longitud: _miLongitud,
          radioKm: _radioKm,
          busqueda: termino.isNotEmpty ? termino : null,
        );
      } else {
        // Consume GET /api/v1/localizacion/coordenadas (Tarea 990)
        lista = await _dataSource.consultarCoordenadasYDistancias(
          latitud: _miLatitud,
          longitud: _miLongitud,
          busqueda: termino.isNotEmpty ? termino : null,
        );
      }

      if (mounted) {
        setState(() => _sugerencias = lista);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _unirseACuponera(LocalCercanoModel local) async {
    if (local.cuponeraId == null || local.cuponeraId!.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getString('usuario_id');
      final token = prefs.getString('token');

      if (usuarioId == null || usuarioId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inicia sesión para suscribirte a esta cuponera.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/cuponeras/${local.cuponeraId}/unirse?usuario_id=$usuarioId',
      );
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['mensaje'] ?? '¡Suscrito a ${local.nombre}!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['detail'] ?? 'No se pudo suscribir'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al suscribirse: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarDialogoCambiarCoordenadas() {
    final latCtrl = TextEditingController(text: _miLatitud.toStringAsFixed(6));
    final lngCtrl = TextEditingController(text: _miLongitud.toStringAsFixed(6));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubicación de Referencia (GPS)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ajusta tus coordenadas actuales para calcular distancias reales hacia los locales:',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: latCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(
                labelText: 'Latitud',
                prefixIcon: Icon(Icons.my_location),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lngCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(
                labelText: 'Longitud',
                prefixIcon: Icon(Icons.explore_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final nuevaLat = double.tryParse(latCtrl.text.trim());
              final nuevaLng = double.tryParse(lngCtrl.text.trim());
              if (nuevaLat != null && nuevaLng != null) {
                setState(() {
                  _miLatitud = nuevaLat;
                  _miLongitud = nuevaLng;
                });
                Navigator.pop(ctx);
                _cargarSugerenciasCercanas();
              }
            },
            child: const Text('Actualizar Ubicación'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Sugerencias Cercanas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_location_alt_outlined),
            tooltip: 'Cambiar mis coordenadas',
            onPressed: _mostrarDialogoCambiarCoordenadas,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar sugerencias',
            onPressed: _cargarSugerenciasCercanas,
          ),
        ],
      ),
      body: Column(
        children: [
          // Panel superior de búsqueda y filtro por radio en kilómetros
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _cargarSugerenciasCercanas(),
                  decoration: InputDecoration(
                    hintText: 'Buscar local o promoción cercana...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _cargarSugerenciasCercanas();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.radar, size: 18, color: Colors.blue.shade700),
                        const SizedBox(width: 6),
                        Text(
                          _filtrarPorRadio
                              ? 'Radio de búsqueda: ${_radioKm.toStringAsFixed(1)} km'
                              : 'Mostrando todos los locales por distancia',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                    Switch(
                      value: _filtrarPorRadio,
                      onChanged: (val) {
                        setState(() => _filtrarPorRadio = val);
                        _cargarSugerenciasCercanas();
                      },
                    ),
                  ],
                ),
                if (_filtrarPorRadio) ...[
                  Slider(
                    value: _radioKm,
                    min: 1.0,
                    max: 25.0,
                    divisions: 24,
                    label: '${_radioKm.toStringAsFixed(0)} km',
                    onChanged: (val) => setState(() => _radioKm = val),
                    onChangeEnd: (_) => _cargarSugerenciasCercanas(),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [1.0, 3.0, 5.0, 10.0, 20.0].map((r) {
                        final seleccionado = (_radioKm - r).abs() < 0.2;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text('${r.toInt()} km'),
                            selected: seleccionado,
                            onSelected: (_) {
                              setState(() => _radioKm = r);
                              _cargarSugerenciasCercanas();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Lista de sugerencias cercanas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_off_outlined, size: 52, color: Colors.redAccent),
                              const SizedBox(height: 12),
                              Text(
                                'No se pudieron obtener las sugerencias cercanas:\n$_error',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _cargarSugerenciasCercanas,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _sugerencias.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.store_mall_directory_outlined, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No se encontraron locales dentro de ${_radioKm.toStringAsFixed(0)} km.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Amplía el radio de búsqueda en kilómetros para descubrir más establecimientos.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _cargarSugerenciasCercanas,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _sugerencias.length,
                              itemBuilder: (context, index) {
                                final item = _sugerencias[index];
                                final distanciaTexto = item.distanciaKm < 1.0
                                    ? '${item.distanciaMetros} m'
                                    : '${item.distanciaKm.toStringAsFixed(2)} km';

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 2,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: item.tieneCuponera
                                        ? () {
                                            context.push(
                                              '/cuponeras/detalle',
                                              extra: {
                                                'id': item.cuponeraId,
                                                'establecimiento_nombre': item.nombre,
                                                'titulo_cuponera': item.tituloCuponera ?? 'Cuponera',
                                                'descripcion_premio': item.descripcionPremio ?? '',
                                                'total_sellos_requeridos': item.totalSellosRequeridos ?? 6,
                                                'configuracion_ui': item.configuracionUi,
                                              },
                                            );
                                          }
                                        : null,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              CircleAvatar(
                                                radius: 24,
                                                backgroundColor: Colors.blue.shade50,
                                                child: Icon(Icons.storefront, color: Colors.blue.shade700, size: 26),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.nombre,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.place_outlined, size: 14, color: Colors.grey),
                                                        const SizedBox(width: 4),
                                                        Expanded(
                                                          child: Text(
                                                            item.direccion ?? 'Ubicación verificada',
                                                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade50,
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(color: Colors.green.shade300),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.near_me, size: 13, color: Colors.green.shade800),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      distanciaTexto,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.green.shade800,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (item.tieneCuponera) ...[
                                            const SizedBox(height: 12),
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.blueGrey.shade50.withValues(alpha: 0.6),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.confirmation_num_outlined, color: Colors.blue, size: 20),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          item.tituloCuponera ?? 'Cuponera disponible',
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                        if (item.descripcionPremio != null)
                                                          Text(
                                                            'Premio: ${item.descripcionPremio}',
                                                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () => _unirseACuponera(item),
                                                    style: ElevatedButton.styleFrom(
                                                      visualDensity: VisualDensity.compact,
                                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                                    ),
                                                    child: const Text('Unirme', style: TextStyle(fontSize: 12)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
