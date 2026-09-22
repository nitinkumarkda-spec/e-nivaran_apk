import 'package:flutter/material.dart';
import 'department_web_portal_screen.dart';

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
      "icon": Icons.assignment_turned_in,
      "badge": "Officer Queue",
      "title": "Grievance Assignment",
      "highlight": "& SLA Prioritization",
      "desc": "Review, moderate, and route citizen complaints with automated SLA countdown timers across Kota and Bundi zones.",
      "color": const Color(0xFFE3861C),
    },
    {
      "icon": Icons.engineering,
      "badge": "Field Operations",
      "title": "Site Inspection",
      "highlight": "& GPS Geotagging",
      "desc": "Conduct on-ground site inspections for JENs & AENs with live camera proofs and instant boundary verification.",
      "color": const Color(0xFF38BDF8),
    },
    {
      "icon": Icons.task_alt,
      "badge": "Resolution & Closure",
      "title": "Contractor Work Orders",
      "highlight": "& Quality Verification",
      "desc": "Empanel contractors, monitor physical work progress, approve resolution certificates, and update citizens transparently.",
      "color": const Color(0xFF10B981),
    },
  ];

  void _finishIntro() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DepartmentWebPortalScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _finishIntro,
            child: const Text(
              "Skip to Login",
              style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 14),
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
                        // Circle Icon Graphic
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: (slide['color'] as Color).withOpacity(0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: (slide['color'] as Color).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(slide['icon'] as IconData, size: 56, color: slide['color'] as Color),
                        ),
                        const SizedBox(height: 36),

                        // Role Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Text(
                            slide['badge'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: slide['color'] as Color,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          slide['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Highlight Subtitle
                        Text(
                          slide['highlight'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: slide['color'] as Color,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Description
                        Text(
                          slide['desc'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF94A3B8),
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
                  // Page Indicators
                  Row(
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i ? const Color(0xFFE3861C) : const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Next / Enter Portal Button
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
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == _slides.length - 1 ? "Enter Portal" : "Next",
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
