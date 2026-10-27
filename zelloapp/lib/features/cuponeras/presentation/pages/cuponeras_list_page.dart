import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/cuponera_lista_model.dart';
import '../../services/cuponeras_service.dart';

class CuponerasListPage extends StatefulWidget {
  const CuponerasListPage({super.key});

  @override
  State<CuponerasListPage> createState() => _CuponerasListPageState();
}

class _CuponerasListPageState extends State<CuponerasListPage> {
  // Instancia del servicio que utiliza ApiConfig internamente
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
          // 1. Estado de Carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } 
          
          // 2. Estado de Error
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

          // 3. Estado Vacío
          if (cuponeras.isEmpty) {
            return const Center(
              child: Text('No hay cuponeras disponibles por el momento.'),
            );
          }

          // 4. Lista Exitosa con tus Tarjetas
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cuponeras.length,
            itemBuilder: (context, index) {
              final cuponera = cuponeras[index];
              return GestureDetector(
                onTap: () {
                  // Transformamos el modelo a Map para pasarlo correctamente al detalle
                  // o aseguramos que la ruta reciba el objeto/mapa adecuado
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
                child: _CuponeraCardReal(cuponera: cuponera),
              );
            },
          );
        },
      ),
    );
  }
}

class _CuponeraCardReal extends StatelessWidget {
  const _CuponeraCardReal({required this.cuponera});

  final CuponeraListaModel cuponera;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: 120,
        child: Row(
          children: [
            // Lado izquierdo: Textos dinámicos basados en la BD
            Expanded(
              flex: 5,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      cuponera.establecimientoNombre, // Nombre del local obtenido de la relación
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cuponera.titulo, // Título de la cuponera
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Premio: ${cuponera.descripcionPremio}', // Descripción de la BD
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            // Lado derecho: Tu contenedor visual con icono
            Expanded(
              flex: 4,
              child: Container(
                color: const Color(0xFF374151),
                child: const Center(
                  child: Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 48,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}