import 'package:flutter/material.dart';

class CreadorCupones extends StatelessWidget {
  const CreadorCupones({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Creador de Cupones')),
      body: const Center(
        child: Text('Aquí irá tu formulario para crear nuevos cupones.'),
      ),
    );
  }
}