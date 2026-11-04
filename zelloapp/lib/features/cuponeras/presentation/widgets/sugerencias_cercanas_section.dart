import 'package:flutter/material.dart';
import '../../../mapa/models/local_mapa_model.dart';

/// Vista y sección maquetada de "Sugerencias Cercanas" con filtro por giro
/// comercial, indicador de distancia y acceso directo al mapa interactivo.
class SugerenciasCercanasSection extends StatefulWidget {
  final List<LocalMapaModel> locales;
  final ValueChanged<LocalMapaModel> onTapLocal;
  final ValueChanged<LocalMapaModel> onUbicarEnMapa;
  final VoidCallback onVerMapaCompleto;

  const SugerenciasCercanasSection({
    super.key,
    required this.locales,
    required this.onTapLocal,
    required this.onUbicarEnMapa,
    required this.onVerMapaCompleto,
  });

  @override
  State<SugerenciasCercanasSection> createState() =>
      _SugerenciasCercanasSectionState();
}

class _SugerenciasCercanasSectionState
    extends State<SugerenciasCercanasSection> {
  static const List<String> _categorias = [
    'Todos',
    'Cafeterías',
    'Restaurantes',
    'Postres',
    'Tiendas',
  ];

  String _categoriaSeleccionada = 'Todos';

  List<LocalMapaModel> get _localesFiltrados {
    if (_categoriaSeleccionada == 'Todos') return widget.locales;
    return widget.locales
        .where((l) => l.categoria == _categoriaSeleccionada)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _localesFiltrados;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.near_me_rounded,
                          size: 18,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Sugerencias Cercanas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Locales aliados a menos de 2 km de tu ubicación',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: widget.onVerMapaCompleto,
                icon: const Icon(Icons.map_outlined, size: 16),
                label: const Text(
                  'Ver mapa',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _categorias.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final categoria = _categorias[index];
              final bool activa = categoria == _categoriaSeleccionada;
              return ChoiceChip(
                label: Text(categoria),
                selected: activa,
                showCheckmark: false,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: activa ? FontWeight.w700 : FontWeight.w500,
                  color: activa ? Colors.white : const Color(0xFF334155),
                ),
                selectedColor: const Color(0xFF1E293B),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: activa
                      ? const Color(0xFF1E293B)
                      : Colors.grey.shade300,
                ),
                onSelected: (_) {
                  setState(() => _categoriaSeleccionada = categoria);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (filtrados.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'No hay locales cercanos en la categoría "$_categoriaSeleccionada".',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
          )
        else
          SizedBox(
            height: 178,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: filtrados.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final local = filtrados[index];
                return _TarjetaSugerenciaCercana(
                  local: local,
                  onTap: () => widget.onTapLocal(local),
                  onUbicarEnMapa: () => widget.onUbicarEnMapa(local),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _TarjetaSugerenciaCercana extends StatelessWidget {
  final LocalMapaModel local;
  final VoidCallback onTap;
  final VoidCallback onUbicarEnMapa;

  const _TarjetaSugerenciaCercana({
    required this.local,
    required this.onTap,
    required this.onUbicarEnMapa,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 265,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: local.colorCategoria.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        local.icono,
                        color: local.colorCategoria,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            local.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            local.categoria,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: local.colorCategoria,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.place_rounded,
                            size: 12,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            local.distanciaFormateada,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            local.direccion,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '🎁 ${local.descripcionPremio}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${local.calificacion} · ${local.totalSellosRequeridos} sellos',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: onUbicarEnMapa,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.map_rounded,
                              size: 14,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Ubicar',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

