import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/task_template_provider.dart';
import '../../domain/entities/task_template.dart';
import '../../domain/entities/todo.dart';

/// 任务模板卡片组件
class TaskTemplateCard extends ConsumerWidget {
  final TaskTemplate template;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const TaskTemplateCard({
    super.key,
    required this.template,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  // 模板图标
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getTemplateTypeColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        _getTemplateTypeIcon(),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 模板名称和描述
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (template.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            template.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 操作按钮
                  if (showActions) ...[
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEdit?.call();
                            break;
                          case 'delete':
                            _showDeleteConfirmation(context, ref);
                            break;
                          case 'duplicate':
                            _duplicateTemplate(context, ref);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('编辑'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Icons.copy, size: 18),
                              SizedBox(width: 8),
                              Text('复制'),
                            ],
                          ),
                        ),
                        if (!template.isDefault)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('删除', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // 模板信息
              Row(
                children: [
                  // 优先级
                  _buildPriorityChip(context, template.defaultPriority),
                  const SizedBox(width: 8),

                  // 预估时间
                  if (template.estimatedMinutes != null) ...[
                    _buildTimeChip(context, template.estimatedMinutes!),
                    const SizedBox(width: 8),
                  ],

                  // 使用次数
                  _buildUsageChip(context, template.usageCount),
                ],
              ),

              // 标签
              if (template.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: template.tags.map((tag) => Chip(
                    label: Text(
                      tag,
                      style: theme.textTheme.bodySmall,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: colorScheme.secondaryContainer,
                    side: BorderSide.none,
                  )).toList(),
                ),
              ],

              // 默认标题预览
              if (template.defaultTitle != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.preview,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '默认标题: ${template.defaultTitle}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(BuildContext context, Priority priority) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color chipColor;
    String priorityText;

    switch (priority) {
      case Priority.high:
        chipColor = Colors.red;
        priorityText = '高优先级';
        break;
      case Priority.medium:
        chipColor = Colors.orange;
        priorityText = '中优先级';
        break;
      case Priority.low:
        chipColor = Colors.green;
        priorityText = '低优先级';
        break;
    }

    return Chip(
      label: Text(
        priorityText,
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.white,
        ),
      ),
      backgroundColor: chipColor,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildTimeChip(BuildContext context, int minutes) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String timeText;
    if (minutes < 60) {
      timeText = '${minutes}分钟';
    } else if (minutes < 1440) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      timeText = mins > 0 ? '${hours}小时${mins}分钟' : '${hours}小时';
    } else {
      final days = minutes ~/ 1440;
      final hours = (minutes % 1440) ~/ 60;
      timeText = hours > 0 ? '${days}天${hours}小时' : '${days}天';
    }

    return Chip(
      avatar: Icon(
        Icons.schedule,
        size: 14,
        color: colorScheme.onSecondaryContainer,
      ),
      label: Text(
        timeText,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSecondaryContainer,
        ),
      ),
      backgroundColor: colorScheme.secondaryContainer,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildUsageChip(BuildContext context, int usageCount) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Chip(
      avatar: Icon(
        Icons.trending_up,
        size: 14,
        color: colorScheme.onTertiaryContainer,
      ),
      label: Text(
        '使用${usageCount}次',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onTertiaryContainer,
        ),
      ),
      backgroundColor: colorScheme.tertiaryContainer,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  TemplateType _getTemplateType() {
    // 通过标签或名称判断模板类型
    if (template.tags.contains('工作') || template.name.contains('工作') || template.name.contains('会议')) {
      return TemplateType.work;
    } else if (template.tags.contains('购物') || template.name.contains('购物')) {
      return TemplateType.shopping;
    } else if (template.tags.contains('学习') || template.name.contains('学习')) {
      return TemplateType.study;
    } else if (template.tags.contains('健身') || template.tags.contains('健康') || template.name.contains('运动')) {
      return TemplateType.health;
    } else if (template.tags.contains('日常') || template.tags.contains('生活')) {
      return TemplateType.daily;
    } else if (template.tags.contains('个人') || template.name.contains('个人')) {
      return TemplateType.personal;
    } else if (template.tags.contains('会议') || template.name.contains('会议')) {
      return TemplateType.meeting;
    } else {
      return TemplateType.custom;
    }
  }

  Color _getTemplateTypeColor() {
    final type = _getTemplateType();
    return type.color;
  }

  IconData _getTemplateTypeIcon() {
    final type = _getTemplateType();
    switch (type) {
      case TemplateType.daily:
        return Icons.home;
      case TemplateType.work:
        return Icons.work;
      case TemplateType.personal:
        return Icons.person;
      case TemplateType.shopping:
        return Icons.shopping_cart;
      case TemplateType.meeting:
        return Icons.groups;
      case TemplateType.study:
        return Icons.school;
      case TemplateType.health:
        return Icons.fitness_center;
      case TemplateType.custom:
        return Icons.edit;
    }
  }

  IconData _getQuickActionIcon(QuickAction action) {
    switch (action) {
      case QuickAction.createFromTemplate:
        return Icons.note_add;
      case QuickAction.duplicateTodo:
        return Icons.content_copy;
      case QuickAction.setDueToday:
        return Icons.today;
      case QuickAction.setDueTomorrow:
        return Icons.event;
      case QuickAction.setDueInOneHour:
        return Icons.timer;
      case QuickAction.togglePinned:
        return Icons.push_pin;
      case QuickAction.archiveTodo:
        return Icons.archive;
      case QuickAction.setHighPriority:
        return Icons.keyboard_double_arrow_up;
      case QuickAction.setLowPriority:
        return Icons.keyboard_double_arrow_down;
      case QuickAction.clearCompleted:
        return Icons.cleaning_services;
    }
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除模板'),
        content: Text('确定要删除模板"${template.name}"吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _duplicateTemplate(BuildContext context, WidgetRef ref) {
    // 复制模板逻辑
    final newTemplateName = '${template.name} (副本)';
    ref.read(taskTemplateProvider.notifier).createTemplate(
      name: newTemplateName,
      description: template.description,
      defaultTitle: template.defaultTitle,
      defaultDescription: template.defaultDescription,
      defaultPriority: template.defaultPriority,
      estimatedMinutes: template.estimatedMinutes,
      categoryId: template.categoryId,
      tags: template.tags,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已复制模板: $newTemplateName')),
    );
  }
}

/// 模板选择对话框
class TaskTemplateDialog extends ConsumerStatefulWidget {
  const TaskTemplateDialog({super.key});

  @override
  ConsumerState<TaskTemplateDialog> createState() => _TaskTemplateDialogState();
}

class _TaskTemplateDialogState extends ConsumerState<TaskTemplateDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    final templates = ref.watch(taskTemplateProvider);

    // 根据搜索条件过滤模板
    List<TaskTemplate> filteredTemplates;
    if (_searchQuery.isNotEmpty) {
      filteredTemplates = ref.read(taskTemplateProvider.notifier).searchTemplates(_searchQuery);
    } else {
      switch (_tabController.index) {
        case 0:
          filteredTemplates = ref.read(recentTemplatesProvider);
          break;
        case 1:
          filteredTemplates = ref.read(predefinedTemplatesProvider);
          break;
        case 2:
          filteredTemplates = ref.read(customTemplatesProvider);
          break;
        default:
          filteredTemplates = ref.read(taskTemplateProvider.notifier).getAllTemplates();
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 标题和搜索
            Row(
              children: [
                Text(
                  '选择任务模板',
                  style: theme.textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 搜索框
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索模板...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 标签页
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '最近使用'),
                Tab(text: '预定义模板'),
                Tab(text: '自定义模板'),
              ],
            ),

            const SizedBox(height: 16),

            // 模板列表
            Expanded(
              child: filteredTemplates.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isNotEmpty ? '没有找到匹配的模板' : '暂无模板',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredTemplates.length,
                      itemBuilder: (context, index) {
                        final template = filteredTemplates[index];
                        return TaskTemplateCard(
                          template: template,
                          onTap: () {
                            Navigator.of(context).pop(template);
                          },
                          showActions: false,
                        );
                      },
                    ),
            ),

            // 底部按钮
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showCreateTemplateDialog();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('创建模板'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTemplateDialog() {
    // 这里显示创建模板的对话框
    // 可以使用现有的TodoFormDialog作为基础进行修改
  }
}

/// 快捷操作按钮组件
class QuickActionButtons extends ConsumerWidget {
  final Todo todo;
  final Function(Todo) onTodoUpdated;

  const QuickActionButtons({
    super.key,
    required this.todo,
    required this.onTodoUpdated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // 常用快捷操作
    final quickActions = [
      QuickAction.setDueToday,
      QuickAction.setDueTomorrow,
      QuickAction.setDueInOneHour,
      QuickAction.setHighPriority,
      QuickAction.setLowPriority,
      QuickAction.duplicateTodo,
      QuickAction.createFromTemplate,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '快捷操作',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickActions.map((action) {
              return ActionChip(
                avatar: Icon(
                  _getQuickActionIcon(action),
                  size: 16,
                ),
                label: Text(
                  action.displayName,
                  style: theme.textTheme.bodySmall,
                ),
                onPressed: () => _handleQuickAction(context, ref, action),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _handleQuickAction(BuildContext context, WidgetRef ref, QuickAction action) async {
    try {
      final templateService = ref.read(taskTemplateProvider.notifier);

      if (action == QuickAction.createFromTemplate) {
        // 显示模板选择对话框
        final selectedTemplate = await showDialog<TaskTemplate>(
          context: context,
          builder: (context) => const TaskTemplateDialog(),
        );

        if (selectedTemplate != null) {
          final newTodo = await templateService.createTodoFromTemplate(selectedTemplate.id);
          onTodoUpdated(newTodo);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已从模板"${selectedTemplate.name}"创建任务')),
          );
        }
      } else {
        final updatedTodo = await templateService.applyQuickAction(todo, action);
        onTodoUpdated(updatedTodo);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已执行: ${action.displayName}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('操作失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}