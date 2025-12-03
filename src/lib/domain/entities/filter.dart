import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'todo.dart';

/// 筛选条件实体
class FilterCriteria extends Equatable {
  final String? categoryId;
  final List<Priority> priorities;
  final List<bool> completionStatus; // [包含已完成, 包含未完成]
  final DateTimeRange? dateRange;
  final bool? hasReminder;
  final List<String> tags;
  final List<String> excludeTags;
  final int? minEstimatedMinutes;
  final int? maxEstimatedMinutes;
  final String? searchText;

  const FilterCriteria({
    this.categoryId,
    this.priorities = const [],
    this.completionStatus = const [true, true], // 默认包含所有状态
    this.dateRange,
    this.hasReminder,
    this.tags = const [],
    this.excludeTags = const [],
    this.minEstimatedMinutes,
    this.maxEstimatedMinutes,
    this.searchText,
  });

  /// 创建空的筛选条件
  factory FilterCriteria.empty() {
    return const FilterCriteria();
  }

  /// 复制并修改部分属性
  FilterCriteria copyWith({
    String? categoryId,
    List<Priority>? priorities,
    List<bool>? completionStatus,
    DateTimeRange? dateRange,
    bool? hasReminder,
    List<String>? tags,
    List<String>? excludeTags,
    int? minEstimatedMinutes,
    int? maxEstimatedMinutes,
    String? searchText,
    bool clearCategoryId = false,
    bool clearPriorities = false,
    bool clearCompletionStatus = false,
    bool clearDateRange = false,
    bool clearHasReminder = false,
    bool clearTags = false,
    bool clearExcludeTags = false,
    bool clearMinEstimatedMinutes = false,
    bool clearMaxEstimatedMinutes = false,
    bool clearSearchText = false,
  }) {
    return FilterCriteria(
      categoryId: clearCategoryId ? null : categoryId ?? this.categoryId,
      priorities: clearPriorities ? [] : priorities ?? this.priorities,
      completionStatus: clearCompletionStatus ? [true, true] : completionStatus ?? this.completionStatus,
      dateRange: clearDateRange ? null : dateRange ?? this.dateRange,
      hasReminder: clearHasReminder ? null : hasReminder ?? this.hasReminder,
      tags: clearTags ? [] : tags ?? this.tags,
      excludeTags: clearExcludeTags ? [] : excludeTags ?? this.excludeTags,
      minEstimatedMinutes: clearMinEstimatedMinutes ? null : minEstimatedMinutes ?? this.minEstimatedMinutes,
      maxEstimatedMinutes: clearMaxEstimatedMinutes ? null : maxEstimatedMinutes ?? this.maxEstimatedMinutes,
      searchText: clearSearchText ? null : searchText ?? this.searchText,
    );
  }

  /// 检查是否有任何筛选条件
  bool get hasAnyFilter {
    return categoryId != null ||
           priorities.isNotEmpty ||
           completionStatus.length != 2 || // 如果不是同时包含已完成和未完成
           dateRange != null ||
           hasReminder != null ||
           tags.isNotEmpty ||
           excludeTags.isNotEmpty ||
           minEstimatedMinutes != null ||
           maxEstimatedMinutes != null ||
           (searchText != null && searchText!.isNotEmpty);
  }

  /// 检查筛选条件是否为空
  bool get isEmpty => !hasAnyFilter;

  /// 筛选任务列表
  List<Todo> applyFilter(List<Todo> todos) {
    return todos.where((todo) => matches(todo)).toList();
  }

  /// 检查任务是否匹配筛选条件
  bool matches(Todo todo) {
    // 分类筛选
    if (categoryId != null && todo.categoryId != categoryId) {
      return false;
    }

    // 优先级筛选
    if (priorities.isNotEmpty && !priorities.contains(todo.priority)) {
      return false;
    }

    // 完成状态筛选
    if (completionStatus.length == 1) {
      if (completionStatus.first && !todo.isCompleted) return false;
      if (!completionStatus.first && todo.isCompleted) return false;
    }

    // 日期范围筛选
    if (dateRange != null) {
      if (todo.dueDate == null) return false;
      final todoDate = DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);
      final startDate = DateTime(dateRange!.start.year, dateRange!.start.month, dateRange!.start.day);
      final endDate = DateTime(dateRange!.end.year, dateRange!.end.month, dateRange!.end.day);
      if (todoDate.isBefore(startDate) || todoDate.isAfter(endDate)) {
        return false;
      }
    }

    // 提醒筛选
    if (hasReminder != null) {
      if (hasReminder! && todo.reminderTime == ReminderTime.none) return false;
      if (!hasReminder! && todo.reminderTime != ReminderTime.none) return false;
    }

