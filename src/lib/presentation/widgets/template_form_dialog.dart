import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/task_template_provider.dart';
import '../../domain/entities/task_template.dart';
import '../../domain/entities/todo.dart';

/// 模板创建/编辑表单对话框
class TemplateFormDialog extends ConsumerStatefulWidget {
  final TaskTemplate? template;

  const TemplateFormDialog({
    super.key,
    this.template,
  });

  @override
  ConsumerState<TemplateFormDialog> createState() => _TemplateFormDialogState();
}

class _TemplateFormDialogState extends ConsumerState<TemplateFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _defaultTitleController = TextEditingController();
  final _defaultDescriptionController = TextEditingController();
  final _estimatedMinutesController = TextEditingController();

  Priority _selectedPriority = Priority.medium;
  String? _selectedCategoryId;
  List<String> _selectedTags = [];
  bool _isCreating = true;

  @override
  void initState() {
    super.initState();
    _isCreating = widget.template == null;

    if (!_isCreating) {
      _initializeFromTemplate(widget.template!);
    }
  }

  void _initializeFromTemplate(TaskTemplate template) {
    _nameController.text = template.name;
    _descriptionController.text = template.description ?? '';
    _defaultTitleController.text = template.defaultTitle ?? '';
    _defaultDescriptionController.text = template.defaultDescription ?? '';
    _selectedPriority = template.defaultPriority;
    _selectedCategoryId = template.categoryId;
    _selectedTags = List.from(template.tags);

    if (template.estimatedMinutes != null) {
      _estimatedMinutesController.text = template.estimatedMinutes.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _defaultTitleController.dispose();
    _defaultDescriptionController.dispose();
    _estimatedMinutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Form(
          key: _formKey,
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
                      _isCreating ? Icons.add_box : Icons.edit,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isCreating ? '创建任务模板' : '编辑任务模板',
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

              // 表单内容
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 基本信息
                      _buildSectionHeader('基本信息', Icons.info_outline),
                      const SizedBox(height: 12),

                      // 模板名称
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '模板名称 *',
                          hintText: '输入模板名称',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入模板名称';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 模板描述
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: '模板描述',
                          hintText: '输入模板描述（可选）',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),

                      // 默认任务设置
                      _buildSectionHeader('默认任务设置', Icons.task),
                      const SizedBox(height: 12),

                      // 默认标题
                      TextFormField(
                        controller: _defaultTitleController,
                        decoration: const InputDecoration(
                          labelText: '默认任务标题',
                          hintText: '使用模板时默认的任务标题',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.subject),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 默认描述
                      TextFormField(
                        controller: _defaultDescriptionController,
                        decoration: const InputDecoration(
                          labelText: '默认任务描述',
                          hintText: '使用模板时默认的任务描述',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // 默认优先级
                      DropdownButtonFormField<Priority>(
                        value: _selectedPriority,
                        decoration: const InputDecoration(
                          labelText: '默认优先级',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flag),
                        ),
                        items: Priority.values.map((priority) {
                          return DropdownMenuItem(
                            value: priority,
                            child: Row(
                              children: [
                                Icon(
                                  _getPriorityIcon(priority),
                                  color: _getPriorityColor(priority),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(_getPriorityText(priority)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (priority) {
                          setState(() {
                            _selectedPriority = priority!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // 预估时间
                      TextFormField(
                        controller: _estimatedMinutesController,
                        decoration: const InputDecoration(
                          labelText: '预估时间（分钟）',
                          hintText: '输入预估完成时间',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final minutes = int.tryParse(value);
                            if (minutes == null || minutes <= 0) {
                              return '请输入有效的分钟数';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // 标签设置
                      _buildSectionHeader('标签设置', Icons.label),
                      const SizedBox(height: 12),
                      _buildTagSelector(),
                      const SizedBox(height: 24),

                      // 预览
                      _buildSectionHeader('预览', Icons.preview),
                      const SizedBox(height: 12),
                      _buildPreview(),
                    ],
                  ),
                ),
              ),

              // 底部按钮
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitForm,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(_isCreating ? Icons.add : Icons.save),
                      label: Text(_isCreating ? '创建模板' : '保存修改'),
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

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildTagSelector() {
    final availableTags = [
      '工作', '个人', '学习', '购物', '健康', '运动', '会议', '日常',
      '紧急', '重要', '创意', '家庭', '社交', '财务', '项目', '阅读'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // 自定义标签输入
        TextField(
          decoration: InputDecoration(
            hintText: '输入自定义标签，按回车添加',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.add),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _selectedTags.clear();
                });
              },
            ),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty && !_selectedTags.contains(value.trim())) {
              setState(() {
                _selectedTags.add(value.trim());
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final estimatedMinutes = _estimatedMinutesController.text.isNotEmpty
        ? int.tryParse(_estimatedMinutesController.text)
        : null;

    final previewTemplate = TaskTemplate(
      id: 'preview',
      name: _nameController.text.isNotEmpty ? _nameController.text : '模板预览',
      description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      defaultTitle: _defaultTitleController.text.isNotEmpty ? _defaultTitleController.text : null,
      defaultDescription: _defaultDescriptionController.text.isNotEmpty ? _defaultDescriptionController.text : null,
      defaultPriority: _selectedPriority,
      estimatedMinutes: estimatedMinutes,
      categoryId: _selectedCategoryId,
      createdAt: DateTime.now(),
      tags: _selectedTags,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '模板预览',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            previewTemplate.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (previewTemplate.description != null) ...[
            const SizedBox(height: 4),
            Text(
              previewTemplate.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (previewTemplate.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: previewTemplate.tags.map((tag) => Chip(
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
        ],
      ),
    );
  }

  bool _isSubmitting = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final estimatedMinutes = _estimatedMinutesController.text.isNotEmpty
          ? int.tryParse(_estimatedMinutesController.text)
          : null;

      if (_isCreating) {
        await ref.read(taskTemplateProvider.notifier).createTemplate(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          defaultTitle: _defaultTitleController.text.trim().isEmpty
              ? null
              : _defaultTitleController.text.trim(),
          defaultDescription: _defaultDescriptionController.text.trim().isEmpty
              ? null
              : _defaultDescriptionController.text.trim(),
          defaultPriority: _selectedPriority,
          estimatedMinutes: estimatedMinutes,
          categoryId: _selectedCategoryId,
          tags: _selectedTags,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('模板创建成功')),
        );
      } else {
        final updatedTemplate = widget.template!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          defaultTitle: _defaultTitleController.text.trim().isEmpty
              ? null
              : _defaultTitleController.text.trim(),
          defaultDescription: _defaultDescriptionController.text.trim().isEmpty
              ? null
              : _defaultDescriptionController.text.trim(),
          defaultPriority: _selectedPriority,
          estimatedMinutes: estimatedMinutes,
          categoryId: _selectedCategoryId,
          tags: _selectedTags,
          updatedAt: DateTime.now(),
        );

        await ref.read(taskTemplateProvider.notifier).updateTemplate(updatedTemplate);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('模板更新成功')),
        );
      }

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('操作失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  IconData _getPriorityIcon(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Icons.keyboard_double_arrow_up;
      case Priority.medium:
        return Icons.remove;
      case Priority.low:
        return Icons.keyboard_double_arrow_down;
    }
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

  String _getPriorityText(Priority priority) {
    switch (priority) {
      case Priority.high:
        return '高优先级';
      case Priority.medium:
        return '中优先级';
      case Priority.low:
        return '低优先级';
    }
  }
}