import 'package:equatable/equatable.dart';
import '../../domain/entities/todo.dart';
import '../../core/services/notification_service.dart';

class TodoModel extends Equatable {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final String priority;
  final String? categoryId;
  final DateTime? dueDate;
  final DateTime? dueTime;
  final String reminderTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TodoModel({
    required this.id,
    required this.title,
    this.description,
    required this.isCompleted,
    required this.priority,
    this.categoryId,
    this.dueDate,
    this.dueTime,
    this.reminderTime = 'before15m',
    required this.createdAt,
    required this.updatedAt,
  });

  // 从数据库Map创建模型
  factory TodoModel.fromMap(Map<String, dynamic> map) {
    return TodoModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      isCompleted: (map['is_completed'] as int) == 1,
      priority: map['priority'] as String? ?? 'medium',
      categoryId: map['category_id'] as String?,
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      dueTime: map['due_time'] != null
          ? DateTime.parse(map['due_time'] as String)
          : null,
      reminderTime: map['reminder_time'] as String? ?? 'before15m',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_completed': isCompleted ? 1 : 0,
      'priority': priority,
      'category_id': categoryId,
      'due_date': dueDate?.toIso8601String(),
      'due_time': dueTime?.toIso8601String(),
      'reminder_time': reminderTime,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // 从实体创建模型
  factory TodoModel.fromEntity(Todo todo) {
    return TodoModel(
      id: todo.id,
      title: todo.title,
      description: todo.description,
      isCompleted: todo.isCompleted,
      priority: todo.priority.name,
      categoryId: todo.categoryId,
      dueDate: todo.dueDate,
      dueTime: todo.dueTime,
      reminderTime: todo.reminderTime.name,
      createdAt: todo.createdAt,
      updatedAt: todo.updatedAt ?? DateTime.now(),
    );
  }

  // 转换为实体
  Todo toEntity() {
    return Todo(
      id: id,
      title: title,
      description: description,
      isCompleted: isCompleted,
      priority: Priority.values.firstWhere(
        (p) => p.name == priority,
        orElse: () => Priority.medium,
      ),
      categoryId: categoryId,
      dueDate: dueDate,
      dueTime: dueTime,
      reminderTime: ReminderTime.values.firstWhere(
        (r) => r.name == reminderTime,
        orElse: () => ReminderTime.before15m,
      ),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // 复制并修改部分属性
  TodoModel copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    String? priority,
    String? categoryId,
    DateTime? dueDate,
    DateTime? dueTime,
    String? reminderTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TodoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      categoryId: categoryId ?? this.categoryId,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        isCompleted,
        priority,
        categoryId,
        dueDate,
        dueTime,
        reminderTime,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'TodoModel(id: $id, title: $title, isCompleted: $isCompleted, priority: $priority)';
  }
}