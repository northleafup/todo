import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../platform/platform_adapter.dart';
import '../storage/secure_storage.dart';
import '../constants/app_constants.dart';

/// 文件选择同步服务 - 让用户选择同步文件夹路径
class FilePickerSyncService {
  String? _syncFolderPath;
  String? _databaseFileName;
  Timer? _syncTimer;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  StreamSubscription<FileSystemEvent>? _watchSubscription;

  /// 默认数据库文件名
  static const String defaultDatabaseFileName = 'todos_sync.db';

  /// 初始化服务
  Future<void> initialize() async {
    try {
      final config = await _loadConfig();
      if (config != null && config['syncFolderPath'] != null) {
        _syncFolderPath = config['syncFolderPath'];
        _databaseFileName = config['databaseFileName'] ?? defaultDatabaseFileName;

        // 验证文件夹是否存在
        if (await _validateSyncFolder()) {
          // 启动文件监控
          _startFileWatcher();
          // 启动自动同步
          _startAutoSync();
        }
      }
    } catch (e) {
      print('文件同步服务初始化失败: $e');
    }
  }

  /// 选择同步文件夹
  Future<FolderPickerResult> selectSyncFolder() async {
    try {
      String? selectedPath;

      if (PlatformAdapter.isAndroid) {
        // Android使用外部存储目录选择
        selectedPath = await _selectAndroidFolder();
      } else if (PlatformAdapter.isIOS) {
        // iOS使用文档目录
        selectedPath = await _selectIOSFolder();
      } else {
        // 桌面平台使用文件夹选择器
        selectedPath = await _selectDesktopFolder();
      }

      if (selectedPath == null || selectedPath.isEmpty) {
        return FolderPickerResult.failure('未选择文件夹');
      }

      // 验证文件夹权限
      final validationResult = await _validateFolderAccess(selectedPath);
      if (!validationResult.success) {
        return FolderPickerResult.failure(validationResult.error!);
      }

      // 保存配置
      _syncFolderPath = selectedPath;
      _databaseFileName = defaultDatabaseFileName;

      await _saveConfig({
        'syncFolderPath': selectedPath,
        'databaseFileName': _databaseFileName,
        'platform': PlatformAdapter.config.name,
        'setupTime': DateTime.now().toIso8601String(),
      });

      // 启动同步
      _startFileWatcher();
      _startAutoSync();

      return FolderPickerResult.success(selectedPath);
    } catch (e) {
      return FolderPickerResult.failure('选择文件夹失败: $e');
    }
  }

