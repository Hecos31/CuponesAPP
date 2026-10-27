import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Asegúrate de tener esta importación

class NovedadesPage extends StatelessWidget {
  const NovedadesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novedades'),
      ),
      body: const Center(
        child: Text('Pantalla de Novedades'),
      ),
      
      // 👇 AÑADE ESTE BLOQUE EXACTAMENTE AQUÍ 👇
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Esto te llevará a tu nueva pantalla de registro
          context.push('/registro-negocio');
        },
        icon: const Icon(Icons.storefront, color: Colors.white),
        label: const Text(
          'Registrar mi Local', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.blueAccent,
      ),
      // 👆 HASTA AQUÍ 👆
      
    );
  }
}