    // 标签筛选（必须包含所有指定标签）
    if (tags.isNotEmpty) {
      for (final tag in tags) {
        if (!todo.tags.contains(tag)) return false;
      }
    }

    // 排除标签筛选
    if (excludeTags.isNotEmpty) {
      for (final tag in excludeTags) {
        if (todo.tags.contains(tag)) return false;
      }
    }

    // 预估时间筛选
    if (minEstimatedMinutes != null && todo.estimatedMinutes != null) {
      if (todo.estimatedMinutes! < minEstimatedMinutes!) return false;
    }
    if (maxEstimatedMinutes != null && todo.estimatedMinutes != null) {
      if (todo.estimatedMinutes! > maxEstimatedMinutes!) return false;
    }

    // 搜索文本筛选
    if (searchText != null && searchText!.isNotEmpty) {
      final query = searchText!.toLowerCase();
      if (!todo.title.toLowerCase().contains(query) &&
          (todo.description == null || !todo.description!.toLowerCase().contains(query)) &&
          !todo.tags.any((tag) => tag.toLowerCase().contains(query))) {
        return false;
      }
    }

    return true;
  }

  /// 获取筛选描述
  String getDescription() {
    final parts = <String>[];

    if (categoryId != null) {
      parts.add('分类: $categoryId');
    }

    if (priorities.isNotEmpty) {
      final priorityNames = priorities.map((p) => p.displayName).join(', ');
      parts.add('优先级: $priorityNames');
    }

    if (completionStatus.length == 1) {
      parts.add(completionStatus.first ? '已完成' : '未完成');
    }

    if (dateRange != null) {
      parts.add('${_formatDate(dateRange!.start)} - ${_formatDate(dateRange!.end)}');
    }

    if (hasReminder == true) {
      parts.add('有提醒');
    } else if (hasReminder == false) {
      parts.add('无提醒');
    }

    if (tags.isNotEmpty) {
      parts.add('标签: ${tags.join(', ')}');
    }

    if (excludeTags.isNotEmpty) {
      parts.add('排除: ${excludeTags.join(', ')}');
    }

    if (minEstimatedMinutes != null || maxEstimatedMinutes != null) {
      if (minEstimatedMinutes != null && maxEstimatedMinutes != null) {
        parts.add('时间: $minEstimatedMinutes-$maxEstimatedMinutes分钟');
      } else if (minEstimatedMinutes != null) {
        parts.add('至少${minEstimatedMinutes}分钟');
      } else if (maxEstimatedMinutes != null) {
        parts.add('最多${maxEstimatedMinutes}分钟');
      }
    }

    if (searchText != null && searchText!.isNotEmpty) {
      parts.add('搜索: $searchText');
    }

    return parts.join(' | ');
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  @override
  List<Object?> get props => [
        categoryId,
        priorities,
        completionStatus,
        dateRange,
        hasReminder,
        tags,
        excludeTags,
        minEstimatedMinutes,
        maxEstimatedMinutes,
        searchText,
      ];

  @override
  String toString() {
    return 'FilterCriteria(${getDescription()})';
  }
}

/// 筛选预设
enum FilterPreset {
  all('全部任务', Icons.dashboard),
  today('今天', Icons.today),
  tomorrow('明天', Icons.event),
  thisWeek('本周', Icons.date_range),
  overdue('已逾期', Icons.warning),
  highPriority('高优先级', Icons.priority_high),
  completed('已完成', Icons.check_circle),
  uncompleted('未完成', Icons.radio_button_unchecked),
  withReminder('有提醒', Icons.notifications),
  withoutReminder('无提醒', Icons.notifications_off),
  tagged('有标签', Icons.label),
  longTerm('长期任务', Icons.schedule),
  quickTasks('快速任务', Icons.flash_on);

  const FilterPreset(this.displayName, this.icon);

  final String displayName;
  final IconData icon;

  FilterCriteria getFilterCriteria() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    switch (this) {
      case FilterPreset.all:
        return FilterCriteria.empty();

      case FilterPreset.today:
        return FilterCriteria(
          dateRange: DateTimeRange(start: today, end: today),
        );

      case FilterPreset.tomorrow:
        return FilterCriteria(
          dateRange: DateTimeRange(start: tomorrow, end: tomorrow),
        );

      case FilterPreset.thisWeek:
        return FilterCriteria(
          dateRange: DateTimeRange(start: weekStart, end: weekEnd),
        );

      case FilterPreset.overdue:
        return FilterCriteria(
          dateRange: DateTimeRange(start: DateTime(2000), end: today.subtract(const Duration(days: 1))),
          completionStatus: [false],
        );

      case FilterPreset.highPriority:
        return FilterCriteria(
          priorities: [Priority.high],
        );

      case FilterPreset.completed:
        return FilterCriteria(
          completionStatus: [true],
        );

      case FilterPreset.uncompleted:
        return FilterCriteria(
          completionStatus: [false],
        );

      case FilterPreset.withReminder:
        return FilterCriteria(
          hasReminder: true,
        );

      case FilterPreset.withoutReminder:
        return FilterCriteria(
          hasReminder: false,
        );

      case FilterPreset.tagged:
        return FilterCriteria(
          tags: [], // 这个筛选需要特殊处理
        );

      case FilterPreset.longTerm:
        return FilterCriteria(
          minEstimatedMinutes: 120, // 2小时以上
        );

      case FilterPreset.quickTasks:
        return FilterCriteria(
          maxEstimatedMinutes: 30, // 30分钟以内
        );
    }
  }
}

