import 'package:flutter/material.dart';
import 'package:corpmove_app/features/auth/presentation/widgets/login_form.dart';
import 'package:corpmove_app/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:corpmove_app/features/auth/presentation/screens/forgot_password_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    size: 45,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Bienvenido a',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300),
              ),
              const Text(
                'CorpMove',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Inicia sesión para continuar',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 40),
              const LoginForm(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿No tienes cuenta? ',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpScreen()),
                      );
                    },
                    child: const Text(
                      'Regístrate',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6D00)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                    );
                  },
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}