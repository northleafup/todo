import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:watcher/watcher.dart';
import '../platform/platform_adapter.dart';
import '../storage/secure_storage.dart';
import '../constants/app_constants.dart';

/// 跨平台实时同步服务
class CrossPlatformSyncService {
  static const String _syncLockFileName = '.sync_lock';
  static const String _syncMetaFileName = '.sync_meta.json';
  static const String _syncConflictFileName = '.sync_conflict.json';

  String? _syncFolderPath;
  Timer? _syncTimer;
  Timer? _heartbeatTimer;
  StreamSubscription<WatchEvent>? _watchSubscription;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _currentDeviceId;
  SyncLock? _currentLock;

  /// 同步间隔（秒）
  static const int _syncInterval = 30;
  static const int _heartbeatInterval = 10;
  static const int _lockTimeout = 60; // 锁超时时间

  /// 初始化跨平台同步
  Future<void> initialize() async {
    try {
      final config = await _loadConfig();
      if (config != null && config['syncFolderPath'] != null) {
        _syncFolderPath = config['syncFolderPath'];
        _currentDeviceId = await _getDeviceId();

        if (await _validateSyncFolder()) {
          // 启动多层次的同步机制
          await _startAdvancedSync();
        }
      }
    } catch (e) {
      print('跨平台同步服务初始化失败: $e');
    }
  }

  /// 启动高级同步机制
  Future<void> _startAdvancedSync() async {
    // 1. 启动文件监控
    _startAdvancedFileWatcher();

    // 2. 启动定期同步
    _startPeriodicSync();

    // 3. 启动心跳机制
    _startHeartbeat();

    // 4. 启动冲突检测
    _startConflictDetection();
  }

