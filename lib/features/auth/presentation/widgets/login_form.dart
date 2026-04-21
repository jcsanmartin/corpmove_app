import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';
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
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isLoading || _isGoogleLoading;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !isLoading,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
              prefixIcon: const Icon(
                Icons.email_outlined,
                color: AppColors.textMuted,
              ),
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.accentLime,
                  width: 1.5,
                ),
              ),
            ),
            validator: (v) => (v == null || v.isEmpty)
                ? 'Ingresa tu correo'
                : (!v.contains('@') ? 'Correo inválido' : null),
          ),
          const SizedBox(height: 20),

          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            enabled: !isLoading,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              labelText: 'Contraseña',
              labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: AppColors.textMuted,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: AppColors.textMuted,
                ),
                onPressed: isLoading
                    ? null
                    : () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible),
              ),
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.accentLime,
                  width: 1.5,
                ),
              ),
            ),
            validator: (v) => (v == null || v.isEmpty)
                ? 'Ingresa tu contraseña'
                : (v.length < 6 ? 'Mínimo 6 caracteres' : null),
          ),
          const SizedBox(height: 32),

          // Login button (accent lime)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentLime,
                foregroundColor: AppColors.textOnAccent,
                disabledBackgroundColor:
                    AppColors.accentLime.withOpacity(0.3),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: AppColors.textOnAccent,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'Iniciar Sesión',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Divider
          Row(
            children: [
              Expanded(
                child: Divider(color: AppColors.borderSubtle, thickness: 0.5),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'O continúa con',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                child: Divider(color: AppColors.borderSubtle, thickness: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Google button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : _signInWithGoogle,
              icon: _isGoogleLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.textPrimary,
                      ),
                    )
                  : Image.network(
                      'https://img.icons8.com/color/48/000000/google-logo.png',
                      width: 24,
                      height: 24,
                    ),
              label: Text(
                'Google',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borderAccent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}