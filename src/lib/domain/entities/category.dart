import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// 分类实体类
class Category extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String color;
  final String icon;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isDefault;

  const Category({
    required this.id,
    required this.name,
    this.description,
    required this.color,
    required this.icon,
    required this.sortOrder,
    required this.createdAt,
    this.updatedAt,
    this.isDefault = false,
  });

  /// 创建新的分类
  factory Category.create({
    required String name,
    String? description,
    String color = '#2196F3',
    String icon = 'folder',
    int sortOrder = 0,
  }) {
    return Category(
      id: const Uuid().v4(),
      name: name,
      description: description,
      color: color,
      icon: icon,
      sortOrder: sortOrder,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 创建默认分类
  factory Category.defaultCategory({
    required String name,
    String? description,
    String color = '#9E9E9E',
    String icon = 'inbox',
    int sortOrder = 0,
  }) {
    return Category(
      id: const Uuid().v4(),
      name: name,
      description: description,
      color: color,
      icon: icon,
      sortOrder: sortOrder,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDefault: true,
    );
  }

  /// 复制并修改分类
  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    String? icon,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDefault,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// 更新名称
  Category updateName(String newName) {
    return copyWith(
      name: newName,
      updatedAt: DateTime.now(),
    );
  }

  /// 更新颜色
  Category updateColor(String newColor) {
    return copyWith(
      color: newColor,
      updatedAt: DateTime.now(),
    );
  }

  /// 更新图标
  Category updateIcon(String newIcon) {
    return copyWith(
      icon: newIcon,
      updatedAt: DateTime.now(),
    );
  }

  /// 更新排序
  Category updateSortOrder(int newSortOrder) {
    return copyWith(
      sortOrder: newSortOrder,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        color,
        icon,
        sortOrder,
        createdAt,
        updatedAt,
        isDefault,
      ];

  @override
  String toString() {
    return 'Category(id: $id, name: $name, color: $color, icon: $icon)';
  }
}
