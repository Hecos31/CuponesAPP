import 'package:flutter/material.dart';

class BusquedaPage extends StatelessWidget {
  const BusquedaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Búsqueda')),
      body: const Center(
        child: Text('Pantalla de Búsqueda', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}