import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/datasources/sucursales_remote_data_source.dart';

class AdministracionSucursalesPage extends StatefulWidget {
  const AdministracionSucursalesPage({super.key});

  @override
  State<AdministracionSucursalesPage> createState() => _AdministracionSucursalesPageState();
}

class _AdministracionSucursalesPageState extends State<AdministracionSucursalesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dataSource = SucursalesRemoteDataSource();

  List<SucursalModel> _sucursales = [];
  List<SolicitudModel> _solicitudes = [];
  bool _isLoadingSucursales = false;
  bool _isLoadingSolicitudes = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    _cargarSucursales();
    _cargarSolicitudes();
  }

  Future<void> _cargarSucursales() async {
    setState(() {
      _isLoadingSucursales = true;
      _error = null;
    });
    try {
      final list = await _dataSource.getSucursales();
      setState(() => _sucursales = list);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoadingSucursales = false);
    }
  }

  Future<void> _cargarSolicitudes() async {
    setState(() => _isLoadingSolicitudes = true);
    try {
      final list = await _dataSource.getSolicitudes();
      setState(() => _solicitudes = list);
    } catch (e) {
      // Ignorar o registrar error
    } finally {
      setState(() => _isLoadingSolicitudes = false);
    }
  }

  Future<void> _cambiarEstadoSolicitud(String id, String nuevoEstado) async {
    try {
      await _dataSource.actualizarEstadoSolicitud(id, nuevoEstado);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solicitud actualizada a "$nuevoEstado".'),
          backgroundColor: nuevoEstado == 'APROBADA' ? Colors.green : Colors.red,
        ),
      );
      _cargarDatos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración de Sucursales'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.store), text: 'Sucursales'),
            Tab(icon: Icon(Icons.rule), text: 'Solicitudes y Verificación'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.verified_outlined),
            onPressed: () => context.push('/sucursales/verificacion'),
            tooltip: 'Verificación de Identidad',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // -------------------------------------------------------------------
          // Pestaña 1: Lista y Gestión de Sucursales
          // -------------------------------------------------------------------
          _isLoadingSucursales
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 12),
                            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _cargarSucursales,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _sucursales.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.storefront_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay sucursales registradas aún.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final res = await context.push('/sucursales/alta');
                              if (res == true) _cargarDatos();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Dar de Alta la Primera Sucursal'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarSucursales,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _sucursales.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _sucursales[index];
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: item.activo ? Colors.blue.shade100 : Colors.grey.shade300,
                                backgroundImage: (item.logoUrl != null && item.logoUrl!.isNotEmpty)
                                    ? NetworkImage(item.logoUrl!)
                                    : null,
                                child: (item.logoUrl == null || item.logoUrl!.isEmpty)
                                    ? Icon(Icons.store, color: item.activo ? Colors.blue.shade800 : Colors.grey)
                                    : null,
                              ),
                              title: Text(item.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('Slug: ${item.slug}', style: const TextStyle(fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: item.activo ? Colors.green : Colors.red,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        item.activo ? 'Operativa (Activa)' : 'Inactiva',
                                        style: TextStyle(
                                          color: item.activo ? Colors.green.shade800 : Colors.red.shade800,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.settings_outlined, color: Colors.blueGrey),
                                tooltip: 'Configuración Especial',
                                onPressed: () async {
                                  final res = await context.push(
                                    '/sucursales/configuracion',
                                    extra: item,
                                  );
                                  if (res == true) _cargarDatos();
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),

          // -------------------------------------------------------------------
          // Pestaña 2: Solicitudes de Verificación y Máquina de Estados
          // -------------------------------------------------------------------
          _isLoadingSolicitudes
              ? const Center(child: CircularProgressIndicator())
              : _solicitudes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text('No hay solicitudes registradas.'),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () => context.push('/sucursales/verificacion'),
                            child: const Text('Crear Solicitud de Verificación'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarSolicitudes,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _solicitudes.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final sol = _solicitudes[index];
                          Color estadoColor = Colors.orange;
                          if (sol.estado == 'APROBADA') estadoColor = Colors.green;
                          if (sol.estado == 'RECHAZADA') estadoColor = Colors.red;

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          sol.nombreNegocio,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ),
                                      Chip(
                                        label: Text(
                                          sol.estado,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                        ),
                                        backgroundColor: estadoColor,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('ID Solicitante: ${sol.usuarioId}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                  if (sol.documentosUrl != null) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.attach_file, size: 16, color: Colors.blueGrey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Doc: ${sol.documentosUrl}',
                                            style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 8),

                                  // Acciones de la máquina de estados
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (sol.estado == 'PENDIENTE') ...[
                                        TextButton.icon(
                                          onPressed: () => _cambiarEstadoSolicitud(sol.id, 'RECHAZADA'),
                                          icon: const Icon(Icons.close, color: Colors.red, size: 18),
                                          label: const Text('Rechazar', style: TextStyle(color: Colors.red)),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          onPressed: () => _cambiarEstadoSolicitud(sol.id, 'APROBADA'),
                                          icon: const Icon(Icons.check, size: 18),
                                          label: const Text('Aprobar'),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                        ),
                                      ] else ...[
                                        Text(
                                          'Estado finalizado',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await context.push('/sucursales/alta');
          if (res == true) _cargarDatos();
        },
        icon: const Icon(Icons.add_business),
        label: const Text('Alta Sucursal'),
      ),
    );
  }
}
