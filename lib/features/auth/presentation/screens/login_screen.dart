import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';
import 'package:corpmove_app/features/auth/presentation/widgets/login_form.dart';
import 'package:corpmove_app/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:corpmove_app/features/auth/presentation/screens/forgot_password_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required bool isCorporateMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // Logo mark
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.accentLime.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.accentLime.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.directions_car_rounded,
                    size: 42,
                    color: AppColors.accentLime,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Welcome text
              Text(
                'Bienvenido a',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'CorpMove',
                style: GoogleFonts.inter(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inicia sesión para continuar',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 48),

              // Login Form
              const LoginForm(),
              const SizedBox(height: 28),

              // Sign up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿No tienes cuenta? ',
                    style: GoogleFonts.inter(color: AppColors.textMuted),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpScreen()),
                      );
                    },
                    child: Text(
                      'Regístrate',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentLime,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Forgot password
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen()),
                    );
                  },
                  child: Text(
                    '¿Olvidaste tu contraseña?',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
