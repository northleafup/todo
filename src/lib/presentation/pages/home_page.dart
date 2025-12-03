import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/todo_provider.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/todo_form_dialog.dart';
import '../widgets/category_manager_dialog.dart';
import '../widgets/export_dialog.dart';
import '../providers/theme_provider.dart';
import '../../core/themes/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/todo.dart';
import '../../domain/entities/category.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // 延迟加载数据，避免在widget构建时修改provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });

    // 监听搜索输入变化
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
      ref.read(todoListProvider.notifier).searchTodos(_searchQuery);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      ref.read(todoListProvider.notifier).loadTodos(),
      ref.read(categoryListProvider.notifier).loadCategories(),
    ]);
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final todoState = ref.watch(todoListProvider);
    final stats = ref.watch(appStatsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 应用栏
          SliverAppBar(
            title: Text(
              AppConstants.appName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimary,
              ),
            ),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            pinned: true,
            floating: true,
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primaryContainer,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        // 欢迎语
                        Text(
                          _getWelcomeMessage(),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 统计卡片
                        _buildStatsCard(stats, colorScheme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '全部'),
                Tab(text: '今日'),
                Tab(text: '逾期'),
                Tab(text: '已完成'),
              ],
              labelColor: colorScheme.onPrimary,
              unselectedLabelColor: colorScheme.onPrimary.withOpacity(0.7),
              indicatorColor: colorScheme.onPrimary,
            ),
            actions: [
              IconButton(
                onPressed: () => _showFilterDialog(),
                icon: const Icon(Icons.filter_list),
                tooltip: '筛选',
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'export_data',
                    child: Row(
                      children: [
                        Icon(Icons.download, size: 18),
                        SizedBox(width: 8),
                        Text('导出数据'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'category_manager',
                    child: Row(
                      children: [
                        Icon(Icons.category, size: 18),
                        SizedBox(width: 8),
                        Text('分类管理'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_completed',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all, size: 18),
                        SizedBox(width: 8),
                        Text('清除已完成'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings, size: 18),
                        SizedBox(width: 8),
                        Text('设置'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'about',
                    child: Row(
                      children: [
                        Icon(Icons.info, size: 18),
                        SizedBox(width: 8),
                        Text('关于'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 搜索栏
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索任务...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                            ref.read(todoListProvider.notifier).searchTodos('');
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant,
                ),
              ),
            ),
          ),

          // 内容区域
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTodoList(todoState.filteredTodos),
                _buildTodoList(todoState.filteredTodos
                    .where((todo) => todo.isDueToday)
                    .toList()),
                _buildTodoList(todoState.filteredTodos
                    .where((todo) => todo.isOverdue)
                    .toList()),
                _buildTodoList(todoState.filteredTodos
                    .where((todo) => todo.isCompleted)
                    .toList()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButtonCustom.primary(
        onPressed: () => _showAddTodoDialog(),
        tooltip: '添加任务',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsCard(Map<String, int> stats, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.onPrimary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('总任务', stats['total'] ?? 0, colorScheme),
          _buildStatItem('今日', stats['today'] ?? 0, colorScheme),
          _buildStatItem('逾期', stats['overdue'] ?? 0, colorScheme),
          _buildStatItem('完成', stats['completed'] ?? 0, colorScheme),
        ],
      ),
    ).animate().slideY(begin: 0.3, end: 0).fadeIn();
  }

  Widget _buildStatItem(String label, int value, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onPrimary.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildTodoList(List<Todo> todos) {
    final todoState = ref.watch(todoListProvider);

    if (todoState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (todoState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              todoState.error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CustomButton.secondary(
              text: '重试',
              onPressed: () => ref.read(todoListProvider.notifier).refresh(),
            ),
          ],
        ),
      );
    }

    if (todos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(todos),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptySubMessage(todos),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // 按优先级和创建时间排序
    final sortedTodos = List<Todo>.from(todos)
      ..sort((a, b) {
        // 首先按优先级排序
        final priorityComparison = b.priorityWeight.compareTo(a.priorityWeight);
        if (priorityComparison != 0) return priorityComparison;

        // 然后按完成状态排序
        final completedComparison = (a.isCompleted ? 1 : 0) - (b.isCompleted ? 1 : 0);
        if (completedComparison != 0) return completedComparison;

        // 最后按创建时间排序
        return b.createdAt.compareTo(a.createdAt);
      });

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100), // 为FAB留空间
        itemCount: sortedTodos.length,
        itemBuilder: (context, index) {
          final todo = sortedTodos[index];
          return TodoCard(
            title: todo.title,
            description: todo.description,
            isCompleted: todo.isCompleted,
            priority: todo.priority.name,
            category: ref.watch(categoryNameProvider(todo.categoryId ?? '')) ?? '',
            categoryColor: ref.watch(categoryColorProvider(todo.categoryId ?? '')),
            dueDate: todo.dueDate,
            onTap: () => _showTodoDetails(todo),
            onToggleComplete: () => _toggleTodoComplete(todo.id),
          ).animate()
              .slideX(begin: -0.1, end: 0)
              .fadeIn(delay: (index * 50).ms);
        },
      ),
    );
  }

  String _getWelcomeMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return '早上好！今天又是充满希望的一天';
    } else if (hour < 18) {
      return '下午好！继续加油完成任务吧';
    } else {
      return '晚上好！今天辛苦了';
    }
  }

  String _getEmptyMessage(List<Todo> todos) {
    if (_tabController.index == 0) {
      return '还没有任务';
    } else if (_tabController.index == 1) {
      return '今天没有任务';
    } else if (_tabController.index == 2) {
      return '没有逾期任务';
    } else {
      return '还没有完成的任务';
    }
  }

  String _getEmptySubMessage(List<Todo> todos) {
    if (_tabController.index == 0) {
      return '点击右下角的 + 按钮添加第一个任务';
    } else if (_tabController.index == 1) {
      return '今天没有安排任务，好好休息吧';
    } else if (_tabController.index == 2) {
      return '太棒了！所有任务都按时完成了';
    } else {
      return '继续努力，完成更多任务吧';
    }
  }

  Future<void> _toggleTodoComplete(String todoId) async {
    await ref.read(todoListProvider.notifier).toggleTodoComplete(todoId);
  }

  Future<void> _showTodoDetails(Todo todo) async {
    // 显示编辑任务对话框
    await showDialog(
      context: context,
      builder: (context) => TodoFormDialog(todo: todo),
    );
  }

  Future<void> _showAddTodoDialog() async {
    // 显示添加任务对话框
    await showDialog(
      context: context,
      builder: (context) => const TodoFormDialog(),
    );
  }

  Future<void> _showFilterDialog() async {
    final todoState = ref.read(todoListProvider);
    final categoryState = ref.read(categoryListProvider);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '筛选任务',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 分类筛选
                Text(
                  '按分类筛选',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('全部'),
                      selected: todoState.selectedCategory == null,
                      onSelected: (selected) {
                        ref.read(todoListProvider.notifier).filterByCategory(null);
                      },
                    ),
                    ...categoryState.categories.map(
                      (category) => FilterChip(
                        label: Text(category.name),
                        selected: todoState.selectedCategory == category.id,
                        onSelected: (selected) {
                          ref.read(todoListProvider.notifier)
                              .filterByCategory(selected ? category.id : null);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 优先级筛选
                Text(
                  '按优先级筛选',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('全部'),
                      selected: todoState.selectedPriority == null,
                      onSelected: (selected) {
                        ref.read(todoListProvider.notifier).filterByPriority(null);
                      },
                    ),
                    FilterChip(
                      label: const Text('高'),
                      selected: todoState.selectedPriority == 'high',
                      onSelected: (selected) {
                        ref.read(todoListProvider.notifier)
                            .filterByPriority(selected ? 'high' : null);
                      },
                    ),
                    FilterChip(
                      label: const Text('中'),
                      selected: todoState.selectedPriority == 'medium',
                      onSelected: (selected) {
                        ref.read(todoListProvider.notifier)
                            .filterByPriority(selected ? 'medium' : null);
                      },
                    ),
                    FilterChip(
                      label: const Text('低'),
                      selected: todoState.selectedPriority == 'low',
                      onSelected: (selected) {
                        ref.read(todoListProvider.notifier)
                            .filterByPriority(selected ? 'low' : null);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 按钮
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ref.read(todoListProvider.notifier).clearFilters();
                          Navigator.of(context).pop();
                        },
                        child: const Text('清除筛选'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('确定'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'export_data':
        await _showExportDialog();
        break;
      case 'clear_completed':
        await _clearCompletedTodos();
        break;
      case 'category_manager':
        await _showCategoryManager();
        break;
      case 'settings':
        await _showSettingsDialog();
        break;
      case 'about':
        _showAboutDialog();
        break;
    }
  }

  Future<void> _clearCompletedTodos() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('确定要清除所有已完成的任务吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: 实现清除已完成任务的功能
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('清除已完成任务功能开发中...')),
      );
    }
  }

  Future<void> _showExportDialog() async {
    await showDialog(
      context: context,
      builder: (context) => const ExportDialog(),
    );
  }

  Future<void> _showCategoryManager() async {
    await showDialog(
      context: context,
      builder: (context) => const CategoryManagerDialog(),
    );
  }

  Future<void> _showSettingsDialog() async {
    final themeNotifier = ref.read(themeProvider.notifier);
    final currentTheme = ref.read(themeProvider);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.brightness_6),
              title: const Text('主题模式'),
              subtitle: Text(_getThemeDisplayName(currentTheme)),
              trailing: PopupMenuButton<ThemeMode>(
                icon: const Icon(Icons.arrow_drop_down),
                onSelected: (ThemeMode? mode) {
                  if (mode != null) {
                    switch (mode) {
                      case ThemeMode.light:
                        themeNotifier.setLightMode();
                        break;
                      case ThemeMode.dark:
                        themeNotifier.setDarkMode();
                        break;
                      case ThemeMode.system:
                        themeNotifier.setSystemMode();
                        break;
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: ThemeMode.light,
                    child: Row(
                      children: [
                        Icon(Icons.light_mode),
                        SizedBox(width: 8),
                        Text('浅色模式'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: ThemeMode.dark,
                    child: Row(
                      children: [
                        Icon(Icons.dark_mode),
                        SizedBox(width: 8),
                        Text('深色模式'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: ThemeMode.system,
                    child: Row(
                      children: [
                        Icon(Icons.settings_brightness),
                        SizedBox(width: 8),
                        Text('跟随系统'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.info_outline),
              title: const Text('应用信息'),
              subtitle: Text('${AppConstants.appName} v${AppConstants.appVersion}'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  String _getThemeDisplayName(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationIcon: const Icon(Icons.task_alt, size: 48),
      children: [
        const Text('一个漂亮的跨平台Todo应用，支持macOS、Ubuntu和Android平台。'),
      ],
    );
  }
}