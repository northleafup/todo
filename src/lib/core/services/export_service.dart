import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/entities/todo.dart';
import '../../domain/entities/category.dart';

class ExportService {
  // 导出为JSON格式
  static String exportToJson(List<Todo> todos, List<Category> categories) {
    final exportData = {
      'export_date': DateTime.now().toIso8601String(),
      'app_version': '1.0.0',
      'categories': categories.map((category) => _categoryToJson(category)).toList(),
      'todos': todos.map((todo) => _todoToJson(todo)).toList(),
      'statistics': _generateStatistics(todos),
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  // 导出为CSV格式
  static String exportToCsv(List<Todo> todos, {List<Category>? categories}) {
    final buffer = StringBuffer();

    // 添加BOM以支持中文
    buffer.write('\uFEFF');

    // CSV标题行
    buffer.writeln('ID,标题,描述,状态,优先级,分类,截止日期,创建时间,更新时间');

    // 数据行
    for (final todo in todos) {
      final categoryName = _getCategoryName(todo.categoryId, categories);
      final row = [
        _escapeCsvField(todo.id),
        _escapeCsvField(todo.title),
        _escapeCsvField(todo.description ?? ''),
        todo.isCompleted ? '已完成' : '未完成',
        _getPriorityDisplayName(todo.priority),
        _escapeCsvField(categoryName),
        todo.dueDate != null ? _formatDateTime(todo.dueDate!) : '',
        _formatDateTime(todo.createdAt),
        todo.updatedAt != null ? _formatDateTime(todo.updatedAt!) : '',
      ];
      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  // 生成统计信息
  static Map<String, dynamic> _generateStatistics(List<Todo> todos) {
    final total = todos.length;
    final completed = todos.where((todo) => todo.isCompleted).length;
    final incomplete = total - completed;
    final overdue = todos
        .where((todo) => !todo.isCompleted && todo.isOverdue)
        .length;
    final today = todos.where((todo) => todo.isDueToday).length;

    // 按优先级统计
    final highPriority = todos
        .where((todo) => todo.priority == 'high')
        .length;
    final mediumPriority = todos
        .where((todo) => todo.priority == 'medium')
        .length;
    final lowPriority = todos
        .where((todo) => todo.priority == 'low')
        .length;

    // 按分类统计
    final categoryStats = <String, int>{};
    for (final todo in todos) {
      final categoryId = todo.categoryId ?? 'uncategorized';
      categoryStats[categoryId] = (categoryStats[categoryId] ?? 0) + 1;
    }

    return {
      'total_tasks': total,
      'completed_tasks': completed,
      'incomplete_tasks': incomplete,
      'overdue_tasks': overdue,
      'today_tasks': today,
      'completion_rate': total > 0 ? (completed / total * 100).toStringAsFixed(1) : '0.0',
      'priority_distribution': {
        'high': highPriority,
        'medium': mediumPriority,
        'low': lowPriority,
      },
      'category_distribution': categoryStats,
    };
  }

  // Category转JSON
  static Map<String, dynamic> _categoryToJson(Category category) {
    return {
      'id': category.id,
      'name': category.name,
      'color': category.color,
      'icon': category.icon,
      'is_default': category.isDefault,
      'created_at': category.createdAt.toIso8601String(),
      'updated_at': category.updatedAt?.toIso8601String(),
    };
  }

  // Todo转JSON
  static Map<String, dynamic> _todoToJson(Todo todo) {
    return {
      'id': todo.id,
      'title': todo.title,
      'description': todo.description,
      'is_completed': todo.isCompleted,
      'priority': todo.priority,
      'category_id': todo.categoryId,
      'due_date': todo.dueDate?.toIso8601String(),
      'created_at': todo.createdAt.toIso8601String(),
      'updated_at': todo.updatedAt?.toIso8601String(),
      'is_overdue': todo.isOverdue,
      'is_due_today': todo.isDueToday,
      'is_due_soon': todo.isDueSoon,
      'priority_weight': todo.priorityWeight,
      'completion_progress': todo.completionProgress,
    };
  }

  // 获取分类名称
  static String _getCategoryName(String? categoryId, List<Category>? categories) {
    if (categoryId == null || categories == null) return '无分类';

    final category = categories
        .where((c) => c.id == categoryId)
        .firstOrNull;

    return category?.name ?? '未知分类';
  }

  // 获取优先级显示名称
  static String _getPriorityDisplayName(Priority priority) {
    switch (priority) {
      case Priority.high:
        return '高';
      case Priority.medium:
        return '中';
      case 'low':
        return '低';
      default:
        return '中';
    }
  }

  // 格式化日期时间
  static String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  // CSV字段转义
  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  // 导出为Markdown格式
  static String exportToMarkdown(List<Todo> todos, {List<Category>? categories}) {
    final buffer = StringBuffer();

    buffer.writeln('# Todo 任务导出');
    buffer.writeln();
    buffer.writeln('**导出时间**: ${_formatDateTime(DateTime.now())}');
    buffer.writeln('**任务总数**: ${todos.length}');
    buffer.writeln();

    // 统计信息
    final completed = todos.where((todo) => todo.isCompleted).length;
    buffer.writeln('## 📊 统计信息');
    buffer.writeln();
    buffer.writeln('- ✅ 已完成: $completed');
    buffer.writeln('- ⏳ 未完成: ${todos.length - completed}');
    buffer.writeln('- 🔴 逾期: ${todos.where((todo) => !todo.isCompleted && todo.isOverdue).length}');
    buffer.writeln('- 📅 今日到期: ${todos.where((todo) => todo.isDueToday).length}');
    buffer.writeln();

    // 任务列表
    buffer.writeln('## 📋 任务列表');
    buffer.writeln();

    for (int i = 0; i < todos.length; i++) {
      final todo = todos[i];
      final statusIcon = todo.isCompleted ? '✅' : '⏳';
      final priorityIcon = _getPriorityIcon(todo.priority);
      final categoryName = _getCategoryName(todo.categoryId, categories);

      buffer.writeln('${i + 1}. $statusIcon **${todo.title}**');

      if (todo.description != null && todo.description!.isNotEmpty) {
        buffer.writeln('   - 💬 ${todo.description}');
      }

      buffer.writeln('   - $priorityIcon 优先级: ${_getPriorityDisplayName(todo.priority)}');
      buffer.writeln('   - 📁 分类: $categoryName');

      if (todo.dueDate != null) {
        final dueDateStr = _formatDateTime(todo.dueDate!);
        buffer.writeln('   - ⏰ 截止日期: $dueDateStr');
      }

      buffer.writeln('   - 🕒 创建时间: ${_formatDateTime(todo.createdAt)}');
      buffer.writeln();
    }

    return buffer.toString();
  }

  // 获取优先级图标
  static String _getPriorityIcon(Priority priority) {
    switch (priority) {
      case Priority.high:
        return '🔴';
      case Priority.medium:
        return '🟡';
      case Priority.low:
        return '🟢';
      default:
        return '🟡';
    }
  }

  // 生成文件名
  static String generateFileName(String extension) {
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyyMMdd_HHmmss').format(now);
    return 'todo_app_backup_$formattedDate.$extension';
  }

  // 导出到文件
  Future<void> exportTodosToFile(String content, String fileName) async {
    try {
      // 使用文件选择器让用户选择保存位置
      final result = await FilePicker.platform.saveFile(
        dialogTitle: '保存导出文件',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: _getFileExtensions(fileName),
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(content, encoding: utf8);
      } else {
        throw Exception('用户取消了文件保存');
      }
    } catch (e) {
      throw Exception('文件导出失败: $e');
    }
  }

  // 根据文件名获取允许的扩展名
  List<String> _getFileExtensions(String fileName) {
    if (fileName.toLowerCase().endsWith('.json')) {
      return ['json'];
    } else if (fileName.toLowerCase().endsWith('.csv')) {
      return ['csv'];
    } else if (fileName.toLowerCase().endsWith('.md')) {
      return ['md'];
    } else if (fileName.toLowerCase().endsWith('.txt')) {
      return ['txt'];
    }
    return ['json', 'csv', 'md', 'txt'];
  }
}