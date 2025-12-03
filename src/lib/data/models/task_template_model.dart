import 'package:equatable/equatable.dart';
import '../../domain/entities/task_template.dart';
import '../../domain/entities/todo.dart';
import '../../core/services/notification_service.dart';

/// 任务模板数据模型
class TaskTemplateModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? defaultTitle;
  final String? defaultDescription;
  final String defaultPriority;
  final int? estimatedMinutes;
  final String? categoryId;
  final int isDefault;
  final int usageCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastUsedAt;
  final String tags; // 以逗号分隔的字符串

  const TaskTemplateModel({
    required this.id,
    required this.name,
    this.description,
    this.defaultTitle,
    this.defaultDescription,
    required this.defaultPriority,
    this.estimatedMinutes,
    this.categoryId,
    required this.isDefault,
    required this.usageCount,
    required this.createdAt,
    this.updatedAt,
    this.lastUsedAt,
    required this.tags,
  });

  // 从数据库Map创建模型
  factory TaskTemplateModel.fromMap(Map<String, dynamic> map) {
    return TaskTemplateModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      defaultTitle: map['default_title'] as String?,
      defaultDescription: map['default_description'] as String?,
      defaultPriority: map['default_priority'] as String? ?? 'medium',
      estimatedMinutes: map['estimated_minutes'] as int?,
      categoryId: map['category_id'] as String?,
      isDefault: (map['is_default'] as int) == 1,
      usageCount: map['usage_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      lastUsedAt: map['last_used_at'] != null
          ? DateTime.parse(map['last_used_at'] as String)
          : null,
      tags: map['tags'] as String? ?? '',
    );
  }

  // 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'default_title': defaultTitle,
      'default_description': defaultDescription,
      'default_priority': defaultPriority,
      'estimated_minutes': estimatedMinutes,
      'category_id': categoryId,
      'is_default': isDefault ? 1 : 0,
      'usage_count': usageCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_used_at': lastUsedAt?.toIso8601String(),
      'tags': tags,
    };
  }

  // 从实体创建模型
  factory TaskTemplateModel.fromEntity(TaskTemplate template) {
    return TaskTemplateModel(
      id: template.id,
      name: template.name,
      description: template.description,
      defaultTitle: template.defaultTitle,
      defaultDescription: template.defaultDescription,
      defaultPriority: template.defaultPriority.name,
      estimatedMinutes: template.estimatedMinutes,
      categoryId: template.categoryId,
      isDefault: template.isDefault ? 1 : 0,
      usageCount: template.usageCount,
      createdAt: template.createdAt,
      updatedAt: template.updatedAt,
      lastUsedAt: template.lastUsedAt,
      tags: template.tags.join(','),
    );
  }

  // 转换为实体
  TaskTemplate toEntity() {
    return TaskTemplate(
      id: id,
      name: name,
      description: description,
      defaultTitle: defaultTitle,
      defaultDescription: defaultDescription,
      defaultPriority: Priority.values.firstWhere(
        (p) => p.name == defaultPriority,
        orElse: () => Priority.medium,
      ),
      estimatedMinutes: estimatedMinutes,
      categoryId: categoryId,
      isDefault: isDefault == 1,
      usageCount: usageCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastUsedAt: lastUsedAt,
      tags: tags.isEmpty ? [] : tags.split(',').where((tag) => tag.isNotEmpty).toList(),
    );
  }

  // 复制并修改部分属性
  TaskTemplateModel copyWith({
    String? id,
    String? name,
    String? description,
    String? defaultTitle,
    String? defaultDescription,
    String? defaultPriority,
    int? estimatedMinutes,
    String? categoryId,
    int? isDefault,
    int? usageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUsedAt,
    String? tags,
  }) {
    return TaskTemplateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      defaultTitle: defaultTitle ?? this.defaultTitle,
      defaultDescription: defaultDescription ?? this.defaultDescription,
      defaultPriority: defaultPriority ?? this.defaultPriority,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      categoryId: categoryId ?? this.categoryId,
      isDefault: isDefault ?? this.isDefault,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        defaultTitle,
        defaultDescription,
        defaultPriority,
        estimatedMinutes,
        categoryId,
        isDefault,
        usageCount,
        createdAt,
        updatedAt,
        lastUsedAt,
        tags,
      ];

  @override
  String toString() {
    return 'TaskTemplateModel(id: $id, name: $name, usageCount: $usageCount)';
  }
}

