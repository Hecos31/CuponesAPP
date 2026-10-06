import 'package:flutter/material.dart';

class NovedadesPage extends StatelessWidget {
  const NovedadesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novedades')),
      body: const Center(
        child: Text('Pantalla de Novedades', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}