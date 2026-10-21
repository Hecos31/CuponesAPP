
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:xml/xml.dart';

import '../../../disenocuponeras/diseno_cuponera_service.dart';

class DisenoCuponeraPage extends StatefulWidget {
  const DisenoCuponeraPage({
    super.key,
    this.cuponeraIdInicial,
  });

  final String? cuponeraIdInicial;

  @override
  State<DisenoCuponeraPage> createState() => _DisenoCuponeraPageState();
}

class _DisenoCuponeraPageState extends State<DisenoCuponeraPage> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();

  late final DisenoCuponeraService _service;

  Color _fondo = const Color(0xFF172554);
  Color _texto = Colors.white;
  Color _sello = const Color(0xFFFBBF24);

  String _tipografia = 'Roboto';
  double _tamanoFuente = 18;
  double _escalaSvg = 100;
  double _posicionX = 0;
  double _posicionY = 0;

  String? _svgOriginal;
  String? _svgEditado;
  bool _svgEliminado = false;

  bool _cargando = false;
  bool _guardando = false;
  String? _mensajeEstado;

  static const int _maxSvgBytes = 2 * 1024 * 1024; // 2 MB

  final List<String> _tipografias = const [
    'Roboto',
    // Fuentes del sistema (no vienen de Google Fonts)
    'Arial', 'Verdana', 'Tahoma', 'Times New Roman', 'Georgia',
    'Courier New', 'Trebuchet MS', 'Impact',
    // Más fuentes de Google Fonts
    'Lora', 'PT Sans', 'Noto Sans', 'Barlow', 'Cabin', 'Kanit', 'Bitter',
    'Exo 2', 'Cinzel', 'Crimson Text', 'Indie Flower', 'Amatic SC',
    'Shadows Into Light',
    'Open Sans',
    'Lato',
    'Montserrat',
    'Poppins',
    'Oswald',
    'Playfair Display',
    'Nunito',
    'Raleway',
    'Merriweather', 'Inter', 'Ubuntu', 'Quicksand', 'Rubik', 'Work Sans',
    'Bebas Neue', 'Anton', 'Pacifico', 'Lobster', 'Dancing Script', 'Caveat',
    'Satisfy', 'Great Vibes', 'Righteous', 'Fredoka', 'Comfortaa',
    'Josefin Sans', 'Abril Fatface', 'Permanent Marker', 'Press Start 2P',
  ];

  @override
  void initState() {
    super.initState();
    _service = DisenoCuponeraService();

    final id = widget.cuponeraIdInicial;
    if (id != null && id.trim().isNotEmpty) {
      _idController.text = id.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _cargarDiseno();
      });
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _service.cerrar();
    super.dispose();
  }

  String _hex(Color color) {
    return '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  Color _colorDesde(dynamic valor, Color predeterminado) {
    if (valor is! String) return predeterminado;

    try {
      var hex = valor.trim().replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      if (hex.length != 8) return predeterminado;
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return predeterminado;
    }
  }

  void _aviso(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Map<String, dynamic> _configuracionActual() {
    return {
      'color_fondo': _hex(_fondo),
      'color_texto': _hex(_texto),
      'color_sello': _hex(_sello),
      'tipografia': _tipografia,
      'tamano_fuente': _tamanoFuente,
      'escala_svg': _escalaSvg,
      'posicion_x_svg': _posicionX,
      'posicion_y_svg': _posicionY,
    };
  }

  String? _svgParaGuardar() {
    if (_svgEliminado) return null;
    return _svgEditado;
  }

  Future<void> _cargarDiseno() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _mensajeEstado = null;
    });

    try {
      final respuesta = await _service.obtener(_idController.text.trim());

      final dynamic datosConfig = respuesta['configuracion_ui'];
      final config = datosConfig is Map
          ? Map<String, dynamic>.from(datosConfig)
          : <String, dynamic>{};

      final svg = respuesta['svg_markup'] as String?;

      if (!mounted) return;

      setState(() {
        _fondo = _colorDesde(config['color_fondo'], _fondo);
        _texto = _colorDesde(config['color_texto'], _texto);
        _sello = _colorDesde(config['color_sello'], _sello);

        final font = config['tipografia'];
        if (font is String && _tipografias.contains(font)) {
          _tipografia = font;
        }

        _tamanoFuente = _numeroEnRango(
          config['tamano_fuente'], 18, 10, 40,
        );
        _escalaSvg = _numeroEnRango(
          config['escala_svg'], 100, 30, 300,
        );
        _posicionX = _numeroEnRango(
          config['posicion_x_svg'], 0, -100, 100,
        );
        _posicionY = _numeroEnRango(
          config['posicion_y_svg'], 0, -100, 100,
        );

        _svgOriginal = svg;
        _svgEditado = svg;
        _svgEliminado = false;
        _mensajeEstado = 'Diseño cargado correctamente.';
      });
    } catch (e) {
      _aviso('No se pudo cargar el diseño: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  double _numeroEnRango(
    dynamic valor,
    double predeterminado,
    double minimo,
    double maximo,
  ) {
    final numero = valor is num ? valor.toDouble() : predeterminado;
    return numero.clamp(minimo, maximo).toDouble();
  }

  Future<void> _guardarDiseno() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _guardando = true;
      _mensajeEstado = null;
    });

    try {
      await _service.guardar(
        cuponeraId: _idController.text.trim(),
        configuracion: _configuracionActual(),
        svgMarkup: _svgParaGuardar(),
        eliminarSvg: _svgEliminado,
      );

      if (!mounted) return;

      setState(() {
        _mensajeEstado = 'Diseño guardado correctamente.';
        if (_svgEliminado) {
          _svgOriginal = null;
          _svgEditado = null;
          _svgEliminado = false;
        } else if (_svgEditado != null) {
          _svgOriginal = _svgEditado;
        }
      });

      _aviso('El diseño se guardó correctamente.');
    } catch (e) {
      _aviso('No se pudo guardar el diseño: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _seleccionarColor({
    required String titulo,
    required Color inicial,
    required ValueChanged<Color> alCambiar,
  }) async {
    Color temporal = inicial;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(titulo),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: temporal,
              onColorChanged: (color) => temporal = color,
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
              child: const Text('Aplicar color'),
            ),
          ],
        );
      },
    );
  }

  String _sanitizarSvg(String contenido) {
    if (utf8.encode(contenido).length > _maxSvgBytes) {
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
      throw Exception('El archivo seleccionado no contiene una raíz SVG.');
    }

    const etiquetasProhibidas = {
      'script',
      'foreignObject',
      'iframe',
      'object',
      'embed',
      'audio',
      'video',
    };

    const atributosProhibidos = {
      'onload',
      'onclick',
      'onerror',
      'onmouseover',
      'onfocus',
    };

    final elementos = <XmlElement>[
      raiz,
      ...raiz.descendants.whereType<XmlElement>(),
    ];

    for (final elemento in elementos) {
      if (etiquetasProhibidas.contains(elemento.name.local.toLowerCase())) {
        throw Exception(
          'El SVG contiene una etiqueta no permitida: ${elemento.name.local}.',
        );
      }

      for (final atributo in elemento.attributes.toList()) {
        final nombre = atributo.name.local.toLowerCase();
        final valor = atributo.value.trim().toLowerCase();

        if (nombre.startsWith('on') ||
            atributosProhibidos.contains(nombre)) {
          elemento.attributes.remove(atributo);
          continue;
        }

        if ((nombre == 'href' || nombre == 'src') &&
            valor.isNotEmpty &&
            !valor.startsWith('#')) {
          throw Exception(
            'El SVG contiene una referencia externa no permitida.',
          );
        }

        if (valor.contains('javascript:') ||
            valor.contains('expression(')) {
          throw Exception('El SVG contiene contenido no permitido.');
        }
      }

      // Elimina referencias a hojas de estilo externas o embebidas.
      if (elemento.name.local.toLowerCase() == 'style') {
        final css = elemento.innerText.toLowerCase();
        if (css.contains('@import') || css.contains('javascript:')) {
          throw Exception('El SVG contiene estilos no permitidos.');
        }
      }
    }

    // Arreglos para que el SVG se vea y se pueda escalar bien.
    _pasarClasesAEstilos(raiz);
    _ajustarTamanoSvg(raiz);
    for (final comentario
        in documento.descendants.whereType<XmlComment>().toList()) {
      comentario.remove();
    }
    for (final meta in raiz.findAllElements('metadata').toList()) {
      meta.remove();
    }

    return documento.toXmlString();
  }

  /// Si el SVG solo tiene width/height, le crea un viewBox
  /// y quita el tamaño fijo para que crezca o se achique sin cortarse.
  void _ajustarTamanoSvg(XmlElement raiz) {
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
      final css = style.innerText;
      for (final regla in RegExp(r'([^{}]+)\{([^}]*)\}').allMatches(css)) {
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

      final estilos = clases
          .split(RegExp(r'\s+'))
          .map((c) => reglas[c] ?? '')
          .join();
      if (estilos.isEmpty) continue;

      final propio = elemento.getAttribute('style') ?? '';
      elemento.setAttribute('style', '$estilos$propio');
    }
  }

  Future<void> _importarSvg() async {
    try {
      final resultado = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['svg'],
        withData: true,
      );

      if (resultado == null || resultado.files.isEmpty) return;

      final archivo = resultado.files.single;
      final bytes = archivo.bytes;

      if (bytes == null) {
        throw Exception('No se pudo leer el contenido del archivo.');
      }

      if (bytes.length > _maxSvgBytes) {
        throw Exception('El SVG supera el límite de 2 MB.');
      }

      final contenido = utf8.decode(bytes, allowMalformed: false);
      final seguro = _sanitizarSvg(contenido);

      if (!mounted) return;

      setState(() {
        _svgOriginal = seguro;
        _svgEditado = seguro;
        _svgEliminado = false;
        _mensajeEstado = 'SVG importado. Guarda para conservar los cambios.';
      });

      _aviso('SVG importado correctamente.');
    } catch (e) {
      _aviso('No se pudo importar el SVG: $e');
    }
  }

  void _eliminarSvg() {
    setState(() {
      _svgOriginal = null;
      _svgEditado = null;
      _svgEliminado = true;
      _mensajeEstado = 'SVG eliminado de la vista previa. Guarda para confirmar.';
    });
  }

  void _restaurarSvg() {
    setState(() {
      _svgEditado = _svgOriginal;
      _svgEliminado = false;
      _mensajeEstado = 'Se restauró el SVG cargado originalmente.';
    });
  }

  Widget _selectorColor({
    required String titulo,
    required Color color,
    required ValueChanged<Color> alCambiar,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(titulo),
      subtitle: Text(_hex(color)),
      trailing: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () => _seleccionarColor(
          titulo: titulo,
          inicial: color,
          alCambiar: alCambiar,
        ),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey),
          ),
          child: const Icon(Icons.colorize, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _seccion({
    required String titulo,
    required Widget contenido,
    IconData icono = Icons.tune,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            contenido,
          ],
        ),
      ),
    );
  }

  // Fuentes que ya trae el sistema (Windows/Web). En Android se usa una parecida.
  static const Set<String> _fuentesSistema = {
    'Arial', 'Verdana', 'Tahoma', 'Times New Roman', 'Georgia',
    'Courier New', 'Trebuchet MS', 'Impact',
  };

  /// Devuelve el estilo de texto para la tipografía elegida.
  /// Si es del sistema la usa directo; si no, la pide a Google Fonts.
  TextStyle _estiloFuente(
    String familia, {
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
  }) {
    final base = TextStyle(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
    );

    if (_fuentesSistema.contains(familia)) {
      return base.copyWith(
        fontFamily: familia,
        fontFamilyFallback: const ['sans-serif'],
      );
    }

    try {
      return GoogleFonts.getFont(familia, textStyle: base);
    } catch (_) {
      return base; // si la fuente no existe, usamos la normal
    }
  }

  Widget _vistaPrevia() {
    final estilo = _estiloFuente(
      _tipografia,
      fontSize: _tamanoFuente,
      color: _texto,
      fontWeight: FontWeight.w600,
    );

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 260),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _fondo,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'MI CUPONERA',
            textAlign: TextAlign.center,
            style: estilo.copyWith(
              fontSize: _tamanoFuente + 5,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tus beneficios favoritos, en un solo lugar',
            textAlign: TextAlign.center,
            style: estilo.copyWith(
              fontSize: _tamanoFuente * 0.72,
              fontWeight: FontWeight.normal,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 110 * _escalaSvg / 100,
            width: double.infinity,
            child: _svgEditado != null && !_svgEliminado
                ? Transform.translate(
                    offset: Offset(_posicionX, _posicionY),
                    child: Center(
                      child: Transform.scale(
                        scale: 1, // el tamaño ya se aplica abajo (se ve nítido)
                        child: SvgPicture.string(
                          _svgEditado!,
                          height: 100 * _escalaSvg / 100,
                          width: 150 * _escalaSvg / 100,
                          fit: BoxFit.contain,
                          placeholderBuilder: (_) => const Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  )
                : Icon(
                    Icons.workspace_premium,
                    size: 76,
                    color: _sello,
                  ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: _sello,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              'BENEFICIO DISPONIBLE',
              style: _estiloFuente(
                _tipografia,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _fondo,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diseñador de cuponera'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _seccion(
                titulo: 'Cuponera a editar',
                icono: Icons.confirmation_number_outlined,
                contenido: Column(
                  children: [
                    TextFormField(
                      controller: _idController,
                      decoration: const InputDecoration(
                        labelText: 'ID de la cuponera',
                        hintText: 'Introduce el ID existente',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.tag),
                      ),
                      validator: (valor) {
                        if (valor == null || valor.trim().isEmpty) {
                          return 'Introduce el ID de la cuponera.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _cargando ? null : _cargarDiseno,
                        icon: _cargando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.cloud_download_outlined),
                        label: const Text('Cargar diseño guardado'),
                      ),
                    ),
                  ],
                ),
              ),
              _seccion(
                titulo: 'Vista previa',
                icono: Icons.preview_outlined,
                contenido: _vistaPrevia(),
              ),
              _seccion(
                titulo: 'Colores',
                icono: Icons.palette_outlined,
                contenido: Column(
                  children: [
                    _selectorColor(
                      titulo: 'Fondo',
                      color: _fondo,
                      alCambiar: (c) => setState(() => _fondo = c),
                    ),
                    _selectorColor(
                      titulo: 'Texto',
                      color: _texto,
                      alCambiar: (c) => setState(() => _texto = c),
                    ),
                    _selectorColor(
                      titulo: 'Sello o acento',
                      color: _sello,
                      alCambiar: (c) => setState(() => _sello = c),
                    ),
                  ],
                ),
              ),
              _seccion(
                titulo: 'Tipografía',
                icono: Icons.text_fields,
                contenido: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _tipografia,
                      decoration: const InputDecoration(
                        labelText: 'Familia tipográfica',
                        border: OutlineInputBorder(),
                      ),
                      items: _tipografias
                          .map(
                            (nombre) => DropdownMenuItem(
                              value: nombre,
                              child: Text(nombre),
                            ),
                          )
                          .toList(),
                      onChanged: (valor) {
                        if (valor != null) {
                          setState(() => _tipografia = valor);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('Tamaño del texto: ${_tamanoFuente.round()}'),
                    Slider(
                      value: _tamanoFuente,
                      min: 10,
                      max: 40,
                      divisions: 30,
                      label: _tamanoFuente.round().toString(),
                      onChanged: (v) => setState(() => _tamanoFuente = v),
                    ),
                  ],
                ),
              ),
              _seccion(
                titulo: 'Gráfico SVG',
                icono: Icons.draw_outlined,
                contenido: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Importa un archivo .svg de hasta 2 MB. '
                      'La vista previa permite ajustar su tamaño y posición.',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _importarSvg,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Importar SVG'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _svgEditado == null
                              ? null
                              : _eliminarSvg,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Eliminar SVG'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _svgOriginal == null
                              ? null
                              : _restaurarSvg,
                          icon: const Icon(Icons.restore),
                          label: const Text('Restaurar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text('Tamaño del SVG: ${_escalaSvg.round()}%'),
                    Slider(
                      value: _escalaSvg,
                      min: 30,
                      max: 300,
                      divisions: 30,
                      label: '${_escalaSvg.round()}%',
                      onChanged: (v) => setState(() => _escalaSvg = v),
                    ),
                    Text('Posición horizontal: ${_posicionX.round()}'),
                    Slider(
                      value: _posicionX,
                      min: -100,
                      max: 100,
                      divisions: 40,
                      onChanged: (v) => setState(() => _posicionX = v),
                    ),
                    Text('Posición vertical: ${_posicionY.round()}'),
                    Slider(
                      value: _posicionY,
                      min: -100,
                      max: 100,
                      divisions: 40,
                      onChanged: (v) => setState(() => _posicionY = v),
                    ),
                    if (_svgEditado != null && !_svgEliminado)
                      const Text(
                        'SVG cargado. Recuerda guardar para conservar los cambios.',
                      ),
                  ],
                ),
              ),
              if (_mensajeEstado != null) ...[
                const SizedBox(height: 4),
                Text(
                  _mensajeEstado!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _guardando ? null : _guardarDiseno,
                  icon: _guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _guardando ? 'Guardando...' : 'Guardar diseño',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
