import 'package:flutter/material.dart';
import 'complaint_track_screen.dart';

class ComplaintsListScreen extends StatefulWidget {
  final List<Map<String, dynamic>> complaints;

  const ComplaintsListScreen({super.key, required this.complaints});

  @override
  State<ComplaintsListScreen> createState() => _ComplaintsListScreenState();
}

class _ComplaintsListScreenState extends State<ComplaintsListScreen> {
  String _selectedFilter = "All";
  String _searchQuery = "";

  final List<String> _filters = ["All", "Pending", "In Progress", "Resolved"];

  @override
  Widget build(BuildContext context) {
    final filtered = widget.complaints.where((c) {
      final status = (c['status'] ?? '').toString().toLowerCase();
      if (_selectedFilter == "Pending" && status != 'pending') return false;
      if (_selectedFilter == "In Progress" && status != 'in progress' && status != 'assigned') return false;
      if (_selectedFilter == "Resolved" && status != 'resolved' && status != 'completed') return false;

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final id = (c['id'] ?? c['complaint_no'] ?? '').toString().toLowerCase();
        final desc = (c['description'] ?? '').toString().toLowerCase();
        final landmark = (c['landmark'] ?? '').toString().toLowerCase();
        return id.contains(query) || desc.contains(query) || landmark.contains(query);
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Search & Filters Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // Search Input
              TextField(
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFE3861C), size: 20),
                  hintText: "Search complaint ID, keyword, landmark...",
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE3861C))),
                ),
              ),
              const SizedBox(height: 10),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFFE3861C),
                        backgroundColor: const Color(0xFFF1F5F9),
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedFilter = filter);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Complaints List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text("No complaints found", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final c = filtered[i];
                    final status = (c['status'] ?? '').toString().toLowerCase();
                    final isResolved = status == 'resolved' || status == 'completed';
                    final isInProgress = status == 'in progress' || status == 'assigned';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      elevation: 1,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ComplaintTrackScreen(complaint: c)),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    c['id'] ?? c['complaint_no'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 14),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isResolved
                                          ? const Color(0xFFD1FAE5)
                                          : (isInProgress ? const Color(0xFFDBEAFE) : const Color(0xFFFEF3C7)),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      (c['status'] ?? 'Pending').toString().toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isResolved
                                            ? const Color(0xFF065F46)
                                            : (isInProgress ? const Color(0xFF1E40AF) : const Color(0xFFB45309)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              Text(
                                c['title'] ?? c['type_name'] ?? 'Civic Problem',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 4),

                              Text(
                                c['description'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                              ),
                              const Divider(height: 20),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 14, color: Color(0xFFE3861C)),
                                      const SizedBox(width: 4),
                                      Text(
                                        c['landmark'] ?? 'Kota',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        c['created_at'] ?? '02 Sep 2026',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.chevron_right, size: 16, color: Color(0xFF94A3B8)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
