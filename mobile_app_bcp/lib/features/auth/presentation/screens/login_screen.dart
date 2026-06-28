// login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app_bcp/core/config/app_constants.dart';
import 'package:mobile_app_bcp/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile_app_bcp/core/utils/validators.dart';
import 'package:mobile_app_bcp/features/cliente_homebanking/presentation/theme/cliente_theme.dart';
import 'package:mobile_app_bcp/features/cliente_homebanking/presentation/widgets/bcp_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  final _dniController = TextEditingController(text: '41884031'); // Demo defaults
  final _codeController = TextEditingController(text: 'A001');     // Demo defaults
  final _passwordController = TextEditingController(text: '123456');

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dniController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final isCliente = _tabController.index == 0;
    
    final success = await ref.read(authProvider.notifier).login(
      Dni: isCliente ? _dniController.text.trim() : null,
      CodigoEmpleado: isCliente ? null : _codeController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      final authState = ref.read(authProvider);
      _redirectByRole(authState.role!);
    }
  }

  void _redirectByRole(String role) {
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
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ClienteTheme.bcpBlue,
              Color(0xFF001428),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Decorative Graphic / Branding
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const BcpLogo(fontSize: 24, paddingHorizontal: 16, paddingVertical: 8),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Banca Móvil',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'VíaBCP',
                              style: TextStyle(
                                fontSize: 13,
                                color: ClienteTheme.bcpLightBlue,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Main Card
                    Card(
                      elevation: 8,
                      shadowColor: Colors.black.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Ingresa a tu cuenta',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: ClienteTheme.bcpBlue,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Custom TabBar inside container
                              Container(
                                height: 46,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: TabBar(
                                  controller: _tabController,
                                  indicator: BoxDecoration(
                                    color: ClienteTheme.bcpBlue,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  labelColor: Colors.white,
                                  unselectedLabelColor: ClienteTheme.bcpTextGrey,
                                  labelStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  unselectedLabelStyle: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 14,
                                  ),
                                  indicatorSize: TabBarIndicatorSize.tab,
                                  tabs: const [
                                    Tab(text: 'Cliente'),
                                    Tab(text: 'Colaborador'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Dynamic Fields based on tab
                              SizedBox(
                                height: 140,
                                child: TabBarView(
                                  controller: _tabController,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    Align(
                                      alignment: Alignment.topCenter,
                                      child: TextFormField(
                                      controller: _dniController,
                                      decoration: InputDecoration(
                                        labelText: 'DNI / Documento',
                                        labelStyle: const TextStyle(color: ClienteTheme.bcpTextGrey, fontSize: 15),
                                        prefixIcon: const Icon(Icons.badge, color: ClienteTheme.bcpBlue),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: ClienteTheme.bcpBlue, width: 2),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: AppConstants.errorRed),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: AppConstants.errorRed, width: 2),
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: Validators.validateDni,
                                      ),
                                    ),
                                    TextFormField(
                                      controller: _codeController,
                                      decoration: InputDecoration(
                                        labelText: 'Código de Empleado',
                                        labelStyle: const TextStyle(color: ClienteTheme.bcpTextGrey, fontSize: 15),
                                        prefixIcon: const Icon(Icons.work, color: ClienteTheme.bcpBlue),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: ClienteTheme.bcpBlue, width: 2),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: AppConstants.errorRed),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: AppConstants.errorRed, width: 2),
                                        ),
                                      ),
                                      keyboardType: TextInputType.text,
                                      validator: Validators.validateCodigoEmpleado,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Clave de Internet',
                                  labelStyle: const TextStyle(color: ClienteTheme.bcpTextGrey),
                                  prefixIcon: const Icon(Icons.lock, color: ClienteTheme.bcpBlue),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                      color: ClienteTheme.bcpTextGrey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: ClienteTheme.bcpBlue, width: 2),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppConstants.errorRed),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppConstants.errorRed, width: 2),
                                  ),
                                ),
                                obscureText: _obscurePassword,
                                validator: (value) => Validators.validateRequired(value, 'Clave'),
                              ),
                              const SizedBox(height: 12),

                              // Forgot password / Recovery simulation link
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => context.go('/forgot-password'),
                                  child: const Text(
                                    '¿Olvidaste tu clave?',
                                    style: TextStyle(
                                      color: ClienteTheme.bcpOrange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Error Banner
                              if (authState.errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppConstants.errorRed.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppConstants.errorRed.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline, color: AppConstants.errorRed, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          authState.errorMessage!,
                                          style: const TextStyle(
                                            color: AppConstants.errorRed,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Submit Button (BCP Orange Gradient)
                              Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: ClienteTheme.orangeButtonGradient,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ClienteTheme.bcpOrange.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: authState.isLoading ? null : _submitLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: authState.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Ingresar',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              Text(
                                'Demo: Cliente=41884031, Asesor=A001, Sup=SUP001, Admin=ADM001 / Clave=123456',
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
