import 'category_model.dart';

class CategoryPayload {
  const CategoryPayload({
    required this.name,
    this.description,
    this.isActive = true,
  });

  final String name;
  final String? description;
  final bool isActive;

  factory CategoryPayload.fromModel(CategoryModel model) {
    return CategoryPayload(
      name: model.name,
      description: model.description,
      isActive: model.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'is_active': isActive,
  };

  CategoryPayload copyWith({
    String? name,
    String? description,
    bool? isActive,
  }) {
    return CategoryPayload(
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}
