import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/main/presentation/pages/main_layout.dart';
import '../../features/cuponeras/presentation/pages/cuponeras_list_page.dart';
import '../../features/cuponeras/presentation/pages/cuponera_detail_page.dart';
import '../../features/novedades/presentation/pages/novedades_page.dart';
import '../../features/busqueda/presentation/pages/busqueda_page.dart';
import '../../features/mapa/presentation/pages/mapa_page.dart';
import '../../features/configuracion/presentation/pages/configuracion_page.dart';
import '../../features/fidelidad/presentation/pages/scanner_page.dart';
import '../../features/auth/presentation/pages/perfil_usuario_page.dart';
import '../../features/auth/presentation/pages/recuperar_password_page.dart';
import '../../features/editor/presentation/pages/editor_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  routes: [
    // --- RUTAS PÚBLICAS O DE PANTALLA COMPLETA (FUERA DEL SHELL) ---
    GoRoute(
      path: '/login', 
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/cuponeras/detalle',
      builder: (context, state) => const CuponeraDetailPage(),
    ),
    GoRoute(
      path: '/editor',
      builder: (context, state) {
        final cuponeraId = state.extra as String?;
        return EditorPage(cuponeraId: cuponeraId);
      },
    ),

    // --- RUTAS CON NAVEGACIÓN INFERIOR (DENTRO DEL SHELL) ---
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainLayout(child: child);
      },
      routes: [
        GoRoute(
          path: '/novedades',
          builder: (context, state) => const NovedadesPage(),
        ),
        GoRoute(
          path: '/cuponeras',
          builder: (context, state) => const CuponerasListPage(),
        ),
        GoRoute(
          path: '/busqueda',
          builder: (context, state) => const BusquedaPage(),
        ),
        GoRoute(
          path: '/mapa', 
          builder: (context, state) => const MapaPage(),
        ),
        GoRoute(
          path: '/configuracion',
          builder: (context, state) => const ConfiguracionPage(),
        ),
        GoRoute(
          path: '/scanner',
          builder: (context, state) => const ScannerPage(),
        ),
        GoRoute(
          path: '/recuperar-password',
          builder: (context, state) => const RecuperarPasswordPage(),
        ),
        GoRoute(
          path: '/perfil',
          builder: (context, state) => const PerfilUsuarioPage(),
        ),
      ],
    ),
  ],
);