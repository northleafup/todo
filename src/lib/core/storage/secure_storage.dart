import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 安全存储服务
class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // 同步相关存储
  static const String _nutstoreConfigKey = 'nutstore_config';
  static const String _crossPlatformSyncConfigKey = 'cross_platform_sync_config';
  static const String _fileSyncConfigKey = 'file_sync_config';
  static const String _fileSyncTimeKey = 'file_sync_time';
  static const String _lastSyncTimeKey = 'last_sync_time';
  static const String _localSyncMetaKey = 'local_sync_meta';
  static const String _deviceIdKey = 'device_id';

  // 设置相关存储
  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language';
  static const String _enableNotificationsKey = 'enable_notifications';
  static const String _enableAutoSyncKey = 'enable_auto_sync';

  // 保存坚果云配置
  static Future<void> saveNutstoreConfig(Map<String, dynamic> config) async {
    final jsonString = config.entries
        .map((e) => '${e.key}:${e.value}')
        .join('|');
    await _storage.write(key: _nutstoreConfigKey, value: jsonString);
  }

  // 获取坚果云配置
  static Future<Map<String, dynamic>?> getNutstoreConfig() async {
    try {
      final data = await _storage.read(key: _nutstoreConfigKey);
      if (data == null) return null;

      final Map<String, dynamic> config = {};
      final pairs = data.split('|');
      for (final pair in pairs) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          config[parts[0]] = parts[1];
        }
      }
      return config;
    } catch (e) {
      return null;
    }
  }

  // 清除坚果云配置
  static Future<void> clearNutstoreConfig() async {
    await _storage.delete(key: _nutstoreConfigKey);
  }

  // 保存跨平台同步配置
  static Future<void> saveCrossPlatformSyncConfig(Map<String, dynamic> config) async {
    final jsonString = config.entries
        .map((e) => '${e.key}:${e.value}')
        .join('|');
    await _storage.write(key: _crossPlatformSyncConfigKey, value: jsonString);
  }

  // 获取跨平台同步配置
  static Future<Map<String, dynamic>?> getCrossPlatformSyncConfig() async {
    try {
      final data = await _storage.read(key: _crossPlatformSyncConfigKey);
      if (data == null) return null;

      final Map<String, dynamic> config = {};
      final pairs = data.split('|');
      for (final pair in pairs) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          config[parts[0]] = parts[1];
        }
      }
      return config;
    } catch (e) {
      return null;
    }
  }

  // 清除跨平台同步配置
  static Future<void> clearCrossPlatformSyncConfig() async {
    await _storage.delete(key: _crossPlatformSyncConfigKey);
  }

  // 保存文件同步配置
  static Future<void> saveFileSyncConfig(Map<String, dynamic> config) async {
    final jsonString = config.entries
        .map((e) => '${e.key}:${e.value}')
        .join('|');
    await _storage.write(key: _fileSyncConfigKey, value: jsonString);
  }

  // 获取文件同步配置
  static Future<Map<String, dynamic>?> getFileSyncConfig() async {
    try {
      final data = await _storage.read(key: _fileSyncConfigKey);
      if (data == null) return null;

      final Map<String, dynamic> config = {};
      final pairs = data.split('|');
      for (final pair in pairs) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          config[parts[0]] = parts[1];
        }
      }
      return config;
    } catch (e) {
      return null;
    }
  }

  // 清除文件同步配置
  static Future<void> clearFileSyncConfig() async {
    await _storage.delete(key: _fileSyncConfigKey);
  }

  // 保存文件同步时间
  static Future<void> saveFileSyncTime(String time) async {
    await _storage.write(key: _fileSyncTimeKey, value: time);
  }

  // 获取文件同步时间
  static Future<String?> getFileSyncTime() async {
    return await _storage.read(key: _fileSyncTimeKey);
  }

  // 保存最后同步时间
  static Future<void> saveLastSyncTime(String time) async {
    await _storage.write(key: _lastSyncTimeKey, value: time);
  }

  // 获取最后同步时间
  static Future<String?> getLastSyncTime() async {
    return await _storage.read(key: _lastSyncTimeKey);
  }

  // 保存本地同步元数据
  static Future<void> saveLocalSyncMeta(String meta) async {
    await _storage.write(key: _localSyncMetaKey, value: meta);
  }

  // 获取本地同步元数据
  static Future<String?> getLocalSyncMeta() async {
    return await _storage.read(key: _localSyncMetaKey);
  }

  // 保存设备ID
  static Future<void> saveDeviceId(String deviceId) async {
    await _storage.write(key: _deviceIdKey, value: deviceId);
  }

  // 获取设备ID
  static Future<String?> getDeviceId() async {
    return await _storage.read(key: _deviceIdKey);
  }

  // 保存主题设置
  static Future<void> saveThemeMode(String themeMode) async {
    await _storage.write(key: _themeKey, value: themeMode);
  }

  // 获取主题设置
  static Future<String?> getThemeMode() async {
    return await _storage.read(key: _themeKey);
  }

  // 保存语言设置
  static Future<void> saveLanguage(String language) async {
    await _storage.write(key: _languageKey, value: language);
  }

  // 获取语言设置
  static Future<String?> getLanguage() async {
    return await _storage.read(key: _languageKey);
  }

  // 保存通知设置
  static Future<void> saveNotificationSettings(bool enabled) async {
    await _storage.write(key: _enableNotificationsKey, value: enabled.toString());
  }

  // 获取通知设置
  static Future<bool> getNotificationSettings() async {
    final data = await _storage.read(key: _enableNotificationsKey);
    return data == 'true';
  }

  // 保存自动同步设置
  static Future<void> saveAutoSyncSettings(bool enabled) async {
    await _storage.write(key: _enableAutoSyncKey, value: enabled.toString());
  }

  // 获取自动同步设置
  static Future<bool> getAutoSyncSettings() async {
    final data = await _storage.read(key: _enableAutoSyncKey);
    return data == 'true';
  }

  // 清除所有设置
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // 添加缺失的方法用于云同步服务
  static Future<String?> getToken(String service) async {
    return await _storage.read(key: '${service}_token');
  }

  static Future<void> saveToken(String service, String token) async {
    await _storage.write(key: '${service}_token', value: token);
  }

  static Future<void> clearToken(String service) async {
    await _storage.delete(key: '${service}_token');
  }

  // 添加通用的读写方法
  static Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  static Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  static Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  static Future<bool?> getBool({required String key}) async {
    final value = await _storage.read(key: key);
    if (value == null) return null;
    return value.toLowerCase() == 'true';
  }

  static Future<void> setBool({required String key, required bool value}) async {
    await _storage.write(key: key, value: value.toString());
  }

  static Future<int?> getInt({required String key}) async {
    final value = await _storage.read(key: key);
    if (value == null) return null;
    return int.tryParse(value);
  }

  static Future<void> setInt({required String key, required int value}) async {
    await _storage.write(key: key, value: value.toString());
  }

  static Future<double?> getDouble({required String key}) async {
    final value = await _storage.read(key: key);
    if (value == null) return null;
    return double.tryParse(value);
  }

  static Future<void> setDouble({required String key, required double value}) async {
    await _storage.write(key: key, value: value.toString());
  }

  static Future<void> saveSyncConfig(String provider, Map<String, dynamic> config) async {
    final jsonString = config.entries
        .map((e) => '${e.key}:${e.value}')
        .join('|');
    await _storage.write(key: '${provider}_config', value: jsonString);
  }

  static Future<void> clearSyncConfig(String provider) async {
    await _storage.delete(key: '${provider}_config');
  }

  static Future<String?> getFirebaseKey() async {
    return await _storage.read(key: 'firebase_api_key');
  }

  static Future<String?> getSupabaseKey() async {
    return await _storage.read(key: 'supabase_api_key');
  }

  static Future<String?> getAppwriteKey() async {
    return await _storage.read(key: 'appwrite_api_key');
  }

  static Future<String?> getCustomApiKey() async {
    return await _storage.read(key: 'custom_api_key');
  }

  // 添加缺失的方法用于任务提醒管理
  static Future<String?> getString(String key) async {
    return await _storage.read(key: key);
  }

  static Future<void> setString(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<void> remove(String key) async {
    await _storage.delete(key: key);
  }
}
