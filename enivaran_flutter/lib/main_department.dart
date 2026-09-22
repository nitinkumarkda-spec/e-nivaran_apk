import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/api_config.dart';
import 'screens/department_web_portal_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F172A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const KDADepartmentApp());
}

class KDADepartmentApp extends StatelessWidget {
  const KDADepartmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KDA e-Nivaran (Department)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD9531E),
          brightness: Brightness.dark,
          primary: const Color(0xFFD9531E),
          secondary: const Color(0xFF38BDF8),
          surface: const Color(0xFF1E293B),
          background: const Color(0xFF0F172A),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const DepartmentWebPortalScreen(),
    );
  }
}
