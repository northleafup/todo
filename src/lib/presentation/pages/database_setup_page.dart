import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/services/database_config_service.dart';
import 'home_page.dart';

class DatabaseSetupPage extends StatefulWidget {
  const DatabaseSetupPage({super.key});

  @override
  State<DatabaseSetupPage> createState() => _DatabaseSetupPageState();
}

class _DatabaseSetupPageState extends State<DatabaseSetupPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isLoading = false;
  bool _hasExistingDatabase = false;
  String? _selectedPath;
  int? _databaseSize;
  DateTime? _lastModified;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingDatabase(String directoryPath) async {
    setState(() => _isLoading = true);

    try {
      final hasDb = await DatabaseConfigService.hasExistingDatabase(directoryPath);
      final size = await DatabaseConfigService.getDatabaseFileSize(directoryPath);
      final modified = await DatabaseConfigService.getDatabaseLastModified(directoryPath);

      setState(() {
        _hasExistingDatabase = hasDb;
        _databaseSize = size;
        _lastModified = modified;
      });
    } catch (e) {
      _showErrorSnackBar('检查现有数据库失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDirectory() async {
    try {
      final String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择数据库存储位置',
        lockParentWindow: true,
      );

      if (selectedDirectory != null) {
        setState(() {
          _selectedPath = selectedDirectory;
        });

        await _checkExistingDatabase(selectedDirectory);
      }
    } catch (e) {
      _showErrorSnackBar('选择目录失败: $e');
    }
  }

  Future<void> _useDefaultPath() async {
    setState(() => _isLoading = true);

    try {
      final dbPath = await DatabaseConfigService.getDatabasePath();
      final directory = dbPath.replaceAll(RegExp(r'/[^/]*$'), '');

      setState(() {
        _selectedPath = directory;
      });

      await _checkExistingDatabase(directory);
    } catch (e) {
      _showErrorSnackBar('获取默认路径失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmSetup() async {
    if (_selectedPath == null) {
      _showErrorSnackBar('请先选择数据库存储位置');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 直接保存用户选择的路径，不再弹出选择对话框
      await DatabaseConfigService.saveDatabaseDirectory(_selectedPath!);

      if (!mounted) return;

      // 跳转到主应用
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('设置数据库失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '未知';

    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '未知';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Logo and Title
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.task_alt_rounded,
                        size: 40,
                        color: colorScheme.onPrimary,
                      ),
                    )
                        .animate(controller: _animationController)
                        .scale(duration: 300.ms)
                        .fadeIn(),

                    const SizedBox(height: 24),

                    Text(
                      'Todo App',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                        .animate(controller: _animationController)
                        .fadeIn(delay: 200.ms),

                    const SizedBox(height: 8),

                    Text(
                      '设置您的任务数据库',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    )
                        .animate(controller: _animationController)
                        .fadeIn(delay: 400.ms),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Selection Area
              Expanded(
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '数据库存储位置',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        if (_selectedPath != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.folder,
                                      size: 20,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _selectedPath!,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                if (_hasExistingDatabase) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colorScheme.secondaryContainer.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.storage,
                                          size: 16,
                                          color: colorScheme.secondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '发现现有数据库',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                  color: colorScheme.secondary,
                                                ),
                                              ),
                                              if (_databaseSize != null || _lastModified != null)
                                                Text(
                                                  '大小: ${_formatFileSize(_databaseSize)} | 修改: ${_formatDate(_lastModified)}',
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    '将在此位置创建新的数据库',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],

                        const Spacer(),

                        // Action Buttons
                        if (_selectedPath == null) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _selectDirectory,
                              icon: const Icon(Icons.folder_open),
                              label: const Text('选择文件夹'),
                            ),
                          ),

                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _useDefaultPath,
                              icon: const Icon(Icons.storage),
                              label: const Text('使用默认位置'),
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isLoading ? null : () {
                                    setState(() {
                                      _selectedPath = null;
                                      _hasExistingDatabase = false;
                                      _databaseSize = null;
                                      _lastModified = null;
                                    });
                                  },
                                  child: const Text('重新选择'),
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _confirmSetup,
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Text('完成设置'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                )
                    .animate(controller: _animationController)
                    .slideY(begin: 0.3, end: 0, delay: 600.ms, duration: 400.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }
}