  /// 手动选择数据库文件
  Future<FilePickerResult> selectDatabaseFile() async {
    try {
      FilePickerResult? result;

      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db', 'sqlite', 'sqlite3'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);

        if (!await file.exists()) {
          return FilePickerResult.failure('选择的文件不存在');
        }

        // 验证是否是有效的SQLite文件
        final isValidDb = await _validateDatabaseFile(file);
        if (!isValidDb) {
          return FilePickerResult.failure('选择的文件不是有效的SQLite数据库');
        }

        _syncFolderPath = file.parent.path;
        _databaseFileName = file.path.split('/').last;

        await _saveConfig({
          'syncFolderPath': _syncFolderPath,
          'databaseFileName': _databaseFileName,
          'platform': PlatformAdapter.config.name,
        });

        _startFileWatcher();
        _startAutoSync();

        return FilePickerResult.success(filePath);
      } else {
        return FilePickerResult.failure('未选择文件');
      }
    } catch (e) {
      return FilePickerResult.failure('选择文件失败: $e');
    }
  }

  /// 设置自定义数据库文件名
  void setDatabaseFileName(String fileName) {
    _databaseFileName = fileName;
    _saveConfig({
      'syncFolderPath': _syncFolderPath,
      'databaseFileName': _databaseFileName,
    });
  }

  /// 获取同步数据库文件路径
  String? get syncDatabasePath {
    if (_syncFolderPath == null || _databaseFileName == null) {
      return null;
    }
    return _getSyncFilePath();
  }

  /// 检查同步文件夹状态
  SyncFolderStatus get folderStatus {
    return SyncFolderStatus(
      isConfigured: _syncFolderPath != null,
      isAccessible: _syncFolderPath != null ? Directory(_syncFolderPath!).existsSync() : false,
      lastSyncTime: _lastSyncTime,
      isSyncing: _isSyncing,
      autoSyncEnabled: _watchSubscription != null,
      folderPath: _syncFolderPath,
      databaseFileName: _databaseFileName,
    );
  }

  /// 强制同步（从外部数据库复制到应用数据库）
  Future<SyncOperationResult> forceSyncFromExternal() async {
    if (_syncFolderPath == null || _databaseFileName == null) {
      return SyncOperationResult.failure('未配置同步文件夹');
    }

    _isSyncing = true;

    try {
      final externalDbFile = File(_getSyncFilePath());
      final appDbPath = await _getAppDatabasePath();

      // 检查外部文件是否存在
      if (!await externalDbFile.exists()) {
        return SyncOperationResult.failure('外部数据库文件不存在');
      }

      // 验证外部数据库
      if (!await _validateDatabaseFile(externalDbFile)) {
        return SyncOperationResult.failure('外部数据库文件无效');
      }

      // 备份当前应用数据库
      await _backupAppDatabase(appDbPath);

      // 复制外部数据库到应用
      await externalDbFile.copy(appDbPath);

      await _updateLastSyncTime();

      return SyncOperationResult.success(
        operation: SyncOperation.import,
        fileSize: await externalDbFile.length(),
      );
    } catch (e) {
      return SyncOperationResult.failure('强制导入失败: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// 强制同步（从应用数据库复制到外部文件夹）
  Future<SyncOperationResult> forceSyncToExternal() async {
    if (_syncFolderPath == null || _databaseFileName == null) {
      return SyncOperationResult.failure('未配置同步文件夹');
    }

    _isSyncing = true;

    try {
      final appDbPath = await _getAppDatabasePath();
      final externalDbFile = File(_getSyncFilePath());

      // 检查应用数据库是否存在
      final appDbFile = File(appDbPath);
      if (!await appDbFile.exists()) {
        return SyncOperationResult.failure('应用数据库文件不存在');
      }

      // 确保外部文件夹存在
      final externalFolder = Directory(_syncFolderPath!);
      if (!await externalFolder.exists()) {
        await externalFolder.create(recursive: true);
      }

      // 复制应用数据库到外部
      await appDbFile.copy(externalDbFile.path);

      await _updateLastSyncTime();

      return SyncOperationResult.success(
        operation: SyncOperation.export,
        fileSize: await appDbFile.length(),
      );
    } catch (e) {
      return SyncOperationResult.failure('强制导出失败: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// 双向同步（智能合并）
  Future<SyncOperationResult> bidirectionalSync() async {
    if (_syncFolderPath == null || _databaseFileName == null) {
      return SyncOperationResult.failure('未配置同步文件夹');
    }

    _isSyncing = true;

    try {
      final appDbPath = await _getAppDatabasePath();
      final externalDbFile = File(_getSyncFilePath());

      final appDbFile = File(appDbPath);

      // 检查文件存在性和有效性
      final appDbExists = await appDbFile.exists();
      final externalDbExists = await externalDbFile.exists();

      if (!appDbExists && !externalDbExists) {
        return SyncOperationResult.failure('两个数据库文件都不存在');
      }

      if (!appDbExists && externalDbExists) {
        // 只有外部文件存在，导入到应用
        return await forceSyncFromExternal();
      }

      if (appDbExists && !externalDbExists) {
        // 只有应用文件存在，导出到外部
        return await forceSyncToExternal();
      }

      // 两个文件都存在，比较修改时间决定同步方向
      final appModified = await appDbFile.lastModified();
      final externalModified = await externalDbFile.lastModified();

      if (externalModified.isAfter(appModified)) {
        // 外部文件更新，导入到应用
        return await forceSyncFromExternal();
      } else if (appModified.isAfter(externalModified)) {
        // 应用文件更新，导出到外部
        return await forceSyncToExternal();
      } else {
        // 文件时间相同，无需同步
        return SyncOperationResult.success(
          operation: SyncOperation.noAction,
          message: '数据库文件已是最新，无需同步',
        );
      }
    } catch (e) {
      return SyncOperationResult.failure('双向同步失败: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// 获取同步文件夹中的数据库文件列表
  Future<List<DatabaseFileInfo>> getDatabaseFilesInFolder() async {
    final files = <DatabaseFileInfo>[];

    if (_syncFolderPath == null) {
      return files;
    }

    try {
      final folder = Directory(_syncFolderPath!);
      if (!await folder.exists()) {
        return files;
      }

      await for (final entity in folder.list()) {
        if (entity is File) {
          final fileName = entity.path.split('/').last;
          if (_isDatabaseFile(fileName)) {
            final stat = await entity.stat();
            final isValidDb = await _validateDatabaseFile(entity);

            files.add(DatabaseFileInfo(
              name: fileName,
              path: entity.path,
              size: stat.size,
              lastModified: stat.modified,
              isValid: isValidDb,
            ));
          }
        }
      }
    } catch (e) {
      print('获取数据库文件列表失败: $e');
    }

    // 按修改时间排序
    files.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    return files;
  }

  /// 启用/禁用自动同步
  void setAutoSync(bool enabled) {
    if (enabled) {
      _startFileWatcher();
      _startAutoSync();
    } else {
      _stopFileWatcher();
      _stopAutoSync();
    }
  }

  /// 清除配置
  Future<void> clearConfig() async {
    _stopFileWatcher();
    _stopAutoSync();
    _syncFolderPath = null;
    _databaseFileName = null;
    _lastSyncTime = null;
    await SecureStorage.clearFileSyncConfig();
  }

  // 私有方法

  Future<String?> _selectAndroidFolder() async {
    try {
      // Android使用Downloads目录作为默认选择
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        final customPath = await _showFolderPickerDialog(downloadsDir.path);
        return customPath;
      }
    } catch (e) {
      print('Android文件夹选择失败: $e');
    }
    return null;
  }

  Future<String?> _selectIOSFolder() async {
    try {
      // iOS使用Documents目录
      final documentsDir = await getApplicationDocumentsDirectory();
      return documentsDir.path;
    } catch (e) {
      print('iOS文件夹选择失败: $e');
    }
    return null;
  }

  Future<String?> _selectDesktopFolder() async {
    try {
      return await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择数据库同步文件夹',
      );
    } catch (e) {
      print('桌面文件夹选择失败: $e');
    }
    return null;
  }

  Future<String?> _showFolderPickerDialog(String basePath) async {
    // 在实际应用中，这里应该显示一个文件夹选择对话框
    // 简化实现，返回默认路径
    return basePath;
  }

  Future<FolderPickerResult> _validateFolderAccess(String folderPath) async {
    try {
      final folder = Directory(folderPath);

      // 检查文件夹是否存在
      if (!await folder.exists()) {
        // 尝试创建文件夹
        await folder.create(recursive: true);
      }

      // 测试写入权限
      final testFile = File('$folderPath/.beautiful_todo_test');
      await testFile.writeAsString('test');
      await testFile.delete();

      return FolderPickerResult.success(folderPath);
    } catch (e) {
      return FolderPickerResult.failure('文件夹访问失败: $e');
    }
  }

  Future<bool> _validateSyncFolder() async {
    if (_syncFolderPath == null) return false;

    try {
      final folder = Directory(_syncFolderPath!);
      return await folder.exists();
    } catch (e) {
      return false;
    }
  }

  Future<bool> _validateDatabaseFile(File file) async {
    try {
      // 简单的SQLite文件头验证
      final bytes = await file.openRead(0, 16).first;

      // SQLite文件头: "SQLite format 3\0"
      final sqliteHeader = [0x53, 0x51, 0x4C, 0x69, 0x74, 0x65, 0x20, 0x66, 0x6F, 0x72, 0x6D, 0x61, 0x74, 0x20, 0x33, 0x00];

      if (bytes.length >= 16) {
        for (int i = 0; i < 16; i++) {
          if (bytes[i] != sqliteHeader[i]) {
            return false;
          }
        }
        return true;
      }
    } catch (e) {
      print('验证数据库文件失败: $e');
    }
    return false;
  }

  bool _isDatabaseFile(String fileName) {
    final extensions = ['.db', '.sqlite', '.sqlite3'];
    return extensions.any((ext) => fileName.toLowerCase().endsWith(ext));
  }

  void _startFileWatcher() {
    if (_syncFolderPath == null) return;

    _stopFileWatcher();

    try {
      final folder = Directory(_syncFolderPath!);
      _watchSubscription = folder.watch().listen((event) {
        if (event.path.endsWith(_databaseFileName ?? '')) {
          _handleDatabaseFileChange(event);
        }
      });
    } catch (e) {
      print('启动文件监控失败: $e');
    }
  }

  void _stopFileWatcher() {
    _watchSubscription?.cancel();
    _watchSubscription = null;
  }

  void _startAutoSync() {
    _stopAutoSync();

    _syncTimer = Timer.periodic(
      const Duration(minutes: 2), // 每2分钟检查一次
      (_) => _performAutoSync(),
    );
  }

  void _stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> _performAutoSync() async {
    if (_isSyncing || _syncFolderPath == null) return;

    try {
      await bidirectionalSync();
    } catch (e) {
      print('自动同步失败: $e');
    }
  }

  void _handleDatabaseFileChange(FileSystemEvent event) {
    if (_isSyncing) return;

    // 延迟执行，避免文件写入过程中的触发
    Future.delayed(const Duration(seconds: 1), () async {
      try {
        if (event.type == FileSystemEvent.modify || event.type == FileSystemEvent.create) {
          await forceSyncFromExternal();
        }
      } catch (e) {
        print('处理文件变更失败: $e');
      }
    });
  }

  String _getSyncFilePath() {
    if (_syncFolderPath == null || _databaseFileName == null) {
      return '';
    }
    return _syncFolderPath!.endsWith(Platform.pathSeparator)
        ? '$_syncFolderPath$_databaseFileName'
        : '$_syncFolderPath${Platform.pathSeparator}$_databaseFileName';
  }

  Future<String> _getAppDatabasePath() async {
    String basePath;
    if (PlatformAdapter.isAndroid) {
      basePath = '/data/data/com.beautiful_todo.app/databases';
    } else if (PlatformAdapter.isIOS) {
      final documentsDir = await getApplicationDocumentsDirectory();
      basePath = documentsDir.path;
    } else {
      final appDir = await getApplicationSupportDirectory();
      basePath = appDir.path;
    }

    return '$basePath${Platform.pathSeparator}todos.db';
  }

  Future<void> _backupAppDatabase(String dbPath) async {
    try {
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final backupPath = '$dbPath.backup.$timestamp';
        await dbFile.copy(backupPath);
      }
    } catch (e) {
      print('备份数据库失败: $e');
    }
  }

  Future<void> _updateLastSyncTime() async {
    _lastSyncTime = DateTime.now();
    await SecureStorage.saveFileSyncTime(_lastSyncTime!.toIso8601String());
  }

  Future<Map<String, dynamic>?> _loadConfig() async {
    return await SecureStorage.getFileSyncConfig();
  }

  Future<void> _saveConfig(Map<String, dynamic> config) async {
    await SecureStorage.saveFileSyncConfig(config);
  }
}

// 数据类

class FolderPickerResult {
  final bool success;
  final String? path;
  final String? error;

  FolderPickerResult._({required this.success, this.path, this.error});

  factory FolderPickerResult.success(String path) =>
      FolderPickerResult._(success: true, path: path);

  factory FolderPickerResult.failure(String error) =>
      FolderPickerResult._(success: false, error: error);
}

class FilePickerResult {
  final bool success;
  final String? path;
  final String? error;

  FilePickerResult._({required this.success, this.path, this.error});

  factory FilePickerResult.success(String path) =>
      FilePickerResult._(success: true, path: path);

  factory FilePickerResult.failure(String error) =>
      FilePickerResult._(success: false, error: error);
}

class SyncOperationResult {
  final bool success;
  final SyncOperation? operation;
  final int? fileSize;
  final String? message;
  final String? error;

  SyncOperationResult._({
    required this.success,
    this.operation,
    this.fileSize,
    this.message,
    this.error,
  });

  factory SyncOperationResult.success({
    required SyncOperation operation,
    int? fileSize,
    String? message,
  }) {
    return SyncOperationResult._(
      success: true,
      operation: operation,
      fileSize: fileSize,
      message: message,
    );
  }

  factory SyncOperationResult.failure(String error) {
    return SyncOperationResult._(success: false, error: error);
  }
}

class SyncFolderStatus {
  final bool isConfigured;
  final bool isAccessible;
  final DateTime? lastSyncTime;
  final bool isSyncing;
  final bool autoSyncEnabled;
  final String? folderPath;
  final String? databaseFileName;

  const SyncFolderStatus({
    required this.isConfigured,
    required this.isAccessible,
    this.lastSyncTime,
    required this.isSyncing,
    required this.autoSyncEnabled,
    this.folderPath,
    this.databaseFileName,
  });
}

class DatabaseFileInfo {
  final String name;
  final String path;
  final int size;
  final DateTime lastModified;
  final bool isValid;

  const DatabaseFileInfo({
    required this.name,
    required this.path,
    required this.size,
    required this.lastModified,
    required this.isValid,
  });
}

enum SyncOperation {
  import,  // 从外部导入到应用
  export,  // 从应用导出到外部
  noAction, // 无需操作
}