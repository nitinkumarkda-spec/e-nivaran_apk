import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CitizenDashboardScreen extends StatefulWidget {
  final Function(int) onNavigateToTab;
  const CitizenDashboardScreen({super.key, required this.onNavigateToTab});

  @override
  State<CitizenDashboardScreen> createState() => _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends State<CitizenDashboardScreen> {
  String _userName = "Citizen";

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString("citizen_name") ?? "Citizen";
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Hero Card matching Web App
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("✨ Welcome, ", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      Text("Citizen 🙏", style: TextStyle(color: Color(0xFFE3861C), fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Hello, $_userName!",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Register and track your civic complaints easily. Kota Development Authority is at your service.",
                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.4),
                ),
                const SizedBox(height: 20),

                // Hero Action Buttons
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => widget.onNavigateToTab(1), // Register Tab
                      icon: const Icon(Icons.add_circle, color: Colors.white, size: 18),
                      label: const Text("Register Grievance", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE3861C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () => widget.onNavigateToTab(2), // Complaints Tab
                      icon: const Icon(Icons.list_alt, color: Colors.white, size: 18),
                      label: const Text("My Complaints", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF475569)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Overview & Status Section Header
          const Row(
            children: [
              Icon(Icons.pie_chart, color: Color(0xFFE3861C), size: 20),
              SizedBox(width: 8),
              Text(
                "Overview & Status (स्थिति सारांश)",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Stats Grid matching Web App (Total, Pending, Assigned, Resolved, Rejected, Reopened)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard("Total", "3", Icons.assignment, const Color(0xFFE3861C), () => widget.onNavigateToTab(2)),
              _buildStatCard("Pending", "1", Icons.hourglass_top, const Color(0xFFD97706), () => widget.onNavigateToTab(2)),
              _buildStatCard("Assigned", "1", Icons.engineering, const Color(0xFF2563EB), () => widget.onNavigateToTab(2)),
              _buildStatCard("Resolved", "1", Icons.check_circle, const Color(0xFF16A34A), () => widget.onNavigateToTab(2)),
              _buildStatCard("Rejected", "0", Icons.cancel, const Color(0xFFDC2626), () => widget.onNavigateToTab(2)),
              _buildStatCard("Reopened", "0", Icons.refresh, const Color(0xFFEA580C), () => widget.onNavigateToTab(2)),
            ],
          ),
          const SizedBox(height: 24),

          // Quick Action Banner
          Card(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.support_agent, color: Color(0xFFE3861C), size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Need Immediate Help?",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Call KDA 24x7 Helpline: 181 / 0744-2500051",
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String count, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                Text(
                  count,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
          ],
        ),
      ),
    );
  }
}
