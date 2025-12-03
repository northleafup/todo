import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/filter.dart';
import '../../domain/entities/todo.dart';
import '../providers/category_provider.dart';

/// 高级筛选对话框
class AdvancedFilterDialog extends ConsumerStatefulWidget {
  final FilterCriteria initialCriteria;

  const AdvancedFilterDialog({
    super.key,
    this.initialCriteria = const FilterCriteria(),
  });

  @override
  ConsumerState<AdvancedFilterDialog> createState() => _AdvancedFilterDialogState();
}

class _AdvancedFilterDialogState extends ConsumerState<AdvancedFilterDialog> {
  late FilterCriteria _criteria;
  late SortConfig _sortConfig;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _criteria = widget.initialCriteria;
    _sortConfig = const SortConfig(option: SortOption.none);
    _searchController.text = _criteria.searchText ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categories = ref.watch(categoryProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_alt,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '高级筛选与排序',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            // 筛选预设
            _buildFilterPresets(),

            const Divider(height: 1),

            // 筛选条件
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 搜索文本
                    _buildSearchSection(),
                    const SizedBox(height: 16),

                    // 分类筛选
                    _buildCategorySection(categories),
                    const SizedBox(height: 16),

                    // 优先级筛选
                    _buildPrioritySection(),
                    const SizedBox(height: 16),

                    // 完成状态筛选
                    _buildCompletionStatusSection(),
                    const SizedBox(height: 16),

                    // 日期范围筛选
                    _buildDateRangeSection(),
                    const SizedBox(height: 16),

                    // 提醒筛选
                    _buildReminderSection(),
                    const SizedBox(height: 16),

                    // 标签筛选
                    _buildTagSection(),
                    const SizedBox(height: 16),

                    // 预估时间筛选
                    _buildEstimatedTimeSection(),
                    const SizedBox(height: 16),

                    // 排序选项
                    _buildSortSection(),
                  ],
                ),
              ),
            ),

            // 底部按钮
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _clearAllFilters,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('清除'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _applyFilters,
                    icon: const Icon(Icons.check),
                    label: const Text('应用'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPresets() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '快速筛选',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FilterPreset.values.map((preset) {
              final isSelected = _criteria.matches(preset.getFilterCriteria());
              return FilterChip(
                avatar: Icon(
                  preset.icon,
                  size: 16,
                  color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                ),
                label: Text(
                  preset.displayName,
                  style: TextStyle(
                    color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _criteria = preset.getFilterCriteria();
                    } else {
                      _criteria = FilterCriteria.empty();
                    }
                  });
                },
                backgroundColor: colorScheme.surface,
                selectedColor: colorScheme.primary,
                checkmarkColor: Colors.white,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '搜索',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: '搜索标题、描述或标签...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _criteria = _criteria.copyWith(searchText: value.trim().isEmpty ? null : value.trim());
            });
          },
        ),
      ],
    );
  }

  Widget _buildCategorySection(List categories) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '分类',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _criteria.categoryId,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '选择分类',
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('全部分类'),
            ),
            ...categories.map((category) => DropdownMenuItem(
              value: category.id,
              child: Text(category.name),
            )),
          ],
          onChanged: (value) {
            setState(() {
              _criteria = _criteria.copyWith(categoryId: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildPrioritySection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '优先级',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Priority.values.map((priority) {
            final isSelected = _criteria.priorities.contains(priority);
            return FilterChip(
              label: Text(priority.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final newPriorities = List<Priority>.from(_criteria.priorities);
                  if (selected) {
                    newPriorities.add(priority);
                  } else {
                    newPriorities.remove(priority);
                  }
                  _criteria = _criteria.copyWith(priorities: newPriorities);
                });
              },
              backgroundColor: _getPriorityColor(priority).withOpacity(0.1),
              selectedColor: _getPriorityColor(priority),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : _getPriorityColor(priority),
              ),
              checkmarkColor: Colors.white,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCompletionStatusSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '完成状态',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: const Text('已完成'),
                value: _criteria.completionStatus.contains(true),
                onChanged: (value) {
                  setState(() {
                    final newStatus = List<bool>.from(_criteria.completionStatus);
                    if (value == true) {
                      if (!newStatus.contains(true)) newStatus.add(true);
                    } else {
                      newStatus.remove(true);
                    }
                    _criteria = _criteria.copyWith(completionStatus: newStatus);
                  });
                },
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: const Text('未完成'),
                value: _criteria.completionStatus.contains(false),
                onChanged: (value) {
                  setState(() {
                    final newStatus = List<bool>.from(_criteria.completionStatus);
                    if (value == true) {
                      if (!newStatus.contains(false)) newStatus.add(false);
                    } else {
                      newStatus.remove(false);
                    }
                    _criteria = _criteria.copyWith(completionStatus: newStatus);
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateRangeSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '日期范围',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectDateRange(),
                icon: const Icon(Icons.date_range),
                label: Text(_criteria.dateRange != null
                    ? '${_formatDate(_criteria.dateRange!.start)} - ${_formatDate(_criteria.dateRange!.end)}'
                    : '选择日期范围'),
              ),
            ),
            if (_criteria.dateRange != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  setState(() {
                    _criteria = _criteria.copyWith(clearDateRange: true);
                  });
                },
                icon: const Icon(Icons.clear),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildReminderSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '提醒',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('全部'),
                value: null,
                groupValue: _criteria.hasReminder,
                onChanged: (value) {
                  setState(() {
                    _criteria = _criteria.copyWith(clearHasReminder: true);
                  });
                },
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('有提醒'),
                value: true,
                groupValue: _criteria.hasReminder,
                onChanged: (value) {
                  setState(() {
                    _criteria = _criteria.copyWith(hasReminder: true);
                  });
                },
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('无提醒'),
                value: false,
                groupValue: _criteria.hasReminder,
                onChanged: (value) {
                  setState(() {
                    _criteria = _criteria.copyWith(hasReminder: false);
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTagSection() {
    final theme = Theme.of(context);

    // 这里可以从所有任务中获取标签列表
    final allTags = ['工作', '个人', '紧急', '重要', '学习', '健康', '购物', '会议'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '标签筛选',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '包含标签',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: allTags.map((tag) {
            final isSelected = _criteria.tags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final newTags = List<String>.from(_criteria.tags);
                  if (selected) {
                    newTags.add(tag);
                  } else {
                    newTags.remove(tag);
                  }
                  _criteria = _criteria.copyWith(tags: newTags);
                });
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        const Text(
          '排除标签',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: allTags.map((tag) {
            final isSelected = _criteria.excludeTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final newTags = List<String>.from(_criteria.excludeTags);
                  if (selected) {
                    newTags.add(tag);
                  } else {
                    newTags.remove(tag);
                  }
                  _criteria = _criteria.copyWith(excludeTags: newTags);
                });
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              backgroundColor: Colors.red.withOpacity(0.1),
              selectedColor: Colors.red,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.red,
              ),
              checkmarkColor: Colors.white,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEstimatedTimeSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '预估时间（分钟）',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _criteria.minEstimatedMinutes?.toString(),
                decoration: const InputDecoration(
                  labelText: '最少',
                  border: OutlineInputBorder(),
                  hintText: '0',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final minutes = int.tryParse(value);
                  setState(() {
                    _criteria = _criteria.copyWith(
                      minEstimatedMinutes: minutes,
                    );
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: _criteria.maxEstimatedMinutes?.toString(),
                decoration: const InputDecoration(
                  labelText: '最多',
                  border: OutlineInputBorder(),
                  hintText: '999',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final minutes = int.tryParse(value);
                  setState(() {
                    _criteria = _criteria.copyWith(
                      maxEstimatedMinutes: minutes,
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '排序',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<SortOption>(
          value: _sortConfig.option,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '选择排序方式',
          ),
          items: SortOption.values.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Row(
                children: [
                  Icon(
                    option.icon,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(option.displayName),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              if (value != null) {
                _sortConfig = _sortConfig.copyWith(option: value);
              }
            });
          },
        ),
        if (_sortConfig.option != SortOption.none && _sortConfig.option != SortOption.completionStatus) ...[
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text(_sortConfig.ascending ? '升序' : '降序'),
            value: _sortConfig.ascending,
            onChanged: (value) {
              setState(() {
                _sortConfig = _sortConfig.copyWith(ascending: value);
              });
            },
          ),
        ],
      ],
    );
  }

  void _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _criteria = _criteria.copyWith(dateRange: picked);
      });
    }
  }

  void _clearAllFilters() {
    setState(() {
      _criteria = FilterCriteria.empty();
      _sortConfig = const SortConfig(option: SortOption.none);
      _searchController.clear();
    });
  }

  void _applyFilters() {
    Navigator.of(context).pop({
      'criteria': _criteria,
      'sortConfig': _sortConfig,
    });
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}

/// 筛选结果显示组件
class FilterResultChips extends ConsumerWidget {
  final FilterCriteria criteria;
  final SortConfig sortConfig;
  final VoidCallback? onClearFilters;

  const FilterResultChips({
    super.key,
    required this.criteria,
    required this.sortConfig,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (criteria.isEmpty && sortConfig.option == SortOption.none) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (criteria.hasAnyFilter) ...[
            Text(
              '筛选条件：',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (criteria.categoryId != null)
                  _buildFilterChip('分类: ${criteria.categoryId}'),
                if (criteria.priorities.isNotEmpty)
                  _buildFilterChip('优先级: ${criteria.priorities.map((p) => p.displayName).join(', ')}'),
                if (criteria.completionStatus.length == 1)
                  _buildFilterChip(criteria.completionStatus.first ? '已完成' : '未完成'),
                if (criteria.dateRange != null)
                  _buildFilterChip('日期: ${_formatDate(criteria.dateRange!.start)} - ${_formatDate(criteria.dateRange!.end)}'),
                if (criteria.hasReminder == true)
                  _buildFilterChip('有提醒'),
                if (criteria.hasReminder == false)
                  _buildFilterChip('无提醒'),
                if (criteria.tags.isNotEmpty)
                  _buildFilterChip('标签: ${criteria.tags.join(', ')}'),
                if (criteria.excludeTags.isNotEmpty)
                  _buildFilterChip('排除: ${criteria.excludeTags.join(', ')}'),
                if (criteria.minEstimatedMinutes != null || criteria.maxEstimatedMinutes != null)
                  _buildFilterChip(_getTimeRangeText()),
                if (criteria.searchText != null && criteria.searchText!.isNotEmpty)
                  _buildFilterChip('搜索: ${criteria.searchText}'),
              ],
            ),
          ],
          if (sortConfig.option != SortOption.none) ...[
            if (criteria.hasAnyFilter) const SizedBox(height: 8),
            Text(
              '排序：',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            _buildFilterChip(sortConfig.option.displayName),
          ],
          if (onClearFilters != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.clear, size: 14),
              label: const Text('清除筛选和排序'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Chip(
      label: Text(
        label,
        style: theme.textTheme.bodySmall,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      backgroundColor: colorScheme.secondaryContainer,
      side: BorderSide.none,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  String _getTimeRangeText() {
    if (criteria.minEstimatedMinutes != null && criteria.maxEstimatedMinutes != null) {
      return '时间: ${criteria.minEstimatedMinutes}-${criteria.maxEstimatedMinutes}分钟';
    } else if (criteria.minEstimatedMinutes != null) {
      return '至少${criteria.minEstimatedMinutes}分钟';
    } else if (criteria.maxEstimatedMinutes != null) {
      return '最多${criteria.maxEstimatedMinutes}分钟';
    }
    return '';
  }
}