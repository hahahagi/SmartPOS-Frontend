class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
  });

  final int id;
  final String name;
  final String? description;
  final bool isActive;

  bool get isInactive => !isActive;

  CategoryModel copyWith({
    int? id,
    String? name,
    String? description,
    bool? isActive,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: _asInt(json['id']),
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      isActive: _asBool(json['is_active'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'is_active': isActive,
  };
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

bool _asBool(dynamic value, {bool defaultValue = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase();
    if (lower == 'true') return true;
    if (lower == 'false') return false;
    final parsed = int.tryParse(lower);
    if (parsed != null) return parsed != 0;
  }
  return defaultValue;
}
