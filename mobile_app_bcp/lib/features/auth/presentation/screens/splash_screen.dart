// splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app_bcp/core/config/app_constants.dart';
import 'package:mobile_app_bcp/features/auth/presentation/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkRedirect();
  }

  Future<void> _checkRedirect() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.token != null && authState.role != null) {
      _navigateToDashboard(authState.role!);
    } else {
      context.go('/login');
    }
  }

  void _navigateToDashboard(String role) {
    switch (role) {
      case 'CLIENTE':
        context.go('/cliente');
        break;
      case 'ASESOR':
        context.go('/asesor');
        break;
      case 'SUPERVISOR':
        context.go('/supervisor');
        break;
      case 'ADMIN':
        context.go('/admin');
        break;
      default:
        context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for state changes to handle logout redirect
    ref.listen(authProvider, (previous, next) {
      if (next.token == null) {
        context.go('/login');
      }
    });

    return Scaffold(
      backgroundColor: AppConstants.primaryBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // BCP Branded Header / Logo Simulation
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                  )
                ],
              ),
              child: const Icon(
                Icons.account_balance,
                size: 80,
                color: AppConstants.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'BCP Mobile Core 360',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ecosistema Móvil Bancario',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.orangeAcento),
            ),
          ],
        ),
      ),
    );
  }
}
