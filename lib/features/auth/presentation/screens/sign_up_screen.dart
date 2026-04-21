import 'package:flutter/material.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';
import 'package:corpmove_app/features/auth/presentation/widgets/sign_up_form.dart';
import 'package:corpmove_app/features/auth/presentation/screens/login_screen.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.accentLime.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.person_add,
                    size: 45,
                    color: AppColors.accentLime,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Crear cuenta',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              const Text(
                'Regístrate para comenzar a usar CorpMove',
                style: TextStyle(fontSize: 16, color: AppColors.textMuted),
              ),
              const SizedBox(height: 40),
              const SignUpForm(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '¿Ya tienes cuenta? ',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen(isCorporateMode: false)),
                      );
                    },
                    child: const Text(
                      'Inicia sesión',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentLime),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}