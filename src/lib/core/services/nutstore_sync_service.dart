import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import '../platform/platform_adapter.dart';
import '../storage/secure_storage.dart';
import '../constants/app_constants.dart';

/// 坚果云文件同步服务 - 基于WebDAV协议
class NutstoreSyncService {
  static const String _baseUrl = 'https://dav.jianguoyun.com/dav';
  String? _username;
  String? _password;
  String? _accessToken;
  Timer? _syncTimer;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  /// 应用数据文件夹路径
  final String _appDataDir = 'beautiful_todo';

  /// 数据库文件名
  final String _dbFileName = 'todos.db';
  final String _dbJournalFileName = 'todos.db-journal';
  final String _dbWalFileName = 'todos.db-wal';
  final String _dbShmFileName = 'todos.db-shm';

  /// 同步状态文件
  final String _syncInfoFileName = 'sync_info.json';

  /// 初始化坚果云同步
  Future<void> initialize() async {
    try {
      final config = await _loadConfig();
      if (config != null) {
        _username = config['username'];
        _password = config['password'];
        _accessToken = config['accessToken'];

        // 验证连接
        final isConnected = await _testConnection();
        if (isConnected) {
          _startAutoSync();
          await _ensureRemoteFolder();
        }
      }
    } catch (e) {
      print('坚果云同步初始化失败: $e');
    }
  }

  /// 设置坚果云账户
  Future<NutstoreAuthResult> setupAccount(String username, String password) async {
    try {
      // 验证账户信息
      final authResult = await _authenticate(username, password);

      if (authResult.success) {
        _username = username;
        _password = password;
        _accessToken = authResult.accessToken;

        // 保存配置
        await _saveConfig({
          'username': username,
          'password': password,
          'accessToken': _accessToken,
        });

        // 创建远程文件夹
        await _ensureRemoteFolder();

        // 启动自动同步
        _startAutoSync();

        return NutstoreAuthResult.success('坚果云连接成功');
      } else {
        return NutstoreAuthResult.failure(authResult.error!);
      }
    } catch (e) {
      return NutstoreAuthResult.failure('设置失败: $e');
    }
  }

  /// 获取坚果云授权URL（使用OAuth）
  String getAuthorizationUrl() {
    final clientId = 'your_client_id'; // 需要在坚果云开发者平台注册
    final redirectUri = 'beautiful_todo://oauth_callback';
    final scope = 'read write';

    return 'https://app.jianguoyun.com/oauth/authorize?'
           'client_id=$clientId&'
           'redirect_uri=$redirectUri&'
           'response_type=code&'
           'scope=$scope';
  }

  /// 处理OAuth回调
  Future<NutstoreAuthResult> handleOAuthCallback(String code) async {
    try {
      final response = await http.post(
        Uri.parse('https://app.jianguoyun.com/oauth/access_token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': 'your_client_id',
          'client_secret': 'your_client_secret',
          'code': code,
          'grant_type': 'authorization_code',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];

        return NutstoreAuthResult.success('授权成功');
      } else {
        return NutstoreAuthResult.failure('授权失败');
      }
    } catch (e) {
      return NutstoreAuthResult.failure('OAuth处理失败: $e');
    }
  }

