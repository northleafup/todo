import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/file_picker_sync_service.dart';
import '../providers/file_sync_provider.dart';
import '../../core/themes/app_theme.dart';
import '../../core/platform/platform_adapter.dart';

/// 文件同步配置对话框
class FileSyncDialog extends ConsumerStatefulWidget {
  const FileSyncDialog({super.key});

  @override
  ConsumerState<FileSyncDialog> createState() => _FileSyncDialogState();
}

class _FileSyncDialogState extends ConsumerState<FileSyncDialog> {
  bool _isLoading = false;
  List<DatabaseFileInfo> _databaseFiles = [];

  @override
  void initState() {
    super.initState();
    _loadDatabaseFiles();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final syncService = ref.watch(fileSyncServiceProvider);
    final folderStatus = syncService.folderStatus;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            _buildHeader(theme, folderStatus),

            // 内容区域
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (folderStatus.isConfigured) ...[
                      _buildSyncStatus(theme, folderStatus, syncService),
                      const SizedBox(height: 24),
                      _buildDatabaseFileList(theme),
                      const SizedBox(height: 24),
                    ],

                    _buildSetupOptions(theme, folderStatus),
                    const SizedBox(height: 24),

                    if (folderStatus.isConfigured) ...[
                      _buildSyncActions(theme, syncService),
                      const SizedBox(height: 24),
                    ],

                    _buildActions(theme, folderStatus),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, SyncFolderStatus folderStatus) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Icon(
            folderStatus.isConfigured ? Icons.folder_shared : Icons.folder,
            color: theme.colorScheme.onPrimaryContainer,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  folderStatus.isConfigured ? '文件同步已配置' : '配置文件同步',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  folderStatus.isConfigured
                      ? '当前路径: ${folderStatus.folderPath}'
                      : '选择文件夹进行本地文件同步',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatus(ThemeData theme, SyncFolderStatus folderStatus, FilePickerSyncService syncService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                folderStatus.isAccessible ? Icons.folder_open : Icons.folder_off,
                color: folderStatus.isAccessible
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '同步状态',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatusChip(
                theme,
                '文件夹可访问',
                folderStatus.isAccessible,
                Icons.check_circle,
              ),
              const SizedBox(width: 8),
              _buildStatusChip(
                theme,
                '自动同步',
                folderStatus.autoSyncEnabled,
                Icons.autorenew,
              ),
              const SizedBox(width: 8),
              _buildStatusChip(
                theme,
                '正在同步',
                folderStatus.isSyncing,
                Icons.sync,
              ),
            ],
          ),
          if (folderStatus.lastSyncTime != null) ...[
            const SizedBox(height: 8),
            Text(
              '上次同步: ${_formatDateTime(folderStatus.lastSyncTime!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
          if (folderStatus.databaseFileName != null) ...[
            const SizedBox(height: 8),
            Text(
              '同步文件: ${folderStatus.databaseFileName}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme, String label, bool active, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: active
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: active
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatabaseFileList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '数据库文件',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _loadDatabaseFiles,
              icon: const Icon(Icons.refresh),
              tooltip: '刷新',
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_databaseFiles.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.folder_open,
                  size: 48,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  '同步文件夹中暂无数据库文件',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          )
        else
          ..._databaseFiles.map((fileInfo) => _buildDatabaseFileItem(theme, fileInfo)),
      ],
    );
  }

  Widget _buildDatabaseFileItem(ThemeData theme, DatabaseFileInfo fileInfo) {
    final syncService = ref.read(fileSyncServiceProvider);
    final isCurrentSyncFile = syncService.folderStatus.databaseFileName == fileInfo.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isCurrentSyncFile
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withOpacity(0.2),
          width: isCurrentSyncFile ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isCurrentSyncFile
            ? theme.colorScheme.primaryContainer.withOpacity(0.1)
            : theme.colorScheme.surface,
      ),
      child: Row(
        children: [
          Icon(
            fileInfo.isValid ? Icons.check_circle : Icons.error,
            color: fileInfo.isValid
                ? theme.colorScheme.primary
                : theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileInfo.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatFileSize(fileInfo.size)} • ${_formatDateTime(fileInfo.lastModified)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          if (!isCurrentSyncFile)
            OutlinedButton(
              onPressed: _isLoading ? null : () async {
                setState(() => _isLoading = true);
                try {
                  syncService.setDatabaseFileName(fileInfo.name);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('已切换到 ${fileInfo.name}')),
                    );
                    await _loadDatabaseFiles();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('切换失败: $e')),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              },
              child: const Text('使用此文件'),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '当前使用',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSetupOptions(ThemeData theme, SyncFolderStatus folderStatus) {
    if (folderStatus.isConfigured) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '重新配置',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _selectSyncFolder,
                  icon: const Icon(Icons.folder),
                  label: const Text('选择其他文件夹'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _selectDatabaseFile,
                  icon: const Icon(Icons.file_present),
                  label: const Text('选择数据库文件'),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择同步方式',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildSetupOption(
          theme,
          icon: Icons.folder,
          title: '选择同步文件夹',
          description: '选择一个文件夹用于存储和同步数据库文件',
          onTap: _selectSyncFolder,
        ),
        const SizedBox(height: 8),
        _buildSetupOption(
          theme,
          icon: Icons.file_present,
          title: '选择现有数据库文件',
          description: '选择一个现有的SQLite数据库文件进行同步',
          onTap: _selectDatabaseFile,
        ),
        if (PlatformAdapter.isDesktop) ...[
          const SizedBox(height: 8),
          _buildSetupOption(
            theme,
            icon: Icons.cloud_sync,
            title: '使用云同步文件夹',
            description: '选择Dropbox/OneDrive/坚果云等云同步文件夹',
            onTap: _selectCloudSyncFolder,
          ),
        ],
      ],
    );
  }

