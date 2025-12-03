import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/todo_provider.dart';
import '../../core/themes/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/category.dart';

class CategoryManagerDialog extends ConsumerStatefulWidget {
  const CategoryManagerDialog({Key? key}) : super(key: key);

  @override
  ConsumerState<CategoryManagerDialog> createState() => _CategoryManagerDialogState();
}

class _CategoryManagerDialogState extends ConsumerState<CategoryManagerDialog> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryState = ref.watch(categoryListProvider);
    final customCategories = categoryState.categories
        .where((category) => !category.isDefault)
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: 500,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Icon(
                  Icons.category,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  '分类管理',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showAddCategoryDialog(),
                  icon: const Icon(Icons.add),
                  tooltip: '添加分类',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 分类列表
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 默认分类
                  if (categoryState.categories.isNotEmpty) ...[
                    Text(
                      '默认分类',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...categoryState.categories
                        .where((category) => category.isDefault)
                        .map((category) => _buildCategoryItem(category, isDefault: true)),
                    const SizedBox(height: 16),
                  ],

                  // 自定义分类
                  Text(
                    '自定义分类',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (customCategories.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 48,
                            color: colorScheme.onSurface.withOpacity(0.4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '还没有自定义分类',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '点击右上角的 + 按钮添加第一个分类',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ...customCategories.map((category) => _buildCategoryItem(category)),
                  ],
                ],
              ),
            ),

            // 关闭按钮
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('关闭'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(Category category, {bool isDefault = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryColor = _parseColor(category.color);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(12),
        color: colorScheme.surface,
      ),
      child: Row(
        children: [
          // 分类图标和颜色
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _getIconData(category.icon),
              color: categoryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // 分类信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      category.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '默认',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                FutureBuilder<int>(
                  future: _getCategoryTodoCount(category.id),
                  builder: (context, snapshot) {
                    final todoCount = snapshot.data ?? 0;
                    return Text(
                      '$todoCount 个任务',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // 操作按钮
          if (!isDefault) ...[
            PopupMenuButton<String>(
              onSelected: (value) => _handleCategoryAction(category, value),
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
              child: Icon(
                Icons.more_vert,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ] else ...[
            Icon(
              Icons.lock_outline,
              color: colorScheme.onSurface.withOpacity(0.4),
              size: 20,
            ),
          ],
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'work':
        return Icons.work;
      case 'personal':
        return Icons.person;
      case 'shopping':
        return Icons.shopping_cart;
      case 'health':
        return Icons.favorite;
      case 'education':
        return Icons.school;
      case 'finance':
        return Icons.account_balance;
      case 'travel':
        return Icons.flight;
      case 'home':
        return Icons.home;
      case 'family':
        return Icons.people;
      default:
        return Icons.category;
    }
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }

  Future<int> _getCategoryTodoCount(String categoryId) async {
    final todoState = ref.read(todoListProvider);
    final todos = todoState.todos
        .where((todo) => todo.categoryId == categoryId)
        .length;
    return todos;
  }

  Future<void> _handleCategoryAction(Category category, String action) async {
    switch (action) {
      case 'edit':
        await _showEditCategoryDialog(category);
        break;
      case 'delete':
        await _showDeleteCategoryDialog(category);
        break;
    }
  }

  Future<void> _showAddCategoryDialog() async {
    await showDialog(
      context: context,
      builder: (context) => CategoryFormDialog(),
    );
  }

  Future<void> _showEditCategoryDialog(Category category) async {
    await showDialog(
      context: context,
      builder: (context) => CategoryFormDialog(category: category),
    );
  }

  Future<void> _showDeleteCategoryDialog(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除分类'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要删除分类 "${category.name}" 吗？'),
            const SizedBox(height: 8),
            const Text(
              '注意：删除分类不会删除相关的任务，但这些任务将失去分类标签。',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(categoryListProvider.notifier).deleteCategory(category.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('分类已删除'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('删除失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class CategoryFormDialog extends ConsumerStatefulWidget {
  final Category? category;

  const CategoryFormDialog({Key? key, this.category}) : super(key: key);

  @override
  ConsumerState<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedIcon = 'work';
  Color _selectedColor = const Color(0xFF6750A4);

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _selectedIcon = widget.category!.icon;
      _selectedColor = _parseColor(widget.category!.color);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = widget.category != null;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Text(
                isEditing ? '编辑分类' : '添加分类',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // 分类名称
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '分类名称',
                  hintText: '输入分类名称...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入分类名称';
                  }
                  if (value.length > 20) {
                    return '名称不能超过20个字符';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // 图标选择
              Text(
                '选择图标',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.defaultCategoryIcons.map(
                  (icon) => _buildIconOption(icon),
                ).toList(),
              ),
              const SizedBox(height: 16),

              // 颜色选择
              Text(
                '选择颜色',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.defaultCategoryColors.map(
                  (color) => _buildColorOption(color),
                ).toList(),
              ),

              const SizedBox(height: 24),

              // 按钮
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveCategory,
                      child: Text(isEditing ? '保存' : '添加'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconOption(String icon) {
    final isSelected = _selectedIcon == icon;
    return FilterChip(
      label: Icon(_getIconData(icon)),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedIcon = icon;
        });
      },
      backgroundColor: Colors.grey.withOpacity(0.1),
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Widget _buildColorOption(String color) {
    final colorValue = _parseColor(color);
    final isSelected = _selectedColor.value == colorValue.value;
    return FilterChip(
      label: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: colorValue,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.white, width: 2)
              : null,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedColor = colorValue;
        });
      },
      backgroundColor: colorValue.withOpacity(0.1),
      selectedColor: colorValue.withOpacity(0.3),
      checkmarkColor: Colors.white,
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'work':
        return Icons.work;
      case 'personal':
        return Icons.person;
      case 'shopping':
        return Icons.shopping_cart;
      case 'health':
        return Icons.favorite;
      case 'education':
        return Icons.school;
      case 'finance':
        return Icons.account_balance;
      case 'travel':
        return Icons.flight;
      case 'home':
        return Icons.home;
      case 'family':
        return Icons.people;
      default:
        return Icons.category;
    }
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final now = DateTime.now();
    final category = Category(
      id: widget.category?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      color: '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}',
      icon: _selectedIcon,
      sortOrder: widget.category?.sortOrder ?? 0,
      createdAt: widget.category?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      if (widget.category != null) {
        // 编辑模式
        await ref.read(categoryListProvider.notifier).updateCategory(category);
      } else {
        // 添加模式
        await ref.read(categoryListProvider.notifier).addCategory(category);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.category != null ? '分类已更新' : '分类已添加'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}