import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zelloapp/core/theme/app_theme.dart';

class _NavDestination {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const _NavDestination({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

class MainLayout extends StatefulWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _isEstablecimiento = false;

  @override
  void initState() {
    super.initState();
    _cargarRol();
  }

  Future<void> _cargarRol() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isEstablecimiento = prefs.getBool('is_establecimiento') ?? false;
      });
    }
  }

  List<_NavDestination> get _destinations => [
        const _NavDestination(
          label: 'Descubrir',
          icon: Icons.explore_outlined,
          activeIcon: Icons.explore_rounded,
          route: '/descubrir',
        ),
        const _NavDestination(
          label: 'Mis Cupones',
          icon: Icons.confirmation_num_outlined,
          activeIcon: Icons.confirmation_num_rounded,
          route: '/mis-cuponeras',
        ),
        const _NavDestination(
          label: 'Buscar',
          icon: Icons.manage_search_rounded,
          activeIcon: Icons.search_rounded,
          route: '/busqueda',
        ),
        const _NavDestination(
          label: 'Ajustes',
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings_rounded,
          route: '/configuracion',
        ),
        if (_isEstablecimiento)
          const _NavDestination(
            label: 'Mi Local',
            icon: Icons.storefront_outlined,
            activeIcon: Icons.storefront_rounded,
            route: '/editor_cuponera',
          ),
      ];

  int _calculateSelectedIndex(BuildContext context, List<_NavDestination> items) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/descubrir')) return 0;
    if (location.startsWith('/mis-cuponeras')) return 1;
    if (location.startsWith('/busqueda') || location.startsWith('/mapa')) return 2;
    if (location.startsWith('/configuracion') ||
        location.startsWith('/perfil') ||
        location.startsWith('/escaner')) {
      return 3;
    }
    if ((location.startsWith('/editor_cuponera') || location.startsWith('/mi-local')) &&
        items.length > 4) {
      return 4;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final items = _destinations;
    final currentIndex = _calculateSelectedIndex(context, items);

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Contenido principal con margen inferior para que nada quede tapado por la barra flotante
          Padding(
            padding: const EdgeInsets.only(bottom: 94),
            child: widget.child,
          ),

          // Barra de navegación flotante moderna con efecto cristal (Glassmorphism)
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryDeep.withValues(alpha: 0.24),
                      blurRadius: 28,
                      spreadRadius: 1,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.darkInk.withValues(alpha: 0.92),
                            AppTheme.primaryDeep.withValues(alpha: 0.90),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(items.length, (index) {
                          final item = items[index];
                          final bool isSelected = index == currentIndex;

                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              _cargarRol();
                              context.go(item.route);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOutCubic,
                              padding: EdgeInsets.symmetric(
                                horizontal: isSelected ? 16 : 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                gradient: isSelected ? AppTheme.brandGradient : null,
                                color: isSelected ? null : Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.accentColor.withValues(alpha: 0.32),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isSelected ? item.activeIcon : item.icon,
                                    size: 22,
                                    color: isSelected
                                        ? AppTheme.accentColor
                                        : Colors.white.withValues(alpha: 0.65),
                                  ),
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOutCubic,
                                    child: isSelected
                                        ? Padding(
                                            padding: const EdgeInsets.only(left: 8),
                                            child: Text(
                                              item.label,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