  Widget _buildSetupOption(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
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
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncActions(ThemeData theme, FilePickerSyncService syncService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '同步操作',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _isLoading || syncService.folderStatus.isSyncing
                    ? null
                    : _bidirectionalSync,
                icon: const Icon(Icons.sync),
                label: Text(syncService.folderStatus.isSyncing ? '同步中...' : '智能同步'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading || syncService.folderStatus.isSyncing
                    ? null
                    : _forceSyncFromExternal,
                icon: const Icon(Icons.download),
                label: const Text('从外部导入'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading || syncService.folderStatus.isSyncing
                    ? null
                    : _forceSyncToExternal,
                icon: const Icon(Icons.upload),
                label: const Text('导出到外部'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: syncService.folderStatus.autoSyncEnabled
                    ? _disableAutoSync
                    : _enableAutoSync,
                icon: Icon(
                  syncService.folderStatus.autoSyncEnabled
                      ? Icons.autorenew
                      : Icons.autorenew_outlined,
                ),
                label: Text(
                  syncService.folderStatus.autoSyncEnabled
                      ? '禁用自动同步'
                      : '启用自动同步',
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: syncService.folderStatus.autoSyncEnabled
                      ? theme.colorScheme.errorContainer
                      : null,
                  foregroundColor: syncService.folderStatus.autoSyncEnabled
                      ? theme.colorScheme.onErrorContainer
                      : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions(ThemeData theme, SyncFolderStatus folderStatus) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ),
        if (folderStatus.isConfigured) ...[
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _clearConfig,
              icon: const Icon(Icons.delete_outline),
              label: const Text('清除配置'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // 操作方法

  Future<void> _selectSyncFolder() async {
    setState(() => _isLoading = true);
    try {
      final syncService = ref.read(fileSyncServiceProvider);
      final result = await syncService.selectSyncFolder();

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已选择同步文件夹: ${result.path}'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadDatabaseFiles();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择文件夹失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDatabaseFile() async {
    setState(() => _isLoading = true);
    try {
      final syncService = ref.read(fileSyncServiceProvider);
      final result = await syncService.selectDatabaseFile();

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已选择数据库文件: ${result.path}'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadDatabaseFiles();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择文件失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectCloudSyncFolder() async {
    // 引导用户选择云同步文件夹
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('请在文件选择器中选择您的云同步文件夹（如Dropbox、OneDrive等）'),
        duration: Duration(seconds: 5),
      ),
    );
    await _selectSyncFolder();
  }

  Future<void> _bidirectionalSync() async {
    setState(() => _isLoading = true);
    try {
      final syncService = ref.read(fileSyncServiceProvider);
      final result = await syncService.bidirectionalSync();

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? '同步完成'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('同步失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _forceSyncFromExternal() async {
    setState(() => _isLoading = true);
    try {
      final syncService = ref.read(fileSyncServiceProvider);
      final result = await syncService.forceSyncFromExternal();

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('从外部导入成功'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _forceSyncToExternal() async {
    setState(() => _isLoading = true);
    try {
      final syncService = ref.read(fileSyncServiceProvider);
      final result = await syncService.forceSyncToExternal();

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('导出到外部成功'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error!),
              backgroundColor: Colors.red,
            ),
          );
        }
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _enableAutoSync() async {
    final syncService = ref.read(fileSyncServiceProvider);
    syncService.setAutoSync(true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已启用自动同步'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _disableAutoSync() async {
    final syncService = ref.read(fileSyncServiceProvider);
    syncService.setAutoSync(false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已禁用自动同步'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _clearConfig() async {
    final confirmed = await _showConfirmDialog(
      '确认清除配置',
      '这将清除当前的文件同步配置，是否继续？',
    );

    if (confirmed) {
      setState(() => _isLoading = true);
      try {
        final syncService = ref.read(fileSyncServiceProvider);
        await syncService.clearConfig();

        if (mounted) {
          setState(() {
            _databaseFiles.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('配置已清除'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('清除配置失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _loadDatabaseFiles() async {
    try {
      final syncService = ref.read(fileSyncServiceProvider);
      final files = await syncService.getDatabaseFilesInFolder();
      if (mounted) {
        setState(() {
          _databaseFiles = files;
        });
      }
    } catch (e) {
      print('加载数据库文件列表失败: $e');
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}