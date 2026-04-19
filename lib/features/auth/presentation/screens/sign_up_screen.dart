import 'package:flutter/material.dart';
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
                    color: const Color(0xFF1A237E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.person_add,
                    size: 45,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Crear cuenta',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
              ),
              const SizedBox(height: 10),
              Text(
                'Regístrate para comenzar a usar CorpMove',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 40),
              const SignUpForm(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿Ya tienes cuenta? ',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      'Inicia sesión',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6D00)),
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