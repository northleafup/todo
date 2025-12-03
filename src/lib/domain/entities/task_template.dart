import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'todo.dart';
import 'category.dart';

/// 任务模板实体类
class TaskTemplate extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? defaultTitle;
  final String? defaultDescription;
  final Priority defaultPriority;
  final int? estimatedMinutes;
  final String? categoryId;
  final bool isDefault;
  final int usageCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastUsedAt;
  final List<String> tags;

  const TaskTemplate({
    required this.id,
    required this.name,
    this.description,
    this.defaultTitle,
    this.defaultDescription,
    required this.defaultPriority,
    this.estimatedMinutes,
    this.categoryId,
    this.isDefault = false,
    this.usageCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.lastUsedAt,
    this.tags = const [],
  });

  /// 创建新的任务模板
  factory TaskTemplate.create({
    required String name,
    String? description,
    String? defaultTitle,
    String? defaultDescription,
    Priority defaultPriority = Priority.medium,
    int? estimatedMinutes,
    String? categoryId,
    bool isDefault = false,
    List<String> tags = const [],
  }) {
    return TaskTemplate(
      id: const Uuid().v4(),
      name: name,
      description: description,
      defaultTitle: defaultTitle,
      defaultDescription: defaultDescription,
      defaultPriority: defaultPriority,
      estimatedMinutes: estimatedMinutes,
      categoryId: categoryId,
      isDefault: isDefault,
      usageCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastUsedAt: null,
      tags: tags,
    );
  }

  /// 复制并修改模板
  TaskTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? defaultTitle,
    String? defaultDescription,
    Priority? defaultPriority,
    int? estimatedMinutes,
    String? categoryId,
    bool? isDefault,
    int? usageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUsedAt,
    List<String>? tags,
  }) {
    return TaskTemplate(
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
      updatedAt: updatedAt ?? DateTime.now(),
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      tags: tags ?? this.tags,
    );
  }

  /// 从模板创建任务
  Todo createTodo({
    String? title,
    String? description,
    String? categoryId,
    Priority? priority,
    int? estimatedMinutes,
    DateTime? dueTime,
    ReminderTime? reminderTime,
    List<String>? tags,
  }) {
    return Todo.create(
      title: title ?? defaultTitle ?? name,
      description: description ?? defaultDescription,
      dueTime: dueTime,
      reminderTime: reminderTime,
      categoryId: categoryId ?? this.categoryId,
      priority: priority ?? defaultPriority,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      tags: tags ?? this.tags,
    );
  }

  /// 使用模板（增加使用次数和最后使用时间）
  TaskTemplate markAsUsed() {
    return copyWith(
      usageCount: usageCount + 1,
      lastUsedAt: DateTime.now(),
    );
  }

  /// 检查是否为常用模板
  bool get isFrequentlyUsed {
    return usageCount >= 5;
  }

  /// 检查是否最近使用过（7天内）
  bool get isRecentlyUsed {
    if (lastUsedAt == null) return false;
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return lastUsedAt!.isAfter(weekAgo);
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
}

/// 预定义的模板类型
enum TemplateType {
  daily,
  work,
  personal,
  shopping,
  meeting,
  study,
  health,
  custom;

  String get displayName {
    switch (this) {
      case TemplateType.daily:
        return '日常';
      case TemplateType.work:
        return '工作';
      case TemplateType.personal:
        return '个人';
      case TemplateType.shopping:
        return '购物';
      case TemplateType.meeting:
        return '会议';
      case TemplateType.study:
        return '学习';
      case TemplateType.health:
        return '健康';
      case TemplateType.custom:
        return '自定义';
    }
  }

  String get description {
    switch (this) {
      case TemplateType.daily:
        return '日常生活相关任务';
      case TemplateType.work:
        return '工作相关任务';
      case TemplateType.personal:
        return '个人事务';
      case TemplateType.shopping:
        return '购物清单';
      case TemplateType.meeting:
        return '会议准备';
      case TemplateType.study:
        return '学习计划';
      case TemplateType.health:
        return '健康管理';
      case TemplateType.custom:
        return '自定义模板';
    }
  }

