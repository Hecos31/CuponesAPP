import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../utils/colores.dart';

/// Fila con un círculo de color. Al tocarla abre la paleta para cambiarlo.
class SelectorColor extends StatelessWidget {
  const SelectorColor({
    super.key,
    required this.titulo,
    required this.color,
    required this.alCambiar,
  });

  final String titulo;
  final Color color;
  final ValueChanged<Color> alCambiar;

  Future<void> _abrirPaleta(BuildContext context) async {
    Color temporal = color;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(titulo),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: temporal,
              onColorChanged: (nuevo) => temporal = nuevo,
              enableAlpha: false,
              paletteType: PaletteType.hsv,
              labelTypes: const [ColorLabelType.hex],
              hexInputBar: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                alCambiar(temporal);
                Navigator.pop(dialogContext);
              },
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(titulo),
      subtitle: Text(colorAHex(color)),
      onTap: () => _abrirPaleta(context),
      trailing: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey),
        ),
      ),
    );
  }
}

