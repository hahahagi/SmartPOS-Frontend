class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'kasir',
  });

  final int id;
  final String name;
  final String email;
  final String role;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final source = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : json;
    return UserModel(
      id: _asInt(source['id']),
      name: source['name'] as String? ?? '',
      email: source['email'] as String? ?? '',
      role: (source['role'] as String? ?? 'kasir').trim(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
  };

  String get _normalizedRole => role.trim().toLowerCase();

  bool get isAdmin => _normalizedRole == 'admin';

  bool get isCashier =>
      _normalizedRole == 'kasir' || _normalizedRole == 'cashier';

  String get roleLabel => isAdmin ? 'Admin' : 'Kasir';
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
