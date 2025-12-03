import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'platform_adapter.dart';

/// 增强的平台服务，处理平台特定功能
class PlatformService {
  static const String _appVersion = '1.0.0';
  static const String _appBuildNumber = '1';

  /// 获取完整的平台信息
  static PlatformInfo get platformInfo => _PlatformInfo();

  /// 检查是否支持特定的系统功能
  static bool supportsFeature(SystemFeature feature) {
    switch (feature) {
      case SystemFeature.notifications:
        if (kIsWeb) return _hasWebNotificationSupport();
        if (PlatformAdapter.isAndroid) return true;
        if (PlatformAdapter.isIOS) return true;
        if (PlatformAdapter.isMacOS) return true;
        if (PlatformAdapter.isLinux) return _hasLinuxNotificationSupport();
        return false;

      case SystemFeature.fileSystem:
        if (kIsWeb) return false;
        return true;

      case SystemFeature.camera:
        return PlatformAdapter.isMobile;

      case SystemFeature.biometric:
        return PlatformAdapter.isMobile;

      case SystemFeature.location:
        return PlatformAdapter.isMobile;

      case SystemFeature.desktopNotifications:
        return PlatformAdapter.isDesktop;

      case SystemFeature.systemTray:
        return PlatformAdapter.isDesktop;

      case SystemFeature.autoStart:
        if (PlatformAdapter.isWindows) return true;
        if (PlatformAdapter.isLinux) return true;
        return false;

      case SystemFeature.deepLink:
        return true;

      case SystemFeature.share:
        return true;

      case SystemFeature.print:
        return PlatformAdapter.isDesktop;

      case SystemFeature.keyboardShortcuts:
        return PlatformAdapter.isDesktop;
    }
  }

  /// 获取平台特定的文件路径
  static String getPlatformPath(String fileName) {
    if (PlatformAdapter.isWeb) {
      return fileName; // Web使用相对路径
    }

    late String basePath;
    if (PlatformAdapter.isAndroid) {
      basePath = '/data/data/com.beautiful_todo.app/files';
    } else if (PlatformAdapter.isIOS) {
      basePath = Platform.environment['HOME'] ?? '';
    } else if (PlatformAdapter.isMacOS) {
      basePath = '${Platform.environment['HOME'] ?? ''}/Library/Application Support';
    } else if (PlatformAdapter.isWindows) {
      basePath = Platform.environment['APPDATA'] ?? '';
    } else if (PlatformAdapter.isLinux) {
      basePath = '${Platform.environment['HOME'] ?? ''}/.local/share';
    } else {
      basePath = '';
    }

    return '$basePath/beautiful_todo/$fileName';
  }

  /// 获取平台特定的字体配置
  static FontConfiguration get fontConfiguration => _FontConfiguration();

  /// 检查系统主题偏好
  static Future<bool> isSystemDarkMode() async {
    if (PlatformAdapter.isMacOS || PlatformAdapter.isWindows) {
      // 桌面平台需要通过平台特定API检查
      return false; // 简化实现
    } else if (PlatformAdapter.isLinux) {
      // 通过GTK主题检查
      return false; // 简化实现
    } else {
      // 移动和Web平台通过MediaQuery检查
      return false; // 需要context，这里返回默认值
    }
  }

  /// 获取系统通知设置
  static NotificationSettings get notificationSettings => _NotificationSettings();

  /// 获取性能优化设置
  static PerformanceSettings get performanceSettings => _PerformanceSettings();

  /// 获取网络代理设置
  static ProxySettings get proxySettings => _ProxySettings();

  // 私有辅助方法
  static bool _hasWebNotificationSupport() {
    // 检查浏览器是否支持通知API
    try {
      return true; // 简化实现
    } catch (e) {
      return false;
    }
  }

  static bool _hasLinuxNotificationSupport() {
    try {
      return Process.runSync('which', ['notify-send']).exitCode == 0;
    } catch (e) {
      return false;
    }
  }
}

/// 系统功能枚举
enum SystemFeature {
  notifications,
  fileSystem,
  camera,
  biometric,
  location,
  desktopNotifications,
  systemTray,
  autoStart,
  deepLink,
  share,
  print,
  keyboardShortcuts,
}

/// 平台信息类
class _PlatformInfo implements PlatformInfo {
  @override
  String get name => PlatformAdapter.config.name;

  @override
  String get version => _getSystemVersion();

  @override
  String get appVersion => PlatformService._appVersion;

  @override
  String get buildNumber => PlatformService._appBuildNumber;

  @override
  String get deviceInfo => _getDeviceInfo();

  @override
  String get architecture => _getArchitecture();

  @override
  String get locale => _getLocale();

  @override
  bool get isTablet => PlatformAdapter.isMobile && _isTabletSize();

  @override
  bool get isDesktop => PlatformAdapter.isDesktop;

  @override
  bool get supportsMultitasking => _supportsMultitasking();

  String _getSystemVersion() {
    if (PlatformAdapter.isAndroid) {
      return 'Android 13+ (澎湃OS 3)';
    } else if (PlatformAdapter.isIOS) {
      return 'iOS 15.0+';
    } else if (PlatformAdapter.isMacOS) {
      return 'macOS 13.6+';
    } else if (PlatformAdapter.isWindows) {
      return 'Windows 10+';
    } else if (PlatformAdapter.isLinux) {
      return 'Ubuntu 22.04+';
    } else {
      return 'Unknown';
    }
  }

