import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:xml/xml.dart';

/// Tamaño máximo permitido para un archivo SVG (2 MB).
const int maxSvgBytes = 2 * 1024 * 1024;

/// Abre el selector de archivos y regresa el SVG ya limpio.
/// Regresa null si el usuario cancela. Lanza Exception si el archivo no sirve.
Future<String?> elegirSvgDelDispositivo() async {
  final resultado = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['svg'],
    withData: true,
  );

  if (resultado == null || resultado.files.isEmpty) return null;

  final bytes = resultado.files.single.bytes;
  if (bytes == null) {
    throw Exception('No se pudo leer el contenido del archivo.');
  }
  if (bytes.length > maxSvgBytes) {
    throw Exception('El SVG supera el límite de 2 MB.');
  }

  return limpiarSvg(utf8.decode(bytes));
}

/// Revisa que el SVG sea seguro y lo arregla para que Flutter lo dibuje bien.
String limpiarSvg(String contenido) {
  if (utf8.encode(contenido).length > maxSvgBytes) {
    throw Exception('El SVG supera el límite de 2 MB.');
  }

  final XmlDocument documento;
  try {
    // Quita el BOM y espacios que algunos editores agregan al inicio.
    documento = XmlDocument.parse(contenido.replaceFirst('\uFEFF', '').trim());
  } catch (_) {
    throw Exception('El archivo no es un SVG válido (está dañado o incompleto).');
  }

  final raiz = documento.rootElement;
  if (raiz.name.local.toLowerCase() != 'svg') {
    throw Exception('El archivo seleccionado no es un SVG.');
  }

  _revisarSeguridad(raiz);
  _pasarClasesAEstilos(raiz);
  _ajustarTamano(raiz);

  // Comentarios y metadatos solo hacen pesado el archivo.
  for (final comentario in documento.descendants.whereType<XmlComment>().toList()) {
    comentario.remove();
  }
  for (final meta in raiz.findAllElements('metadata').toList()) {
    meta.remove();
  }

  return documento.toXmlString();
}

/// No dejamos pasar scripts, eventos ni enlaces a otras páginas.
void _revisarSeguridad(XmlElement raiz) {
  const etiquetasProhibidas = {
    'script', 'foreignobject', 'iframe', 'object', 'embed', 'audio', 'video',
  };

  final elementos = [raiz, ...raiz.descendants.whereType<XmlElement>()];

  for (final elemento in elementos) {
    final etiqueta = elemento.name.local.toLowerCase();
    if (etiquetasProhibidas.contains(etiqueta)) {
      throw Exception('El SVG contiene una etiqueta no permitida: $etiqueta.');
    }

    for (final atributo in elemento.attributes.toList()) {
      final nombre = atributo.name.local.toLowerCase();
      final valor = atributo.value.trim().toLowerCase();

      // onclick, onload, etc. se borran
      if (nombre.startsWith('on')) {
        elemento.attributes.remove(atributo);
        continue;
      }

      if ((nombre == 'href' || nombre == 'src') &&
          valor.isNotEmpty &&
          !valor.startsWith('#') &&
          !valor.startsWith('data:image/')) {
        throw Exception('El SVG intenta cargar archivos externos.');
      }

      if (valor.contains('javascript:')) {
        throw Exception('El SVG contiene contenido no permitido.');
      }
    }

    if (etiqueta == 'style' && elemento.innerText.contains('@import')) {
      throw Exception('El SVG contiene estilos externos no permitidos.');
    }
  }
}

/// Si el SVG solo tiene width/height, le crea un viewBox
/// y quita el tamaño fijo para que crezca o se achique sin cortarse.
void _ajustarTamano(XmlElement raiz) {
  double? numero(String? valor) {
    if (valor == null || valor.contains('%')) return null;
    return double.tryParse(valor.replaceAll(RegExp(r'[a-zA-Z\s]'), ''));
  }

  final ancho = numero(raiz.getAttribute('width'));
  final alto = numero(raiz.getAttribute('height'));

  if (raiz.getAttribute('viewBox') == null && ancho != null && alto != null) {
    raiz.setAttribute('viewBox', '0 0 $ancho $alto');
  }

  if (raiz.getAttribute('viewBox') != null) {
    raiz.removeAttribute('width');
    raiz.removeAttribute('height');
  }
}

/// Programas como Illustrator guardan los colores en <style> con clases
/// (.cls-1 {fill:red}). Flutter no las entiende y el dibujo sale negro,
/// así que copiamos esos estilos directo a cada elemento.
void _pasarClasesAEstilos(XmlElement raiz) {
  final reglas = <String, String>{};

  for (final style in raiz.findAllElements('style').toList()) {
    for (final regla in RegExp(r'([^{}]+)\{([^}]*)\}').allMatches(style.innerText)) {
      for (final selector in regla.group(1)!.split(',')) {
        final s = selector.trim();
        if (s.startsWith('.')) {
          final clase = s.substring(1);
          reglas[clase] = '${reglas[clase] ?? ''}${regla.group(2)!.trim()};';
        }
      }
    }
    style.remove();
  }

  if (reglas.isEmpty) return;

  for (final elemento in raiz.descendants.whereType<XmlElement>()) {
    final clases = elemento.getAttribute('class');
    if (clases == null) continue;

    final estilos = clases.split(RegExp(r'\s+')).map((c) => reglas[c] ?? '').join();
    if (estilos.isEmpty) continue;

    final propio = elemento.getAttribute('style') ?? '';
    elemento.setAttribute('style', '$estilos$propio');
  }
}

