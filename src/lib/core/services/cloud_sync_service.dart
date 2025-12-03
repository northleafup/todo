import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../platform/platform_adapter.dart';
import '../storage/secure_storage.dart';
import '../errors/exceptions.dart';
import '../constants/app_constants.dart';

/// 云同步服务，支持多种同步策略
class CloudSyncService {
  static const String _baseUrl = 'https://api.beautiful-todo.com/v1';
  String? _authToken;
  Timer? _syncTimer;
  bool _isSyncing = false;

  /// 初始化云同步服务
  Future<void> initialize() async {
    try {
      _authToken = await SecureStorage.getToken('cloud_sync');

      if (_authToken != null && isOnline) {
        // 启动自动同步
        _startAutoSync();
      }
    } catch (e) {
      throw SyncException('初始化云同步服务失败: $e');
    }
  }

  /// 检查网络连接状态
  bool get isOnline {
    // 在实际应用中，应该使用connectivity_plus插件
    return true; // 简化实现
  }

  /// 检查是否已登录
  bool get isLoggedIn => _authToken != null;

  /// 登录到云服务
  Future<LoginResult> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'deviceId': await _getDeviceId(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['token'];
        await SecureStorage.saveToken('cloud_sync', _authToken!);

        // 启动自动同步
        if (isOnline) {
          _startAutoSync();
        }

        return LoginResult.success(data['user']);
      } else {
        final error = jsonDecode(response.body)['message'];
        return LoginResult.failure(error);
      }
    } catch (e) {
      return LoginResult.failure('登录失败: $e');
    }
  }

  /// 登出
  Future<void> logout() async {
    _authToken = null;
    await SecureStorage.clearToken('cloud_sync');
    _stopAutoSync();
  }

  /// 注册新账户
  Future<RegisterResult> register(String email, String password, String name) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'deviceId': await _getDeviceId(),
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return RegisterResult.success(data['user']);
      } else {
        final error = jsonDecode(response.body)['message'];
        return RegisterResult.failure(error);
      }
    } catch (e) {
      return RegisterResult.failure('注册失败: $e');
    }
  }

  /// 同步本地数据到云端
  Future<SyncResult> syncToCloud(Map<String, dynamic> localData) async {
    if (!isLoggedIn) {
      return SyncResult.failure('未登录');
    }

    if (_isSyncing) {
      return SyncResult.failure('同步进行中，请稍候');
    }

    _isSyncing = true;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sync/upload'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'data': localData,
          'deviceId': await _getDeviceId(),
          'timestamp': DateTime.now().toIso8601String(),
          'platform': PlatformAdapter.config.name,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _updateLastSyncTime();
        return SyncResult.success(data['syncId']);
      } else {
        final error = jsonDecode(response.body)['message'];
        return SyncResult.failure(error);
      }
    } catch (e) {
      return SyncResult.failure('上传失败: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// 从云端下载数据
  Future<DownloadResult> downloadFromCloud({DateTime? since}) async {
    if (!isLoggedIn) {
      return DownloadResult.failure('未登录');
    }

    try {
      final uri = Uri.parse('$_baseUrl/sync/download');
      final requestUri = since != null
          ? uri.replace(queryParameters: {'since': since.toIso8601String()})
          : uri;

      final response = await http.get(
        requestUri,
        headers: {'Authorization': 'Bearer $_authToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _updateLastSyncTime();
        return DownloadResult.success(data['data'], data['version']);
      } else {
        final error = jsonDecode(response.body)['message'];
        return DownloadResult.failure(error);
      }
    } catch (e) {
      return DownloadResult.failure('下载失败: $e');
    }
  }

  /// 增量同步
  Future<IncrementalSyncResult> incrementalSync() async {
    if (!isLoggedIn || !isOnline) {
      return IncrementalSyncResult.skipped('离线状态');
    }

    try {
      final lastSync = await _getLastSyncTime();

      // 1. 下载云端变更
      final downloadResult = await downloadFromCloud(since: lastSync);
      if (!downloadResult.success) {
        return IncrementalSyncResult.failure(downloadResult.error!);
      }

      // 2. 上传本地变更
      final localChanges = await _getLocalChanges(lastSync);
      if (localChanges.isNotEmpty) {
        final uploadResult = await syncToCloud(localChanges);
        if (!uploadResult.success) {
          return IncrementalSyncResult.failure(uploadResult.error!);
        }
      }

      return IncrementalSyncResult.success(
        downloadedCount: downloadResult.data.length,
        uploadedCount: localChanges.length,
      );
    } catch (e) {
      return IncrementalSyncResult.failure('增量同步失败: $e');
    }
  }

  /// 冲突解决
  Future<ConflictResolutionResult> resolveConflicts(
    List<DataConflict> conflicts,
  ) async {
    try {
      final resolvedConflicts = <ResolvedConflict>[];

      for (final conflict in conflicts) {
        final resolution = await _resolveConflict(conflict);
        resolvedConflicts.add(resolution);
      }

      // 上传解决方案
      final response = await http.post(
        Uri.parse('$_baseUrl/sync/resolve-conflicts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'resolutions': resolvedConflicts.map((r) => r.toJson()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        return ConflictResolutionResult.success(resolvedConflicts);
      } else {
        final error = jsonDecode(response.body)['message'];
        return ConflictResolutionResult.failure(error);
      }
    } catch (e) {
      return ConflictResolutionResult.failure('解决冲突失败: $e');
    }
  }

  /// 获取同步状态
  SyncStatus get syncStatus {
    return SyncStatus(
      isLoggedIn: isLoggedIn,
      isOnline: isOnline,
      isSyncing: _isSyncing,
      lastSyncTime: null, // 应该从存储获取
      autoSyncEnabled: _syncTimer?.isActive ?? false,
    );
  }

  /// 启用/禁用自动同步
  void setAutoSync(bool enabled) {
    if (enabled && isLoggedIn && isOnline) {
      _startAutoSync();
    } else {
      _stopAutoSync();
    }
  }

  /// 手动触发同步
  Future<IncrementalSyncResult> manualSync() async {
    return await incrementalSync();
  }

  // 私有方法

  void _startAutoSync() {
    _stopAutoSync(); // 确保没有重复的定时器

    _syncTimer = Timer.periodic(
      const Duration(minutes: 5), // 每5分钟同步一次
      (_) async {
        if (isLoggedIn && isOnline && !_isSyncing) {
          await incrementalSync();
        }
      },
    );
  }

  void _stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<String> _getDeviceId() async {
    // 生成或获取设备唯一标识符
    return SecureStorage.getDeviceId() ?? 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _updateLastSyncTime() async {
    final now = DateTime.now().toIso8601String();
    await SecureStorage.saveLastSyncTime(now);
  }

  Future<DateTime?> _getLastSyncTime() async {
    final timeString = await SecureStorage.getLastSyncTime();
    return timeString != null ? DateTime.parse(timeString) : null;
  }

  Future<Map<String, dynamic>> _getLocalChanges(DateTime since) async {
    // 这里应该从本地数据库获取自指定时间以来的变更
    // 简化实现，返回空Map
    return {};
  }

  Future<ResolvedConflict> _resolveConflict(DataConflict conflict) async {
    // 简化的冲突解决策略：总是选择云端版本
    return ResolvedConflict(
      conflictId: conflict.id,
      resolvedData: conflict.remoteData,
      resolutionType: ConflictResolutionType.useRemote,
    );
  }
}

// 数据类和结果类

class LoginResult {
  final bool success;
  final String? user;
  final String? error;

  LoginResult._({required this.success, this.user, this.error});

  factory LoginResult.success(String user) =>
      LoginResult._(success: true, user: user);

  factory LoginResult.failure(String error) =>
      LoginResult._(success: false, error: error);
}

class RegisterResult {
  final bool success;
  final String? user;
  final String? error;

  RegisterResult._({required this.success, this.user, this.error});

  factory RegisterResult.success(String user) =>
      RegisterResult._(success: true, user: user);

  factory RegisterResult.failure(String error) =>
      RegisterResult._(success: false, error: error);
}

class SyncResult {
  final bool success;
  final String? syncId;
  final String? error;

  SyncResult._({required this.success, this.syncId, this.error});

  factory SyncResult.success(String syncId) =>
      SyncResult._(success: true, syncId: syncId);

  factory SyncResult.failure(String error) =>
      SyncResult._(success: false, error: error);
}

class DownloadResult {
  final bool success;
  final Map<String, dynamic> data;
  final int? version;
  final String? error;

  DownloadResult._({
    required this.success,
    required this.data,
    this.version,
    this.error,
  });

  factory DownloadResult.success(Map<String, dynamic> data, int version) =>
      DownloadResult._(success: true, data: data, version: version);

  factory DownloadResult.failure(String error) =>
      DownloadResult._(success: false, data: {}, error: error);
}

class IncrementalSyncResult {
  final bool success;
  final int? downloadedCount;
  final int? uploadedCount;
  final String? error;

  IncrementalSyncResult._({
    required this.success,
    this.downloadedCount,
    this.uploadedCount,
    this.error,
  });

  factory IncrementalSyncResult.success({
    required int downloadedCount,
    required int uploadedCount,
  }) => IncrementalSyncResult._(
    success: true,
    downloadedCount: downloadedCount,
    uploadedCount: uploadedCount,
  );

  factory IncrementalSyncResult.failure(String error) =>
      IncrementalSyncResult._(success: false, error: error);

  factory IncrementalSyncResult.skipped(String reason) =>
      IncrementalSyncResult._(success: false, error: reason);
}

class ConflictResolutionResult {
  final bool success;
  final List<ResolvedConflict>? resolvedConflicts;
  final String? error;

  ConflictResolutionResult._({
    required this.success,
    this.resolvedConflicts,
    this.error,
  });

  factory ConflictResolutionResult.success(List<ResolvedConflict> conflicts) =>
      ConflictResolutionResult._(success: true, resolvedConflicts: conflicts);

  factory ConflictResolutionResult.failure(String error) =>
      ConflictResolutionResult._(success: false, error: error);
}

class SyncStatus {
  final bool isLoggedIn;
  final bool isOnline;
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final bool autoSyncEnabled;

  const SyncStatus({
    required this.isLoggedIn,
    required this.isOnline,
    required this.isSyncing,
    this.lastSyncTime,
    required this.autoSyncEnabled,
  });
}

class DataConflict {
  final String id;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final DateTime localModified;
  final DateTime remoteModified;

  const DataConflict({
    required this.id,
    required this.localData,
    required this.remoteData,
    required this.localModified,
    required this.remoteModified,
  });
}

class ResolvedConflict {
  final String conflictId;
  final Map<String, dynamic> resolvedData;
  final ConflictResolutionType resolutionType;

  const ResolvedConflict({
    required this.conflictId,
    required this.resolvedData,
    required this.resolutionType,
  });

  Map<String, dynamic> toJson() {
    return {
      'conflictId': conflictId,
      'resolvedData': resolvedData,
      'resolutionType': resolutionType.name,
    };
  }
}

enum ConflictResolutionType {
  useLocal,
  useRemote,
  merge,
  manual,
}