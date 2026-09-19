class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.role,
    required this.status,
    this.phone,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String role;
  final String status;
  final String? phone;
  final DateTime? createdAt;

  bool get isActive => status == 'active';
  bool get isAdmin => role == 'admin';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      phone: json['phone'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );
  }
}
