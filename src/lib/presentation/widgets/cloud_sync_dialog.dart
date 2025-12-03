import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/simple_sync_service.dart';
import '../providers/sync_provider.dart';
import '../../core/themes/app_theme.dart';

/// 云同步配置对话框
class CloudSyncDialog extends ConsumerStatefulWidget {
  const CloudSyncDialog({super.key});

  @override
  ConsumerState<CloudSyncDialog> createState() => _CloudSyncDialogState();
}

class _CloudSyncDialogState extends ConsumerState<CloudSyncDialog> {
  final _formKey = GlobalKey<FormState>();
  CloudProvider? _selectedProvider;
  bool _isLoading = false;

  // Firebase配置
  final _firebaseProjectIdController = TextEditingController();
  final _firebaseApiKeyController = TextEditingController();

  // Supabase配置
  final _supabaseUrlController = TextEditingController();
  final _supabaseKeyController = TextEditingController();

  // Appwrite配置
  final _appwriteEndpointController = TextEditingController();
  final _appwriteProjectIdController = TextEditingController();
  final _appwriteKeyController = TextEditingController();

  // 自定义API配置
  final _customApiUrlController = TextEditingController();
  final _customApiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  @override
  void dispose() {
    _firebaseProjectIdController.dispose();
    _firebaseApiKeyController.dispose();
    _supabaseUrlController.dispose();
    _supabaseKeyController.dispose();
    _appwriteEndpointController.dispose();
    _appwriteProjectIdController.dispose();
    _appwriteKeyController.dispose();
    _customApiUrlController.dispose();
    _customApiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final syncService = ref.watch(syncServiceProvider);
    final syncStatus = syncService.syncStatus;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            _buildHeader(theme, syncStatus),

            // 内容区域
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (syncStatus.isConfigured) ...[
                      _buildSyncStatus(theme, syncStatus, syncService),
                      const SizedBox(height: 24),
                    ],

                    _buildProviderSelection(theme),
                    const SizedBox(height: 24),

                    if (_selectedProvider != null) ...[
                      _buildProviderConfig(theme),
                      const SizedBox(height: 24),
                    ],

                    _buildActions(theme, syncService),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, SyncStatus syncStatus) {
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
            syncStatus.isConfigured ? Icons.cloud_done : Icons.cloud_upload,
            color: theme.colorScheme.onPrimaryContainer,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  syncStatus.isConfigured ? '云同步已配置' : '配置云同步',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  syncStatus.isConfigured
                      ? '当前使用: ${_getProviderName(syncStatus.provider)}'
                      : '选择云服务提供商以启用数据同步',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
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

  Widget _buildSyncStatus(ThemeData theme, SyncStatus syncStatus, SimpleSyncService syncService) {
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
                syncStatus.isSyncing ? Icons.sync : Icons.sync_disabled,
                color: syncStatus.isSyncing
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
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
                '自动同步',
                syncStatus.autoSyncEnabled,
                Icons.schedule,
              ),
              const SizedBox(width: 8),
              _buildStatusChip(
                theme,
                '已连接',
                syncStatus.isConfigured,
                Icons.cloud,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: syncStatus.isSyncing ? null : () async {
                    await syncService.manualSync([]);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('手动同步已触发')),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(syncStatus.isSyncing ? '同步中...' : '立即同步'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    await syncService.clearConfig();
                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('云同步配置已清除')),
                      );
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('清除配置'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                ),
              ),
            ],
          ),
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

  Widget _buildProviderSelection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择云服务提供商',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...CloudProvider.values.map((provider) => _buildProviderOption(theme, provider)),
      ],
    );
  }

  Widget _buildProviderOption(ThemeData theme, CloudProvider provider) {
    final isSelected = _selectedProvider == provider;

    return InkWell(
      onTap: () => setState(() => _selectedProvider = provider),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? theme.colorScheme.primaryContainer.withOpacity(0.1)
              : theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            Icon(
              _getProviderIcon(provider),
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.6),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getProviderName(provider),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getProviderDescription(provider),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Radio<CloudProvider>(
              value: provider,
              groupValue: _selectedProvider,
              onChanged: (value) => setState(() => _selectedProvider = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderConfig(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_getProviderName(_selectedProvider!)} 配置',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildConfigFields(theme),
        ],
      ),
    );
  }

  Widget _buildConfigFields(ThemeData theme) {
    switch (_selectedProvider) {
      case CloudProvider.firebase:
        return Column(
          children: [
            TextFormField(
              controller: _firebaseProjectIdController,
              decoration: const InputDecoration(
                labelText: '项目ID',
                hintText: 'your-project-id',
                prefixIcon: Icon(Icons.fingerprint),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入项目ID';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _firebaseApiKeyController,
              decoration: const InputDecoration(
                labelText: 'API密钥',
                hintText: 'your-api-key',
                prefixIcon: Icon(Icons.key),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入API密钥';
                }
                return null;
              },
            ),
          ],
        );

      case CloudProvider.supabase:
        return Column(
          children: [
            TextFormField(
              controller: _supabaseUrlController,
              decoration: const InputDecoration(
                labelText: '项目URL',
                hintText: 'https://your-project.supabase.co',
                prefixIcon: Icon(Icons.link),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入项目URL';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _supabaseKeyController,
              decoration: const InputDecoration(
                labelText: '匿名密钥',
                hintText: 'your-anon-key',
                prefixIcon: Icon(Icons.key),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入匿名密钥';
                }
                return null;
              },
            ),
          ],
        );

      case CloudProvider.appwrite:
        return Column(
          children: [
            TextFormField(
              controller: _appwriteEndpointController,
              decoration: const InputDecoration(
                labelText: '端点地址',
                hintText: 'https://cloud.appwrite.io/v1',
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _appwriteProjectIdController,
              decoration: const InputDecoration(
                labelText: '项目ID',
                hintText: 'your-project-id',
                prefixIcon: Icon(Icons.fingerprint),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _appwriteKeyController,
              decoration: const InputDecoration(
                labelText: 'API密钥',
                hintText: 'your-api-key',
                prefixIcon: Icon(Icons.key),
              ),
            ),
          ],
        );

      case CloudProvider.selfHosted:
        return Column(
          children: [
            TextFormField(
              controller: _customApiUrlController,
              decoration: const InputDecoration(
                labelText: 'API地址',
                hintText: 'https://your-api.com/api',
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customApiKeyController,
              decoration: const InputDecoration(
                labelText: 'API密钥',
                hintText: 'your-api-key',
                prefixIcon: Icon(Icons.key),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildActions(ThemeData theme, SimpleSyncService syncService) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FilledButton(
            onPressed: _isLoading || _selectedProvider == null ? null : _saveConfig,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存配置'),
          ),
        ),
      ],
    );
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final syncService = ref.read(syncServiceProvider);

      switch (_selectedProvider!) {
        case CloudProvider.firebase:
          await syncService.setupFirebaseSync(
            _firebaseProjectIdController.text.trim(),
            _firebaseApiKeyController.text.trim(),
          );
          break;

        case CloudProvider.supabase:
          await syncService.setupSupabaseSync(
            _supabaseUrlController.text.trim(),
            _supabaseKeyController.text.trim(),
          );
          break;

        case CloudProvider.appwrite:
          await syncService.setupAppwriteSync(
            _appwriteEndpointController.text.trim(),
            _appwriteProjectIdController.text.trim(),
            _appwriteKeyController.text.trim(),
          );
          break;

        case CloudProvider.selfHosted:
          await syncService.setupCustomApiSync(
            _customApiUrlController.text.trim(),
            _customApiKeyController.text.trim(),
          );
          break;
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已成功配置 ${_getProviderName(_selectedProvider!)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('配置失败: $e'),
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

  Future<void> _loadCurrentConfig() async {
    // 加载当前配置的提供商
    final syncService = ref.read(syncServiceProvider);
    final provider = syncService.currentProvider;

    if (provider != null) {
      setState(() => _selectedProvider = provider);
    }
  }

  String _getProviderName(CloudProvider provider) {
    switch (provider) {
      case CloudProvider.firebase:
        return 'Firebase Firestore';
      case CloudProvider.supabase:
        return 'Supabase';
      case CloudProvider.appwrite:
        return 'Appwrite';
      case CloudProvider.selfHosted:
        return '自定义API';
    }
  }

  String _getProviderDescription(CloudProvider provider) {
    switch (provider) {
      case CloudProvider.firebase:
        return 'Google提供的实时数据库服务，有免费额度';
      case CloudProvider.supabase:
        return '开源的Firebase替代方案，基于PostgreSQL';
      case CloudProvider.appwrite:
        return '开源的后端即服务平台，支持自托管';
      case CloudProvider.selfHosted:
        return '连接到你自己的API服务器';
    }
  }

  IconData _getProviderIcon(CloudProvider provider) {
    switch (provider) {
      case CloudProvider.firebase:
        return Icons.local_fire_department;
      case CloudProvider.supabase:
        return Icons.storage;
      case CloudProvider.appwrite:
        return Icons.dns;
      case CloudProvider.selfHosted:
        return Icons.api;
    }
  }
}