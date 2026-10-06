import 'package:flutter/material.dart';

class MapaPage extends StatelessWidget {
  const MapaPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa')),
      body: const Center(
        child: Text('Pantalla de Mapa', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}