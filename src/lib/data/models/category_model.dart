import 'package:equatable/equatable.dart';
import '../../domain/entities/category.dart';

class CategoryModel extends Equatable {
  final String id;
  final String name;
  final String color;
  final String icon;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.createdAt,
    required this.updatedAt,
  });

  // 从数据库Map创建模型
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      color: map['color'] as String,
      icon: map['icon'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // 从实体创建模型
  factory CategoryModel.fromEntity(Category category) {
    return CategoryModel(
      id: category.id,
      name: category.name,
      color: category.color,
      icon: category.icon,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt ?? DateTime.now(),
    );
  }

  // 转换为实体
  Category toEntity() {
    return Category(
      id: id,
      name: name,
      color: color,
      icon: icon,
      sortOrder: 0, // 默认排序
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // 复制并修改部分属性
  CategoryModel copyWith({
    String? id,
    String? name,
    String? color,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        color,
        icon,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, color: $color, icon: $icon)';
  }
}