import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_session.dart';
import '../../data/datasources/sucursales_remote_data_source.dart';

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
        propietarioId: AuthSession.instance.userId,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Sucursales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarSucursales,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.verified_user_outlined),
            onPressed: () async {
              await context.push('/sucursales/verificacion');
              _cargarSucursales();
            },
            tooltip: 'Solicitar Verificación y Alta',
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
                              'Aún no tienes sucursales aprobadas o dadas de alta.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Solicita tu verificación de identidad (INE o Pasaporte) y registra los datos de tu sucursal para que un administrador apruebe tu alta.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: Colors.black54),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await context.push('/sucursales/verificacion');
                                _cargarSucursales();
                              },
                              icon: const Icon(Icons.verified_user_outlined),
                              label: const Text('Solicitar Verificación para Alta de Sucursal'),
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
          await context.push('/sucursales/verificacion');
          _cargarSucursales();
        },
        icon: const Icon(Icons.verified_user_outlined),
        label: const Text('Solicitar Alta de Sucursal'),
      ),
    );
  }
}
