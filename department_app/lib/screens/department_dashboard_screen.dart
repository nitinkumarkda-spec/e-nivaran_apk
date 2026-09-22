import 'package:flutter/material.dart';
import 'department_web_portal_screen.dart';
import 'department_login_screen.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../widgets/metric_card.dart';
import '../widgets/action_tile.dart';

class DepartmentDashboardScreen extends StatefulWidget {
  const DepartmentDashboardScreen({super.key});

  @override
  State<DepartmentDashboardScreen> createState() => _DepartmentDashboardScreenState();
}

class _DepartmentDashboardScreenState extends State<DepartmentDashboardScreen> {
  String _role = "JEN";
  String _email = "officer@kda.rajasthan.gov.in";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  void _loadUserInfo() async {
    final role = await AuthService.getUserRole();
    final email = await AuthService.getUserEmail();
    if (mounted) {
      setState(() {
        _role = role;
        _email = email;
      });
    }
  }

  void _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DepartmentLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text(
          "Department Console",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Color(0xFF38BDF8)),
            tooltip: "Open Web Portal",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DepartmentWebPortalScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
            tooltip: "Logout",
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Officer Profile Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3861C).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE3861C).withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.shield, color: Color(0xFFE3861C), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _role,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "ACTIVE",
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _email,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Jurisdiction: Kota & Bundi Urban Zones",
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Portal Action Banner
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DepartmentWebPortalScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3861C),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE3861C).withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.dashboard_customize, color: Colors.white, size: 28),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Launch Web Portal Workspace",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Access full grievance pipeline, map & reports",
                            style: TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section Header
            const Text(
              "Operational Overview",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),

            // 4 Grid Metric Cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: const [
                MetricCard(title: "Assigned", count: "14", icon: Icons.inbox, color: Color(0xFF38BDF8)),
                MetricCard(title: "In Progress", count: "08", icon: Icons.pending_actions, color: Color(0xFFF59E0B)),
                MetricCard(title: "SLA Critical", count: "02", icon: Icons.timer_outlined, color: Color(0xFFEF4444)),
                MetricCard(title: "Resolved", count: "45", icon: Icons.check_circle_outline, color: Color(0xFF10B981)),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              "Field Quick Actions",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),

            ActionTile(
              icon: Icons.assignment,
              title: "Grievance Inspection Queue",
              subtitle: "Review newly routed complaints requiring field visit",
              color: const Color(0xFF38BDF8),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DepartmentWebPortalScreen(
                      initialUrl: ApiConfig.complaintsUrl,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            ActionTile(
              icon: Icons.person,
              title: "Department Profile & Zone",
              subtitle: "Manage contact information and active assigned ward",
              color: const Color(0xFF10B981),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DepartmentWebPortalScreen(
                      initialUrl: ApiConfig.profileUrl,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            ActionTile(
              icon: Icons.dns,
              title: "Server Host Settings",
              subtitle: "Current: ${ApiConfig.baseUrl}",
              color: const Color(0xFF94A3B8),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DepartmentWebPortalScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
