class UserModel {
  final String id;
  final String name;
  final String email;
  final String npm; // Nomor Pokok Mahasiswa
  final String role; // 'mahasiswa', 'asisten'
  final String? photoUrl;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.npm,
    required this.role,
    this.photoUrl,
    required this.createdAt,
  });

  static String _normalizeRole(String? rawRole) {
    final role = rawRole?.toLowerCase();
    if (role == 'asisten') return 'asisten';
    return 'mahasiswa';
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      npm: map['npm'] ?? '',
      role: _normalizeRole(map['role'] as String?),
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'npm': npm,
      'role': role,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get roleLabel {
    switch (role) {
      case 'asisten':
        return 'Asisten Praktikum';
      default:
        return 'Mahasiswa';
    }
  }
}
