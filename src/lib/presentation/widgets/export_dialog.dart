import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../providers/todo_provider.dart';
import '../../core/services/export_service.dart';
import '../../core/themes/app_theme.dart';
import 'package:flutter/foundation.dart';

class ExportDialog extends ConsumerStatefulWidget {
  const ExportDialog({Key? key}) : super(key: key);

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final todoState = ref.watch(todoListProvider);
    final categoryState = ref.watch(categoryListProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 450),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Icon(
                  Icons.download,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  '导出数据',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 数据概览
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '数据概览',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          '任务总数',
                          todoState.todos.length,
                          colorScheme.primary,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          '已完成',
                          todoState.todos.where((t) => t.isCompleted).length,
                          Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          '分类数',
                          categoryState.categories.length,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 导出格式选择
            Text(
              '选择导出格式',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                _buildExportOption(
                  icon: Icons.code,
                  title: 'JSON 格式',
                  description: '完整的结构化数据，包含所有信息和统计',
                  onTap: () => _exportData('json', ref),
                  color: Colors.blue,
                ),
                const SizedBox(height: 8),
                _buildExportOption(
                  icon: Icons.table_chart,
                  title: 'CSV 格式',
                  description: '表格格式，可在Excel等软件中打开',
                  onTap: () => _exportData('csv', ref),
                  color: Colors.green,
                ),
                const SizedBox(height: 8),
                _buildExportOption(
                  icon: Icons.description,
                  title: 'Markdown 格式',
                  description: '文档格式，便于阅读和分享',
                  onTap: () => _exportData('markdown', ref),
                  color: Colors.purple,
                ),
              ],
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

  Widget _buildStatItem(String label, int value, Color color) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value.toString(),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.download,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(String format, WidgetRef ref) async {
    final todoState = ref.read(todoListProvider);
    final categoryState = ref.read(categoryListProvider);

    try {
      String content;
      String mimeType;
      String fileName;

      switch (format) {
        case 'json':
          content = ExportService.exportToJson(todoState.todos, categoryState.categories);
          mimeType = 'application/json';
          fileName = ExportService.generateFileName('json');
          break;
        case 'csv':
          content = ExportService.exportToCsv(todoState.todos, categories: categoryState.categories);
          mimeType = 'text/csv;charset=utf-8';
          fileName = ExportService.generateFileName('csv');
          break;
        case 'markdown':
          content = ExportService.exportToMarkdown(todoState.todos, categories: categoryState.categories);
          mimeType = 'text/markdown;charset=utf-8';
          fileName = ExportService.generateFileName('md');
          break;
        default:
          throw Exception('不支持的导出格式: $format');
      }

      // 在Web环境中下载文件
      await _downloadFile(content, fileName, mimeType);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('数据已导出为 $fileName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadFile(String content, String fileName, String mimeType) async {
    // 仅支持桌面和移动平台
    try {
      // 对于桌面和移动平台，使用 file_picker 保存文件
      await _downloadFileDesktop(content, fileName, mimeType);
    } catch (e) {
      throw Exception('文件下载失败: $e');
    }
  }

  Future<void> _downloadFileDesktop(String content, String fileName, String mimeType) async {
    // 对于桌面和移动平台，使用 file_picker 和路径保存
    final exportService = ExportService();
    await exportService.exportTodosToFile(content, fileName);
  }
}


