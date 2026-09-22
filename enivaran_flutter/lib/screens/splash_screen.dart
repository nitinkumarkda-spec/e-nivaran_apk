import 'package:flutter/material.dart';
import 'intro_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const IntroScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // KDA Logo Box
                Container(
                  width: 90,
                  height: 90,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Image.asset(
                    'assets/images/logo2.png',
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, e, st) => const Icon(Icons.shield, size: 50, color: Color(0xFF005792)),
                  ),
                ),
                const SizedBox(height: 24),

                // App Title
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    children: [
                      TextSpan(text: "KDA "),
                      TextSpan(text: "e", style: TextStyle(color: Color(0xFFE3861C), fontSize: 28)),
                      TextSpan(text: "-Nivaran"),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                const Text(
                  "Kota Development Authority",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF005792)),
                ),
                const SizedBox(height: 4),

                const Text(
                  "Public Grievance Redressal Portal",
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 36),

                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFFE3861C),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
