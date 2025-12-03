import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../storage/secure_storage.dart';

class DatabaseConfigService {
  static const String _dbPathKey = 'custom_database_path';
  static const String _dbName = 'todos.db';

  /// 检查是否是首次启动
  static Future<bool> get isFirstLaunch async {
    final customPath = await SecureStorage.read(key: _dbPathKey);
    return customPath == null;
  }

  /// 获取数据库路径
  static Future<String> getDatabasePath() async {
    try {
      // 首先检查是否有自定义路径
      final customPath = await SecureStorage.read(key: _dbPathKey);
      if (customPath != null) {
        final fullPath = path.join(customPath, _dbName);
        if (await _validateDatabasePath(fullPath)) {
          return fullPath;
        }
      }

      // 如果没有自定义路径或路径无效，使用默认路径
      final defaultPath = await _getDefaultDatabasePath();
      return defaultPath;
    } catch (e) {
      // 如果所有路径都失败，创建一个临时路径
      return await _createTemporaryDatabasePath();
    }
  }

  /// 让用户选择数据库存储位置
  static Future<String?> selectDatabaseDirectory() async {
    try {
      final String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择数据库存储位置',
        lockParentWindow: true,
      );

      if (selectedDirectory != null) {
        return await saveDatabaseDirectory(selectedDirectory);
      }

      return null;
    } catch (e) {
      throw Exception('选择目录失败: $e');
    }
  }

  /// 直接保存数据库目录路径
  static Future<String> saveDatabaseDirectory(String directoryPath) async {
    try {
      // 验证目录是否可写
      final testFile = File(path.join(directoryPath, '.test'));
      try {
        await testFile.writeAsString('test');
        await testFile.delete();

        // 保存选择的路径
        await SecureStorage.setString(_dbPathKey, directoryPath);
        return directoryPath;
      } catch (e) {
        throw Exception('选择的目录不可写: $e');
      }
    } catch (e) {
      throw Exception('保存目录失败: $e');
    }
  }

  /// 检查指定路径是否有现有数据库
  static Future<bool> hasExistingDatabase(String directoryPath) async {
    try {
      final dbPath = path.join(directoryPath, _dbName);
      final dbFile = File(dbPath);
      return await dbFile.exists();
    } catch (e) {
      return false;
    }
  }

  /// 获取数据库文件大小
  static Future<int?> getDatabaseFileSize(String directoryPath) async {
    try {
      final dbPath = path.join(directoryPath, _dbName);
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        return await dbFile.length();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 获取数据库最后修改时间
  static Future<DateTime?> getDatabaseLastModified(String directoryPath) async {
    try {
      final dbPath = path.join(directoryPath, _dbName);
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        final stat = await dbFile.stat();
        return stat.modified;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 验证数据库路径是否有效
  static Future<bool> _validateDatabasePath(String dbPath) async {
    try {
      final dbFile = File(dbPath);
      final directory = dbFile.parent;

      // 检查目录是否存在
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // 测试写入权限
      final testFile = File(path.join(directory.path, '.test'));
      await testFile.writeAsString('test');
      await testFile.delete();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取默认数据库路径
  static Future<String> _getDefaultDatabasePath() async {
    try {
      // 尝试使用用户文档目录
      if (Platform.isLinux || Platform.isMacOS) {
        final home = Platform.environment['HOME'];
        if (home != null) {
          final appDataDir = Directory(path.join(home, '.local', 'share', 'todo-app'));
          if (!await appDataDir.exists()) {
            await appDataDir.create(recursive: true);
          }
          return path.join(appDataDir.path, _dbName);
        }
      }

      // 如果没有合适的用户目录，使用当前工作目录
      final currentDir = Directory.current;
      return path.join(currentDir.path, _dbName);
    } catch (e) {
      // 如果所有方法都失败，使用临时目录
      return await _createTemporaryDatabasePath();
    }
  }

  /// 创建临时数据库路径
  static Future<String> _createTemporaryDatabasePath() async {
    try {
      final tempDir = Directory.systemTemp;
      final appTempDir = Directory(path.join(tempDir.path, 'todo-app'));
      if (!await appTempDir.exists()) {
        await appTempDir.create(recursive: true);
      }
      return path.join(appTempDir.path, _dbName);
    } catch (e) {
      // 最后的备选方案
      return path.join(Directory.current.path, 'data', _dbName);
    }
  }

  /// 重置数据库配置
  static Future<void> resetDatabaseConfig() async {
    try {
      await SecureStorage.remove(_dbPathKey);
    } catch (e) {
      // 忽略错误
    }
  }
}