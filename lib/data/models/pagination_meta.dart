class PaginationMeta {
  const PaginationMeta({
    required this.currentPage,
    required this.total,
    required this.perPage,
  });

  final int currentPage;
  final int total;
  final int perPage;

  bool get hasMore => currentPage * perPage < total;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: _asInt(json['current_page'], fallback: 1),
      total: _asInt(json['total']),
      perPage: _asInt(json['per_page'], fallback: 10),
    );
  }
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}
