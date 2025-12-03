import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import '../providers/todo_provider.dart';
import '../../core/themes/app_theme.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/task_reminder_manager.dart';
import '../../domain/entities/todo.dart';
import '../../domain/entities/category.dart';
import 'reminder_settings_widget.dart';

class TodoFormDialog extends ConsumerStatefulWidget {
  final Todo? todo; // 如果为null，则是添加模式；否则是编辑模式

  const TodoFormDialog({
    Key? key,
    this.todo,
  }) : super(key: key);

  @override
  ConsumerState<TodoFormDialog> createState() => _TodoFormDialogState();
}

class _TodoFormDialogState extends ConsumerState<TodoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  Priority _priority = Priority.medium;
  String? _selectedCategoryId;
  DateTime? _dueDate;
  bool _isCompleted = false;
  ReminderTime _reminderTime = ReminderTime.before15m;

  @override
  void initState() {
    super.initState();
    // 如果是编辑模式，填充现有数据
    if (widget.todo != null) {
      _titleController.text = widget.todo!.title;
      _descriptionController.text = widget.todo!.description ?? '';
      _priority = widget.todo!.priority;
      _selectedCategoryId = widget.todo!.categoryId;
      _dueDate = widget.todo!.dueDate;
      _reminderTime = widget.todo!.reminderTime;
      _isCompleted = widget.todo!.isCompleted;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryState = ref.watch(categoryListProvider);
    final isEditing = widget.todo != null;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit : Icons.add_task,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? '编辑任务' : '添加任务',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题输入
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: '任务标题',
                          hintText: '输入任务标题...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入任务标题';
                          }
                          if (value.length > 100) {
                            return '标题不能超过100个字符';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // 描述输入
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: '任务描述',
                          hintText: '输入任务描述（可选）...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.description),
                        ),
                        maxLines: 3,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // 优先级选择
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '优先级',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildPriorityChip(Priority.high, '高', Colors.red),
                              const SizedBox(width: 8),
                              _buildPriorityChip(Priority.medium, '中', Colors.orange),
                              const SizedBox(width: 8),
                              _buildPriorityChip(Priority.low, '低', Colors.green),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 分类选择
                      if (categoryState.categories.isNotEmpty) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '分类',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildCategoryChip(null, '无分类'),
                                ...categoryState.categories.map(
                                  (category) => _buildCategoryChip(
                                    category.id,
                                    category.name,
                                    color: _parseColor(category.color),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 截止日期
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '截止日期',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _selectDueDate,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: colorScheme.outline),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _dueDate != null
                                        ? _formatDate(_dueDate!)
                                        : '选择截止日期（可选）',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: _dueDate != null
                                          ? colorScheme.onSurface
                                          : colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_dueDate != null)
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _dueDate = null;
                                        });
                                      },
                                      icon: Icon(
                                        Icons.clear,
                                        color: colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 提醒设置
                      ReminderSettingsWidget(
                        currentReminderTime: _reminderTime,
                        dueTime: _dueDate,
                        onReminderTimeChanged: (time) {
                          setState(() {
                            _reminderTime = time;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // 完成状态（仅在编辑模式下显示）
                      if (isEditing) ...[
                        SwitchListTile(
                          title: Text(
                            '已完成',
                            style: theme.textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            _isCompleted ? '标记为已完成' : '标记为未完成',
                          ),
                          value: _isCompleted,
                          onChanged: (value) {
                            setState(() {
                              _isCompleted = value!;
                            });
                          },
                          activeColor: colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),

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
                      onPressed: _saveTodo,
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

  Widget _buildPriorityChip(Priority priority, String label, Color color) {
    final isSelected = _priority == priority;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _priority = priority;
        });
      },
      backgroundColor: color.withOpacity(0.1),
      selectedColor: color.withOpacity(0.3),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
    );
  }

  Widget _buildCategoryChip(String? categoryId, String label, {Color? color}) {
    final isSelected = _selectedCategoryId == categoryId;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategoryId = selected ? categoryId : null;
        });
      },
      backgroundColor: color?.withOpacity(0.1) ?? null,
      selectedColor: color?.withOpacity(0.3),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
      avatar: color != null
          ? Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }

  void _selectDueDate() {
    DatePicker.showDateTimePicker(
      context,
      showTitleActions: true,
      minTime: DateTime.now(),
      maxTime: DateTime.now().add(const Duration(days: 365)),
      onChanged: (date) {
        // 可以在这里处理日期变化
      },
      onConfirm: (date) {
        setState(() {
          _dueDate = date;
        });
      },
      currentTime: _dueDate ?? DateTime.now(),
      locale: LocaleType.zh,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }

  Future<void> _saveTodo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final now = DateTime.now();
    final todo = Todo(
      id: widget.todo?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      isCompleted: _isCompleted,
      priority: _priority,
      categoryId: _selectedCategoryId,
      dueDate: _dueDate,
      dueTime: _dueDate,
      reminderTime: _reminderTime,
      createdAt: widget.todo?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      final reminderManager = TaskReminderManager();

      if (widget.todo != null) {
        // 编辑模式
        await ref.read(todoListProvider.notifier).updateTodo(todo);
        // 更新提醒
        await reminderManager.updateTaskReminder(
          oldTodo: widget.todo!,
          newTodo: todo,
        );
      } else {
        // 添加模式
        await ref.read(todoListProvider.notifier).addTodo(todo);
        // 设置提醒
        if (todo.shouldHaveReminder) {
          await reminderManager.setTaskReminder(
            todo: todo,
            reminderTime: _reminderTime,
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.todo != null ? '任务已更新' : '任务已添加'),
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