  String get icon {
    switch (this) {
      case TemplateType.daily:
        return '🏠';
      case TemplateType.work:
        return '💼';
      case TemplateType.personal:
        return '👤';
      case TemplateType.shopping:
        return '🛒';
      case TemplateType.meeting:
        return '🤝';
      case TemplateType.study:
        return '📚';
      case TemplateType.health:
        return '💪';
      case TemplateType.custom:
        return '📝';
    }
  }

  Color get color {
    switch (this) {
      case TemplateType.daily:
        return const Color(0xFF4CAF50); // Green
      case TemplateType.work:
        return const Color(0xFF2196F3); // Blue
      case TemplateType.personal:
        return const Color(0xFF9C27B0); // Purple
      case TemplateType.shopping:
        return const Color(0xFFFF9800); // Orange
      case TemplateType.meeting:
        return const Color(0xFFF44336); // Red
      case TemplateType.study:
        return const Color(0xFF00BCD4); // Cyan
      case TemplateType.health:
        return const Color(0xFF8BC34A); // Light Green
      case TemplateType.custom:
        return const Color(0xFF607D8B); // Blue Grey
    }
  }
}

/// 快捷操作类型
enum QuickAction {
  createFromTemplate,
  duplicateTodo,
  setDueToday,
  setDueTomorrow,
  setDueInOneHour,
  togglePinned,
  archiveTodo,
  setHighPriority,
  setLowPriority,
  clearCompleted;

  String get displayName {
    switch (this) {
      case QuickAction.createFromTemplate:
        return '从模板创建';
      case QuickAction.duplicateTodo:
        return '复制任务';
      case QuickAction.setDueToday:
        return '设为今天到期';
      case QuickAction.setDueTomorrow:
        return '设为明天到期';
      case QuickAction.setDueInOneHour:
        return '设为1小时后到期';
      case QuickAction.togglePinned:
        return '切换置顶状态';
      case QuickAction.archiveTodo:
        return '归档任务';
      case QuickAction.setHighPriority:
        return '设为高优先级';
      case QuickAction.setLowPriority:
        return '设为低优先级';
      case QuickAction.clearCompleted:
        return '清除已完成任务';
    }
  }

  String get icon {
    switch (this) {
      case QuickAction.createFromTemplate:
        return '📋';
      case QuickAction.duplicateTodo:
        return '📄';
      case QuickAction.setDueToday:
        return '📅';
      case QuickAction.setDueTomorrow:
        return '📆';
      case QuickAction.setDueInOneHour:
        return '⏰';
      case QuickAction.togglePinned:
        return '📌';
      case QuickAction.archiveTodo:
        return '📦';
      case QuickAction.setHighPriority:
        return '🔴';
      case QuickAction.setLowPriority:
        return '🟢';
      case QuickAction.clearCompleted:
        return '🧹';
    }
  }

  String get description {
    switch (this) {
      case QuickAction.createFromTemplate:
        return '使用预定义模板快速创建任务';
      case QuickAction.duplicateTodo:
        return '复制选中的任务';
      case QuickAction.setDueToday:
        return '将任务截止时间设为今天';
      case QuickAction.setDueTomorrow:
        return '将任务截止时间设为明天';
      case QuickAction.setDueInOneHour:
        return '将任务截止时间设为1小时后';
      case QuickAction.togglePinned:
        return '切换任务的置顶状态';
      case QuickAction.archiveTodo:
        return '将任务移动到归档';
      case QuickAction.setHighPriority:
        return '将任务优先级设为高';
      case QuickAction.setLowPriority:
        return '将任务优先级设为低';
      case QuickAction.clearCompleted:
        return '清除所有已完成的任务';
    }
  }
}