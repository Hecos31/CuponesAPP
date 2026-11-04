import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../cuponeras/services/cuponeras_service.dart';
import '../../models/local_mapa_model.dart';
import '../../widgets/lienzo_mapa_interactivo.dart';

class MapaPage extends StatefulWidget {
  final String? localSeleccionadoIdInicial;

  const MapaPage({super.key, this.localSeleccionadoIdInicial});

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  final CuponerasService _cuponerasService = CuponerasService();
  final TransformationController _mapController = TransformationController();
  final TextEditingController _busquedaController = TextEditingController();

  static const List<String> _categorias = [
    'Todos',
    'Cafeterías',
    'Restaurantes',
    'Postres',
    'Tiendas',
  ];

  List<LocalMapaModel> _todosLosLocales = localesCercanosDemostracion;
  String _categoriaSeleccionada = 'Todos';
  String _textoBusqueda = '';
  LocalMapaModel? _localSeleccionado;
  Size _viewportSize = const Size(380, 500);

  @override
  void initState() {
    super.initState();
    _inicializarSeleccion();
    _cargarLocalesConCuponerasReales();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_localSeleccionado != null) {
        _centrarEnPosicion(_localSeleccionado!.posicionMapa);
      } else {
        _centrarEnPosicion(LienzoMapaInteractivo.posicionUsuario);
      }
    });
  }

  void _inicializarSeleccion() {
    if (widget.localSeleccionadoIdInicial != null) {
      for (final l in _todosLosLocales) {
        if (l.id == widget.localSeleccionadoIdInicial) {
          _localSeleccionado = l;
          return;
        }
      }
    }
    _localSeleccionado = _todosLosLocales.first;
  }

  Future<void> _cargarLocalesConCuponerasReales() async {
    try {
      final cuponerasReales = await _cuponerasService
          .obtenerCuponerasDisponibles();
      if (!mounted) return;
      final combinados = construirListaLocalesCercanos(cuponerasReales);

      setState(() {
        _todosLosLocales = combinados;
        if (widget.localSeleccionadoIdInicial != null) {
          for (final l in combinados) {
            if (l.id == widget.localSeleccionadoIdInicial) {
              _localSeleccionado = l;
              break;
            }
          }
        }
        _localSeleccionado ??= combinados.isNotEmpty ? combinados.first : null;
      });

      if (_localSeleccionado != null) {
        _centrarEnPosicion(_localSeleccionado!.posicionMapa);
      }
    } catch (_) {
      // Si el servidor no responde, conservamos los locales de demostración
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _busquedaController.dispose();
    super.dispose();
  }

  List<LocalMapaModel> get _localesFiltrados {
    return _todosLosLocales.where((local) {
      final coincideCategoria =
          _categoriaSeleccionada == 'Todos' ||
          local.categoria == _categoriaSeleccionada;

      final q = _textoBusqueda.trim().toLowerCase();
      final coincideTexto =
          q.isEmpty ||
          local.nombre.toLowerCase().contains(q) ||
          local.direccion.toLowerCase().contains(q) ||
          local.tituloPromocion.toLowerCase().contains(q) ||
          local.descripcionPremio.toLowerCase().contains(q);

      return coincideCategoria && coincideTexto;
    }).toList();
  }

  void _centrarEnPosicion(Offset posicionNormalizada, {double escala = 1.05}) {
    final targetX = posicionNormalizada.dx * LienzoMapaInteractivo.anchoMapa;
    final targetY = posicionNormalizada.dy * LienzoMapaInteractivo.altoMapa;

    final dx = (_viewportSize.width / 2) - (targetX * escala);
    final dy = (_viewportSize.height / 2) - (targetY * escala) - 35;

    final matrix = Matrix4.identity()
      ..translateByDouble(dx, dy, 0.0, 1.0)
      ..scaleByDouble(escala, escala, 1.0, 1.0);
    _mapController.value = matrix;
  }

  void _cambiarZoom(double factor) {
    final escalaActual = _mapController.value.getMaxScaleOnAxis();
    final nuevaEscala = (escalaActual * factor).clamp(0.6, 2.3);
    final objetivo =
        _localSeleccionado?.posicionMapa ??
        LienzoMapaInteractivo.posicionUsuario;
    _centrarEnPosicion(objetivo, escala: nuevaEscala);
  }

  void _seleccionarLocal(LocalMapaModel local) {
    setState(() => _localSeleccionado = local);
    _centrarEnPosicion(local.posicionMapa, escala: 1.15);
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _localesFiltrados;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Locales'),
        actions: [
          IconButton(
            tooltip: 'Centrar en mi ubicación',
            icon: const Icon(Icons.my_location_rounded),
            onPressed: () {
              setState(() => _localSeleccionado = null);
              _centrarEnPosicion(
                LienzoMapaInteractivo.posicionUsuario,
                escala: 1.0,
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);

          return Stack(
            children: [
              // 1. Lienzo del mapa interactivo
              Positioned.fill(
                child: LienzoMapaInteractivo(
                  transformationController: _mapController,
                  locales: filtrados,
                  localSeleccionado: _localSeleccionado,
                  onPinTap: _seleccionarLocal,
                  onFondoTap: () => setState(() => _localSeleccionado = null),
                ),
              ),

              // 2. Buscador y filtros flotantes superiores
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _busquedaController,
                        onChanged: (valor) {
                          setState(() => _textoBusqueda = valor);
                        },
                        decoration: InputDecoration(
                          hintText: 'Buscar local, calle o beneficio...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _textoBusqueda.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _busquedaController.clear();
                                    setState(() => _textoBusqueda = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categorias.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final cat = _categorias[index];
                          final activa = cat == _categoriaSeleccionada;
                          return ChoiceChip(
                            label: Text(cat),
                            selected: activa,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: activa
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: activa
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                            ),
                            selectedColor: const Color(0xFF0F172A),
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.94,
                            ),
                            onSelected: (_) {
                              setState(() {
                                _categoriaSeleccionada = cat;
                                final nuevos = _localesFiltrados;
                                if (nuevos.isNotEmpty) {
                                  _seleccionarLocal(nuevos.first);
                                } else {
                                  _localSeleccionado = null;
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Botones flotantes de Zoom (+/-) y ubicación
              Positioned(
                right: 14,
                bottom: _localSeleccionado != null ? 210 : 140,
                child: Column(
                  children: [
                    _BotonControlMapa(
                      icono: Icons.add_rounded,
                      tooltip: 'Acercar',
                      onTap: () => _cambiarZoom(1.22),
                    ),
                    const SizedBox(height: 8),
                    _BotonControlMapa(
                      icono: Icons.remove_rounded,
                      tooltip: 'Alejar',
                      onTap: () => _cambiarZoom(0.82),
                    ),
                    const SizedBox(height: 8),
                    _BotonControlMapa(
                      icono: Icons.near_me_rounded,
                      tooltip: 'Mi ubicación',
                      colorIcono: Colors.blue.shade700,
                      onTap: () => _centrarEnPosicion(
                        LienzoMapaInteractivo.posicionUsuario,
                        escala: 1.05,
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Panel inferior con la tarjeta del local seleccionado o carrusel
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _localSeleccionado != null
                    ? _TarjetaDetalleLocalMapa(
                        local: _localSeleccionado!,
                        onCerrar: () =>
                            setState(() => _localSeleccionado = null),
                        onVerCuponera: () {
                          context.push(
                            '/cuponeras/detalle',
                            extra: _localSeleccionado!.toCuponeraDetailMap(),
                          );
                        },
                      )
                    : _CarruselMiniLocalesMapa(
                        locales: filtrados,
                        onSelect: _seleccionarLocal,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BotonControlMapa extends StatelessWidget {
  final IconData icono;
  final String tooltip;
  final VoidCallback onTap;
  final Color? colorIcono;

  const _BotonControlMapa({
    required this.icono,
    required this.tooltip,
    required this.onTap,
    this.colorIcono,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              icono,
              color: colorIcono ?? const Color(0xFF1E293B),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _TarjetaDetalleLocalMapa extends StatelessWidget {
  final LocalMapaModel local;
  final VoidCallback onCerrar;
  final VoidCallback onVerCuponera;

  const _TarjetaDetalleLocalMapa({
    required this.local,
    required this.onCerrar,
    required this.onVerCuponera,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: local.colorCategoria.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(local.icono, color: local.colorCategoria, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      local.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${local.categoria} · A ${local.distanciaFormateada} · ★ ${local.calificacion}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onCerrar,
                icon: const Icon(Icons.close_rounded, size: 20),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 15,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${local.direccion}  •  ${local.horario}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.card_giftcard_rounded,
                  size: 16,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${local.tituloPromocion}: ${local.descripcionPremio}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onVerCuponera,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.confirmation_num_outlined, size: 18),
              label: const Text(
                'Ver Cuponera del Local',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarruselMiniLocalesMapa extends StatelessWidget {
  final List<LocalMapaModel> locales;
  final ValueChanged<LocalMapaModel> onSelect;

  const _CarruselMiniLocalesMapa({
    required this.locales,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (locales.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'No se encontraron locales con ese filtro.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: locales.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final local = locales[index];
          return GestureDetector(
            onTap: () => onSelect(local),
            child: Container(
              width: 240,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: local.colorCategoria.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(local.icono, color: local.colorCategoria),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          local.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${local.distanciaFormateada} · ${local.tituloPromocion}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
