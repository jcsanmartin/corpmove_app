import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:corpmove_app/core/services/supabase_service.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';
import 'package:corpmove_app/features/splash/presentation/screens/splash_screen.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
import 'firebase_options.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Status bar transparente para look inmersivo
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.scaffoldLight,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    // Firebase sólo para Auth (login, Google Sign-In)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Supabase para base de datos y storage
    await SupabaseService.initialize();

    // Inicializar Mapbox (Reemplaza con tu token público pk.eyJ...)
    mbx.MapboxOptions.setAccessToken(
        "pk.eyJ1IjoiamNzYW5tYXJ0aW4iLCJhIjoiY21vYWJsZmUzMDR5eTJ4cTA5MmFvbmJpbSJ9.OZtHCg1w7y-HUow9Cl9Vsw");

    runApp(const CorpMoveApp());
  } catch (e, stackTrace) {
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red.shade900,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Error de Inicialización:\n\n$e\n\n$stackTrace',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ),
    ));
  }
}

class CorpMoveApp extends StatelessWidget {
  const CorpMoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CorpMove',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}