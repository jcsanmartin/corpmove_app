import 'package:flutter/material.dart';
import 'package:corpmove_app/core/services/auth_service.dart';
import 'package:corpmove_app/core/utils/user_role.dart';
import 'package:corpmove_app/features/trip_passenger/presentation/screens/passenger_home_screen.dart';
import 'package:corpmove_app/features/trip_driver/presentation/screens/driver_home_screen.dart';
import 'package:corpmove_app/features/company_admin/presentation/screens/company_admin_screen.dart';
import 'package:corpmove_app/features/owner/presentation/screens/owner_dashboard_screen.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final userData = await _authService.signUpWithEmail(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        _navigateToRole(userData['role'] as UserRole);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final userData = await _authService.signInWithGoogle();
      _navigateToRole(userData['role'] as UserRole);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
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
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre completo',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ingresa tu nombre';
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ingresa tu correo';
              if (!value.contains('@')) return 'Correo inválido';
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ingresa una contraseña';
              if (value.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Confirmar contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Confirma tu contraseña';
              if (value != _passwordController.text) return 'Las contraseñas no coinciden';
              return null;
            },
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signUp,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Registrarse',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 15),
          const Text('— O regístrate con —', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _signUpWithGoogle,
              icon: Image.network(
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
        ],
      ),
    );
  }
}