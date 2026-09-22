import 'package:flutter/material.dart';
import 'citizen_dashboard_screen.dart';
import 'register_complaint_screen.dart';
import 'complaints_list_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class MainCitizenNavScreen extends StatefulWidget {
  const MainCitizenNavScreen({super.key});

  @override
  State<MainCitizenNavScreen> createState() => _MainCitizenNavScreenState();
}

class _MainCitizenNavScreenState extends State<MainCitizenNavScreen> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _complaints = [
    {
      "id": "#KDA-8142",
      "complaint_no": "#KDA-8142",
      "type_name": "Civil / Road Construction",
      "sub_type_name": "Pothole Repair (सड़क में गड्ढे)",
      "title": "Pothole Repair (सड़क में गड्ढे)",
      "description": "Deep dangerous pothole near Aerodrome Circle causing traffic slowdown.",
      "landmark": "Aerodrome Circle, Kota",
      "address": "Aerodrome Circle, Gumanpura, Kota, Rajasthan - 324007",
      "status": "In Progress",
      "priority": "High",
      "created_at": "02 Sep 2026, 10:15 AM",
    },
    {
      "id": "#KDA-7901",
      "complaint_no": "#KDA-7901",
      "type_name": "Street Light / Electrical",
      "sub_type_name": "Street Light Not Working (स्ट्रीट लाइट बंद)",
      "title": "Street Light Not Working",
      "description": "Pole lamp fuse blown out for the past 3 days.",
      "landmark": "Near Community Center, Dadabari",
      "address": "Sector 4, Dadabari, Kota, Rajasthan - 324009",
      "status": "Resolved",
      "priority": "Medium",
      "created_at": "28 Aug 2026, 08:30 PM",
    },
    {
      "id": "#KDA-7650",
      "complaint_no": "#KDA-7650",
      "type_name": "Sanitation & Drainage",
      "sub_type_name": "Drainage Overflow (नाली जाम)",
      "title": "Drainage Overflow",
      "description": "Drain overflowing after monsoon rains near main vegetable market.",
      "landmark": "Gumanpura Main Market",
      "address": "Main Market Road, Gumanpura, Kota - 324007",
      "status": "Resolved",
      "priority": "Urgent",
      "created_at": "24 Aug 2026, 09:00 AM",
    },
  ];

  void _onComplaintSubmitted(Map<String, dynamic> complaint) {
    setState(() {
      _complaints.insert(0, complaint);
      _currentIndex = 2; // Switch to Complaints tab
    });
  }

  void _onNavigateToTab(int tabIndex) {
    setState(() {
      _currentIndex = tabIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      CitizenDashboardScreen(onNavigateToTab: _onNavigateToTab),
      RegisterComplaintScreen(onComplaintSubmitted: _onComplaintSubmitted),
      ComplaintsListScreen(complaints: _complaints),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];

    final titles = [
      "Citizen Dashboard",
      "Register Complaint",
      "My Complaints",
      "KDA Alerts",
      "Citizen Profile",
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Image.asset(
                'assets/images/logo2.png',
                fit: BoxFit.contain,
                errorBuilder: (ctx, e, st) => const Icon(Icons.shield, size: 24, color: Color(0xFF005792)),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    children: [
                      TextSpan(text: "KDA "),
                      TextSpan(text: "e", style: TextStyle(color: Color(0xFFE3861C), fontSize: 18)),
                      TextSpan(text: "-Nivaran"),
                    ],
                  ),
                ),
                Text(
                  titles[_currentIndex],
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xFF0F172A)),
            onPressed: () => setState(() => _currentIndex = 3),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: const Color(0xFFE3861C),
        unselectedItemColor: const Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: "Register",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            activeIcon: Icon(Icons.list_alt_rounded),
            label: "Complaints",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            activeIcon: Icon(Icons.notifications),
            label: "Alerts",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
