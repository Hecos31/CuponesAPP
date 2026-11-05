import 'package:flutter/material.dart';
import 'package:zelloapp/core/theme/app_theme.dart';

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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDeep.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Boton(
            icono: Icons.text_fields_rounded,
            texto: 'Texto',
            onTap: alAgregarTexto,
          ),
          _Boton(
            icono: Icons.crop_square_rounded,
            texto: 'Cuadrado',
            onTap: alAgregarCuadrado,
          ),
          _Boton(
            icono: Icons.circle_outlined,
            texto: 'Círculo',
            onTap: alAgregarCirculo,
          ),
          _Boton(
            icono: Icons.change_history_rounded,
            texto: 'Triángulo',
            onTap: alAgregarTriangulo,
          ),
          _Boton(
            icono: Icons.code_rounded,
            texto: 'SVG',
            onTap: alAgregarSvg,
          ),
        ],
      ),
    );
  }
}

class _Boton extends StatelessWidget {
  final IconData icono;
  final String texto;
  final VoidCallback onTap;

  const _Boton({
    required this.icono,
    required this.texto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icono,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                texto,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
