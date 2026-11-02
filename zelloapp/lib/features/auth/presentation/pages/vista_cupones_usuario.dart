import 'package:flutter/material.dart';

class VistaCuponesUsuario extends StatelessWidget {
  const VistaCuponesUsuario({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cupones Disponibles')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(child: ListTile(title: Text('2x1 en Hamburguesas'))),
          Card(child: ListTile(title: Text('50% de Descuento en Helados'))),
        ],
      ),
    );
  }
}