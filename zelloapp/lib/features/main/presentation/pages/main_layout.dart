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
  String _statusLocal = 'pendiente';
  bool _isEstablecimiento = false;

  @override
  void initState() {
    super.initState();
    _cargarRolYEstado();
  }

  Future<void> _cargarRolYEstado() async {
    final prefs = await SharedPreferences.getInstance();
    // Validamos 'mounted' para evitar errores si el widget se destruye antes de que termine la lectura
    if (mounted) {
      setState(() {
        _statusLocal = prefs.getString('status_local') ?? 'pendiente';
        _isEstablecimiento = prefs.getBool('is_establecimiento') ?? false; 
      });
    }
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/novedades'); break;
      case 1: context.go('/cuponeras'); break;
      case 2: context.go('/busqueda'); break;
      case 3: context.go('/mapa'); break;
      case 4: context.go('/configuracion'); break;
      case 5: context.go('/crear-cupon'); break; 
    }
  }

 @override
  Widget build(BuildContext context) {
    // Construimos la lista usando el "Collection if" de Dart.
    // Esto es mucho más seguro y evita el error "Unsupported operation: add".
    final navItems = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
      const BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Cuponeras'),
      const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
      const BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
      const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ajustes'),
      
      // Inyectamos la pestaña exclusiva directamente aquí
      if (_isEstablecimiento && _statusLocal == 'aprobado')
        const BottomNavigationBarItem(
          icon: Icon(Icons.storefront), 
          label: 'Mi Local'
        ),
    ];

    // Calculamos el índice actual
    int currentIndex = _calculateSelectedIndex(context);

    // Candado de seguridad
    if (currentIndex >= navItems.length) {
      currentIndex = 0;
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: navItems,
        currentIndex: currentIndex, 
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/novedades')) return 0;
    if (location.startsWith('/cuponeras')) return 1;
    if (location.startsWith('/busqueda')) return 2;
    if (location.startsWith('/mapa')) return 3;
    if (location.startsWith('/configuracion')) return 4;
    // Si agregas más vistas de administración (como '/vista-usuario'), súmalas aquí
    if (location.startsWith('/crear-cupon') || location.startsWith('/vista-usuario')) return 5; 
    return 0;
  }
}