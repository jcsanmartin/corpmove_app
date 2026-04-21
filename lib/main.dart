import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:corpmove_app/core/services/supabase_service.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';
import 'package:corpmove_app/features/splash/presentation/screens/splash_screen.dart';
import 'firebase_options.dart';

void main() async {
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
  runApp(const CorpMoveApp());
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