/// 预定义模板数据
class PredefinedTemplates {
  static const List<Map<String, dynamic>> defaultTemplates = [
    {
      'name': '日常晨会',
      'description': '晨会讨论事项模板',
      'default_title': '晨会讨论',
      'default_description': '准备晨会要讨论的内容',
      'default_priority': 'medium',
      'estimated_minutes': 30,
      'tags': '工作,会议',
      'is_default': 1,
    },
    {
      'name': '工作任务',
      'description': '标准工作任务模板',
      'default_title': '工作任务',
      'default_description': '待处理的工作事项',
      'default_priority': 'high',
      'estimated_minutes': 60,
      'tags': '工作',
      'is_default': 1,
    },
    {
      'name': '学习计划',
      'description': '学习任务和目标模板',
      'default_title': '学习任务',
      'default_description': '学习目标和内容',
      'default_priority': 'medium',
      'estimatedMinutes': 45,
      'tags': '学习,个人',
      'is_default': 1,
    },
    {
      'name': '健身计划',
      'description': '健身和运动任务模板',
      'default_title': '健身锻炼',
      'default_description': '今日健身计划和目标',
      'default_priority': 'medium',
      'estimatedMinutes': 60,
      'tags': '健康,运动',
      'is_default': 1,
    },
    {
      'name': '购物清单',
      'description': '购物采购清单模板',
      'default_title': '采购清单',
      'default_description': '需要购买的物品列表',
      'default_priority': 'low',
      'estimatedMinutes': 30,
      'tags': '购物,生活',
      'is_default': 1,
    },
    {
      'name': '会议准备',
      'description': '会议前准备工作模板',
      'default_title': '会议准备',
      'default_description': '会议前需要准备的材料和事项',
      'default_priority': 'high',
      'estimatedMinutes': 30,
      'tags': '工作,会议',
      'is_default': 1,
    },
  ];

  /// 获取所有预定义模板
  static List<TaskTemplateModel> getAllPredefined() {
    return defaultTemplates.map((data) {
      final now = DateTime.now();
      return TaskTemplateModel(
        id: 'predefined_${data['name']}',
        name: data['name'] as String,
        description: data['description'] as String?,
        defaultTitle: data['default_title'] as String?,
        defaultDescription: data['default_description'] as String?,
        defaultPriority: data['default_priority'] as String,
        estimatedMinutes: data['estimated_minutes'] as int?,
        categoryId: null,
        isDefault: data['is_default'] as int,
        usageCount: 0,
        createdAt: now,
        updatedAt: now,
        lastUsedAt: null,
        tags: data['tags'] as String,
      );
    }).toList();
  }

  /// 根据名称获取预定义模板
  static TaskTemplateModel? getTemplateByName(String name) {
    final template = defaultTemplates.firstWhere(
      (data) => data['name'] == name,
      orElse: () => null,
    );

    if (template == null) return null;

    final now = DateTime.now();
    return TaskTemplateModel(
      id: 'predefined_${template['name']}',
      name: template['name'] as String,
      description: template['description'] as String?,
      defaultTitle: template['default_title'] as String?,
      defaultDescription: template['default_description'] as String?,
      defaultPriority: template['default_priority'] as String,
      estimatedMinutes: template['estimated_minutes'] as int?,
      categoryId: null,
      isDefault: template['is_default'] as int,
      usageCount: 0,
      createdAt: now,
      updatedAt: now,
      lastUsedAt: null,
      tags: template['tags'] as String,
    );
  }
}