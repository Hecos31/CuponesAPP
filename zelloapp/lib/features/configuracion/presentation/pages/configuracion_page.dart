import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../configuracion/services/sucursal_service.dart';
import '../../../../core/network/sesion_usuario.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfiguracionPage extends StatefulWidget {
  const ConfiguracionPage({Key? key}) : super(key: key);

  @override
  State<ConfiguracionPage> createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends State<ConfiguracionPage> {
  final SucursalService _sucursalService = SucursalService();
  bool _cargando = true;
  bool _esSucursal = false;
  String? _cuponeraIdReal;

  @override
  void initState() {
    super.initState();
    _verificarEstadoEnBaseDeDatos();
  }

  // Consultamos la BD en tiempo real al abrir la pantalla
  Future<void> _verificarEstadoEnBaseDeDatos() async {
    final usuarioId = SesionUsuario().usuarioId;
    if (usuarioId == null || usuarioId.isEmpty) {
      setState(() => _cargando = false);
      return;
    }

    try {
      final estado = await _sucursalService.consultarEstadoSucursal(usuarioId);
      if (!mounted) return;

      setState(() {
        _esSucursal = estado['es_sucursal'] ?? false;
        _cuponeraIdReal = estado['cuponera_id'];
        SesionUsuario().rol = estado['rol']; // Sincronizamos rol real
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  void _mostrarDialogoAltaSucursal() {
    final TextEditingController controladorNombre = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convertirme en Sucursal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa el nombre de tu establecimiento para generar tu espacio de cuponera exclusivo:'),
            const SizedBox(height: 16),
            TextField(
              controller: controladorNombre,
              decoration: const InputDecoration(
                labelText: 'Nombre del Negocio',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final nombreNegocio = controladorNombre.text.trim();
              if (nombreNegocio.isEmpty) return;

              final idReal = SesionUsuario().usuarioId;
              if (idReal == null) return;

              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              navigator.pop();
              setState(() => _cargando = true);

              try {
                final resultado = await _sucursalService.solicitarAltaSucursal(
                  idReal, 
                  nombreNegocio,
                );

                if (!mounted) return;

                // Volvemos a consultar la BD para refrescar IDs exactos
                await _verificarEstadoEnBaseDeDatos();

                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text(resultado['mensaje'] ?? '¡Alta exitosa!')),
                );
              } catch (e) {
                if (!mounted) return;
                setState(() => _cargando = false);
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Registrar Negocio'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('Mi Cuenta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Perfil de Usuario'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/perfil'),
          ),
          
          const Divider(height: 32),
          
          const Text('Zona para Comercios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // LÓGICA DINÁMICA SEGÚN EL ESTADO DEL USUARIO
          if (_statusLocal == 'ninguno' || _statusLocal == 'rechazado')
            ListTile(
              leading: const Icon(Icons.storefront, color: Colors.blue),
              title: const Text('Registrar mi Local'),
              subtitle: const Text('Crea tu cuponera y atrae clientes'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await context.push('/registro-negocio');
                _cargarEstado(); // Refresca al volver
              },
            )
          else if (_statusLocal == 'pendiente')
            ListTile(
              leading: const Icon(Icons.hourglass_empty, color: Colors.orange),
              title: const Text('Estado de Aprobación'),
              subtitle: const Text('Tu solicitud está en revisión'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await context.push('/revision_local');
                _cargarEstado(); // Refresca al volver
              },
            )
          else if (_statusLocal == 'aprobado')
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: Colors.green),
              title: const Text('Administrar mi Local'),
              subtitle: const Text('Edita tu cuponera y escanea QR'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/editor_cuponera'),
            ),

          const SizedBox(height: 16),
          // Botón del escáner (Solo útil si ya es comercio, pero lo dejamos como herramienta)
          if (_statusLocal == 'aprobado')
            OutlinedButton.icon(
              onPressed: () => context.push('/scanner'),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Escanear QR de Cliente'),
            ),

          const Divider(height: 32),
          
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}