import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zelloapp/core/network/api_config.dart';
import 'package:zelloapp/core/network/sesion_usuario.dart';
import 'package:zelloapp/features/sucursales/data/datasources/sucursales_remote_data_source.dart';

class AdministracionSucursalesPage extends StatefulWidget {
  const AdministracionSucursalesPage({super.key});

  @override
  State<AdministracionSucursalesPage> createState() => _AdministracionSucursalesPageState();
}

class _AdministracionSucursalesPageState extends State<AdministracionSucursalesPage> {
  final _dataSource = SucursalesRemoteDataSource();

  List<SucursalModel> _sucursales = [];
  bool _isLoadingSucursales = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarSucursales();
  }

  Future<void> _cargarSucursales() async {
    setState(() {
      _isLoadingSucursales = true;
      _error = null;
    });
    try {
      final list = await _dataSource.getSucursales(
        propietarioId: SesionUsuario().usuarioId,
      );
      if (mounted) {
        setState(() => _sucursales = list);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingSucursales = false);
      }
    }
  }

  String? _construirUrlLogo(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final trimmed = rawUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final serverRoot = ApiConfig.baseUrl.replaceAll('/api/v1', '');
    if (trimmed.startsWith('/')) {
      return '$serverRoot$trimmed';
    }
    return '$serverRoot/$trimmed';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración de Sucursales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarSucursales,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoadingSucursales
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
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
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
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.storefront_outlined, size: 68, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text(
                              'Aún no tienes sucursales aprobadas.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await context.push('/registro-negocio');
                                _cargarSucursales();
                              },
                              icon: const Icon(Icons.storefront),
                              label: const Text('Registrar mi Local'),
                            ),
                          ],
                        ),
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
                          final logoFullUrl = _construirUrlLogo(item.logoUrl);
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: item.activo ? Colors.blue.shade100 : Colors.grey.shade300,
                                backgroundImage: logoFullUrl != null
                                    ? NetworkImage(logoFullUrl)
                                    : null,
                                child: logoFullUrl == null
                                    ? Icon(Icons.store, color: item.activo ? Colors.blue.shade800 : Colors.grey)
                                    : null,
                              ),
                              title: Text(
                                item.nombre,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
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
                                tooltip: 'Configuración Especial de Sucursal',
                                onPressed: () async {
                                  final res = await context.push(
                                    '/sucursales/configuracion',
                                    extra: item,
                                  );
                                  if (res == true) _cargarSucursales();
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/registro-negocio');
          _cargarSucursales();
        },
        icon: const Icon(Icons.add_business),
        label: const Text('Registrar otra Sucursal'),
      ),
    );
  }
}
