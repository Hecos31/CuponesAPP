import 'dart:async';
import 'package:flutter/material.dart';

/// Modelo de datos para cada tarjeta del carrusel promocional minimalista.
class BannerPromocionalItem {
  final String etiqueta;
  final String titulo;
  final String subtitulo;
  final String textoAccion;
  final IconData icono;
  final Color colorFondo;
  final Color colorAcento;
  final VoidCallback? onTap;

  const BannerPromocionalItem({
    required this.etiqueta,
    required this.titulo,
    required this.subtitulo,
    required this.textoAccion,
    required this.icono,
    required this.colorFondo,
    required this.colorAcento,
    this.onTap,
  });
}

/// Carrusel de banners promocionales con diseño minimalista, auto-desplazamiento
/// suave e indicadores dinámicos.
class CarruselBannersMinimalista extends StatefulWidget {
  final List<BannerPromocionalItem> banners;
  final ValueChanged<int>? onBannerSelected;

  const CarruselBannersMinimalista({
    super.key,
    required this.banners,
    this.onBannerSelected,
  });

  @override
  State<CarruselBannersMinimalista> createState() =>
      _CarruselBannersMinimalistaState();
}

class _CarruselBannersMinimalistaState
    extends State<CarruselBannersMinimalista> {
  late final PageController _pageController;
  int _paginaActual = 0;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _iniciarAutoPlay();
  }

  void _iniciarAutoPlay() {
    _autoPlayTimer?.cancel();
    if (widget.banners.length <= 1) return;

    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final siguiente = (_paginaActual + 1) % widget.banners.length;
      _pageController.animateToPage(
        siguiente,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 148,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification &&
                  notification.dragDetails != null) {
                _autoPlayTimer?.cancel();
              } else if (notification is ScrollEndNotification) {
                _iniciarAutoPlay();
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.banners.length,
              onPageChanged: (index) {
                setState(() => _paginaActual = index);
              },
              itemBuilder: (context, index) {
                final item = widget.banners[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _TarjetaBannerMinimalista(
                    item: item,
                    onTap: () {
                      item.onTap?.call();
                      widget.onBannerSelected?.call(index);
                    },
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.banners.length, (index) {
            final bool activo = index == _paginaActual;
            return GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 6,
                width: activo ? 22 : 6,
                decoration: BoxDecoration(
                  color: activo
                      ? const Color(0xFF1E293B)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _TarjetaBannerMinimalista extends StatelessWidget {
  final BannerPromocionalItem item;
  final VoidCallback onTap;

  const _TarjetaBannerMinimalista({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.colorFondo,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            // Círculo decorativo sutil de estilo minimalista
            Positioned(
              right: -24,
              bottom: -24,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.colorAcento.withValues(alpha: 0.10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: item.colorAcento.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item.etiqueta.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: item.colorAcento,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.titulo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.subtitulo,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF475569),
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.textoAccion,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: item.colorAcento,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: item.colorAcento,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      item.icono,
                      color: item.colorAcento,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

