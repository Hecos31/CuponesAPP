import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfiguracionPage extends StatefulWidget {
  const ConfiguracionPage({super.key});

  @override
  State<ConfiguracionPage> createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends State<ConfiguracionPage> {
  String _statusLocal = 'ninguno'; 

  @override
  void initState() {
    super.initState();
    _cargarEstado();
  }

  Future<void> _cargarEstado() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _statusLocal = prefs.getString('status_local') ?? 'ninguno';
      });
    }
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