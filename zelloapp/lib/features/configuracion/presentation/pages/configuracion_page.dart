import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../configuracion/services/sucursal_service.dart';
import '../../../../core/network/sesion_usuario.dart';

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
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Pantalla de Configuración', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 30),

                    OutlinedButton.icon(
                      onPressed: () => context.push('/scanner'),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Simular Escanear QR (Establecimiento)'),
                    ),
                    const SizedBox(height: 20),

                    if (!_esSucursal) ...[
                      Card(
                        color: Colors.orange.shade50,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text(
                                '¿Tienes un negocio?',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Solicita tu alta como sucursal para crear tu propia cuponera editable y fidelizar clientes.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Colors.black87),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _mostrarDialogoAltaSucursal,
                                icon: const Icon(Icons.storefront),
                                label: const Text('Solicitar Alta como Sucursal'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      Card(
                        color: Colors.blue.shade50,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text(
                                '¡Tu establecimiento está activo!',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Tu espacio de cuponera exclusivo ya está registrado en el sistema.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Colors.black87),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Pasamos el ID real de la cuponera al editor si lo requiere tu ruta
                                  context.push('/editor', extra: _cuponeraIdReal);
                                },
                                icon: const Icon(Icons.design_services),
                                label: const Text('Abrir Editor Visual de Cuponera'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}