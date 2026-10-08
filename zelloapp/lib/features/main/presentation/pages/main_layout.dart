import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/novedades')) return 0;
    if (location.startsWith('/cuponeras')) return 1;
    if (location.startsWith('/busqueda')) return 2;
    if (location.startsWith('/mapa')) return 3;
    if (location.startsWith('/configuracion')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/novedades');
        break;
      case 1:
        context.go('/cuponeras');
        break;
      case 2:
        context.go('/busqueda');
        break;
      case 3:
        context.go('/mapa');
        break;
      case 4:
        context.go('/configuracion');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _calculateSelectedIndex(context),
            onTap: (index) => _onItemTapped(index, context),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Inicio'),
              BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Cuponeras'),
              BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
              BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Mapa'),
              BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Ajustes'),
            ],
          ),
        ),
      ),
    );
  }
}