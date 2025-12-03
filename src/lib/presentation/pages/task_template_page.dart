import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/task_template_provider.dart';
import '../widgets/task_template_widget.dart';
import '../widgets/template_form_dialog.dart';
import '../../domain/entities/task_template.dart';

/// 任务模板管理页面
class TaskTemplatePage extends ConsumerStatefulWidget {
  const TaskTemplatePage({super.key});

  @override
  ConsumerState<TaskTemplatePage> createState() => _TaskTemplatePageState();
}

class _TaskTemplatePageState extends ConsumerState<TaskTemplatePage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final templateState = ref.watch(taskTemplateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('任务模板'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '推荐', icon: Icon(Icons.recommend)),
            Tab(text: '最近使用', icon: Icon(Icons.history)),
            Tab(text: '预定义', icon: Icon(Icons.bookmark)),
            Tab(text: '自定义', icon: Icon(Icons.edit)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showImportDialog,
            icon: const Icon(Icons.upload_file),
            tooltip: '导入模板',
          ),
          IconButton(
            onPressed: _exportTemplates,
            icon: const Icon(Icons.download),
            tooltip: '导出模板',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 18),
                    SizedBox(width: 8),
                    Text('重置为默认'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_usage',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, size: 18),
                    SizedBox(width: 8),
                    Text('清除使用统计'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索框
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索模板...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // 统计信息
          if (_searchQuery.isEmpty) _buildStatsRow(),

          // 模板列表
          Expanded(
            child: templateState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : templateState.error != null
                    ? _buildErrorWidget(templateState.error!)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildRecommendedTemplates(),
                          _buildRecentTemplates(),
                          _buildPredefinedTemplates(),
                          _buildCustomTemplates(),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTemplateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsRow() {
    final theme = Theme.of(context);
    final templateState = ref.watch(taskTemplateProvider);

    final totalTemplates = templateState.templates.length;
    final customTemplates = templateState.templates.where((t) => !t.isDefault).length;
    final totalUsage = templateState.usageStats.values.fold(0, (sum, count) => sum + count);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStatItem('总模板', '$totalTemplates', Icons.dashboard),
          const SizedBox(width: 16),
          _buildStatItem('自定义', '$customTemplates', Icons.edit),
          const SizedBox(width: 16),
          _buildStatItem('总使用', '$totalUsage', Icons.trending_up),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(taskTemplateProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedTemplates() {
    final templates = ref.read(templateRecommendationProvider);
    return _buildTemplateList(templates, '暂无推荐模板');
  }

  Widget _buildRecentTemplates() {
    final templates = ref.read(recentTemplatesProvider);
    return _buildTemplateList(templates, '暂无最近使用的模板');
  }

  Widget _buildPredefinedTemplates() {
    final templates = ref.read(predefinedTemplatesProvider);
    return _buildTemplateList(templates, '暂无预定义模板');
  }

  Widget _buildCustomTemplates() {
    final templates = ref.read(customTemplatesProvider);
    return _buildTemplateList(templates, '暂无自定义模板');
  }

  Widget _buildTemplateList(List<TaskTemplate> templates, String emptyMessage) {
    if (_searchQuery.isNotEmpty) {
      templates = ref.read(taskTemplateProvider.notifier).searchTemplates(_searchQuery);
    }

    if (templates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (_searchQuery.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '尝试使用不同的搜索关键词',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(taskTemplateProvider.notifier).refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final template = templates[index];
          return TaskTemplateCard(
            template: template,
            onTap: () => _showTemplateOptions(template),
            onEdit: () => _showEditTemplateDialog(template),
            onDelete: () => _deleteTemplate(template.id),
          );
        },
      ),
    );
  }

  void _showCreateTemplateDialog() {
    showDialog(
      context: context,
      builder: (context) => const TemplateFormDialog(),
    );
  }

  void _showEditTemplateDialog(TaskTemplate template) {
    showDialog(
      context: context,
      builder: (context) => TemplateFormDialog(template: template),
    );
  }

  void _showTemplateOptions(TaskTemplate template) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 拖动指示器
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 模板标题
              Text(
                template.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (template.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  template.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // 操作按钮
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.add_task),
                      title: const Text('从此模板创建任务'),
                      onTap: () {
                        Navigator.pop(context);
                        _createTodoFromTemplate(template);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('编辑模板'),
                      onTap: () {
                        Navigator.pop(context);
                        _showEditTemplateDialog(template);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.copy),
                      title: const Text('复制模板'),
                      onTap: () {
                        Navigator.pop(context);
                        _duplicateTemplate(template);
                      },
                    ),
                    if (!template.isDefault)
                      ListTile(
                        leading: const Icon(Icons.delete, color: Colors.red),
                        title: const Text('删除模板', style: TextStyle(color: Colors.red)),
                        onTap: () {
                          Navigator.pop(context);
                          _confirmDeleteTemplate(template);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createTodoFromTemplate(TaskTemplate template) {
    // 这里应该跳转到任务创建页面，并预填充模板数据
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('从模板"${template.name}"创建任务功能待实现')),
    );
  }

  void _duplicateTemplate(TaskTemplate template) async {
    try {
      await ref.read(taskTemplateProvider.notifier).createTemplate(
        name: '${template.name} (副本)',
        description: template.description,
        defaultTitle: template.defaultTitle,
        defaultDescription: template.defaultDescription,
        defaultPriority: template.defaultPriority,
        estimatedMinutes: template.estimatedMinutes,
        categoryId: template.categoryId,
        tags: template.tags,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已复制模板: ${template.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('复制失败: $e')),
      );
    }
  }

  void _confirmDeleteTemplate(TaskTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除模板'),
        content: Text('确定要删除模板"${template.name}"吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTemplate(template.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _deleteTemplate(String templateId) async {
    try {
      final success = await ref.read(taskTemplateProvider.notifier).deleteTemplate(templateId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('模板删除成功')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: $e')),
      );
    }
  }

  void _exportTemplates() async {
    try {
      final data = await ref.read(taskTemplateProvider.notifier).exportTemplates();
      // 这里可以保存到文件或分享
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('模板导出功能待实现')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    }
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入模板'),
        content: const Text('模板导入功能待实现'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'reset':
        _confirmResetToDefault();
        break;
      case 'clear_usage':
        _confirmClearUsageStats();
        break;
    }
  }

  void _confirmResetToDefault() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置为默认模板'),
        content: const Text('此操作将删除所有自定义模板和使用统计，恢复到默认模板。确定继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(taskTemplateProvider.notifier).resetToDefault();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已重置为默认模板')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('重置失败: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }

  void _confirmClearUsageStats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除使用统计'),
        content: const Text('此操作将清除所有模板的使用统计和最近使用记录。确定继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(taskTemplateProvider.notifier).resetToDefault();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已清除使用统计')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('清除失败: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }
}