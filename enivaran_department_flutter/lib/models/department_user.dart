class DepartmentUser {
  final String id;
  final String name;
  final String email;
  final String role; // super_admin, moderator, jen, aen, xen, contractor
  final String zone;
  final String mobile;

  DepartmentUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.zone = 'All Zones',
    this.mobile = '',
  });

  String get roleDisplay {
    switch (role.toLowerCase()) {
      case 'super_admin':
        return 'Super Administrator';
      case 'admin':
        return 'Administrator';
      case 'moderator':
        return 'Grievance Moderator';
      case 'jen':
        return 'Junior Engineer (JEN)';
      case 'aen':
        return 'Assistant Engineer (AEN)';
      case 'xen':
        return 'Executive Engineer (XEN)';
      case 'contractor':
        return 'Empaneled Contractor';
      default:
        return 'Department Officer';
    }
  }

  factory DepartmentUser.fromJson(Map<String, dynamic> json) {
    return DepartmentUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Officer',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'officer',
      zone: json['zone']?.toString() ?? 'All Zones',
      mobile: json['mobile']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'zone': zone,
      'mobile': mobile,
    };
  }
}
