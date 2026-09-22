import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/api_config.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const KDACitizenApp());
}

class KDACitizenApp extends StatelessWidget {
  const KDACitizenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KDA e-Nivaran (Citizen)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE3861C),
          primary: const Color(0xFFE3861C),
          secondary: const Color(0xFF005792),
          surface: Colors.white,
          background: const Color(0xFFF8FAFC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: Color(0xFF0F172A)),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
