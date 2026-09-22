class Complaint {
  final String complaintNo;
  final String title;
  final String typeName;
  final String subTypeName;
  final String? gardenParkName;
  final String description;
  final String landmark;
  final String address;
  final String? latitude;
  final String? longitude;
  final String status;
  final String priority;
  final String createdAt;
  final String? photoPath;
  final String? jenName;
  final String? contractorName;
  final List<TimelineStep> timeline;

  Complaint({
    required this.complaintNo,
    required this.title,
    required this.typeName,
    required this.subTypeName,
    this.gardenParkName,
    required this.description,
    required this.landmark,
    required this.address,
    this.latitude,
    this.longitude,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.photoPath,
    this.jenName,
    this.contractorName,
    required this.timeline,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      complaintNo: json['complaint_no'] ?? json['tracking_id'] ?? json['id'] ?? '',
      title: json['title'] ?? json['description'] ?? 'Grievance',
      typeName: json['type_name'] ?? json['category'] ?? 'General',
      subTypeName: json['sub_type_name'] ?? 'Other',
      gardenParkName: json['garden_park_name'],
      description: json['description'] ?? '',
      landmark: json['landmark'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'medium',
      createdAt: json['created_at'] ?? 'Today',
      photoPath: json['photo_url'] ?? json['photo_path'],
      jenName: json['jen_name'],
      contractorName: json['contractor_name'],
      timeline: (json['timeline'] as List<dynamic>?)
              ?.map((t) => TimelineStep.fromJson(t))
              .toList() ??
          [],
    );
  }
}

class TimelineStep {
  final String title;
  final String description;
  final String date;
  final bool isCompleted;

  TimelineStep({
    required this.title,
    required this.description,
    required this.date,
    required this.isCompleted,
  });

  factory TimelineStep.fromJson(Map<String, dynamic> json) {
    return TimelineStep(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: json['date'] ?? '',
      isCompleted: json['is_completed'] ?? false,
    );
  }
}
