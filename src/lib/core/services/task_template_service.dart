import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../data/models/task_template_model.dart';
import '../domain/entities/task_template.dart';
import '../domain/entities/todo.dart';
import '../core/services/file_sync_service.dart';
import '../core/services/secure_storage_service.dart';

/// 任务模板管理服务
class TaskTemplateService {
  static const String _templatesKey = 'task_templates';
  static const String _usageStatsKey = 'template_usage_stats';
  static const String _recentTemplatesKey = 'recent_templates';

  final SecureStorageService _secureStorage;
  final FileSyncService _fileSyncService;
  final List<TaskTemplate> _templates = [];
  final List<String> _recentTemplateIds = [];
  final Map<String, int> _usageStats = {};
  Timer? _syncTimer;

  TaskTemplateService(this._secureStorage, this._fileSyncService);

  /// 初始化模板服务
  Future<void> initialize() async {
    await _loadTemplates();
    await _loadUsageStats();
    await _loadRecentTemplates();
    _startSyncTimer();
  }

  /// 销毁服务
  void dispose() {
    _syncTimer?.cancel();
  }

  /// 启动同步定时器
  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _syncWithCloud();
    });
  }

  /// 获取所有模板
  List<TaskTemplate> getAllTemplates() {
    return List.unmodifiable(_templates);
  }

  /// 获取预定义模板
  List<TaskTemplate> getPredefinedTemplates() {
    return _templates.where((t) => t.isDefault).toList();
  }

  /// 获取自定义模板
  List<TaskTemplate> getCustomTemplates() {
    return _templates.where((t) => !t.isDefault).toList();
  }

  /// 根据ID获取模板
  TaskTemplate? getTemplateById(String id) {
    try {
      return _templates.firstWhere((template) => template.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 根据类型获取模板
  List<TaskTemplate> getTemplatesByType(TemplateType type) {
    return _templates.where((template) {
      // 通过标签或名称判断模板类型
      switch (type) {
        case TemplateType.daily:
          return template.tags.contains('日常') ||
                 template.name.contains('日常') ||
                 template.tags.contains('生活');
        case TemplateType.work:
          return template.tags.contains('工作') ||
                 template.name.contains('工作') ||
                 template.name.contains('会议');
        case TemplateType.personal:
          return template.tags.contains('个人') ||
                 template.name.contains('个人') ||
                 template.tags.contains('私事');
        case TemplateType.shopping:
          return template.tags.contains('购物') ||
                 template.name.contains('购物') ||
                 template.name.contains('采购');
        case TemplateType.meeting:
          return template.tags.contains('会议') ||
                 template.name.contains('会议');
        case TemplateType.study:
          return template.tags.contains('学习') ||
                 template.name.contains('学习') ||
                 template.name.contains('培训');
        case TemplateType.health:
          return template.tags.contains('健康') ||
                 template.name.contains('健身') ||
                 template.name.contains('运动');
        case TemplateType.custom:
          return !template.isDefault;
      }
    }).toList();
  }

  /// 获取常用模板
  List<TaskTemplate> getFrequentlyUsedTemplates({int minUsage = 5}) {
    return _templates
        .where((template) => template.usageCount >= minUsage)
        .toList()
      ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
  }

  /// 获取最近使用的模板
  List<TaskTemplate> getRecentlyUsedTemplates({int limit = 10}) {
    final recentTemplates = _recentTemplateIds
        .map((id) => getTemplateById(id))
        .where((template) => template != null)
        .cast<TaskTemplate>()
        .toList();

    return recentTemplates.take(limit).toList();
  }

  /// 搜索模板
  List<TaskTemplate> searchTemplates(String query) {
    if (query.isEmpty) return getAllTemplates();

    final lowerQuery = query.toLowerCase();
    return _templates.where((template) {
      return template.name.toLowerCase().contains(lowerQuery) ||
             (template.description?.toLowerCase().contains(lowerQuery) ?? false) ||
             (template.defaultTitle?.toLowerCase().contains(lowerQuery) ?? false) ||
             template.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// 创建新模板
  Future<TaskTemplate> createTemplate({
    required String name,
    String? description,
    String? defaultTitle,
    String? defaultDescription,
    Priority defaultPriority = Priority.medium,
    int? estimatedMinutes,
    String? categoryId,
    List<String> tags = const [],
  }) async {
    final template = TaskTemplate.create(
      name: name,
      description: description,
      defaultTitle: defaultTitle,
      defaultDescription: defaultDescription,
      defaultPriority: defaultPriority,
      estimatedMinutes: estimatedMinutes,
      categoryId: categoryId,
      tags: tags,
    );

    _templates.add(template);
    await _saveTemplates();
    await _syncWithCloud();

    return template;
  }

  /// 更新模板
  Future<TaskTemplate> updateTemplate(TaskTemplate template) async {
    final index = _templates.indexWhere((t) => t.id == template.id);
    if (index == -1) {
      throw Exception('Template not found: ${template.id}');
    }

    _templates[index] = template.copyWith(updatedAt: DateTime.now());
    await _saveTemplates();
    await _syncWithCloud();

    return _templates[index];
  }

  /// 删除模板
  Future<bool> deleteTemplate(String templateId) async {
    final index = _templates.indexWhere((t) => t.id == templateId);
    if (index == -1) return false;

    _templates.removeAt(index);
    _recentTemplateIds.remove(templateId);
    _usageStats.remove(templateId);

    await _saveTemplates();
    await _saveUsageStats();
    await _saveRecentTemplates();
    await _syncWithCloud();

    return true;
  }

  /// 从模板创建任务
  Future<Todo> createTodoFromTemplate(
    String templateId, {
    String? title,
    String? description,
    String? categoryId,
    Priority? priority,
    int? estimatedMinutes,
    DateTime? dueTime,
    ReminderTime? reminderTime,
    List<String>? tags,
  }) async {
    final template = getTemplateById(templateId);
    if (template == null) {
      throw Exception('Template not found: $templateId');
    }

    // 创建任务
    final todo = template.createTodo(
      title: title,
      description: description,
      categoryId: categoryId,
      priority: priority,
      estimatedMinutes: estimatedMinutes,
      dueTime: dueTime,
      reminderTime: reminderTime,
      tags: tags,
    );

    // 更新模板使用统计
    await _markTemplateAsUsed(templateId);

    return todo;
  }

  /// 标记模板为已使用
  Future<void> _markTemplateAsUsed(String templateId) async {
    final index = _templates.indexWhere((t) => t.id == templateId);
    if (index != -1) {
      _templates[index] = _templates[index].markAsUsed();

      // 更新使用统计
      _usageStats[templateId] = (_usageStats[templateId] ?? 0) + 1;

      // 更新最近使用列表
      _recentTemplateIds.remove(templateId);
      _recentTemplateIds.insert(0, templateId);
      if (_recentTemplateIds.length > 20) {
        _recentTemplateIds.removeLast();
      }

      await _saveTemplates();
      await _saveUsageStats();
      await _saveRecentTemplates();
      await _syncWithCloud();
    }
  }

  /// 应用快捷操作
  Future<Todo> applyQuickAction(
    Todo todo,
    QuickAction action, {
    String? templateId,
  }) async {
    switch (action) {
      case QuickAction.createFromTemplate:
        if (templateId != null) {
          return await createTodoFromTemplate(
            templateId,
            title: todo.title,
            description: todo.description,
          );
        }
        return todo;

      case QuickAction.duplicateTodo:
        return todo.copyWith(
          id: const Uuid().v4(),
          isCompleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          dueDate: null, // 重置截止时间
          dueTime: null,
        );

      case QuickAction.setDueToday:
        final now = DateTime.now();
        final tonight = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return todo.copyWith(dueDate: tonight);

      case QuickAction.setDueTomorrow:
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final tomorrowNight = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59, 59);
        return todo.copyWith(dueDate: tomorrowNight);

      case QuickAction.setDueInOneHour:
        final oneHourLater = DateTime.now().add(const Duration(hours: 1));
        return todo.copyWith(
          dueDate: oneHourLater,
          dueTime: oneHourLater,
        );

      case QuickAction.togglePinned:
        // 假设Todo有isPinned字段
        return todo; // todo.copyWith(isPinned: !todo.isPinned);

      case QuickAction.archiveTodo:
        // 归档逻辑（可能是移动到归档分类或设置归档标志）
        return todo; // todo.copyWith(isArchived: true);

      case QuickAction.setHighPriority:
        return todo.copyWith(priority: Priority.high);

      case QuickAction.setLowPriority:
        return todo.copyWith(priority: Priority.low);

      case QuickAction.clearCompleted:
        // 这个操作需要批量处理，这里返回原任务
        return todo;
    }
  }

  /// 获取模板使用统计
  Map<String, int> getUsageStats() {
    return Map.unmodifiable(_usageStats);
  }

  /// 获取模板推荐
  List<TaskTemplate> getTemplateRecommendations({int limit = 5}) {
    // 基于使用频率和最近使用时间推荐
    final allTemplates = getAllTemplates();

    // 计算推荐分数
    final scoredTemplates = allTemplates.map((template) {
      double score = 0;

      // 使用次数权重
      score += template.usageCount * 2;

      // 最近使用权重
      final recentIndex = _recentTemplateIds.indexOf(template.id);
      if (recentIndex != -1) {
        score += (20 - recentIndex); // 越近使用分数越高
      }

      // 是否为默认模板
      if (template.isDefault) {
        score += 1;
      }

      return MapEntry(template, score);
    }).toList();

    // 按分数排序并返回前N个
    scoredTemplates.sort((a, b) => b.value.compareTo(a.value));
    return scoredTemplates.map((e) => e.key).take(limit).toList();
  }

  /// 导出模板
  Future<String> exportTemplates() async {
    final exportData = {
      'templates': _templates.map((t) => TaskTemplateModel.fromEntity(t).toMap()).toList(),
      'usageStats': _usageStats,
      'recentTemplates': _recentTemplateIds,
      'exportTime': DateTime.now().toIso8601String(),
      'version': '1.0',
    };

    return jsonEncode(exportData);
  }

  /// 导入模板
  Future<bool> importTemplates(String json_data) async {
    try {
      final data = jsonDecode(json_data) as Map<String, dynamic>;
      final templatesData = data['templates'] as List<dynamic>;

      for (final templateData in templatesData) {
        final model = TaskTemplateModel.fromMap(templateData as Map<String, dynamic>);
        final template = model.toEntity();

        // 检查是否已存在
        final existingIndex = _templates.indexWhere((t) => t.id == template.id);
        if (existingIndex == -1) {
          _templates.add(template);
        } else {
          // 合并使用统计
          _templates[existingIndex] = template.copyWith(
            usageCount: _templates[existingIndex].usageCount + template.usageCount,
          );
        }
      }

      // 导入使用统计和最近使用
      if (data['usageStats'] != null) {
        final importUsageStats = data['usageStats'] as Map<String, dynamic>;
        importUsageStats.forEach((key, value) {
          _usageStats[key] = (_usageStats[key] ?? 0) + (value as int);
        });
      }

      if (data['recentTemplates'] != null) {
        final importRecent = (data['recentTemplates'] as List<dynamic>).cast<String>();
        for (final templateId in importRecent) {
          if (!_recentTemplateIds.contains(templateId)) {
            _recentTemplateIds.add(templateId);
          }
        }
        // 保持最近列表长度限制
        if (_recentTemplateIds.length > 20) {
          _recentTemplateIds.removeRange(0, _recentTemplateIds.length - 20);
        }
      }

      await _saveTemplates();
      await _saveUsageStats();
      await _saveRecentTemplates();
      await _syncWithCloud();

      return true;
    } catch (e) {
      print('Error importing templates: $e');
      return false;
    }
  }

  /// 重置为默认模板
  Future<void> resetToDefault() async {
    _templates.clear();
    _recentTemplateIds.clear();
    _usageStats.clear();

    // 加载预定义模板
    final predefinedModels = PredefinedTemplates.getAllPredefined();
    _templates.addAll(predefinedModels.map((model) => model.toEntity()));

    await _saveTemplates();
    await _saveUsageStats();
    await _saveRecentTemplates();
    await _syncWithCloud();
  }

  /// 加载模板
  Future<void> _loadTemplates() async {
    try {
      final data = await _secureStorage.read(_templatesKey);
      if (data != null) {
        final List<dynamic> templatesList = jsonDecode(data);
        _templates.clear();

        for (final templateData in templatesList) {
          final model = TaskTemplateModel.fromMap(templateData as Map<String, dynamic>);
          _templates.add(model.toEntity());
        }
      } else {
        // 首次加载，添加预定义模板
        final predefinedModels = PredefinedTemplates.getAllPredefined();
        _templates.addAll(predefinedModels.map((model) => model.toEntity()));
        await _saveTemplates();
      }
    } catch (e) {
      print('Error loading templates: $e');
      // 发生错误时加载预定义模板
      _templates.clear();
      final predefinedModels = PredefinedTemplates.getAllPredefined();
      _templates.addAll(predefinedModels.map((model) => model.toEntity()));
    }
  }

  /// 保存模板
  Future<void> _saveTemplates() async {
    final data = _templates
        .map((template) => TaskTemplateModel.fromEntity(template).toMap())
        .toList();
    await _secureStorage.write(_templatesKey, jsonEncode(data));
  }

  /// 加载使用统计
  Future<void> _loadUsageStats() async {
    try {
      final data = await _secureStorage.read(_usageStatsKey);
      if (data != null) {
        final Map<String, dynamic> stats = jsonDecode(data);
        _usageStats.clear();
        stats.forEach((key, value) {
          _usageStats[key] = value as int;
        });
      }
    } catch (e) {
      print('Error loading usage stats: $e');
    }
  }

  /// 保存使用统计
  Future<void> _saveUsageStats() async {
    await _secureStorage.write(_usageStatsKey, jsonEncode(_usageStats));
  }

  /// 加载最近使用的模板
  Future<void> _loadRecentTemplates() async {
    try {
      final data = await _secureStorage.read(_recentTemplatesKey);
      if (data != null) {
        final List<dynamic> recentList = jsonDecode(data);
        _recentTemplateIds.clear();
        _recentTemplateIds.addAll(recentList.cast<String>());
      }
    } catch (e) {
      print('Error loading recent templates: $e');
    }
  }

  /// 保存最近使用的模板
  Future<void> _saveRecentTemplates() async {
    await _secureStorage.write(_recentTemplatesKey, jsonEncode(_recentTemplateIds));
  }

  /// 与云端同步
  Future<void> _syncWithCloud() async {
    try {
      // 同步模板数据
      await _fileSyncService.syncData(
        'templates.json',
        () async {
          final data = await _exportTemplatesToJson();
          return data;
        },
        (remoteData) async {
          await _importFromJson(remoteData);
        },
      );
    } catch (e) {
      print('Sync error: $e');
    }
  }

  /// 导出为JSON
  Future<String> _exportTemplatesToJson() async {
    final data = {
      'templates': _templates.map((t) => TaskTemplateModel.fromEntity(t).toMap()).toList(),
      'usageStats': _usageStats,
      'recentTemplates': _recentTemplateIds,
      'lastModified': DateTime.now().toIso8601String(),
      'deviceId': await _fileSyncService.getDeviceId(),
    };
    return jsonEncode(data);
  }

  /// 从JSON导入
  Future<void> _importFromJson(String jsonData) async {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      final remoteLastModified = DateTime.parse(data['lastModified'] as String);

      // 这里可以添加冲突检测和解决逻辑
      // 简单起见，直接使用远程数据

      final templatesData = data['templates'] as List<dynamic>;
      _templates.clear();

      for (final templateData in templatesData) {
        final model = TaskTemplateModel.fromMap(templateData as Map<String, dynamic>);
        _templates.add(model.toEntity());
      }

      if (data['usageStats'] != null) {
        final Map<String, dynamic> stats = data['usageStats'] as Map<String, dynamic>;
        _usageStats.clear();
        stats.forEach((key, value) {
          _usageStats[key] = value as int;
        });
      }

      if (data['recentTemplates'] != null) {
        final List<dynamic> recent = data['recentTemplates'] as List<dynamic>;
        _recentTemplateIds.clear();
        _recentTemplateIds.addAll(recent.cast<String>());
      }

      await _saveTemplates();
      await _saveUsageStats();
      await _saveRecentTemplates();
    } catch (e) {
      print('Error importing from JSON: $e');
    }
  }
}