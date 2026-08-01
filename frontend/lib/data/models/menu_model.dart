import 'package:equatable/equatable.dart';

enum MenuCategory {
  manis('manis', 'Manis'),
  telur('telur', 'Telur'),
  tipis('tipis', 'Tipis');

  final String value;
  final String label;

  const MenuCategory(this.value, this.label);

  static MenuCategory? fromValue(String value) {
    try {
      return MenuCategory.values.firstWhere((cat) => cat.value == value);
    } catch (_) {
      return null;
    }
  }
}

class CategoryModel extends Equatable {
  final int id;
  final String name;
  final int? sortOrder;
  final bool isActive;

  const CategoryModel({
    required this.id,
    required this.name,
    this.sortOrder,
    this.isActive = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      sortOrder: json['sort_order'] as int?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [id, name, sortOrder, isActive];
}

class MenuModel extends Equatable {
  final int id;
  final String name;
  final int price;
  final int? categoryId;
  final String? categoryName;
  final String emoji;
  final String? image;
  final String? imageUrl;
  final String defaultImageUrl;
  final bool isActive;
  final int sortOrder;

  const MenuModel({
    required this.id,
    required this.name,
    required this.price,
    this.categoryId,
    this.categoryName,
    required this.emoji,
    this.image,
    this.imageUrl,
    required this.defaultImageUrl,
    required this.isActive,
    required this.sortOrder,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    int? categoryId;
    String? categoryName;

    if (category is Map<String, dynamic>) {
      categoryId = category['id'] as int?;
      categoryName = category['name'] as String?;
    } else if (category is String) {
      categoryName = category;
    }

    return MenuModel(
      id: json['id'] as int,
      name: json['name'] as String,
      price: json['price'] as int,
      categoryId: categoryId,
      categoryName: categoryName,
      emoji: json['emoji'] as String? ?? '🥞',
      image: json['image'] as String?,
      imageUrl: json['image_url'] as String?,
      defaultImageUrl: json['default_image_url'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category_id': categoryId,
      'emoji': emoji,
      'image': image,
      'image_url': imageUrl,
      'default_image_url': defaultImageUrl,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }

  @override
  List<Object?> get props => [id, name, price, categoryId, categoryName, emoji, isActive];
}
