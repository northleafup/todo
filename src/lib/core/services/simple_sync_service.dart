import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../platform/platform_adapter.dart';
import '../storage/secure_storage.dart';
import '../constants/app_constants.dart';

/// 简化的云同步服务 - 基于REST API的增量同步
class SimpleSyncService {
  // 可以选择不同的云服务提供商
  static const List<CloudProvider> _supportedProviders = [
    CloudProvider.firebase,
    CloudProvider.supabase,
    CloudProvider.appwrite,
    CloudProvider.selfHosted,
  ];

  CloudProvider? _currentProvider;
  String? _baseUrl;
  String? _apiKey;
  Timer? _syncTimer;
  bool _isSyncing = false;

  /// 初始化同步服务
  Future<void> initialize({CloudProvider? provider, String? customUrl}) async {
    try {
      if (provider != null) {
        _currentProvider = provider;
        _baseUrl = _getProviderUrl(provider, customUrl);
        _apiKey = await _getProviderKey(provider);
      }

      // 启动自动同步（如果已配置）
      if (_currentProvider != null && _apiKey != null) {
        _startAutoSync();
      }
    } catch (e) {
      print('同步服务初始化失败: $e');
    }
  }

  /// 使用Firebase实现同步
  Future<void> setupFirebaseSync(String projectId, String apiKey) async {
    _currentProvider = CloudProvider.firebase;
    _baseUrl = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';
    _apiKey = apiKey;

    await SecureStorage.saveSyncConfig({
      'provider': 'firebase',
      'baseUrl': _baseUrl,
      'apiKey': _apiKey,
    });

    _startAutoSync();
  }

  /// 使用Supabase实现同步
  Future<void> setupSupabaseSync(String url, String apiKey) async {
    _currentProvider = CloudProvider.supabase;
    _baseUrl = '$url/rest/v1';
    _apiKey = apiKey;

    await SecureStorage.saveSyncConfig({
      'provider': 'supabase',
      'baseUrl': _baseUrl,
      'apiKey': _apiKey,
    });

    _startAutoSync();
  }

  /// 使用Appwrite实现同步
  Future<void> setupAppwriteSync(String endpoint, String projectId, String apiKey) async {
    _currentProvider = CloudProvider.appwrite;
    _baseUrl = '$endpoint/v1/databases/$projectId/collections';
    _apiKey = apiKey;

    await SecureStorage.saveSyncConfig({
      'provider': 'appwrite',
      'baseUrl': _baseUrl,
      'apiKey': _apiKey,
    });

    _startAutoSync();
  }

  /// 自建API同步
  Future<void> setupCustomApiSync(String baseUrl, String apiKey) async {
    _currentProvider = CloudProvider.selfHosted;
    _baseUrl = baseUrl;
    _apiKey = apiKey;

    await SecureStorage.saveSyncConfig({
      'provider': 'selfHosted',
      'baseUrl': _baseUrl,
      'apiKey': _apiKey,
    });

    _startAutoSync();
  }

