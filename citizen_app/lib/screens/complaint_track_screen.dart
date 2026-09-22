import 'package:flutter/material.dart';

class ComplaintTrackScreen extends StatelessWidget {
  final Map<String, dynamic> complaint;

  const ComplaintTrackScreen({super.key, required this.complaint});

  @override
  Widget build(BuildContext context) {
    final status = complaint['status']?.toString().toLowerCase() ?? 'pending';
    final isResolved = status == 'completed' || status == 'resolved';
    final isInProgress = status == 'in progress' || status == 'assigned';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          "Track: ${complaint['id'] ?? complaint['complaint_no']}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Bar Card matching Web App
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        complaint['id'] ?? complaint['complaint_no'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        complaint['created_at'] ?? '02 Sep 2026',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isResolved
                              ? const Color(0xFFD1FAE5)
                              : (isInProgress ? const Color(0xFFDBEAFE) : const Color(0xFFFEF3C7)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          complaint['status']?.toString().toUpperCase() ?? 'PENDING',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isResolved
                                ? const Color(0xFF065F46)
                                : (isInProgress ? const Color(0xFF1E40AF) : const Color(0xFFB45309)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          complaint['priority']?.toString().toUpperCase() ?? 'MEDIUM',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFE3861C)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Complaint Details Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    complaint['title'] ?? complaint['description'] ?? 'Grievance',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    complaint['description'] ?? '',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                  ),
                  const Divider(height: 24),

                  _buildDetailRow("Category", complaint['type_name'] ?? '-'),
                  _buildDetailRow("Sub Type", complaint['sub_type_name'] ?? '-'),
                  if (complaint['garden_park_name'] != null)
                    _buildDetailRow("Garden / Park", complaint['garden_park_name']),
                  _buildDetailRow("Address", complaint['address'] ?? '-'),
                  _buildDetailRow("Landmark", complaint['landmark'] ?? '-'),

                  const SizedBox(height: 12),
                  // Engineer Info Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.engineering, color: Color(0xFF0284C7), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Assigned to JEN: Er. Ramesh Sharma | Contractor: Kota Infratech Pvt Ltd",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0369A1)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Resolution Milestone Stepper matching Web App
            const Text(
              "Resolution Timeline (प्रगति विवरण)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildTimelineItem(
                    title: "Grievance Lodged by Citizen",
                    desc: "Complaint successfully received on KDA e-Nivaran portal.",
                    time: complaint['created_at'] ?? '02 Sep 2026, 10:15 AM',
                    isDone: true,
                    isLast: false,
                  ),
                  _buildTimelineItem(
                    title: "Verified by Moderator",
                    desc: "Jurisdiction and division assigned to Civil Division.",
                    time: "02 Sep 2026, 11:30 AM",
                    isDone: true,
                    isLast: false,
                  ),
                  _buildTimelineItem(
                    title: "Assigned to Field Engineer (JEN)",
                    desc: "Engineer assigned for inspection and site verification.",
                    time: "02 Sep 2026, 02:45 PM",
                    isDone: true,
                    isLast: false,
                  ),
                  _buildTimelineItem(
                    title: "Contractor Work in Progress",
                    desc: "Repair team mobilized to the designated landmark location.",
                    time: isInProgress ? "Active now" : (isResolved ? "Completed" : "Pending"),
                    isDone: isResolved,
                    isCurrent: isInProgress,
                    isLast: false,
                  ),
                  _buildTimelineItem(
                    title: "Resolved & Closed",
                    desc: "Field inspection passed and grievance resolved.",
                    time: isResolved ? "03 Sep 2026, 11:00 AM" : "Estimated within 24h",
                    isDone: isResolved,
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String desc,
    required String time,
    required bool isDone,
    bool isCurrent = false,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isDone
                    ? const Color(0xFF10B981)
                    : (isCurrent ? const Color(0xFFE3861C) : const Color(0xFFE2E8F0)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDone ? Icons.check : (isCurrent ? Icons.circle : Icons.circle_outlined),
                size: 13,
                color: (isDone || isCurrent) ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: isDone ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: (isDone || isCurrent) ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                      ),
                    ),
                    Text(time, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
