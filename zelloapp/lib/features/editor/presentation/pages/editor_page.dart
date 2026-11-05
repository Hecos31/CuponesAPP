import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:zelloapp/core/theme/app_theme.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:convert';

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
  final DisenoLienzo _diseno = DisenoLienzo(fondo: Colors.grey.shade100);
  final CuponerasService _cuponerasService = CuponerasService();
  final _uuid = const Uuid();
  
  String? _seleccionadoId;
  bool _cargando = true;
  bool _mostrarCuadricula = false;
  bool _imanActivado = true;
  bool _mostrarCapas = false;
  
  int _totalVisitas = 6;
  List<int> _premiosIntermedios = [];

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
          elementosJson = (confUi.containsKey('configuracion_ui') && confUi['configuracion_ui'] is Map) 
              ? confUi['configuracion_ui']['elementos'] 
              : confUi['elementos'];
        }
        
        if (elementosJson != null && elementosJson.isNotEmpty) {
          _diseno.elementos = elementosJson.map((e) => ElementoDiseno.fromJson(e as Map<String, dynamic>)).toList();
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
          color: esPremio ? Colors.white : Colors.blueGrey.shade800,
          texto: '${i + 1}',
          tamanoFuente: 20,
          negrita: true,
          colorFondo: esPremio ? AppTheme.accentColor : Colors.white,
          colorBorde: esPremio ? AppTheme.accentDeep : Colors.blueGrey.shade200,
          grosorBorde: 2,
          radioBorde: 27,
          conSombra: true,
        ),
      );
    }

    _diseno.elementos.add(
      ElementoDiseno(
        id: 'boton_qr_base',
        tipo: TipoElemento.botonQr,
        x: 30,
        y: 480,
        ancho: 300,
        alto: 55,
        color: Colors.white,
        colorFondo: AppTheme.accentColor,
        radioBorde: 16,
        conSombra: true,
        texto: 'Generar QR',
        negrita: true,
        tamanoFuente: 18,
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

  void _agregarElemento(TipoElemento tipo, {String forma = 'cuadrado'}) {
    double anchoInicial = 100;
    double altoInicial = tipo == TipoElemento.texto ? 40 : 100;

    double centroX = (DisenoLienzo.ancho - anchoInicial) / 2;
    double centroY = (DisenoLienzo.alto - altoInicial) / 2;

    String? svgPrueba;
    if (tipo == TipoElemento.svg) {
      svgPrueba = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="currentColor" d="M13.13 22.19L11.5 18.36C13.07 17.78 14.54 17 15.9 16.09L13.13 22.19M5.64 12.5L1.81 10.87L7.91 8.1C7 9.46 6.22 10.93 5.64 12.5M21.61 2.39C21.61 2.39 16.66 .269 11 5.93C8.81 8.12 7.5 11.38 6.53 13.56L3.93 14.65C3.39 14.88 3.14 15.5 3.37 16.05C3.54 16.44 3.96 16.69 4.39 16.63L7.71 16.14C8.07 17.5 8.65 18.79 9.46 20C9.8 20.47 10.45 20.59 10.94 20.27C11.16 20.12 11.3 19.9 11.35 19.66L11.86 16.29C13.21 15.35 14.5 14.41 15.5 13.2C21.43 7.28 19.12 2.11 19.12 2.11L21.61 2.39Z"/></svg>';
    }

    final nuevo = ElementoDiseno(
      id: _uuid.v4(),
      tipo: tipo,
      forma: forma,
      x: centroX,
      y: centroY,
      ancho: anchoInicial,
      alto: altoInicial,
      colorFondo: tipo == TipoElemento.forma ? Colors.blueAccent.withOpacity(0.2) : Colors.transparent,
      radioBorde: 8,
      svgContenido: svgPrueba,
    );
    
    setState(() {
      _diseno.elementos.add(nuevo);
      _seleccionadoId = nuevo.id;
    });
  }

  void _mostrarEditorPropiedades(ElementoDiseno elemento) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: IgnorePointer(
                      child: ElementoVista(elemento: elemento, escala: 1.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: PanelPropiedades(
                      elemento: elemento,
                      alCambiar: () {
                        setState(() {});
                        setSheet(() {});
                      },
                      alCambiarSvg: () async {
                        try {
                          const XTypeGroup typeGroup = XTypeGroup(
                            label: 'Imágenes SVG',
                            extensions: ['svg'],
                          );
                          final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

                          if (file != null) {
                            final bytes = await file.readAsBytes();
                            final String svgString = utf8.decode(bytes);
                            setState(() {
                              elemento.svgContenido = svgString;
                            });
                            setSheet(() {});
                          }
                        } catch (e) {
                          debugPrint('Error al seleccionar SVG: $e');
                        }
                      },
                      alDuplicar: () {
                        if (elemento.id.startsWith('sello_base') || elemento.id == 'boton_qr_base') return;
                        
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
                        Navigator.pop(ctx);
                      },
                      alEliminar: () {
                        if (elemento.id.startsWith('sello_base') || elemento.id == 'boton_qr_base') return;
                        
                        setState(() {
                          _diseno.elementos.remove(elemento);
                          _seleccionadoId = null;
                        });
                        Navigator.pop(ctx);
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
          );
        },
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
        premiosIntermedios: _premiosIntermedios.isNotEmpty ? _premiosIntermedios.join(',') : null,
      );
      
      if (!mounted) return;
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('¡Diseño guardado exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EEF2),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text('Editor Visual', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.layers_outlined, color: _mostrarCapas ? Colors.blueAccent : Colors.grey.shade600),
            onPressed: () => setState(() => _mostrarCapas = !_mostrarCapas),
          ),
          IconButton(
            icon: Icon(_imanActivado ? Icons.filter_center_focus : Icons.open_with, color: _imanActivado ? Colors.blueAccent : Colors.grey.shade600),
            onPressed: () => setState(() => _imanActivado = !_imanActivado),
          ),
          IconButton(
            icon: Icon(_mostrarCuadricula ? Icons.grid_on : Icons.grid_off, color: Colors.grey.shade600),
            onPressed: () => setState(() => _mostrarCuadricula = !_mostrarCuadricula),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _abrirConfiguracion,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: FilledButton.icon(
              onPressed: _guardarDiseno,
              icon: const Icon(Icons.cloud_upload_outlined, size: 18),
              label: const Text('Guardar'),
            ),
          )
        ],
      ),
      body: _cargando 
          ? const Center(child: CircularProgressIndicator()) 
          : Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 100, top: 16),
                          child: AspectRatio(
                            aspectRatio: 9 / 16,
                            child: LienzoCuponera(
                              diseno: _diseno,
                              seleccionadoId: _seleccionadoId,
                              alSeleccionar: (id) => setState(() => _seleccionadoId = id),
                              alCambiar: () => setState(() {}),
                              mostrarCuadricula: _mostrarCuadricula,
                              imanActivado: _imanActivado,
                              alAbrirEditor: (id) => _mostrarEditorPropiedades(_diseno.elementos.firstWhere((e) => e.id == id)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 20, left: 0, right: 0,
                  child: SafeArea(
                    child: BarraAgregar(
                      alAgregarTexto: () => _agregarElemento(TipoElemento.texto),
                      alAgregarSvg: () => _agregarElemento(TipoElemento.svg),
                      alAgregarCuadrado: () => _agregarElemento(TipoElemento.forma, forma: 'cuadrado'),
                      alAgregarCirculo: () => _agregarElemento(TipoElemento.forma, forma: 'circulo'),
                      alAgregarTriangulo: () => _agregarElemento(TipoElemento.forma, forma: 'triangulo'),
                    ),
                  ),
                ),
                if (_mostrarCapas)
                  Positioned(
                    right: 0, top: 0, bottom: 0, width: 280,
                    child: Material(
                      elevation: 16, 
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                      child: Column(
                        children: [
                          AppBar(
                            title: const Text('Gestión de Capas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            automaticallyImplyLeading: false,
                            actions: [
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => setState(() => _mostrarCapas = false),
                              )
                            ],
                          ),
                          Expanded(
                            child: PanelCapas(
                              diseno: _diseno,
                              seleccionadoId: _seleccionadoId,
                              alSeleccionar: (id) => setState(() => _seleccionadoId = id),
                              alCambiar: () => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}