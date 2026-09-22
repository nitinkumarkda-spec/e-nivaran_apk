import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  final List<Map<String, String>> _notifications = const [
    {
      "title": "Road Repair Verification Completed",
      "body": "Grievance #KDA-7901 regarding street light replacement in Dadabari has been verified and marked Resolved.",
      "time": "Today, 11:20 AM",
      "type": "resolved",
    },
    {
      "title": "Engineer Assigned to Your Complaint",
      "body": "Er. Ramesh Sharma (JEN Civil) has been assigned to grievance #KDA-8142 (Aerodrome Circle).",
      "time": "Yesterday, 03:45 PM",
      "type": "assigned",
    },
    {
      "title": "Monsoon Road Repair Drive",
      "body": "KDA Engineering Cell has deployed mobile pothole patching vans across Aerodrome and Gumanpura zones.",
      "time": "02 Sep 2026",
      "type": "announcement",
    },
    {
      "title": "Complaint Successfully Registered",
      "body": "Your grievance has been submitted with Ticket ID #KDA-8142. Track updates in real time.",
      "time": "02 Sep 2026",
      "type": "registered",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      itemBuilder: (ctx, i) {
        final n = _notifications[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_active, color: Color(0xFFE3861C), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n['title']!,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n['body']!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        n['time']!,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