/// 排序选项
enum SortOption {
  none('不排序', Icons.sort),
  createdAtAsc('创建时间升序', Icons.arrow_upward),
  createdAtDesc('创建时间降序', Icons.arrow_downward),
  dueDateAsc('截止时间升序', Icons.arrow_upward),
  dueDateDesc('截止时间降序', Icons.arrow_downward),
  priorityAsc('优先级升序', Icons.arrow_upward),
  priorityDesc('优先级降序', Icons.arrow_downward),
  titleAsc('标题升序', Icons.arrow_upward),
  titleDesc('标题降序', Icons.arrow_downward),
  estimatedTimeAsc('预估时间升序', Icons.arrow_upward),
  estimatedTimeDesc('预估时间降序', Icons.arrow_downward),
  completionStatus('完成状态', Icons.check_circle);

  const SortOption(this.displayName, this.icon);

  final String displayName;
  final IconData icon;

  bool get isAscending => name.endsWith('Asc');
}

/// 排序配置
class SortConfig extends Equatable {
  final SortOption option;
  final bool ascending;

  const SortConfig({
    required this.option,
    this.ascending = true,
  });

  SortConfig copyWith({
    SortOption? option,
    bool? ascending,
  }) {
    return SortConfig(
      option: option ?? this.option,
      ascending: ascending ?? this.ascending,
    );
  }

  /// 应用排序
  List<Todo> applySort(List<Todo> todos) {
    if (option == SortOption.none) return todos;

    final sortedTodos = List<Todo>.from(todos);
    sortedTodos.sort((a, b) => _compareTodos(a, b));
    return sortedTodos;
  }

  int _compareTodos(Todo a, Todo b) {
    int result = 0;

    switch (option) {
      case SortOption.createdAtAsc:
        result = a.createdAt.compareTo(b.createdAt);
        break;
      case SortOption.createdAtDesc:
        result = b.createdAt.compareTo(a.createdAt);
        break;
      case SortOption.dueDateAsc:
        if (a.dueDate == null && b.dueDate == null) {
          result = 0;
        } else if (a.dueDate == null) {
          result = 1;
        } else if (b.dueDate == null) {
          result = -1;
        } else {
          result = a.dueDate!.compareTo(b.dueDate!);
        }
        break;
      case SortOption.dueDateDesc:
        if (a.dueDate == null && b.dueDate == null) {
          result = 0;
        } else if (a.dueDate == null) {
          result = 1;
        } else if (b.dueDate == null) {
          result = -1;
        } else {
          result = b.dueDate!.compareTo(a.dueDate!);
        }
        break;
      case SortOption.priorityAsc:
        result = a.priority.index.compareTo(b.priority.index);
        break;
      case SortOption.priorityDesc:
        result = b.priority.index.compareTo(a.priority.index);
        break;
      case SortOption.titleAsc:
        result = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        break;
      case SortOption.titleDesc:
        result = b.title.toLowerCase().compareTo(a.title.toLowerCase());
        break;
      case SortOption.estimatedTimeAsc:
        if (a.estimatedMinutes == null && b.estimatedMinutes == null) {
          result = 0;
        } else if (a.estimatedMinutes == null) {
          result = 1;
        } else if (b.estimatedMinutes == null) {
          result = -1;
        } else {
          result = a.estimatedMinutes!.compareTo(b.estimatedMinutes!);
        }
        break;
      case SortOption.estimatedTimeDesc:
        if (a.estimatedMinutes == null && b.estimatedMinutes == null) {
          result = 0;
        } else if (a.estimatedMinutes == null) {
          result = 1;
        } else if (b.estimatedMinutes == null) {
          result = -1;
        } else {
          result = b.estimatedMinutes!.compareTo(a.estimatedMinutes!);
        }
        break;
      case SortOption.completionStatus:
        result = a.isCompleted.compareTo(b.isCompleted);
        break;
      case SortOption.none:
      default:
        result = 0;
        break;
    }

    return result;
  }

  @override
  List<Object?> get props => [option, ascending];

  @override
  String toString() {
    return 'SortConfig(option: $option, ascending: $ascending)';
  }
}