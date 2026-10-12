import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/editor_provider.dart';

class EditorPage extends ConsumerWidget {
  const EditorPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elements = ref.watch(editorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor de Cuponera'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // Aquí convertiremos la lista a JSON para enviar al backend
            },
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double screenWidth = constraints.maxWidth;
          final double screenHeight = constraints.maxHeight;

          return Container(
            color: Colors.grey[200], // Fondo temporal del lienzo
            child: Stack(
              children: elements.map((element) {
                return Positioned(
                  left: screenWidth * element.x,
                  top: screenHeight * element.y,
                  width: screenWidth * element.width,
                  height: screenHeight * element.height,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      // Traducir píxeles a porcentaje relativo
                      final double deltaX = details.delta.dx / screenWidth;
                      final double deltaY = details.delta.dy / screenHeight;
                      
                      ref.read(editorProvider.notifier).moveElement(element.id, deltaX, deltaY);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueAccent, width: 2), // Indicador de selección
                        color: Colors.white.withOpacity(0.5),
                      ),
                      child: _renderElementByType(element.type, element.properties),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _renderElementByType(String type, Map<String, dynamic> properties) {
    if (type == 'text') {
      return Text(
        properties['text'] ?? '',
        style: TextStyle(
          fontSize: properties['fontSize'] ?? 16.0,
          color: Colors.black, // Simplificado por ahora
        ),
      );
    }
    return const SizedBox.shrink();
  }
}