import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- TUS IMPORTS EXISTENTES ---
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/main/presentation/pages/main_layout.dart';
import '../../features/busqueda/presentation/pages/busqueda_page.dart';
import '../../features/mapa/presentation/pages/mapa_page.dart';
import '../../features/configuracion/presentation/pages/configuracion_page.dart';
import '../../features/fidelidad/presentation/pages/scanner_page.dart';
import '../../features/auth/presentation/pages/perfil_usuario_page.dart';
import '../../features/auth/presentation/pages/recuperar_password_page.dart';
import '../../features/auth/presentation/pages/approval_status_page.dart';
import '../../features/auth/presentation/pages/registro_negocio_page.dart';

// --- IMPORTS DE CUPONERAS ---
import '../../features/cuponeras/presentation/pages/mis_cuponeras_page.dart';
import '../../features/cuponeras/presentation/pages/cuponera_detail_page.dart';
// IMPORTANTE: Asegúrate de haber creado este archivo con el código de "Descubrir Cuponeras"
import '../../features/cuponeras/presentation/pages/cuponeras_list_page.dart'; 

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  routes: [
    // ======================================================
    // RUTAS GLOBALES (Fuera de la barra de navegación)
    // ======================================================
    GoRoute(path: '/', redirect: (context, state) => '/login'),
    
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    
    GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),

    GoRoute(
      path: '/registro-negocio',
      builder: (context, state) => const RegistroNegocioPage(),
    ),

    GoRoute(
      path: '/revision_local',
      builder: (context, state) => const ApprovalStatusPage(),
    ),

    // 📝 RUTA: Detalle de la cuponera (El cliente ve su progreso y su QR)
    GoRoute(
      path: '/cuponeras/detalle',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>? ?? {};
        return CuponeraDetailPage(cuponeraData: data);
      },
    ),

    // ======================================================
    // RUTAS CON BARRA DE NAVEGACIÓN (MainLayout)
    // ======================================================
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainLayout(child: child);
      },
      routes: [
        // 📝 RUTA: Feed general de cuponeras públicas (Descubrir)
        GoRoute(
          path: '/descubrir',
          builder: (context, state) => const CuponerasListPage(),
        ),
        
        // 📝 RUTA: Cuponeras a las que el cliente ya se suscribió
        GoRoute(
          path: '/mis-cuponeras',
          builder: (context, state) => const MisCuponerasPage(),
        ),
        
        GoRoute(
          path: '/busqueda',
          builder: (context, state) => const BusquedaPage(),
        ),
        
        GoRoute(
          path: '/mapa', 
          builder: (context, state) => const MapaPage()
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
        
        // 📝 RUTA TEMPORAL: Mi Local (Hasta que fusiones la rama del editor)
        GoRoute(
          path: '/editor_cuponera',
          builder: (context, state) {
            // VISTA TEMPORAL MIENTRAS TRAES EL EDITOR
            return Scaffold(
              appBar: AppBar(title: const Text('Administración de Mi Local')),
              body: const Center(
                child: Text(
                  'El Editor Visual llegará en la próxima actualización.\n(Rama pendiente de merge)', 
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            );
          },
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            final status = prefs.getString('status_local') ?? 'pendiente';

            if (status == 'pendiente' || status == 'rechazado') {
              return '/revision_local';
            }
            return null;
          },
        ),
      ],
    ),
  ],
);