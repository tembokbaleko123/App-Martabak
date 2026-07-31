import 'package:equatable/equatable.dart';

class MenuModel extends Equatable {
  final int id;
  final String name;
  final int price;
  final String category;
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
    required this.category,
    required this.emoji,
    this.image,
    this.imageUrl,
    required this.defaultImageUrl,
    required this.isActive,
    required this.sortOrder,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    return MenuModel(
      id: json['id'] as int,
      name: json['name'] as String,
      price: json['price'] as int,
      category: json['category'] as String,
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
      'category': category,
      'emoji': emoji,
      'image': image,
      'image_url': imageUrl,
      'default_image_url': defaultImageUrl,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }

  @override
  List<Object?> get props => [id, name, price, category, emoji, isActive];
}

enum MenuCategory {
  manis('manis', 'Manis'),
  telur('telur', 'Telur'),
  tipis('tipis', 'Tipis');

  final String value;
  final String label;

  const MenuCategory(this.value, this.label);

  static MenuCategory? fromValue(String value) {
    return MenuCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MenuCategory.manis,
    );
  }
}
