import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/task_template_service.dart';
import '../../core/services/secure_storage_service.dart';
import '../../core/services/file_sync_service.dart';
import '../../domain/entities/task_template.dart';
import '../../domain/entities/todo.dart';

/// 任务模板服务提供者
final taskTemplateServiceProvider = Provider<TaskTemplateService>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final fileSyncService = ref.watch(fileSyncServiceProvider);
  return TaskTemplateService(secureStorage, fileSyncService);
});

/// 任务模板状态管理
class TaskTemplateState {
  final List<TaskTemplate> templates;
  final List<TaskTemplate> recentTemplates;
  final Map<String, int> usageStats;
  final bool isLoading;
  final String? error;

  const TaskTemplateState({
    this.templates = const [],
    this.recentTemplates = const [],
    this.usageStats = const {},
    this.isLoading = false,
    this.error,
  });

  TaskTemplateState copyWith({
    List<TaskTemplate>? templates,
    List<TaskTemplate>? recentTemplates,
    Map<String, int>? usageStats,
    bool? isLoading,
    String? error,
  }) {
    return TaskTemplateState(
      templates: templates ?? this.templates,
      recentTemplates: recentTemplates ?? this.recentTemplates,
      usageStats: usageStats ?? this.usageStats,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// 任务模板状态提供者
final taskTemplateProvider = StateNotifierProvider<TaskTemplateNotifier, TaskTemplateState>((ref) {
  final service = ref.watch(taskTemplateServiceProvider);
  return TaskTemplateNotifier(service);
});

/// 任务模板状态管理器
class TaskTemplateNotifier extends StateNotifier<TaskTemplateState> {
  final TaskTemplateService _service;

  TaskTemplateNotifier(this._service) : super(const TaskTemplateState()) {
    _initialize();
  }

  /// 初始化
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.initialize();
      state = state.copyWith(
        templates: _service.getAllTemplates(),
        recentTemplates: _service.getRecentlyUsedTemplates(),
        usageStats: _service.getUsageStats(),
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 刷新模板列表
  Future<void> refresh() async {
    await _initialize();
  }

  /// 获取所有模板
  List<TaskTemplate> getAllTemplates() {
    return _service.getAllTemplates();
  }

  /// 获取预定义模板
  List<TaskTemplate> getPredefinedTemplates() {
    return _service.getPredefinedTemplates();
  }

  /// 获取自定义模板
  List<TaskTemplate> getCustomTemplates() {
    return _service.getCustomTemplates();
  }

  /// 根据类型获取模板
  List<TaskTemplate> getTemplatesByType(TemplateType type) {
    return _service.getTemplatesByType(type);
  }

  /// 获取常用模板
  List<TaskTemplate> getFrequentlyUsedTemplates({int minUsage = 5}) {
    return _service.getFrequentlyUsedTemplates(minUsage: minUsage);
  }

  /// 获取最近使用的模板
  List<TaskTemplate> getRecentlyUsedTemplates({int limit = 10}) {
    return _service.getRecentlyUsedTemplates(limit: limit);
  }

  /// 搜索模板
  List<TaskTemplate> searchTemplates(String query) {
    return _service.searchTemplates(query);
  }

  /// 根据ID获取模板
  TaskTemplate? getTemplateById(String id) {
    return _service.getTemplateById(id);
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
    try {
      state = state.copyWith(isLoading: true);

      final template = await _service.createTemplate(
        name: name,
        description: description,
        defaultTitle: defaultTitle,
        defaultDescription: defaultDescription,
        defaultPriority: defaultPriority,
        estimatedMinutes: estimatedMinutes,
        categoryId: categoryId,
        tags: tags,
      );

      state = state.copyWith(
        templates: _service.getAllTemplates(),
        isLoading: false,
        error: null,
      );

      return template;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// 更新模板
  Future<TaskTemplate> updateTemplate(TaskTemplate template) async {
    try {
      state = state.copyWith(isLoading: true);

      final updatedTemplate = await _service.updateTemplate(template);

      state = state.copyWith(
        templates: _service.getAllTemplates(),
        isLoading: false,
        error: null,
      );

      return updatedTemplate;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// 删除模板
  Future<bool> deleteTemplate(String templateId) async {
    try {
      state = state.copyWith(isLoading: true);

      final success = await _service.deleteTemplate(templateId);

      if (success) {
        state = state.copyWith(
          templates: _service.getAllTemplates(),
          recentTemplates: _service.getRecentlyUsedTemplates(),
          usageStats: _service.getUsageStats(),
          isLoading: false,
          error: null,
        );
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
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
    try {
      state = state.copyWith(isLoading: true);

      final todo = await _service.createTodoFromTemplate(
        templateId,
        title: title,
        description: description,
        categoryId: categoryId,
        priority: priority,
        estimatedMinutes: estimatedMinutes,
        dueTime: dueTime,
        reminderTime: reminderTime,
        tags: tags,
      );

      state = state.copyWith(
        recentTemplates: _service.getRecentlyUsedTemplates(),
        usageStats: _service.getUsageStats(),
        isLoading: false,
        error: null,
      );

      return todo;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// 应用快捷操作
  Future<Todo> applyQuickAction(
    Todo todo,
    QuickAction action, {
    String? templateId,
  }) async {
    try {
      state = state.copyWith(isLoading: true);

      final updatedTodo = await _service.applyQuickAction(
        todo,
        action,
        templateId: templateId,
      );

      state = state.copyWith(
        recentTemplates: _service.getRecentlyUsedTemplates(),
        usageStats: _service.getUsageStats(),
        isLoading: false,
        error: null,
      );

      return updatedTodo;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// 获取模板使用统计
  Map<String, int> getUsageStats() {
    return _service.getUsageStats();
  }

  /// 获取模板推荐
  List<TaskTemplate> getTemplateRecommendations({int limit = 5}) {
    return _service.getTemplateRecommendations(limit: limit);
  }

  /// 导出模板
  Future<String> exportTemplates() async {
    try {
      return await _service.exportTemplates();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// 导入模板
  Future<bool> importTemplates(String jsonData) async {
    try {
      state = state.copyWith(isLoading: true);

      final success = await _service.importTemplates(jsonData);

      if (success) {
        state = state.copyWith(
          templates: _service.getAllTemplates(),
          recentTemplates: _service.getRecentlyUsedTemplates(),
          usageStats: _service.getUsageStats(),
          isLoading: false,
          error: null,
        );
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// 重置为默认模板
  Future<void> resetToDefault() async {
    try {
      state = state.copyWith(isLoading: true);

      await _service.resetToDefault();

      state = state.copyWith(
        templates: _service.getAllTemplates(),
        recentTemplates: _service.getRecentlyUsedTemplates(),
        usageStats: _service.getUsageStats(),
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 清除错误
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

/// 模板推荐提供者
final templateRecommendationProvider = Provider<List<TaskTemplate>>((ref) {
  final templateNotifier = ref.watch(taskTemplateProvider.notifier);
  return templateNotifier.getTemplateRecommendations();
});

/// 最近使用模板提供者
final recentTemplatesProvider = Provider<List<TaskTemplate>>((ref) {
  final templateState = ref.watch(taskTemplateProvider);
  return templateState.recentTemplates;
});

/// 模板使用统计提供者
final templateUsageStatsProvider = Provider<Map<String, int>>((ref) {
  final templateState = ref.watch(taskTemplateProvider);
  return templateState.usageStats;
});

/// 常用模板提供者
final frequentlyUsedTemplatesProvider = Provider<List<TaskTemplate>>((ref) {
  final templateNotifier = ref.watch(taskTemplateProvider.notifier);
  return templateNotifier.getFrequentlyUsedTemplates();
});

/// 预定义模板提供者
final predefinedTemplatesProvider = Provider<List<TaskTemplate>>((ref) {
  final templateNotifier = ref.watch(taskTemplateProvider.notifier);
  return templateNotifier.getPredefinedTemplates();
});

/// 自定义模板提供者
final customTemplatesProvider = Provider<List<TaskTemplate>>((ref) {
  final templateNotifier = ref.watch(taskTemplateProvider.notifier);
  return templateNotifier.getCustomTemplates();
});

/// 工作模板提供者
final workTemplatesProvider = Provider<List<TaskTemplate>>((ref) {
  final templateNotifier = ref.watch(taskTemplateProvider.notifier);
  return templateNotifier.getTemplatesByType(TemplateType.work);
});

/// 个人模板提供者
final personalTemplatesProvider = Provider<List<TaskTemplate>>((ref) {
  final templateNotifier = ref.watch(taskTemplateProvider.notifier);
  return templateNotifier.getTemplatesByType(TemplateType.personal);
});

/// 学习模板提供者
final studyTemplatesProvider = Provider<List<TaskTemplate>>((ref) {
  final templateNotifier = ref.watch(taskTemplateProvider.notifier);
  return templateNotifier.getTemplatesByType(TemplateType.study);
});

/// 购物模板提供者
final shoppingTemplatesProvider = Provider<List<TaskTemplate>>((ref) {
  final templateNotifier = ref.watch(taskTemplateProvider.notifier);
  return templateNotifier.getTemplatesByType(TemplateType.shopping);
});

/// 健康模板提供者
final healthTemplatesProvider = Provider<List<TaskTemplate>>((ref) {
  final templateNotifier = ref.watch(taskTemplateProvider.notifier);
  return templateNotifier.getTemplatesByType(TemplateType.health);
});

/// 日常模板提供者
final dailyTemplatesProvider = Provider<List<TaskTemplate>>((ref) {
  final templateNotifier = ref.watch(taskTemplateProvider.notifier);
  return templateNotifier.getTemplatesByType(TemplateType.daily);
});

/// 会议模板提供者
final meetingTemplatesProvider = Provider<List<TaskTemplate>>((ref) {
  final templateNotifier = ref.watch(taskTemplateProvider.notifier);
  return templateNotifier.getTemplatesByType(TemplateType.meeting);
});