  /// 同步本地数据库到云端
  Future<FileSyncResult> syncToCloud() async {
    if (!_isConfigured) {
      return FileSyncResult.failure('未配置坚果云账户');
    }

    _isSyncing = true;

    try {
      // 1. 获取本地数据库文件
      final localDbPath = await _getLocalDatabasePath();
      final dbFile = File(localDbPath);

      if (!await dbFile.exists()) {
        return FileSyncResult.failure('本地数据库文件不存在');
      }

      // 2. 检查云端文件版本
      final remoteSyncInfo = await _getRemoteSyncInfo();

      // 3. 决定同步策略
      final localLastModified = await dbFile.lastModified();

      if (remoteSyncInfo != null &&
          remoteSyncInfo['lastModified'] != null &&
          DateTime.parse(remoteSyncInfo['lastModified']).isAfter(localLastModified)) {
        // 云端更新，需要下载
        return await _downloadFromCloud();
      } else {
        // 本地更新，需要上传
        return await _uploadToCloud(dbFile);
      }
    } catch (e) {
      return FileSyncResult.failure('同步失败: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// 强制上传到云端
  Future<FileSyncResult> forceUploadToCloud() async {
    if (!_isConfigured) {
      return FileSyncResult.failure('未配置坚果云账户');
    }

    _isSyncing = true;

    try {
      final localDbPath = await _getLocalDatabasePath();
      final dbFile = File(localDbPath);

      if (!await dbFile.exists()) {
        return FileSyncResult.failure('本地数据库文件不存在');
      }

      final result = await _uploadToCloud(dbFile, force: true);
      if (result.success) {
        await _updateLastSyncTime();
      }

      return result;
    } catch (e) {
      return FileSyncResult.failure('强制上传失败: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// 强制从云端下载
  Future<FileSyncResult> forceDownloadFromCloud() async {
    if (!_isConfigured) {
      return FileSyncResult.failure('未配置坚果云账户');
    }

    _isSyncing = true;

    try {
      final result = await _downloadFromCloud(force: true);
      if (result.success) {
        await _updateLastSyncTime();
      }

      return result;
    } catch (e) {
      return FileSyncResult.failure('强制下载失败: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// 检查同步状态
  NutstoreSyncStatus get syncStatus {
    return NutstoreSyncStatus(
      isConfigured: _isConfigured,
      isSyncing: _isSyncing,
      lastSyncTime: _lastSyncTime,
      username: _username,
      autoSyncEnabled: _syncTimer?.isActive ?? false,
    );
  }

  /// 启用/禁用自动同步
  void setAutoSync(bool enabled) {
    if (enabled && _isConfigured) {
      _startAutoSync();
    } else {
      _stopAutoSync();
    }
  }

  /// 清除配置
  Future<void> clearConfig() async {
    _stopAutoSync();
    _username = null;
    _password = null;
    _accessToken = null;
    _lastSyncTime = null;
    await SecureStorage.clearNutstoreConfig();
  }

  /// 获取云端文件列表
  Future<List<NutstoreFileInfo>> getRemoteFileList() async {
    if (!_isConfigured) {
      return [];
    }

    try {
      final response = await _makeRequest('PROPFIND', '/$_appDataDir/');

      if (response.statusCode == 207) { // Multi-Status
        return _parseWebDavResponse(response.body);
      }
    } catch (e) {
      print('获取云端文件列表失败: $e');
    }

    return [];
  }

  // 私有方法

  bool get _isConfigured => (_username != null && _password != null) || _accessToken != null;

  void _startAutoSync() {
    _stopAutoSync();

    _syncTimer = Timer.periodic(
      const Duration(minutes: 3), // 每3分钟检查一次
      (_) => _performAutoSync(),
    );
  }

  void _stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> _performAutoSync() async {
    if (_isSyncing || !_isConfigured) return;

    try {
      await syncToCloud();
    } catch (e) {
      print('自动同步失败: $e');
    }
  }

  Future<NutstoreAuthResult> _authenticate(String username, String password) async {
    try {
      // 测试WebDAV连接
      final response = await http.get(
        Uri.parse('$_baseUrl/'),
        headers: _getAuthHeaders(username, password),
      );

      if (response.statusCode == 200) {
        return NutstoreAuthResult.success('认证成功');
      } else {
        return NutstoreAuthResult.failure('认证失败: ${response.statusCode}');
      }
    } catch (e) {
      return NutstoreAuthResult.failure('网络错误: $e');
    }
  }

  Future<bool> _testConnection() async {
    try {
      final response = await _makeRequest('GET', '/');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> _ensureRemoteFolder() async {
    try {
      // 创建应用文件夹
      await _makeRequest('MKCOL', '/$_appDataDir/');
    } catch (e) {
      // 文件夹可能已存在，忽略错误
      print('创建远程文件夹失败: $e');
    }
  }

  Future<FileSyncResult> _uploadToCloud(File dbFile, {bool force = false}) async {
    try {
      final fileBytes = await dbFile.readAsBytes();
      final lastModified = await dbFile.lastModified();

      // 上传主数据库文件
      final response = await _makeRequest(
        'PUT',
        '/$_appDataDir/$_dbFileName',
        body: fileBytes,
      );

      if (response.statusCode == 201 || response.statusCode == 204) {
        // 上传相关文件
        await _uploadRelatedFiles(dbFile.parent);

        // 更新同步信息
        await _updateRemoteSyncInfo({
          'lastModified': lastModified.toIso8601String(),
          'fileSize': fileBytes.length,
          'version': '1.0',
        });

        await _updateLastSyncTime();

        return FileSyncResult.success(
          operation: FileSyncOperation.upload,
          fileSize: fileBytes.length,
        );
      } else {
        return FileSyncResult.failure('上传失败: ${response.statusCode}');
      }
    } catch (e) {
      return FileSyncResult.failure('上传异常: $e');
    }
  }

  Future<FileSyncResult> _downloadFromCloud({bool force = false}) async {
    try {
      final localDbPath = await _getLocalDatabasePath();
      final localDbDir = Directory(path.dirname(localDbPath));

      // 确保本地目录存在
      if (!await localDbDir.exists()) {
        await localDbDir.create(recursive: true);
      }

      // 下载主数据库文件
      final response = await _makeRequest('GET', '/$_appDataDir/$_dbFileName');

      if (response.statusCode == 200) {
        // 备份本地文件
        await _backupLocalFile(localDbPath);

        // 写入新文件
        final dbFile = File(localDbPath);
        await dbFile.writeAsBytes(response.bodyBytes);

        // 下载相关文件
        await _downloadRelatedFiles(localDbDir);

        await _updateLastSyncTime();

        return FileSyncResult.success(
          operation: FileSyncOperation.download,
          fileSize: response.bodyBytes.length,
        );
      } else {
        return FileSyncResult.failure('下载失败: ${response.statusCode}');
      }
    } catch (e) {
      return FileSyncResult.failure('下载异常: $e');
    }
  }

  Future<void> _uploadRelatedFiles(Directory dbDir) async {
    final relatedFiles = [_dbJournalFileName, _dbWalFileName, _dbShmFileName];

    for (final fileName in relatedFiles) {
      final file = File(path.join(dbDir.path, fileName));
      if (await file.exists()) {
        final fileBytes = await file.readAsBytes();
        await _makeRequest(
          'PUT',
          '/$_appDataDir/$fileName',
          body: fileBytes,
        );
      }
    }
  }

  Future<void> _downloadRelatedFiles(Directory localDbDir) async {
    final relatedFiles = [_dbJournalFileName, _dbWalFileName, _dbShmFileName];

    for (final fileName in relatedFiles) {
      try {
        final response = await _makeRequest('GET', '/$_appDataDir/$fileName');
        if (response.statusCode == 200) {
          final file = File(path.join(localDbDir.path, fileName));
          await file.writeAsBytes(response.bodyBytes);
        }
      } catch (e) {
        print('下载相关文件 $fileName 失败: $e');
      }
    }
  }

  Future<void> _backupLocalFile(String filePath) async {
    final originalFile = File(filePath);
    if (await originalFile.exists()) {
      final backupFile = File('$filePath.backup.${DateTime.now().millisecondsSinceEpoch}');
      await originalFile.copy(backupFile.path);
    }
  }

  Future<Future<http.Response>> _makeRequest(
    String method,
    String path, {
    Map<String, String>? headers,
    List<int>? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final request = http.Request(method, uri);

    // 设置认证头
    final authHeaders = _getAuthHeaders();
    request.headers.addAll(authHeaders);

    if (headers != null) {
      request.headers.addAll(headers);
    }

    if (body != null) {
      request.bodyBytes = body;
    }

    return await request.send();
  }

  Map<String, String> _getAuthHeaders([String? username, String? password]) {
    if (_accessToken != null) {
      return {'Authorization': 'Bearer $_accessToken'};
    } else if (username != null && password != null) {
      final credentials = base64Encode(utf8.encode('$username:$password'));
      return {'Authorization': 'Basic $credentials'};
    } else {
      return {};
    }
  }

  Future<String> _getLocalDatabasePath() async {
    String basePath;
    if (PlatformAdapter.isAndroid) {
      basePath = '/data/data/com.beautiful_todo.app/databases';
    } else if (PlatformAdapter.isIOS) {
      final documentsDir = await getApplicationDocumentsDirectory();
      basePath = documentsDir.path;
    } else {
      basePath = PlatformService.getPlatformPath('databases');
    }

    return path.join(basePath, _dbFileName);
  }

  Future<Map<String, dynamic>?> _getRemoteSyncInfo() async {
    try {
      final response = await _makeRequest('GET', '/$_appDataDir/$_syncInfoFileName');

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      print('获取远程同步信息失败: $e');
    }

    return null;
  }

  Future<void> _updateRemoteSyncInfo(Map<String, dynamic> info) async {
    info['lastSync'] = DateTime.now().toIso8601String();
    info['device'] = await _getDeviceInfo();

    final infoJson = jsonEncode(info);
    await _makeRequest(
      'PUT',
      '/$_appDataDir/$_syncInfoFileName',
      body: utf8.encode(infoJson),
    );
  }

  Future<void> _updateLastSyncTime() async {
    _lastSyncTime = DateTime.now();
    await SecureStorage.saveLastSyncTime(_lastSyncTime!.toIso8601String());
  }

  Future<Map<String, dynamic>> _loadConfig() async {
    return await SecureStorage.getNutstoreConfig();
  }

  Future<void> _saveConfig(Map<String, dynamic> config) async {
    await SecureStorage.saveNutstoreConfig(config);
  }

  Future<String> _getDeviceInfo() async {
    return '${PlatformAdapter.config.name}_${PlatformService.platformInfo.deviceInfo}';
  }

  List<NutstoreFileInfo> _parseWebDavResponse(String xml) {
    // 简化的XML解析，实际应用中应该使用xml包
    final files = <NutstoreFileInfo>[];

    // 这里应该解析WebDAV PROPFIND响应
    // 为了简化，返回空列表

    return files;
  }
}

// 数据类

class NutstoreAuthResult {
  final bool success;
  final String? accessToken;
  final String? error;

  NutstoreAuthResult._({required this.success, this.accessToken, this.error});

  factory NutstoreAuthResult.success(String accessToken) =>
      NutstoreAuthResult._(success: true, accessToken: accessToken);

  factory NutstoreAuthResult.failure(String error) =>
      NutstoreAuthResult._(success: false, error: error);
}

class FileSyncResult {
  final bool success;
  final FileSyncOperation? operation;
  final int? fileSize;
  final String? error;

  FileSyncResult._({required this.success, this.operation, this.fileSize, this.error});

  factory FileSyncResult.success({
    required FileSyncOperation operation,
    int? fileSize,
  }) {
    return FileSyncResult._(
      success: true,
      operation: operation,
      fileSize: fileSize,
    );
  }

  factory FileSyncResult.failure(String error) {
    return FileSyncResult._(success: false, error: error);
  }
}

enum FileSyncOperation {
  upload,
  download,
  noAction,
}

class NutstoreSyncStatus {
  final bool isConfigured;
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final String? username;
  final bool autoSyncEnabled;

  const NutstoreSyncStatus({
    required this.isConfigured,
    required this.isSyncing,
    this.lastSyncTime,
    this.username,
    required this.autoSyncEnabled,
  });
}

class NutstoreFileInfo {
  final String name;
  final int size;
  final DateTime lastModified;
  final String path;

  const NutstoreFileInfo({
    required this.name,
    required this.size,
    required this.lastModified,
    required this.path,
  });
}