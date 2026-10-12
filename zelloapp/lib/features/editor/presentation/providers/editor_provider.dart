import 'package:flutter_riverpod/legacy.dart';
import '../../data/models/canvas_element.dart';

class EditorNotifier extends StateNotifier<List<CanvasElement>> {
  EditorNotifier() : super([
    // Elemento de prueba inicial
    CanvasElement(
      id: 'titulo_1',
      type: 'text',
      x: 0.1,
      y: 0.1,
      width: 0.8,
      height: 0.1,
      properties: {'text': '¡Gana tu premio!', 'color': '#000000', 'fontSize': 24.0},
    ),
  ]);

  void moveElement(String id, double deltaX, double deltaY) {
    state = [
      for (final el in state)
        if (el.id == id)
          el.copyWith(
            x: (el.x + deltaX).clamp(0.0, 1.0),
            y: (el.y + deltaY).clamp(0.0, 1.0),
          )
        else
          el
    ];
  }
}

final editorProvider = StateNotifierProvider<EditorNotifier, List<CanvasElement>>((ref) {
  return EditorNotifier();
});
