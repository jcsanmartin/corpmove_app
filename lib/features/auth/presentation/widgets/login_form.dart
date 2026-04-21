import 'package:firebase_auth/firebase_auth.dart';
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
        final user = await _authService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (user != null) {
          await _navigateBasedOnRole(user.uid);
        }
      } on FirebaseAuthException catch (e) {
        String message = 'Error al iniciar sesión';
        if (e.code == 'user-not-found') {
          message = 'No existe usuario con este correo';
        } else if (e.code == 'wrong-password') {
          message = 'Contraseña incorrecta';
        } else if (e.code == 'invalid-email') {
          message = 'Correo inválido';
        }
        _showError(message);
      } catch (e) {
        _showError('Error: ${e.toString()}');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        await _navigateBasedOnRole(user.uid);
      }
    } catch (e) {
      _showError('Error con Google: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _navigateBasedOnRole(String uid) async {
    final role = await _authService.getUserRole(uid);
    debugPrint('═══ LOGIN: UID $uid → Rol desde Supabase: $role ═══');

    Widget screen;
    switch (role) {
      case UserRole.owner:
        screen = const OwnerDashboardScreen();
      case UserRole.admin:
        screen = const CompanyAdminScreen();
      case UserRole.driver:
        screen = const DriverHomeScreen();
      case UserRole.employee:
        screen = const PassengerHomeScreen(isCorporateEnabled: true);
      case UserRole.normal:
        screen = const PassengerHomeScreen(isCorporateEnabled: false);
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => screen),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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
            validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu correo' : (!v.contains('@') ? 'Correo inválido' : null),
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
                icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                onPressed: isLoading ? null : () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : (v.length < 6 ? 'Mínimo 6 caracteres' : null),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : _login,
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Iniciar Sesión', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : Image.network('https://img.icons8.com/color/48/000000/google-logo.png', width: 24, height: 24),
              label: const Text('Google'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.grey),
                foregroundColor: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}