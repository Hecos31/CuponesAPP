import 'package:flutter/material.dart';

import '../../../disenocuponeras/diseno_cuponera_service.dart';
import '../../../disenocuponeras/models/diseno_lienzo.dart';
import '../../../disenocuponeras/models/elemento_diseno.dart';
import '../../../disenocuponeras/utils/svg_utils.dart';
import '../../../disenocuponeras/widgets/barra_agregar.dart';
import '../../../disenocuponeras/widgets/lienzo_cuponera.dart';
import '../../../disenocuponeras/widgets/panel_capas.dart';
import '../../../disenocuponeras/widgets/panel_propiedades.dart';
import '../../../disenocuponeras/widgets/selector_color.dart';


class DisenoCuponeraPage extends StatefulWidget {
  const DisenoCuponeraPage({super.key, this.cuponeraIdInicial});

  final String? cuponeraIdInicial;

  @override
  State<DisenoCuponeraPage> createState() => _DisenoCuponeraPageState();
}

class _DisenoCuponeraPageState extends State<DisenoCuponeraPage> {
  final _idController = TextEditingController();
  final _service = DisenoCuponeraService();

  DisenoLienzo _diseno = DisenoLienzo.porDefecto();
  String? _seleccionadoId;

  bool _cargando = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final id = widget.cuponeraIdInicial?.trim();
    if (id != null && id.isNotEmpty) {
      _idController.text = id;
      WidgetsBinding.instance.addPostFrameCallback((_) => _cargarDiseno());
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _service.cerrar();
    super.dispose();
  }

  ElementoDiseno? get _seleccionado {
    for (final e in _diseno.elementos) {
      if (e.id == _seleccionadoId) return e;
    }
    return null;
  }

