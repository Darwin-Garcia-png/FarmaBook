import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../controllers/recovery_controller.dart';
import '../screens/ventas_screen.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/inicio_screen.dart';
import '../screens/almacen_screen.dart';
import '../screens/proveedores_screen.dart';
import '../screens/categorias_screen.dart';
import '../screens/presentaciones_screen.dart';
import '../screens/estadisticas_screen.dart';
import '../screens/configuracion_screen.dart';
import '../screens/usuarios_screen.dart';
import '../screens/manual_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/verify_pin_screen.dart';
import '../screens/reset_password_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/login',
  routes: <RouteBase>[
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => ForgotPasswordScreen(
        controller: state.extra as RecoveryController? ?? RecoveryController(),
      ),
    ),
    GoRoute(
      path: '/verify-pin',
      builder: (context, state) => VerifyPinScreen(
        controller: state.extra as RecoveryController,
      ),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => ResetPasswordScreen(
        controller: state.extra as RecoveryController,
      ),
    ),
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/ventas',
      builder: (context, state) => const VentasScreen(),
    ),
    GoRoute(
      path: '/inicio',
      builder: (context, state) => const InicioScreen(),
    ),
    GoRoute(
      path: '/almacen',
      builder: (context, state) => const AlmacenScreen(),
    ),
    GoRoute(
      path: '/proveedores',
      builder: (context, state) => const ProveedoresScreen(),
    ),
    GoRoute(
      path: '/categorias',
      builder: (context, state) => const CategoriasScreen(),
    ),
    GoRoute(
      path: '/presentaciones',
      builder: (context, state) => const PresentacionesScreen(),
    ),
    GoRoute(
      path: '/estadisticas',
      builder: (context, state) => const EstadisticasScreen(),
    ),
    GoRoute(
      path: '/configuracion',
      builder: (context, state) => const ConfigScreen(),
    ),
    GoRoute(
      path: '/usuarios',
      builder: (context, state) => const UsuariosScreen(),
    ),
    GoRoute(
      path: '/manual',
      builder: (context, state) => const ManualScreen(),
    ),
  ],
);