  String _getDeviceInfo() {
    if (PlatformAdapter.isHyperOS) {
      return 'Xiaomi HyperOS 3 Device';
    } else if (PlatformAdapter.isXiaomi14) {
      return 'Xiaomi 14';
    } else if (PlatformAdapter.isAppleSiliconMac) {
      return 'Apple Silicon Mac';
    } else if (PlatformAdapter.isIntelMac()) {
      return 'Intel Mac';
    } else if (PlatformAdapter.isLinux) {
      return 'Ubuntu Desktop';
    } else {
      return '${PlatformAdapter.config.name} Device';
    }
  }

  String _getArchitecture() {
    if (Platform.isLinux) {
      return Platform.environment['HOSTTYPE'] ?? 'unknown';
    } else if (Platform.isMacOS) {
      return Platform.environment['PROCESSOR_ARCHITECTURE'] ?? 'unknown';
    } else if (Platform.isWindows) {
      return Platform.environment['PROCESSOR_ARCHITECTURE'] ?? 'unknown';
    } else {
      return 'unknown';
    }
  }

  String _getLocale() {
    return Platform.localeName ?? 'en_US';
  }

  bool _isTabletSize() {
    // 简化的平板检测，实际应用中需要使用MediaQuery
    return false;
  }

  bool _supportsMultitasking() {
    if (PlatformAdapter.isDesktop) return true;
    if (PlatformAdapter.isIOS) return true;
    if (PlatformAdapter.isAndroid) return true;
    return false;
  }
}

/// 字体配置类
class _FontConfiguration implements FontConfiguration {
  @override
  String get primaryFont {
    if (PlatformAdapter.isAndroid) {
      return 'Roboto'; // Android默认字体
    } else if (PlatformAdapter.isIOS) {
      return 'San Francisco'; // iOS默认字体
    } else if (PlatformAdapter.isMacOS) {
      return 'SF Pro Display'; // macOS默认字体
    } else if (PlatformAdapter.isLinux) {
      return 'Ubuntu'; // Ubuntu默认字体
    } else {
      return 'System'; // Web默认字体
    }
  }

  @override
  String get chineseFont {
    if (PlatformAdapter.isAndroid) {
      return 'Noto Sans CJK SC';
    } else if (PlatformAdapter.isIOS || PlatformAdapter.isMacOS) {
      return 'PingFang SC';
    } else if (PlatformAdapter.isLinux) {
      return 'Noto Sans CJK SC';
    } else {
      return 'Source Han Sans SC';
    }
  }

  @override
  double get defaultSize => PlatformAdapter.defaultFontSize;

  @override
  FontWeight get defaultWeight => FontWeight.w400;

  @override
  List<String> get fontFamilies => [primaryFont, chineseFont, 'System'];
}

/// 通知设置类
class _NotificationSettings implements NotificationSettings {
  @override
  bool get enabled => PlatformService.supportsFeature(SystemFeature.notifications);

  @override
  bool get sound => PlatformAdapter.isMobile;

  @override
  bool get badge => PlatformAdapter.isIOS || PlatformAdapter.isMacOS;

  @override
  bool get vibration => PlatformAdapter.isAndroid;

  @override
  bool get led => PlatformAdapter.isAndroid;

  @override
  Duration get defaultDuration => const Duration(seconds: 5);

  @override
  String get channel => 'todo_reminders';
}

/// 性能设置类
class _PerformanceSettings implements PerformanceSettings {
  @override
  bool get enableAnimations => PlatformAdapter.enableAnimations;

  @override
  Duration get animationDuration => PlatformAdapter.animationDuration;

  @override
  bool get enableHardwareAcceleration => !PlatformAdapter.isWeb;

  @override
  int get maxCacheSize => PlatformAdapter.isMobile ? 50 : 200;

  @override
  bool get enableLazyLoading => PlatformAdapter.isMobile;

  @override
  bool get enableMemoryOptimization => PlatformAdapter.isMobile;
}

/// 代理设置类
class _ProxySettings implements ProxySettings {
  @override
  bool get enabled => false;

  @override
  String? get host => null;

  @override
  int? get port => null;

  @override
  bool get authRequired => false;

  @override
  String? get username => null;

  @override
  String? get password => null;
}

/// 平台信息接口
abstract interface class PlatformInfo {
  String get name;
  String get version;
  String get appVersion;
  String get buildNumber;
  String get deviceInfo;
  String get architecture;
  String get locale;
  bool get isTablet;
  bool get isDesktop;
  bool get supportsMultitasking;
}

/// 字体配置接口
abstract interface class FontConfiguration {
  String get primaryFont;
  String get chineseFont;
  double get defaultSize;
  FontWeight get defaultWeight;
  List<String> get fontFamilies;
}

/// 通知设置接口
abstract interface class NotificationSettings {
  bool get enabled;
  bool get sound;
  bool get badge;
  bool get vibration;
  bool get led;
  Duration get defaultDuration;
  String get channel;
}

/// 性能设置接口
abstract interface class PerformanceSettings {
  bool get enableAnimations;
  Duration get animationDuration;
  bool get enableHardwareAcceleration;
  int get maxCacheSize;
  bool get enableLazyLoading;
  bool get enableMemoryOptimization;
}

/// 代理设置接口
abstract interface class ProxySettings {
  bool get enabled;
  String? get host;
  int? get port;
  bool get authRequired;
  String? get username;
  String? get password;
}