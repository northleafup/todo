import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/notification_service.dart';

/// Todo实体类
class Todo extends Equatable {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? dueDate;
  final DateTime? dueTime; // dueTime与dueDate保持一致，便于理解
  final ReminderTime reminderTime;
  final String? categoryId;
  final Priority priority;
  final List<String> tags;
  final bool isPinned;
  final int? estimatedMinutes;
  final int? actualMinutes;

  const Todo({
    required this.id,
    required this.title,
    this.description,
    required this.isCompleted,
    required this.createdAt,
    this.updatedAt,
    this.dueDate,
    this.dueTime,
    this.reminderTime = ReminderTime.before15m,
    this.categoryId,
    this.priority = Priority.medium,
    this.tags = const [],
    this.isPinned = false,
    this.estimatedMinutes,
    this.actualMinutes,
  });

  /// 创建新的Todo
  factory Todo.create({
    required String title,
    String? description,
    DateTime? dueDate,
    ReminderTime reminderTime = ReminderTime.before15m,
    String? categoryId,
    Priority priority = Priority.medium,
    List<String> tags = const [],
    bool isPinned = false,
    int? estimatedMinutes,
  }) {
    return Todo(
      id: const Uuid().v4(),
      title: title,
      description: description,
      isCompleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      dueDate: dueDate,
      dueTime: dueDate,
      reminderTime: reminderTime,
      categoryId: categoryId,
      priority: priority,
      tags: tags,
      isPinned: isPinned,
      estimatedMinutes: estimatedMinutes,
    );
  }

  /// 复制并修改Todo
  Todo copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dueDate,
    DateTime? dueTime,
    ReminderTime? reminderTime,
    String? categoryId,
    Priority? priority,
    List<String>? tags,
    bool? isPinned,
    int? estimatedMinutes,
    int? actualMinutes,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      reminderTime: reminderTime ?? this.reminderTime,
      categoryId: categoryId ?? this.categoryId,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
    );
  }

  /// 标记为完成
  Todo markAsCompleted({int? actualMinutes}) {
    return copyWith(
      isCompleted: true,
      updatedAt: DateTime.now(),
      actualMinutes: actualMinutes,
    );
  }

  /// 标记为未完成
  Todo markAsIncomplete() {
    return copyWith(
      isCompleted: false,
      updatedAt: DateTime.now(),
    );
  }

  /// 切换完成状态
  Todo toggleCompleted({int? actualMinutes}) {
    if (isCompleted) {
      return markAsIncomplete();
    } else {
      return markAsCompleted(actualMinutes: actualMinutes);
    }
  }

  /// 检查是否逾期
  bool get isOverdue {
    if (dueTime == null || isCompleted) return false;
    return DateTime.now().isAfter(dueTime!);
  }

  /// 检查是否今天到期
  bool get isDueToday {
    if (dueTime == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueTime!.year, dueTime!.month, dueTime!.day);
    return dueDay.isAtSameMomentAs(today);
  }

  /// 检查是否即将到期（3天内）
  bool get isDueSoon {
    if (dueTime == null || isCompleted) return false;
    final now = DateTime.now();
    final dueSoon = DateTime.now().add(const Duration(days: 3));
    return dueTime!.isBefore(dueSoon);
  }

  /// 获取提醒时间
  DateTime? get reminderTimeScheduled {
    if (dueTime == null) return null;
    return reminderTime.calculateReminderTime(dueTime!);
  }

  /// 检查是否需要提醒
  bool get shouldHaveReminder {
    return dueTime != null && reminderTime != ReminderTime.none;
  }

  /// 获取优先级权重
  double get priorityWeight {
    return priority.value * 10.0;
  }

  /// 获取完成进度
  double get completionProgress {
    if (estimatedMinutes == null) return isCompleted ? 1.0 : 0.0;
    if (actualMinutes == null) return 0.0;

    if (actualMinutes! <= estimatedMinutes!) {
      return 1.0;
    } else {
      return estimatedMinutes! / actualMinutes!;
    }
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        isCompleted,
        createdAt,
        updatedAt,
        dueDate,
        dueTime,
        reminderTime,
        categoryId,
        priority,
        tags,
        isPinned,
        estimatedMinutes,
        actualMinutes,
      ];
}

/// 优先级枚举
enum Priority {
  low,
  medium,
  high;

  int get value {
    switch (this) {
      case Priority.low:
        return 1;
      case Priority.medium:
        return 2;
      case Priority.high:
        return 3;
    }
  }
}
