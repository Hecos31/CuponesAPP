import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/descubrir'); break; // Feed general
      case 1: context.go('/mis-cuponeras'); break; // Suscripciones del usuario
      case 2: context.go('/busqueda'); break;
      case 3: context.go('/configuracion'); break;
      case 4: context.go('/editor_cuponera'); break; // Panel de administración del comercio
    }
  }

 @override
  Widget build(BuildContext context) {
    final navItems = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Descubrir'),
      const BottomNavigationBarItem(icon: Icon(Icons.loyalty), label: 'Mis Cuponeras'),
      const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
      const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ajustes'),
      if (_isEstablecimiento)
        const BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Mi Local'),
    ];

    int currentIndex = _calculateSelectedIndex(context);
    if (currentIndex >= navItems.length) currentIndex = 0;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey,
        items: navItems,
        currentIndex: currentIndex, 
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/descubrir')) return 0;
    if (location.startsWith('/mis-cuponeras')) return 1;
    if (location.startsWith('/busqueda')) return 2;
    if (location.startsWith('/configuracion')) return 3;
    if (location.startsWith('/editor_cuponera') || location.startsWith('/mi-local')) return 4; 
    return 0;
  }
}