  /// 同步Todo数据
  Future<SyncResult> syncTodos(List<Map<String, dynamic>> todos) async {
    if (!isConfigured) {
      return SyncResult.failure('未配置云同步服务');
    }

    _isSyncing = true;

    try {
      final lastSync = await _getLastSyncTime();

      // 1. 获取云端自上次同步以来的变更
      final remoteChanges = await _getRemoteChanges('todos', lastSync);

      // 2. 上传本地变更
      final uploadResult = await _uploadChanges('todos', todos);

      // 3. 合并数据
      final mergedData = await _mergeData(todos, remoteChanges);

      await _updateLastSyncTime();

      return SyncResult.success(
        data: mergedData,
        downloadedCount: remoteChanges.length,
        uploadedCount: uploadResult.affectedCount,
      );
    } catch (e) {
      return SyncResult.failure('同步失败: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// 同步分类数据
  Future<SyncResult> syncCategories(List<Map<String, dynamic>> categories) async {
    if (!isConfigured) {
      return SyncResult.failure('未配置云同步服务');
    }

    return await _syncData('categories', categories);
  }

  /// 批量同步所有数据
  Future<BatchSyncResult> syncAllData({
    required List<Map<String, dynamic>> todos,
    required List<Map<String, dynamic>> categories,
  }) async {
    final results = <String, SyncResult>{};

    try {
      // 同步分类
      results['categories'] = await syncCategories(categories);

      // 同步Todo
      results['todos'] = await syncTodos(todos);

      // 检查是否全部成功
      final allSuccess = results.values.every((result) => result.success);

      return BatchSyncResult(
        success: allSuccess,
        results: results,
      );
    } catch (e) {
      return BatchSyncResult(
        success: false,
        results: results,
        error: '批量同步失败: $e',
      );
    }
  }

  /// 获取同步状态
  SyncStatus get syncStatus => SyncStatus(
    isConfigured: isConfigured,
    isSyncing: _isSyncing,
    provider: _currentProvider,
    autoSyncEnabled: _syncTimer?.isActive ?? false,
  );

  /// 手动触发同步
  Future<SyncResult> manualSync(List<Map<String, dynamic>> todos) async {
    return await syncTodos(todos);
  }

  /// 停止自动同步
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// 清除同步配置
  Future<void> clearConfig() async {
    stopAutoSync();
    _currentProvider = null;
    _baseUrl = null;
    _apiKey = null;
    await SecureStorage.clearSyncConfig();
  }

  // Getters
  bool get isConfigured => _currentProvider != null && _apiKey != null;
  CloudProvider? get currentProvider => _currentProvider;

  // 私有方法

  Future<SyncResult> _syncData(String collection, List<Map<String, dynamic>> data) async {
    _isSyncing = true;

    try {
      final lastSync = await _getLastSyncTime();
      final remoteChanges = await _getRemoteChanges(collection, lastSync);
      final uploadResult = await _uploadChanges(collection, data);
      final mergedData = await _mergeData(data, remoteChanges);

      await _updateLastSyncTime();

      return SyncResult.success(
        data: mergedData,
        downloadedCount: remoteChanges.length,
        uploadedCount: uploadResult.affectedCount,
      );
    } catch (e) {
      return SyncResult.failure('同步$collection失败: $e');
    } finally {
      _isSyncing = false;
    }
  }

  void _startAutoSync() {
    _stopAutoSync();

    _syncTimer = Timer.periodic(
      const Duration(minutes: 5), // 每5分钟自动同步
      (_) => _performAutoSync(),
    );
  }

  Future<void> _performAutoSync() async {
    if (_isSyncing || !isConfigured) return;

    try {
      // 这里应该获取当前的数据进行同步
      // 由于需要访问Repository，这里只是示例
      print('执行自动同步...');
    } catch (e) {
      print('自动同步失败: $e');
    }
  }

  String _getProviderUrl(CloudProvider provider, String? customUrl) {
    switch (provider) {
      case CloudProvider.firebase:
        return customUrl ?? 'https://firestore.googleapis.com/v1';
      case CloudProvider.supabase:
        return customUrl ?? 'https://your-project.supabase.co/rest/v1';
      case CloudProvider.appwrite:
        return customUrl ?? 'https://cloud.appwrite.io/v1';
      case CloudProvider.selfHosted:
        return customUrl ?? 'https://your-api.com/api';
    }
  }

  Future<String?> _getProviderKey(CloudProvider provider) async {
    switch (provider) {
      case CloudProvider.firebase:
        return await SecureStorage.getFirebaseKey();
      case CloudProvider.supabase:
        return await SecureStorage.getSupabaseKey();
      case CloudProvider.appwrite:
        return await SecureStorage.getAppwriteKey();
      case CloudProvider.selfHosted:
        return await SecureStorage.getCustomApiKey();
    }
  }

  Future<List<Map<String, dynamic>>> _getRemoteChanges(String collection, DateTime? since) async {
    if (_currentProvider == null || _baseUrl == null || _apiKey == null) {
      return [];
    }

    try {
      Map<String, String> headers = {'Authorization': 'Bearer $_apiKey'};
      String url = '$_baseUrl/$collection';

      if (since != null) {
        url += '?updated_at=gte.${since.toIso8601String()}';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 根据不同的云服务提供商解析数据
        if (_currentProvider == CloudProvider.firebase) {
          return _parseFirebaseData(data);
        } else {
          return List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      print('获取远程变更失败: $e');
    }

    return [];
  }

  Future<UploadResult> _uploadChanges(String collection, List<Map<String, dynamic>> data) async {
    if (_currentProvider == null || _baseUrl == null || _apiKey == null) {
      return UploadResult(0);
    }

    try {
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/$collection/batch'),
        headers: headers,
        body: jsonEncode({
          'data': data,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return UploadResult(result['affectedCount'] ?? data.length);
      }
    } catch (e) {
      print('上传变更失败: $e');
    }

    return UploadResult(0);
  }

  Future<List<Map<String, dynamic>>> _mergeData(
    List<Map<String, dynamic>> localData,
    List<Map<String, dynamic>> remoteChanges,
  ) async {
    // 简化的合并策略：基于修改时间
    final merged = <Map<String, dynamic>>[];

    // 添加本地数据
    merged.addAll(localData);

    // 合并远程变更
    for (final change in remoteChanges) {
      final existingIndex = merged.indexWhere(
        (item) => item['id'] == change['id'],
      );

      if (existingIndex >= 0) {
        // 如果远程数据更新时间较新，则替换
        final localModified = DateTime.parse(merged[existingIndex]['updated_at']);
        final remoteModified = DateTime.parse(change['updated_at']);

        if (remoteModified.isAfter(localModified)) {
          merged[existingIndex] = change;
        }
      } else {
        // 新增数据
        merged.add(change);
      }
    }

    return merged;
  }

  List<Map<String, dynamic>> _parseFirebaseData(Map<String, dynamic> data) {
    final documents = data['documents'] as List? ?? [];
    return documents.map((doc) {
      final fields = doc['fields'] as Map<String, dynamic>?;
      final parsed = <String, dynamic>{};

      fields?.forEach((key, value) {
        if (value['stringValue'] != null) {
          parsed[key] = value['stringValue'];
        } else if (value['integerValue'] != null) {
          parsed[key] = int.parse(value['integerValue']);
        } else if (value['booleanValue'] != null) {
          parsed[key] = value['booleanValue'];
        } else if (value['arrayValue'] != null) {
          parsed[key] = value['arrayValue']['values'] ?? [];
        }
      });

      parsed['id'] = doc['name']?.split('/')?.last;
      return parsed;
    }).toList();
  }

  Future<void> _updateLastSyncTime() async {
    await SecureStorage.saveLastSyncTime(DateTime.now().toIso8601String());
  }

  Future<DateTime?> _getLastSyncTime() async {
    final timeString = await SecureStorage.getLastSyncTime();
    return timeString != null ? DateTime.parse(timeString) : null;
  }

  // 添加缺失的方法
  void _stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> _syncPlatform(String platform) async {
    // 这里可以添加特定平台的同步逻辑
    print('同步平台: $platform');
  }

  Future<List<Map<String, dynamic>>> _getLocalChanges(String collection) async {
    // 这里应该从本地数据库获取变更
    // 由于需要访问Repository，这里只是示例
    print('获取本地变更: $collection');
    return [];
  }
}

// 数据类

enum CloudProvider {
  firebase,
  supabase,
  appwrite,
  selfHosted,
}

class SyncResult {
  final bool success;
  final List<Map<String, dynamic>>? data;
  final int? downloadedCount;
  final int? uploadedCount;
  final String? error;

  SyncResult({
    required this.success,
    this.data,
    this.downloadedCount,
    this.uploadedCount,
    this.error,
  });

  factory SyncResult.success({
    List<Map<String, dynamic>>? data,
    int? downloadedCount,
    int? uploadedCount,
  }) {
    return SyncResult(
      success: true,
      data: data,
      downloadedCount: downloadedCount,
      uploadedCount: uploadedCount,
    );
  }

  factory SyncResult.failure(String error) {
    return SyncResult(success: false, error: error);
  }
}

class BatchSyncResult {
  final bool success;
  final Map<String, SyncResult> results;
  final String? error;

  BatchSyncResult({
    required this.success,
    required this.results,
    this.error,
  });
}

class UploadResult {
  final int affectedCount;

  UploadResult(this.affectedCount);
}

class SyncStatus {
  final bool isConfigured;
  final bool isSyncing;
  final CloudProvider? provider;
  final bool autoSyncEnabled;

  const SyncStatus({
    required this.isConfigured,
    required this.isSyncing,
    this.provider,
    required this.autoSyncEnabled,
  });
}