  void _aviso(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  /// Agrega un elemento al frente y lo deja seleccionado.
  void _agregar(ElementoDiseno elemento) {
    setState(() {
      _diseno.elementos.add(elemento);
      _seleccionadoId = elemento.id;
    });
  }

  /// Abre el selector de archivos. Regresa null si cancela o falla.
  Future<String?> _pedirSvg() async {
    try {
      return await elegirSvgDelDispositivo();
    } catch (e) {
      _aviso('No se pudo usar el SVG: ${e.toString().replaceFirst('Exception: ', '')}');
      return null;
    }
  }
  // Agregar elementos

  void _agregarTexto() {
    _agregar(ElementoDiseno(
      id: nuevoIdElemento(),
      tipo: TipoElemento.texto,
      texto: 'Nuevo texto',
      x: 80,
      y: 85,
      ancho: 200,
      alto: 50,
    ));
  }

  Future<void> _agregarSvg() async {
    final svg = await _pedirSvg();
    if (svg == null) return;

    _agregar(ElementoDiseno(
      id: nuevoIdElemento(),
      tipo: TipoElemento.svg,
      svg: svg,
      x: 120,
      y: 50,
      ancho: 120,
      alto: 120,
    ));
  }

  void _agregarSello() {
    _agregar(ElementoDiseno(
      id: nuevoIdElemento(),
      tipo: TipoElemento.sello,
      color: const Color(0xFFFBBF24),
      x: 145,
      y: 75,
      ancho: 70,
      alto: 70,
    ));
  }

  // Acciones sobre el elemento seleccionado
  Future<void> _cambiarSvg(ElementoDiseno elemento) async {
    final svg = await _pedirSvg();
    if (svg == null) return;
    setState(() => elemento.svg = svg);
  }

  void _duplicar(ElementoDiseno elemento) {
    _agregar(elemento.copiar());
  }

  void _eliminar(ElementoDiseno elemento) {
    setState(() {
      _diseno.elementos.remove(elemento);
      _seleccionadoId = null;
    });
  }

  void _traerAlFrente(ElementoDiseno elemento) {
    setState(() {
      _diseno.elementos
        ..remove(elemento)
        ..add(elemento);
    });
  }

  void _enviarAtras(ElementoDiseno elemento) {
    setState(() {
      _diseno.elementos
        ..remove(elemento)
        ..insert(0, elemento);
    });
  }
  // Cargar y guardar en el backend
  bool _hayId() {
    if (_idController.text.trim().isEmpty) {
      _aviso('Escribe el ID de la cuponera.');
      return false;
    }
    return true;
  }

  Future<void> _cargarDiseno() async {
    if (!_hayId()) return;
    setState(() => _cargando = true);

    try {
      final respuesta = await _service.obtener(_idController.text.trim());
      final config = respuesta['configuracion_ui'] is Map
          ? Map<String, dynamic>.from(respuesta['configuracion_ui'] as Map)
          : <String, dynamic>{};

      if (!mounted) return;
      setState(() {
        _diseno = DisenoLienzo.desdeJson(
          config,
          svgAnterior: respuesta['svg_markup'] as String?,
        );
        _seleccionadoId = null;
      });
      _aviso('Diseño cargado.');
    } catch (e) {
      _aviso('No se pudo cargar el diseño: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _guardarDiseno() async {
    if (!_hayId()) return;
    setState(() => _guardando = true);

    try {
      await _service.guardar(
        cuponeraId: _idController.text.trim(),
        configuracion: _diseno.toJson(),
        // Los SVG ahora viajan dentro de cada elemento.
        // Borramos el SVG suelto del formato viejo para no duplicarlo.
        eliminarSvg: true,
      );
      _aviso('Diseño guardado correctamente.');
    } catch (e) {
      _aviso('No se pudo guardar el diseño: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
  // Pantalla
  @override
  Widget build(BuildContext context) {
    final seleccionado = _seleccionado;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diseñador de cuponera'),
        actions: [
          IconButton(
            tooltip: 'Guardar',
            onPressed: _guardando ? null : _guardarDiseno,
            icon: _guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
          ),
        ],
      ),
      body: Column(
        children: [
          // ID de la cuponera + botón de cargar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _idController,
                    decoration: const InputDecoration(
                      labelText: 'ID de la cuponera',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Cargar diseño guardado',
                  onPressed: _cargando ? null : _cargarDiseno,
                  icon: _cargando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                ),
              ],
            ),
          ),

          // El lienzo queda fijo arriba (fuera del scroll) para que
          // arrastrar elementos no mueva la pantalla.
          Padding(
            padding: const EdgeInsets.all(16),
            child: LienzoCuponera(
              diseno: _diseno,
              seleccionadoId: _seleccionadoId,
              alSeleccionar: (id) => setState(() => _seleccionadoId = id),
              alCambiar: () => setState(() {}),
            ),
          ),

          BarraAgregar(
            alAgregarTexto: _agregarTexto,
            alAgregarSvg: _agregarSvg,
            alAgregarSello: _agregarSello,
          ),
          const SizedBox(height: 8),

          // Opciones (con scroll)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: seleccionado == null
                        ? SelectorColor(
                            titulo: 'Color de fondo de la cuponera',
                            color: _diseno.fondo,
                            alCambiar: (color) =>
                                setState(() => _diseno.fondo = color),
                          )
                        : PanelPropiedades(
                            elemento: seleccionado,
                            alCambiar: () => setState(() {}),
                            alCambiarSvg: () => _cambiarSvg(seleccionado),
                            alDuplicar: () => _duplicar(seleccionado),
                            alEliminar: () => _eliminar(seleccionado),
                            alTraerAlFrente: () => _traerAlFrente(seleccionado),
                            alEnviarAtras: () => _enviarAtras(seleccionado),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'Capas',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        PanelCapas(
                          elementos: _diseno.elementos,
                          seleccionadoId: _seleccionadoId,
                          alSeleccionar: (id) =>
                              setState(() => _seleccionadoId = id),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
