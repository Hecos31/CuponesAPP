import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../utils/colores.dart';

class SelectorColor extends StatelessWidget {
  const SelectorColor({super.key, required this.titulo, required this.color, required this.alCambiar});
  final String titulo;
  final Color color;
  final ValueChanged<Color> alCambiar;

  Future<void> _abrirPaleta(BuildContext context) async {
    Color temporal = color;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: temporal,
            onColorChanged: (nuevo) => temporal = nuevo,
            enableAlpha: false,
            paletteType: PaletteType.hsvWithHue,
            labelTypes: const [ColorLabelType.hex],
            hexInputBar: true,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () { alCambiar(temporal); Navigator.pop(ctx); },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(colorAHex(color), style: TextStyle(color: Colors.grey.shade600)),
      onTap: () => _abrirPaleta(context),
      trailing: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.black12, width: 2), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      ),
    );
  }
}