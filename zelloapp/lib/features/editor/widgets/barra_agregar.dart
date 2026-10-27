import 'package:flutter/material.dart';

class BarraAgregar extends StatelessWidget {
  final VoidCallback alAgregarTexto;
  final VoidCallback alAgregarSvg;
  final VoidCallback alAgregarCuadrado;
  final VoidCallback alAgregarCirculo;
  final VoidCallback alAgregarTriangulo;

  const BarraAgregar({
    super.key,
    required this.alAgregarTexto,
    required this.alAgregarSvg,
    required this.alAgregarCuadrado,
    required this.alAgregarCirculo,
    required this.alAgregarTriangulo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Boton(icono: Icons.text_fields, texto: 'Texto', onTap: alAgregarTexto),
          _Boton(icono: Icons.square, texto: 'Cuadrado', onTap: alAgregarCuadrado),
          _Boton(icono: Icons.circle, texto: 'Círculo', onTap: alAgregarCirculo),
          _Boton(icono: Icons.change_history, texto: 'Triángulo', onTap: alAgregarTriangulo),
          _Boton(icono: Icons.code, texto: 'SVG', onTap: alAgregarSvg),
        ],
      ),
    );
  }
}

class _Boton extends StatelessWidget {
  final IconData icono;
  final String texto;
  final VoidCallback onTap;

  const _Boton({required this.icono, required this.texto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: Colors.blue.shade700),
            const SizedBox(height: 4),
            Text(texto, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}