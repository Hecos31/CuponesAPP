import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ConfiguracionPage extends StatelessWidget {
  const ConfiguracionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Pantalla de Configuración',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.push('/sucursales/verificacion'),
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('Solicitar Verificación para Alta de Sucursal'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push('/sucursales/administracion'),
                icon: const Icon(Icons.storefront),
                label: const Text('Administración de Sucursales'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push('/perfil'),
                icon: const Icon(Icons.person_outline),
                label: const Text('Mi Perfil de Usuario'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push('/scanner'),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Simular Escanear QR (Establecimiento)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