  /// 手动强制同步所有平台
  Future<CrossPlatformSyncResult> forceCrossPlatformSync() async {
    if (_syncFolderPath == null) {
      return CrossPlatformSyncResult.failure('未配置同步文件夹');
    }

    _isSyncing = true;

    try {
      // 1. 尝试获取同步锁
      final lockAcquired = await _acquireSyncLock();
      if (!lockAcquired) {
        return CrossPlatformSyncResult.failure('其他设备正在同步，请稍候');
      }

      try {
        // 2. 检查远程文件状态
        final remoteMeta = await _getRemoteSyncMeta();
        final localMeta = await _getLocalSyncMeta();

        // 3. 决定同步策略
        final syncStrategy = _determineSyncStrategy(remoteMeta, localMeta);

        CrossPlatformSyncResult result;
        switch (syncStrategy) {
          case SyncStrategy.pull:
            result = await _pullFromRemote(remoteMeta);
            break;
          case SyncStrategy.push:
            result = await _pushToRemote();
            break;
          case SyncStrategy.merge:
            result = await _mergeSync(remoteMeta, localMeta);
            break;
          case SyncStrategy.conflict:
            result = await _handleSyncConflict(remoteMeta, localMeta);
            break;
          default:
            result = CrossPlatformSyncResult.success('数据已是最新');
        }

        // 4. 更新同步元数据
        if (result.success) {
          await _updateSyncMeta();
        }

        return result;
      } finally {
        await _releaseSyncLock();
      }
    } catch (e) {
      return CrossPlatformSyncResult.failure('跨平台同步失败: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// 高级文件监控
  void _startAdvancedFileWatcher() {
    if (_syncFolderPath == null) return;

    _stopFileWatcher();

    try {
      final folder = Directory(_syncFolderPath!);

      // 监控多个文件类型
      final watchPatterns = [
        '*.db',        // 主数据库文件
        '*.db-*',      // WAL, SHM, Journal文件
        '.sync_*',     // 同步元数据文件
      ];

      _watchSubscription = Watcher(_syncFolderPath!)
          .events
          .where((event) => _shouldProcessFile(event.path))
          .listen((event) {
            _handleCrossPlatformFileChange(event);
          });
    } catch (e) {
      print('启动高级文件监控失败: $e');
    }
  }

  /// 判断是否应该处理文件变化
  bool _shouldProcessFile(String filePath) {
    final fileName = filePath.split(Platform.pathSeparator).last;

    // 忽略临时文件和锁文件
    if (fileName.startsWith('.') && !fileName.startsWith('.sync_')) {
      return false;
    }

    // 忽略自己创建的临时文件
    if (fileName.contains('~') || fileName.endsWith('.tmp')) {
      return false;
    }

    return true;
  }

  /// 处理跨平台文件变化
  void _handleCrossPlatformFileChange(WatchEvent event) {
    if (_isSyncing) return;

    final fileName = event.path.split(Platform.pathSeparator).last;

    // 延迟处理，避免文件写入过程中的频繁触发
    Future.delayed(Duration(seconds: _isDatabaseFile(fileName) ? 2 : 1), () async {
      try {
        if (event.type == ChangeType.MODIFY || event.type == ChangeType.CREATE) {
          await _handleFileModification(event.path);
        }
      } catch (e) {
        print('处理文件变化失败: $e');
      }
    });
  }

  /// 处理文件修改
  Future<void> _handleFileModification(String filePath) async {
    final fileName = filePath.split(Platform.pathSeparator).last;

    if (_isDatabaseFile(fileName)) {
      // 数据库文件变化，需要同步
      await _handleDatabaseChange(filePath);
    } else if (fileName.startsWith('.sync_')) {
      // 同步元数据变化，需要重新评估同步状态
      await _handleSyncMetaChange(filePath);
    }
  }

  /// 处理数据库变化
  Future<void> _handleDatabaseChange(String filePath) async {
    try {
      // 检查是否是当前设备造成的修改
      if (await _isLocalChange(filePath)) {
        // 本地修改，推送到其他设备
        await _pushToRemote();
      } else {
        // 远程修改，拉取到本地
        await _pullFromRemote();
      }
    } catch (e) {
      print('处理数据库变化失败: $e');
    }
  }

  /// 处理同步元数据变化
  Future<void> _handleSyncMetaChange(String filePath) async {
    try {
      final remoteMeta = await _getRemoteSyncMeta();
      final localMeta = await _getLocalSyncMeta();

      // 检查是否有其他设备更新了数据
      if (remoteMeta != null &&
          remoteMeta['deviceId'] != _currentDeviceId &&
          remoteMeta['lastModified'] != null) {

        final remoteModified = DateTime.parse(remoteMeta['lastModified']);
        final localModified = localMeta?['lastModified'] != null
            ? DateTime.parse(localMeta!['lastModified'])
            : DateTime.fromMillisecondsSinceEpoch(0);

        if (remoteModified.isAfter(localModified)) {
          // 有其他设备更新，触发同步
          await forceCrossPlatformSync();
        }
      }
    } catch (e) {
      print('处理同步元数据变化失败: $e');
    }
  }

  /// 定期同步
  void _startPeriodicSync() {
    _stopPeriodicSync();

    _syncTimer = Timer.periodic(
      Duration(seconds: _syncInterval),
      (_) async {
        if (!_isSyncing) {
          await _performPeriodicSync();
        }
      },
    );
  }

  /// 心跳机制
  void _startHeartbeat() {
    _stopHeartbeat();

    _heartbeatTimer = Timer.periodic(
      Duration(seconds: _heartbeatInterval),
      (_) async {
        await _sendHeartbeat();
      },
    );
  }

  /// 冲突检测
  void _startConflictDetection() {
    Timer.periodic(const Duration(minutes: 1), (_) async {
      await _detectConflicts();
    });
  }

  /// 发送心跳
  Future<void> _sendHeartbeat() async {
    try {
      final heartbeatFile = File('${_syncFolderPath}${Platform.pathSeparator}.heartbeat_${_currentDeviceId}');
      await heartbeatFile.writeAsString(jsonEncode({
        'deviceId': _currentDeviceId,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': PlatformAdapter.config.name,
      }));

      // 清理过期的心跳文件
      await _cleanupExpiredHeartbeats();
    } catch (e) {
      print('发送心跳失败: $e');
    }
  }

  /// 清理过期的心跳文件
  Future<void> _cleanupExpiredHeartbeats() async {
    try {
      final folder = Directory(_syncFolderPath!);
      await for (final entity in folder.list()) {
        if (entity is File && entity.path.contains('.heartbeat_')) {
          final stat = await entity.stat();
          final age = DateTime.now().difference(stat.modified);

          // 删除超过2分钟的心跳文件
          if (age.inMinutes > 2) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      print('清理过期心跳文件失败: $e');
    }
  }

  /// 检测冲突
  Future<void> _detectConflicts() async {
    try {
      final activeDevices = await _getActiveDevices();

      if (activeDevices.length > 1) {
        // 有多个活跃设备，检查是否有冲突
        final remoteMeta = await _getRemoteSyncMeta();
        final localMeta = await _getLocalSyncMeta();

        if (remoteMeta != null && localMeta != null) {
          final remoteModified = DateTime.parse(remoteMeta['lastModified']);
          final localModified = DateTime.parse(localMeta['lastModified']);

          // 如果两个设备都在短时间内修改了数据，可能有冲突
          final diff = remoteModified.difference(localModified);
          if (diff.inSeconds.abs() < 30 && remoteMeta['deviceId'] != _currentDeviceId) {
            await _createConflictRecord(remoteMeta, localMeta);
          }
        }
      }
    } catch (e) {
      print('冲突检测失败: $e');
    }
  }

  /// 获取活跃设备列表
  Future<List<String>> _getActiveDevices() async {
    final activeDevices = <String>[];

    try {
      final folder = Directory(_syncFolderPath!);
      await for (final entity in folder.list()) {
        if (entity is File && entity.path.contains('.heartbeat_')) {
          final fileName = entity.path.split(Platform.pathSeparator).last;
          final deviceId = fileName.replaceFirst('.heartbeat_', '');
          activeDevices.add(deviceId);
        }
      }
    } catch (e) {
      print('获取活跃设备列表失败: $e');
    }

    return activeDevices;
  }

  /// 执行定期同步
  Future<void> _performPeriodicSync() async {
    try {
      // 检查是否需要同步
      final needsSync = await _checkIfNeedsSync();
      if (needsSync) {
        await forceCrossPlatformSync();
      }
    } catch (e) {
      print('定期同步失败: $e');
    }
  }

  /// 检查是否需要同步
  Future<bool> _checkIfNeedsSync() async {
    try {
      final remoteMeta = await _getRemoteSyncMeta();
      final localMeta = await _getLocalSyncMeta();

      if (remoteMeta == null && localMeta == null) {
        return false;
      }

      if (remoteMeta == null) {
        // 只有本地有数据，需要推送
        return true;
      }

      if (localMeta == null) {
        // 只有远程有数据，需要拉取
        return true;
      }

      // 比较时间戳
      final remoteModified = DateTime.parse(remoteMeta['lastModified']);
      final localModified = DateTime.parse(localMeta['lastModified']);

      return remoteModified.difference(localModified).inSeconds.abs() > 5;
    } catch (e) {
      print('检查同步需求失败: $e');
      return false;
    }
  }

  /// 决定同步策略
  SyncStrategy _determineSyncStrategy(
    Map<String, dynamic>? remoteMeta,
    Map<String, dynamic>? localMeta,
  ) {
    if (remoteMeta == null && localMeta == null) {
      return SyncStrategy.noAction;
    }

    if (remoteMeta == null) {
      return SyncStrategy.push;
    }

    if (localMeta == null) {
      return SyncStrategy.pull;
    }

    final remoteModified = DateTime.parse(remoteMeta['lastModified']);
    final localModified = DateTime.parse(localMeta['lastModified']);
    final diff = remoteModified.difference(localModified);

    if (diff.inSeconds.abs() < 5) {
      return SyncStrategy.noAction;
    }

    if (remoteModified.isAfter(localModified)) {
      if (diff.inMinutes < 1 && remoteMeta['deviceId'] != _currentDeviceId) {
        return SyncStrategy.conflict;
      }
      return SyncStrategy.pull;
    } else {
      return SyncStrategy.push;
    }
  }

  /// 从远程拉取数据
  Future<CrossPlatformSyncResult> _pullFromRemote([Map<String, dynamic>? remoteMeta]) async {
    try {
      // 实现拉取逻辑
      // 这里需要根据具体的数据库实现来完成
      return CrossPlatformSyncResult.success('已从远程拉取最新数据');
    } catch (e) {
      return CrossPlatformSyncResult.failure('拉取数据失败: $e');
    }
  }

  /// 推送数据到远程
  Future<CrossPlatformSyncResult> _pushToRemote() async {
    try {
      // 实现推送逻辑
      // 这里需要根据具体的数据库实现来完成
      return CrossPlatformSyncResult.success('已推送数据到远程');
    } catch (e) {
      return CrossPlatformSyncResult.failure('推送数据失败: $e');
    }
  }

  /// 合并同步
  Future<CrossPlatformSyncResult> _mergeSync(
    Map<String, dynamic> remoteMeta,
    Map<String, dynamic> localMeta,
  ) async {
    try {
      // 实现合并逻辑
      // 这里需要根据具体的业务逻辑来完成数据合并
      return CrossPlatformSyncResult.success('已合并数据');
    } catch (e) {
      return CrossPlatformSyncResult.failure('合并数据失败: $e');
    }
  }

  /// 处理同步冲突
  Future<CrossPlatformSyncResult> _handleSyncConflict(
    Map<String, dynamic> remoteMeta,
    Map<String, dynamic> localMeta,
  ) async {
    try {
      // 创建冲突记录
      await _createConflictRecord(remoteMeta, localMeta);

      // 简化策略：默认使用远程数据
      final result = await _pullFromRemote(remoteMeta);

      return CrossPlatformSyncResult.success(
        '检测到冲突，已使用远程数据。请检查冲突记录。'
      );
    } catch (e) {
      return CrossPlatformSyncResult.failure('处理冲突失败: $e');
    }
  }

  /// 获取同步锁
  Future<bool> _acquireSyncLock() async {
    try {
      final lockFile = File('${_syncFolderPath}${Platform.pathSeparator}$_syncLockFileName');

      // 检查现有锁
      if (await lockFile.exists()) {
        final lockData = await lockFile.readAsString();
        final existingLock = SyncLock.fromJson(jsonDecode(lockData));

        // 检查锁是否过期
        if (!existingLock.isExpired()) {
          return false; // 锁仍然有效
        }
      }

      // 创建新锁
      _currentLock = SyncLock(
        deviceId: _currentDeviceId!,
        timestamp: DateTime.now(),
        platform: PlatformAdapter.config.name,
      );

      await lockFile.writeAsString(jsonEncode(_currentLock.toJson()));
      return true;
    } catch (e) {
      print('获取同步锁失败: $e');
      return false;
    }
  }

  /// 释放同步锁
  Future<void> _releaseSyncLock() async {
    try {
      final lockFile = File('${_syncFolderPath}${Platform.pathSeparator}$_syncLockFileName');

      if (await lockFile.exists()) {
        final lockData = await lockFile.readAsString();
        final existingLock = SyncLock.fromJson(jsonDecode(lockData));

        // 只能释放自己的锁
        if (existingLock.deviceId == _currentDeviceId) {
          await lockFile.delete();
        }
      }

      _currentLock = null;
    } catch (e) {
      print('释放同步锁失败: $e');
    }
  }

  /// 获取远程同步元数据
  Future<Map<String, dynamic>?> _getRemoteSyncMeta() async {
    try {
      final metaFile = File('${_syncFolderPath}${Platform.pathSeparator}$_syncMetaFileName');

      if (await metaFile.exists()) {
        final data = await metaFile.readAsString();
        return jsonDecode(data);
      }
    } catch (e) {
      print('获取远程同步元数据失败: $e');
    }

    return null;
  }

  /// 获取本地同步元数据
  Future<Map<String, dynamic>?> _getLocalSyncMeta() async {
    try {
      final localMeta = await SecureStorage.getLocalSyncMeta();
      return localMeta != null ? jsonDecode(localMeta) : null;
    } catch (e) {
      print('获取本地同步元数据失败: $e');
      return null;
    }
  }

  /// 更新同步元数据
  Future<void> _updateSyncMeta() async {
    try {
      final meta = {
        'deviceId': _currentDeviceId,
        'platform': PlatformAdapter.config.name,
        'lastModified': DateTime.now().toIso8601String(),
        'version': '1.0',
      };

      // 保存到远程
      final metaFile = File('${_syncFolderPath}${Platform.pathSeparator}$_syncMetaFileName');
      await metaFile.writeAsString(jsonEncode(meta));

      // 保存到本地
      await SecureStorage.saveLocalSyncMeta(jsonEncode(meta));

      _lastSyncTime = DateTime.now();
    } catch (e) {
      print('更新同步元数据失败: $e');
    }
  }

  /// 创建冲突记录
  Future<void> _createConflictRecord(
    Map<String, dynamic> remoteMeta,
    Map<String, dynamic> localMeta,
  ) async {
    try {
      final conflict = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'deviceId': _currentDeviceId,
        'remoteMeta': remoteMeta,
        'localMeta': localMeta,
        'resolved': false,
      };

      final conflictFile = File('${_syncFolderPath}${Platform.pathSeparator}$_syncConflictFileName');

      List<Map<String, dynamic>> conflicts = [];
      if (await conflictFile.exists()) {
        final data = await conflictFile.readAsString();
        conflicts = List<Map<String, dynamic>>.from(jsonDecode(data));
      }

      conflicts.add(conflict);

      // 只保留最近10个冲突记录
      if (conflicts.length > 10) {
        conflicts = conflicts.sublist(conflicts.length - 10);
      }

      await conflictFile.writeAsString(jsonEncode(conflicts));
    } catch (e) {
      print('创建冲突记录失败: $e');
    }
  }

  /// 检查是否是本地修改
  Future<bool> _isLocalChange(String filePath) async {
    try {
      final stat = await File(filePath).stat();

      // 简化实现：如果文件在最近5秒内被修改，认为是本地修改
      final age = DateTime.now().difference(stat.modified);
      return age.inSeconds < 5;
    } catch (e) {
      return false;
    }
  }

  /// 验证同步文件夹
  Future<bool> _validateSyncFolder() async {
    if (_syncFolderPath == null) return false;

    try {
      final folder = Directory(_syncFolderPath!);
      return await folder.exists();
    } catch (e) {
      return false;
    }
  }

  /// 检查是否是数据库文件
  bool _isDatabaseFile(String fileName) {
    return fileName.endsWith('.db') ||
           fileName.contains('.db-wal') ||
           fileName.contains('.db-shm') ||
           fileName.contains('.db-journal');
  }

  /// 获取设备ID
  Future<String> _getDeviceId() async {
    String? deviceId = await SecureStorage.getDeviceId();

    if (deviceId == null) {
      deviceId = '${PlatformAdapter.config.name}_${DateTime.now().millisecondsSinceEpoch}';
      await SecureStorage.saveDeviceId(deviceId);
    }

    return deviceId;
  }

  /// 停止所有同步机制
  Future<void> stopAllSync() async {
    await _releaseSyncLock();
    _stopFileWatcher();
    _stopPeriodicSync();
    _stopHeartbeat();
  }

  void _stopFileWatcher() {
    _watchSubscription?.cancel();
    _watchSubscription = null;
  }

  void _stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<Map<String, dynamic>?> _loadConfig() async {
    return await SecureStorage.getCrossPlatformSyncConfig();
  }

  /// 清理配置
  Future<void> clearConfig() async {
    await stopAllSync();
    _syncFolderPath = null;
    _currentDeviceId = null;
    _lastSyncTime = null;
    await SecureStorage.clearCrossPlatformSyncConfig();
  }
}

// 数据类

enum SyncStrategy {
  pull,        // 从远程拉取
  push,        // 推送到远程
  merge,       // 合并数据
  conflict,    // 处理冲突
  noAction,    // 无需操作
}

class CrossPlatformSyncResult {
  final bool success;
  final String? message;
  final String? error;

  CrossPlatformSyncResult._({required this.success, this.message, this.error});

  factory CrossPlatformSyncResult.success(String message) =>
      CrossPlatformSyncResult._(success: true, message: message);

  factory CrossPlatformSyncResult.failure(String error) =>
      CrossPlatformSyncResult._(success: false, error: error);
}

class SyncLock {
  final String deviceId;
  final DateTime timestamp;
  final String platform;

  SyncLock({
    required this.deviceId,
    required this.timestamp,
    required this.platform,
  });

  bool isExpired() {
    return DateTime.now().difference(timestamp).inSeconds > CrossPlatformSyncService._lockTimeout;
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'timestamp': timestamp.toIso8601String(),
      'platform': platform,
    };
  }

  factory SyncLock.fromJson(Map<String, dynamic> json) {
    return SyncLock(
      deviceId: json['deviceId'],
      timestamp: DateTime.parse(json['timestamp']),
      platform: json['platform'],
    );
  }
}