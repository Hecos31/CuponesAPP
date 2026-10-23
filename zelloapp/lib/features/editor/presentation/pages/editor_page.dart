import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/diseno_lienzo.dart';
import '../../models/elemento_diseno.dart';
// Corregido el import de widgets según la ruta relativa correcta de tu estructura
import '../../widgets/lienzo_cuponera.dart';
import '../../widgets/barra_agregar.dart';
import '../../widgets/panel_propiedades.dart';
import '../../widgets/elemento_vista.dart';
import '../../../cuponeras/services/cuponeras_service.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key, this.cuponeraId});

  final String? cuponeraId;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final DisenoLienzo _diseno = DisenoLienzo();
  final CuponerasService _cuponerasService = CuponerasService();
  String? _seleccionadoId;
  final _uuid = const Uuid();

  bool _cargando = true; // Control de carga inicial desde la BD
  int _totalVisitas = 6;
  List<int> _premiosIntermedios = [];

  bool _mostrarCuadricula = false;
  bool _imanActivado = true;

  @override
  void initState() {
    super.initState();
    _cargarDisenoDesdeBD();
  }

  // CARGAR DISEÑO Y REGLAS DESDE LA BASE DE DATOS
  Future<void> _cargarDisenoDesdeBD() async {
    if (widget.cuponeraId == null || widget.cuponeraId!.isEmpty) {
      _generarSellosPorDefecto();
      setState(() => _cargando = false);
      return;
    }

    try {
      final data = await _cuponerasService.obtenerCuponeraDetalle(widget.cuponeraId!);
      print('📦 Datos recibidos del backend: $data'); // Útil para depurar en la consola

      setState(() {
        _totalVisitas = data['total_sellos_requeridos'] ?? 6;

        final premiosStr = data['premios_intermedios'];
        if (premiosStr != null && premiosStr.toString().isNotEmpty) {
          _premiosIntermedios = premiosStr.toString()
              .split(',')
              .map((e) => int.tryParse(e.trim()) ?? -1)
              .where((e) => e > 0)
              .toList();
        }

        // Extracción flexible de elementos sin importar el nivel de anidación
        final dynamic confUi = data['configuracion_ui'];
        List<dynamic>? elementosJson;

        if (confUi is Map) {
          if (confUi.containsKey('configuracion_ui') && confUi['configuracion_ui'] is Map) {
            elementosJson = confUi['configuracion_ui']['elementos'];
          } else if (confUi.containsKey('elementos')) {
            elementosJson = confUi['elementos'];
          }
        }

        if (elementosJson != null && elementosJson.isNotEmpty) {
          _diseno.elementos = elementosJson
              .map((e) => ElementoDiseno.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          // Si no hay elementos guardados aún, cargamos la plantilla base
          _generarSellosPorDefecto();
        }

        _cargando = false;
      });
    } catch (e) {
      print('❌ Error al cargar diseño de BD: $e'); // Muestra el error real en consola
      _generarSellosPorDefecto();
      setState(() => _cargando = false);
    }
  }

  void _generarSellosPorDefecto() {
    _diseno.elementos.clear();
    double startX = 20;
    double startY = 20;

    for (int i = 0; i < _totalVisitas; i++) {
      final esPremio = _premiosIntermedios.contains(i + 1) || i == _totalVisitas - 1;
      _diseno.elementos.add(
        ElementoDiseno(
          id: 'sello_base_$i',
          tipo: TipoElemento.sello,
          x: startX + ((i % 4) * 70),
          y: startY + ((i ~/ 4) * 70),
          ancho: 50,
          alto: 50,
          color: esPremio ? Colors.red : Colors.black87,
          texto: '${i + 1}',
          tamanoFuente: 20,
          tipografia: 'Roboto',
          colorFondo: Colors.transparent,
          colorBorde: esPremio ? Colors.red : Colors.black87,
          grosorBorde: 2,
          radioBorde: 25, 
        ),
      );
    }

    _diseno.elementos.add(
      ElementoDiseno(
        id: 'boton_qr_base',
        tipo: TipoElemento.botonQr,
        x: 30,
        y: 500,
        ancho: 300,
        alto: 50,
        color: Colors.white,
        colorFondo: Colors.orange,
        radioBorde: 12,
        conSombra: true,
        texto: 'Generar QR',
        tamanoFuente: 20,
        tipografia: 'Roboto',
        negrita: true,
      ),
    );
  }

  Future<void> _abrirConfiguracion() async {
    int tempVisitas = _totalVisitas;
    String tempPremios = _premiosIntermedios.join(', ');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configurar Cuponera'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: tempVisitas.toString(),
              decoration: const InputDecoration(labelText: 'Total de visitas (Ej: 9)'),
              keyboardType: TextInputType.number,
              onChanged: (val) => tempVisitas = int.tryParse(val) ?? tempVisitas,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: tempPremios,
              decoration: const InputDecoration(labelText: 'Premios intermedios (Ej: 3, 6)'),
              onChanged: (val) {
                tempPremios = val;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _totalVisitas = tempVisitas;
                _premiosIntermedios = tempPremios
                    .split(',')
                    .map((e) => int.tryParse(e.trim()) ?? -1)
                    .where((e) => e > 0)
                    .toList();
                _generarSellosPorDefecto();
              });
              Navigator.pop(ctx);
            },
            child: const Text('Aplicar y Regenerar'),
          ),
        ],
      ),
    );
  }

  void _actualizar() => setState(() {});

  void _agregarElemento(TipoElemento tipo) {
    final nuevoElemento = ElementoDiseno(
      id: _uuid.v4(),
      tipo: tipo,
      x: 50,
      y: 50,
      ancho: 100,
      alto: 50,
    );
    setState(() {
      _diseno.elementos.add(nuevoElemento);
      _seleccionadoId = nuevoElemento.id;
    });
  }

  void _mostrarEditorPropiedades(ElementoDiseno elemento) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateBottomSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Vista Previa', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: IgnorePointer(
                              child: ElementoVista(elemento: elemento, escala: 1.0),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: PanelPropiedades(
                          elemento: elemento,
                          alCambiar: () {
                            _actualizar();
                            setStateBottomSheet(() {});
                          },
                          alCambiarSvg: () {},
                          alDuplicar: () {
                            if (elemento.id.startsWith('sello_base') || elemento.id == 'boton_qr_base') return;
                            final copia = ElementoDiseno(
                              id: _uuid.v4(), tipo: elemento.tipo, x: elemento.x + 20, y: elemento.y + 20,
                              ancho: elemento.ancho, alto: elemento.alto, texto: elemento.texto,
                              color: elemento.color, tipografia: elemento.tipografia, colorFondo: elemento.colorFondo,
                              colorBorde: elemento.colorBorde, grosorBorde: elemento.grosorBorde, radioBorde: elemento.radioBorde,
                              conSombra: elemento.conSombra,
                            );
                            setState(() { _diseno.elementos.add(copia); _seleccionadoId = copia.id; });
                            Navigator.pop(context);
                          },
                          alEliminar: () {
                            if (elemento.id.startsWith('sello_base') || elemento.id == 'boton_qr_base') return;
                            setState(() { _diseno.elementos.remove(elemento); _seleccionadoId = null; });
                            Navigator.pop(context);
                          },
                          alTraerAlFrente: () => setState(() { _diseno.elementos.remove(elemento); _diseno.elementos.add(elemento); }),
                          alEnviarAtras: () => setState(() { _diseno.elementos.remove(elemento); _diseno.elementos.insert(0, elemento); }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        title: const Text('Editor de Cuponera'),
        actions: [
          IconButton(
            icon: Icon(_imanActivado ? Icons.filter_center_focus : Icons.open_with),
            color: _imanActivado ? Colors.blue : Colors.grey,
            tooltip: 'Imán a cuadrícula',
            onPressed: () => setState(() => _imanActivado = !_imanActivado),
          ),
          IconButton(
            icon: Icon(_mostrarCuadricula ? Icons.grid_on : Icons.grid_off),
            tooltip: 'Alternar cuadrícula',
            onPressed: () => setState(() => _mostrarCuadricula = !_mostrarCuadricula),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configurar visitas',
            onPressed: _abrirConfiguracion,
          ),
          // Botón de guardar conectado al backend
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Guardar',
            onPressed: () async {
              final String? cuponeraIdReal = widget.cuponeraId; 

              if (cuponeraIdReal == null || cuponeraIdReal.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error: No se encontró el ID de la cuponera a guardar.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final scaffoldMessenger = ScaffoldMessenger.of(context);
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Guardando diseño en la base de datos...')),
              );

              try {
                final Map<String, dynamic> disenoJsonCompleto = {
                  'configuracion_ui': _diseno.toJson(),
                };

                await _cuponerasService.guardarDisenoCuponera(
                  cuponeraId: cuponeraIdReal,
                  disenoJson: disenoJsonCompleto,
                  totalVisitas: _totalVisitas,
                  premiosIntermedios: _premiosIntermedios.isNotEmpty 
                      ? _premiosIntermedios.join(',') 
                      : null,
                );

                if (!mounted) return;

                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('¡Diseño guardado y publicado con éxito!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Error al guardar: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CustomPaint(
                      painter: _BordePunteadoPainter(),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: LienzoCuponera(
                          diseno: _diseno,
                          seleccionadoId: _seleccionadoId,
                          alSeleccionar: (id) => setState(() => _seleccionadoId = id),
                          alCambiar: _actualizar,
                          mostrarCuadricula: _mostrarCuadricula,
                          imanActivado: _imanActivado,
                          alAbrirEditor: (id) {
                            final elemento = _diseno.elementos.firstWhere((e) => e.id == id);
                            _mostrarEditorPropiedades(elemento);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                BarraAgregar(
                  alAgregarTexto: () => _agregarElemento(TipoElemento.texto),
                  alAgregarSvg: () => _agregarElemento(TipoElemento.svg),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }
}

class _BordePunteadoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const double dashWidth = 8;
    const double dashSpace = 6;

    Path path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      double distance = 0;
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}