import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:zelloapp/core/theme/app_theme.dart';
import 'package:zelloapp/core/widgets/zello_logo.dart';

import '../../models/diseno_lienzo.dart';
import '../../models/elemento_diseno.dart';
import '../../widgets/lienzo_cuponera.dart';
import '../../widgets/barra_agregar.dart';
import '../../widgets/panel_propiedades.dart';
import '../../widgets/elemento_vista.dart';
import '../../widgets/panel_capas.dart';
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

  bool _cargando = true;
  int _totalVisitas = 6;
  List<int> _premiosIntermedios = [];

  bool _mostrarCuadricula = false;
  bool _imanActivado = true;
  bool _mostrarCapas = false;

  @override
  void initState() {
    super.initState();
    _cargarDisenoDesdeBD();
  }

  Future<void> _cargarDisenoDesdeBD() async {
    if (widget.cuponeraId == null || widget.cuponeraId!.isEmpty) {
      _generarSellosPorDefecto();
      setState(() => _cargando = false);
      return;
    }

    try {
      final data = await _cuponerasService.obtenerCuponeraDetalle(widget.cuponeraId!);

      setState(() {
        _totalVisitas = data['total_sellos_requeridos'] ?? 6;
        final premiosStr = data['premios_intermedios'];
        if (premiosStr != null && premiosStr.toString().isNotEmpty) {
          _premiosIntermedios = premiosStr
              .toString()
              .split(',')
              .map((e) => int.tryParse(e.trim()) ?? -1)
              .where((e) => e > 0)
              .toList();
        }

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
          _generarSellosPorDefecto();
        }
        _cargando = false;
      });
    } catch (e) {
      _generarSellosPorDefecto();
      setState(() => _cargando = false);
    }
  }

  void _generarSellosPorDefecto() {
    _diseno.elementos.clear();
    double startX = 28;
    double startY = 30;

    for (int i = 0; i < _totalVisitas; i++) {
      final esPremio = _premiosIntermedios.contains(i + 1) || i == _totalVisitas - 1;
      _diseno.elementos.add(
        ElementoDiseno(
          id: 'sello_base_$i',
          tipo: TipoElemento.sello,
          x: startX + ((i % 4) * 74),
          y: startY + ((i ~/ 4) * 74),
          ancho: 54,
          alto: 54,
          color: esPremio ? AppTheme.accentDeep : AppTheme.primaryColor,
          texto: '${i + 1}',
          tamanoFuente: 20,
          negrita: true,
          colorFondo: esPremio ? AppTheme.accentSoft : AppTheme.primarySoft,
          colorBorde: esPremio ? AppTheme.accentColor : AppTheme.primaryColor,
          grosorBorde: 2,
          radioBorde: 27,
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
        alto: 52,
        color: Colors.white,
        colorFondo: AppTheme.accentColor,
        radioBorde: 16,
        conSombra: true,
        texto: 'Generar QR',
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.tune_rounded, color: AppTheme.primaryColor),
            SizedBox(width: 10),
            Text(
              'Configurar Cuponera',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: tempVisitas.toString(),
              decoration: const InputDecoration(
                labelText: 'Total de visitas (Ej: 9)',
                prefixIcon: Icon(Icons.stars_rounded),
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) => tempVisitas = int.tryParse(val) ?? tempVisitas,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: tempPremios,
              decoration: const InputDecoration(
                labelText: 'Premios intermedios (Ej: 3, 6)',
                prefixIcon: Icon(Icons.redeem_rounded),
              ),
              onChanged: (val) => tempPremios = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
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

  void _agregarElemento(TipoElemento tipo, {String forma = 'cuadrado'}) {
    final nuevoElemento = ElementoDiseno(
      id: _uuid.v4(),
      tipo: tipo,
      forma: forma,
      x: 50,
      y: 50,
      ancho: 100,
      alto: 50,
      colorFondo: tipo == TipoElemento.forma
          ? AppTheme.primaryColor.withValues(alpha: 0.65)
          : Colors.transparent,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateBottomSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.78),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Vista Previa del Elemento',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkInk,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.16),
                        ),
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
                            if (elemento.id.startsWith('sello_base') ||
                                elemento.id == 'boton_qr_base') {
                              return;
                            }
                            final copia = ElementoDiseno(
                              id: _uuid.v4(),
                              tipo: elemento.tipo,
                              forma: elemento.forma,
                              x: elemento.x + 20,
                              y: elemento.y + 20,
                              ancho: elemento.ancho,
                              alto: elemento.alto,
                              texto: elemento.texto,
                              color: elemento.color,
                              tipografia: elemento.tipografia,
                              colorFondo: elemento.colorFondo,
                              colorBorde: elemento.colorBorde,
                              grosorBorde: elemento.grosorBorde,
                              radioBorde: elemento.radioBorde,
                              conSombra: elemento.conSombra,
                              svgContenido: elemento.svgContenido,
                            );
                            setState(() {
                              _diseno.elementos.add(copia);
                              _seleccionadoId = copia.id;
                            });
                            Navigator.pop(context);
                          },
                          alEliminar: () {
                            if (elemento.id.startsWith('sello_base') ||
                                elemento.id == 'boton_qr_base') {
                              return;
                            }
                            setState(() {
                              _diseno.elementos.remove(elemento);
                              _seleccionadoId = null;
                            });
                            Navigator.pop(context);
                          },
                          alTraerAlFrente: () => setState(() {
                            _diseno.elementos.remove(elemento);
                            _diseno.elementos.add(elemento);
                          }),
                          alEnviarAtras: () => setState(() {
                            _diseno.elementos.remove(elemento);
                            _diseno.elementos.insert(0, elemento);
                          }),
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

  Widget _buildHeaderToolButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool active = false,
    bool accentHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: accentHighlight
              ? AppTheme.accentColor
              : (active
                  ? Colors.white.withValues(alpha: 0.24)
                  : Colors.white.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(9.0),
              child: Icon(
                icon,
                size: 20,
                color: active && !accentHighlight ? AppTheme.accentBright : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _guardarDiseno() async {
    if (widget.cuponeraId == null || widget.cuponeraId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abre el editor desde "Administrar mi Local" para guardar en tu sucursal.'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      return;
    }
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Guardando diseño de cuponera...')),
    );
    try {
      await _cuponerasService.guardarDisenoCuponera(
        cuponeraId: widget.cuponeraId!,
        disenoJson: {'configuracion_ui': _diseno.toJson()},
        totalVisitas: _totalVisitas,
        premiosIntermedios:
            _premiosIntermedios.isNotEmpty ? _premiosIntermedios.join(',') : null,
      );
      if (!mounted) return;
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('¡Diseño guardado exitosamente!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: ZelloAmbientBackground(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Encabezado moderno Zello del Editor Visual
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 44, 18, 18),
                    decoration: BoxDecoration(
                      gradient: AppTheme.darkHeaderGradient,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryDeep.withValues(alpha: 0.24),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const ZelloLogo(size: 38),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ESTUDIO ZELLO',
                                style: TextStyle(
                                  color: AppTheme.accentBright,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                'Editor de Cuponera',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildHeaderToolButton(
                          icon: Icons.layers_rounded,
                          tooltip: 'Capas',
                          active: _mostrarCapas,
                          onPressed: () => setState(() => _mostrarCapas = !_mostrarCapas),
                        ),
                        _buildHeaderToolButton(
                          icon: _imanActivado
                              ? Icons.filter_center_focus_rounded
                              : Icons.open_with_rounded,
                          tooltip: 'Imán de alineación',
                          active: _imanActivado,
                          onPressed: () => setState(() => _imanActivado = !_imanActivado),
                        ),
                        _buildHeaderToolButton(
                          icon: _mostrarCuadricula
                              ? Icons.grid_on_rounded
                              : Icons.grid_off_rounded,
                          tooltip: 'Cuadrícula',
                          active: _mostrarCuadricula,
                          onPressed: () =>
                              setState(() => _mostrarCuadricula = !_mostrarCuadricula),
                        ),
                        _buildHeaderToolButton(
                          icon: Icons.tune_rounded,
                          tooltip: 'Configurar sellos',
                          onPressed: _abrirConfiguracion,
                        ),
                        _buildHeaderToolButton(
                          icon: Icons.save_rounded,
                          tooltip: 'Guardar diseño',
                          accentHighlight: true,
                          onPressed: _guardarDiseno,
                        ),
                      ],
                    ),
                  ),

                  // Área del lienzo interactivo
                  Expanded(
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryDeep.withValues(alpha: 0.08),
                                  blurRadius: 22,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: CustomPaint(
                              painter: _BordePunteadoPainter(),
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: LienzoCuponera(
                                    diseno: _diseno,
                                    seleccionadoId: _seleccionadoId,
                                    alSeleccionar: (id) =>
                                        setState(() => _seleccionadoId = id),
                                    alCambiar: _actualizar,
                                    mostrarCuadricula: _mostrarCuadricula,
                                    imanActivado: _imanActivado,
                                    alAbrirEditor: (id) => _mostrarEditorPropiedades(
                                      _diseno.elementos.firstWhere((e) => e.id == id),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_mostrarCapas)
                          Positioned(
                            right: 12,
                            top: 12,
                            bottom: 12,
                            width: 260,
                            child: Material(
                              elevation: 16,
                              borderRadius: BorderRadius.circular(24),
                              clipBehavior: Clip.antiAlias,
                              color: Colors.white,
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: const BoxDecoration(
                                      gradient: AppTheme.brandGradient,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(
                                              Icons.layers_rounded,
                                              color: AppTheme.accentBright,
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Capas del Lienzo',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        InkWell(
                                          onTap: () =>
                                              setState(() => _mostrarCapas = false),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: PanelCapas(
                                      diseno: _diseno,
                                      seleccionadoId: _seleccionadoId,
                                      alSeleccionar: (id) =>
                                          setState(() => _seleccionadoId = id),
                                      alCambiar: () => setState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Barra flotante de herramientas para agregar elementos
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                    child: BarraAgregar(
                      alAgregarTexto: () => _agregarElemento(TipoElemento.texto),
                      alAgregarSvg: () => _agregarElemento(TipoElemento.svg),
                      alAgregarCuadrado: () =>
                          _agregarElemento(TipoElemento.forma, forma: 'cuadrado'),
                      alAgregarCirculo: () =>
                          _agregarElemento(TipoElemento.forma, forma: 'circulo'),
                      alAgregarTriangulo: () =>
                          _agregarElemento(TipoElemento.forma, forma: 'triangulo'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BordePunteadoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryColor.withValues(alpha: 0.28)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const double dashWidth = 8, dashSpace = 6;
    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(24),
        ),
      );
    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      double distance = 0;
      while (distance < pathMetric.length) {
        canvas.drawPath(pathMetric.extractPath(distance, distance + dashWidth), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
