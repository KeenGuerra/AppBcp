// app_router.dart
import 'package:go_router/go_router.dart';
import 'package:mobile_app_bcp/features/auth/presentation/screens/splash_screen.dart';
import 'package:mobile_app_bcp/features/auth/presentation/screens/login_screen.dart';
import 'package:mobile_app_bcp/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:mobile_app_bcp/features/cliente_homebanking/presentation/screens/cliente_dashboard_screen.dart';
import 'package:mobile_app_bcp/features/cliente_homebanking/presentation/screens/perfil_screen.dart';
import 'package:mobile_app_bcp/features/cliente_homebanking/presentation/screens/cuentas_screen.dart';
import 'package:mobile_app_bcp/features/cliente_homebanking/presentation/screens/creditos_screen.dart';
import 'package:mobile_app_bcp/features/cliente_homebanking/presentation/screens/cronograma_screen.dart';
import 'package:mobile_app_bcp/features/cliente_homebanking/presentation/screens/movimientos_screen.dart';
import 'package:mobile_app_bcp/features/cliente_homebanking/presentation/screens/tarjetas_screen.dart';
import 'package:mobile_app_bcp/features/cliente_homebanking/presentation/screens/solicitar_credito_screen.dart';
import 'package:mobile_app_bcp/features/cliente_homebanking/presentation/screens/transferencia_screen.dart';
import 'package:mobile_app_bcp/features/cliente_homebanking/presentation/screens/pago_credito_screen.dart';
import 'package:mobile_app_bcp/features/cliente_homebanking/presentation/screens/notificaciones_screen.dart';
import 'package:mobile_app_bcp/features/fuerza_ventas/presentation/screens/asesor_dashboard_screen.dart';
import 'package:mobile_app_bcp/features/fuerza_ventas/presentation/screens/cartera_hoy_screen.dart';
import 'package:mobile_app_bcp/features/fuerza_ventas/presentation/screens/ficha_cliente_screen.dart';
import 'package:mobile_app_bcp/features/fuerza_ventas/presentation/screens/mis_solicitudes_screen.dart';
import 'package:mobile_app_bcp/features/fuerza_ventas/presentation/screens/solicitud_detalle_screen.dart';
import 'package:mobile_app_bcp/features/supervisor/presentation/screens/supervisor_dashboard_screen.dart';
import 'package:mobile_app_bcp/features/supervisor/presentation/screens/comite_solicitudes_screen.dart';
import 'package:mobile_app_bcp/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:mobile_app_bcp/features/admin/presentation/screens/usuarios_screen.dart';
import 'package:mobile_app_bcp/features/admin/presentation/screens/productos_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Auth
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),

    // Cliente / Homebanking
    GoRoute(path: '/cliente', builder: (context, state) => const ClienteDashboardScreen()),
    GoRoute(path: '/cliente/perfil', builder: (context, state) => const PerfilScreen()),
    GoRoute(path: '/cliente/cuentas', builder: (context, state) => const CuentasScreen()),
    GoRoute(path: '/cliente/creditos', builder: (context, state) => const CreditosScreen()),
    GoRoute(path: '/cliente/creditos/:id/cronograma', builder: (context, state) => CronogramaScreen(idCredito: state.pathParameters['id']!)),
    GoRoute(path: '/cliente/movimientos', builder: (context, state) => const MovimientosScreen()),
    GoRoute(path: '/cliente/tarjetas', builder: (context, state) => const TarjetasScreen()),
    GoRoute(path: '/cliente/solicitar', builder: (context, state) => const SolicitarCreditoScreen()),
    GoRoute(path: '/cliente/transferencia', builder: (context, state) => const TransferenciaScreen()),
    GoRoute(path: '/cliente/pago-credito', builder: (context, state) => const PagoCreditoScreen()),
    GoRoute(path: '/cliente/notificaciones', builder: (context, state) => const NotificacionesScreen()),

    // Fuerza de Ventas / Asesor
    GoRoute(path: '/asesor', builder: (context, state) => const AsesorDashboardScreen()),
    GoRoute(path: '/asesor/cartera', builder: (context, state) => const CarteraHoyScreen()),
    GoRoute(path: '/asesor/solicitudes', builder: (context, state) => const MisSolicitudesScreen()),
    GoRoute(path: '/asesor/cliente/:id', builder: (context, state) {
      final cliente = state.extra as Map<String, dynamic>? ?? {};
      return FichaClienteScreen(cliente: cliente);
    }),
    GoRoute(path: '/asesor/solicitud/:id', builder: (context, state) {
      final solicitud = state.extra as Map<String, dynamic>? ?? {};
      return SolicitudDetalleScreen(solicitud: solicitud);
    }),

    // Supervisor
    GoRoute(path: '/supervisor', builder: (context, state) => const SupervisorDashboardScreen()),
    GoRoute(path: '/supervisor/comite', builder: (context, state) => const ComiteSolicitudesScreen()),

    // Admin
    GoRoute(path: '/admin', builder: (context, state) => const AdminDashboardScreen()),
    GoRoute(path: '/admin/usuarios', builder: (context, state) => const UsuariosScreen()),
    GoRoute(path: '/admin/productos', builder: (context, state) => const ProductosScreen()),
  ],
);
