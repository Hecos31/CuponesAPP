// import 'dart:io';
// import 'package:file_picker/file_picker.dart';

// Future<String?> seleccionarSvgLocal() async {
//   final result = await FilePicker.platform.pickFiles(
//     type: FileType.custom,
//     allowedExtensions: ['svg'],
//   );

//   if (result != null && result.files.single.path != null) {
//     final file = File(result.files.single.path!);
//     // Leemos el archivo SVG como una cadena de texto para renderizarlo y guardarlo en el JSON
//     return await file.readAsString();
//   }
//   return null;
// }