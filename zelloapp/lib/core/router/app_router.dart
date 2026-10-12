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
import '../../features/sucursales/data/datasources/sucursales_remote_data_source.dart';
import '../../features/sucursales/presentation/pages/administracion_sucursales_page.dart';
import '../../features/sucursales/presentation/pages/alta_sucursal_page.dart';
import '../../features/sucursales/presentation/pages/configuracion_sucursal_page.dart';
import '../../features/sucursales/presentation/pages/verificacion_identidad_page.dart';


final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
    GoRoute(
      path: '/sucursales/administracion',
      builder: (context, state) => const AdministracionSucursalesPage(),
    ),
    GoRoute(
      path: '/sucursales/alta',
      builder: (context, state) => const AltaSucursalPage(),
    ),
    GoRoute(
      path: '/sucursales/configuracion',
      builder: (context, state) {
        final sucursal = state.extra as SucursalModel?;
        return ConfiguracionSucursalPage(sucursal: sucursal);
      },
    ),
    GoRoute(
      path: '/sucursales/verificacion',
      builder: (context, state) => const VerificacionIdentidadPage(),
    ),
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
          routes: [
            GoRoute(
              path: 'detalle',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => const CuponeraDetailPage(),
            ),
          ],
        ),
        GoRoute(
          path: '/busqueda',
          builder: (context, state) => const BusquedaPage(),
        ),
        GoRoute(path: '/mapa', builder: (context, state) => const MapaPage()),
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
          builder: (context, state) {
            return const RecuperarPasswordPage();
          },
        ),
        GoRoute(
          path: '/perfil',
          builder: (context, state) {
            return const PerfilUsuarioPage();
          },
        ),
      ],
    ),
  ],
);
