import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/auth_state.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_routes.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/add_plant/add_plant_screen.dart';
import 'presentation/screens/add_plant/identify_plant_screen.dart';
import 'presentation/screens/plant_detail/plant_detail_screen.dart';
import 'presentation/screens/care_log/care_log_screen.dart';
import 'presentation/screens/growth_history/growth_history_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/notifications/notifications_screen.dart';

final _router = GoRouter(
  initialLocation: AppRoutes.splash,
  // Reconfigura o router sempre que o estado de auth muda
  refreshListenable: authState,
  redirect: (context, state) {
    final isLoggedIn = authState.value;
    final isOnAuth =
        state.matchedLocation == AppRoutes.login ||
        state.matchedLocation == AppRoutes.register ||
        state.matchedLocation == AppRoutes.splash;

    if (!isLoggedIn && !isOnAuth) return AppRoutes.login;
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.addPlant,
      builder: (context, state) => const AddPlantScreen(),
    ),
    GoRoute(
      path: AppRoutes.identifyPlant,
      builder: (context, state) => const IdentifyPlantScreen(),
    ),
    GoRoute(
      path: AppRoutes.plantDetail,
      builder: (context, state) =>
          PlantDetailScreen(plantId: state.pathParameters['id']!),
      routes: [
        GoRoute(
          path: 'history',
          builder: (context, state) =>
              CareLogScreen(plantId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: 'growth',
          builder: (context, state) => GrowthHistoryScreen(
            plantId: state.pathParameters['id']!,
            plantName: state.uri.queryParameters['name'] ?? 'Planta',
          ),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      builder: (context, state) => const NotificationsScreen(),
    ),
  ],
);

class ReggieApp extends ConsumerWidget {
  const ReggieApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'ReggieApp',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: _router,
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
