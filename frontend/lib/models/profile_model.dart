class ProfileModel {
  final String id;
  final String fullName;
  final String? phone;
  final String role; // 'adopter' | 'shelter' | 'individual_rescuer' | 'admin'
  final String? organizationName;
  final String? avatarUrl;
  final String? address;
  final bool isVerified;

  ProfileModel({
    required this.id,
    required this.fullName,
    this.phone,
    required this.role,
    this.organizationName,
    this.avatarUrl,
    this.address,
    this.isVerified = false,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'adopter',
      organizationName: json['organization_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      address: json['address'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }

  String get roleTitle {
    switch (role) {
      case 'shelter':
        return 'Refugio u ONG';
      case 'individual_rescuer':
        return 'Particular con Camada / Rescatista';
      case 'admin':
        return 'Administrador';
      case 'adopter':
      default:
        return 'Adoptante';
    }
  }
}
