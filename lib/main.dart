import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // 1. Configuración inicial
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 2. Intenta conectar con Firebase (funcionará en Android, fallará en Web por ahora)
    await Firebase.initializeApp();
  } catch (e) {
    // Si falla (como en la Web), imprime el error pero NO detiene la app
    print("Firebase no configurado o no soportado en esta plataforma: $e");
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CorpMove App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CorpMove - Inicio'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rocket_launch, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              '¡CorpMove está lista!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'La interfaz está corriendo en tu navegador.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                print("¡Botón presionado!");
              },
              child: const Text('Comenzar'),
            ),
          ],
        ),
      ),
    );
  }
}