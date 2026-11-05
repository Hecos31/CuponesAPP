import 'package:flutter/material.dart';

class BarraAgregar extends StatelessWidget {
  final VoidCallback alAgregarTexto, alAgregarSvg, alAgregarCuadrado, alAgregarCirculo, alAgregarTriangulo;

  const BarraAgregar({
    super.key, required this.alAgregarTexto, required this.alAgregarSvg, required this.alAgregarCuadrado, required this.alAgregarCirculo, required this.alAgregarTriangulo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Boton(icono: Icons.text_fields, texto: 'Texto', onTap: alAgregarTexto),
          _Boton(icono: Icons.square_rounded, texto: 'Forma', onTap: alAgregarCuadrado),
          _Boton(icono: Icons.circle, texto: 'Círculo', onTap: alAgregarCirculo),
          _Boton(icono: Icons.change_history_rounded, texto: 'Triángulo', onTap: alAgregarTriangulo),
          _Boton(icono: Icons.image_outlined, texto: 'SVG', onTap: alAgregarSvg),
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
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: Colors.blueAccent, size: 26),
            const SizedBox(height: 4),
            Text(texto, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}