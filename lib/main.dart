import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corpmove_app/features/splash/presentation/screens/splash_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CorpMoveApp());
}

class CorpMoveApp extends StatelessWidget {
  const CorpMoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CorpMove',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        primaryColor: const Color(0xFF1A237E),
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          secondary: const Color(0xFFFF6D00),
          surface: Colors.white,
          error: Colors.redAccent,
        ),
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          titleLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          titleMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          bodyLarge: const TextStyle(fontSize: 16),
          bodyMedium: const TextStyle(fontSize: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 2,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1A237E),
          titleTextStyle: TextStyle(
            color: Color(0xFF1A237E),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}