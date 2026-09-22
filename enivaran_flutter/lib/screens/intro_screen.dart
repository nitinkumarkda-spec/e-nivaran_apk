import 'package:flutter/material.dart';
import 'citizen_web_portal_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      "icon": Icons.photo_camera,
      "badge": "Smart Reporting",
      "title": "Send a Photo & Geotag",
      "highlight": "Get it Resolved",
      "desc": "Capture photo of civic problems with instant auto-detected GPS location across Kota and Bundi territories.",
      "color": const Color(0xFFE3861C),
    },
    {
      "icon": Icons.timeline,
      "badge": "Live Tracking",
      "title": "Track Progress in Real Time",
      "highlight": "Step-by-Step",
      "desc": "Follow your complaint as it is verified by Moderator, assigned to JEN, and executed by field contractors.",
      "color": const Color(0xFF005792),
    },
    {
      "icon": Icons.verified_user,
      "badge": "Citizen-First",
      "title": "Transparent & Accountable",
      "highlight": "Direct Action",
      "desc": "Time-bound SLA resolution by Kota Development Authority with SMS notifications and resolution verification.",
      "color": const Color(0xFF10B981),
    },
  ];

  void _finishIntro() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CitizenWebPortalScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _finishIntro,
            child: const Text(
              "Skip",
              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _slides.length,
                itemBuilder: (ctx, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Circle Graphic
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: slide['color'].withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(slide['icon'], size: 64, color: slide['color']),
                        ),
                        const SizedBox(height: 36),

                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFFD6B3)),
                          ),
                          child: Text(
                            slide['badge'],
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE3861C)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          slide['title'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Highlight Subtitle
                        Text(
                          slide['highlight'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: slide['color'],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Description
                        Text(
                          slide['desc'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF475569),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation: Indicators & Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicators
                  Row(
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i ? const Color(0xFFE3861C) : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Next / Get Started Button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finishIntro();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE3861C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == _slides.length - 1 ? "Get Started" : "Next",
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
