import 'package:flutter/material.dart';
import 'package:corpmove_app/core/services/auth_service.dart';
import 'package:corpmove_app/core/utils/user_role.dart';
import 'package:corpmove_app/features/trip_passenger/presentation/screens/passenger_home_screen.dart';
import 'package:corpmove_app/features/trip_driver/presentation/screens/driver_home_screen.dart';
import 'package:corpmove_app/features/company_admin/presentation/screens/company_admin_screen.dart';
import 'package:corpmove_app/features/owner/presentation/screens/owner_dashboard_screen.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Credenciales de prueba pre-llenadas para facilitar demostración
    _emailController.text = 'empleado@corpmove.com';
    _passwordController.text = '123456';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final userData = await _authService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) {
          _navigateToRole(userData['role'] as UserRole);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final userData = await _authService.signInWithGoogle();
      if (mounted) {
        _navigateToRole(userData['role'] as UserRole);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error con Google: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _navigateToRole(UserRole role) {
    Widget screen;
    switch (role) {
      case UserRole.owner:
        screen = const OwnerDashboardScreen();
        break;
      case UserRole.admin:
        screen = const CompanyAdminScreen();
        break;
      case UserRole.driver:
        screen = const DriverHomeScreen();
        break;
      case UserRole.employee:
        screen = const PassengerHomeScreen(isCorporateEnabled: true);
        break;
      case UserRole.normal:
        screen = const PassengerHomeScreen(isCorporateEnabled: false);
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isLoading || _isGoogleLoading;
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !isLoading,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa tu correo';
              }
              if (!value.contains('@')) {
                return 'Correo inválido';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            enabled: !isLoading,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: isLoading ? null : () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa tu contraseña';
              }
              if (value.length < 6) {
                return 'Mínimo 6 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : _login,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Iniciar Sesión',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 15),
          const Text('— O continúa con —', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : _signInWithGoogle,
              icon: _isGoogleLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Image.network(
                      'https://img.icons8.com/color/48/000000/google-logo.png',
                      width: 24,
                      height: 24,
                    ),
              label: const Text('Google'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.grey),
                foregroundColor: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Credenciales de prueba:',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 5),
          const Text(
            '👤 Normal: usuario@email.com\n'
            '🏢 Empleado: empleado@corpmove.com\n'
            '🚖 Conductor: conductor@corpmove.com\n'
            '📊 Admin: admin@empresa.com\n'
            '👑 Owner: owner@corpmove.com',
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}