import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';

/// 跨平台适配工具类
class PlatformAdapter {
  // 平台类型枚举
  static const _PlatformType _unknown = _PlatformType.unknown;
  static const _PlatformType _android = _PlatformType.android;
  static const _PlatformType _ios = _PlatformType.ios;
  static const _PlatformType _macOS = _PlatformType.macOS;
  static const _PlatformType _windows = _PlatformType.windows;
  static const _PlatformType _linux = _PlatformType.linux;

  static _PlatformType get _platform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _PlatformType.android;
      case TargetPlatform.iOS:
        return _PlatformType.ios;
      case TargetPlatform.macOS:
        return _PlatformType.macOS;
      case TargetPlatform.windows:
        return _PlatformType.windows;
      case TargetPlatform.linux:
        return _PlatformType.linux;
      default:
        return _PlatformType.unknown;
    }
  }

  /// 检查是否为Android平台
  static bool get isAndroid => _platform == _PlatformType.android;

  /// 检查是否为iOS平台
  static bool get isIOS => _platform == _PlatformType.ios;

  /// 检查是否为macOS平台
  static bool get isMacOS => _platform == _PlatformType.macOS;

  /// 检查是否为Windows平台
  static bool get isWindows => _platform == _PlatformType.windows;

  /// 检查是否为Linux平台
  static bool get isLinux => _platform == _PlatformType.linux;

  /// 检查是否为Web平台
  static bool get isWeb => _platform == _PlatformType.web;

  /// 检查是否为移动平台
  static bool get isMobile => isAndroid || isIOS;

  /// 检查是否为桌面平台
  static bool get isDesktop => isMacOS || isWindows || isLinux;

  /// 获取平台特定的配置
  static PlatformConfig get config => PlatformConfig(_platform);

  /// 检查是否支持文件下载
  static bool get supportsFileDownload => isWeb || isDesktop;

  /// 检查是否支持通知
  static bool get supportsNotifications => !isWeb;

  /// 检查是否支持生物识别
  static bool get supportsBiometric => isMobile;

  /// 检查是否支持相机
  static bool get supportsCamera => isMobile;

  /// 检查是否需要全面屏适配
  static bool get needsEdgeToEdge => isMobile || (isMacOS && _isMacOSSequivalentOrNewer(13, 0));

  /// 检查是否需要RTL支持
  static bool get needsRTL => true; // 中文环境通常需要

  /// 检查是否需要高性能模式
  static bool get needsHighPerformance => isMobile || _isLowEndDevice();

  /// 获取默认字体大小
  static double get defaultFontSize {
    if (isMobile) return 14.0;
    if (isDesktop) return 16.0;
    return 15.0;
  }

  /// 获取默认间距
  static double get defaultSpacing {
    if (isMobile) return 16.0;
    if (isDesktop) return 24.0;
    return 20.0;
  }

  /// 获取导航栏高度
  static double get navBarHeight {
    if (isAndroid) {
      return 56.0; // 标准Android导航栏
    } else if (isIOS) {
      return 44.0; // iOS安全区域
    } else {
      return 0.0; // 其他平台无固定导航栏
    }
  }

  /// 获取状态栏高度
  static double get statusBarHeight {
    if (isAndroid) {
      return 24.0; // 标准Android状态栏
    } else if (isIOS) {
      return 44.0; // iOS刘海屏区域
    } else {
      return 0.0; // 其他平台通过MediaQuery获取
    }
  }

  /// 获取底部安全区域高度
  static double get bottomSafeHeight {
    if (isIOS) {
      return 34.0; // iOS Home Indicator
    } else {
      return 0.0;
    }
  }

  /// 获取应用内边距
  static EdgeInsets get safePadding {
    return EdgeInsets.only(
      top: statusBarHeight,
      bottom: bottomSafeHeight,
    );
  }

  /// 获取平台特定的小工具栏高度
  static double get toolbarHeight {
    if (isMobile) {
      return 56.0;
    } else {
      return 64.0;
    }
  }

  /// 获取卡片默认圆角
  static double get cardBorderRadius {
    if (isMobile) {
      return 12.0;
    } else {
      return 16.0;
    }
  }

  /// 获取按钮默认高度
  static double get buttonHeight {
    if (isMobile) {
      return 40.0;
    } else {
      return 48.0;
    }
  }

  /// 获取最大内容宽度
  static double get maxContentWidth {
    if (isMobile) {
      return 768.0; // 平板宽度
    } else {
      return 1200.0; // 桌面宽度
    }
  }

  /// 获取网格布局列数
  static int get gridColumns {
    if (isMobile) {
      return 2;
    } else {
      return 3;
    }
  }

  /// 检查是否启用动画
  static bool get enableAnimations {
    // 在低端设备上禁用动画以提高性能
    return !_isLowEndDevice();
  }

  /// 获取动画持续时间
  static Duration get animationDuration {
    if (enableAnimations) {
      return const Duration(milliseconds: 300);
    } else {
      return const Duration(milliseconds: 0);
    }
  }

  /// 检查是否为小米澎湃OS
  static bool get isHyperOS {
    return isAndroid && _deviceModel.contains('澎湃OS');
  }

  /// 检查是否为小米设备
  static bool get isXiaomi {
    return isAndroid && _deviceModel.contains('Mi');
  }

  /// 检查是否为小米14
  static bool get isXiaomi14 {
    return isAndroid && _deviceModel.contains('23013') ||
           _deviceModel.contains('2206122C');
  }

  /// 检查是否为Intel芯片Mac
  static bool get isIntelMac => isMacOS && _deviceInfo.contains('Intel');

  /// 检查是否为Apple Silicon Mac
  static bool get isAppleSiliconMac => isMacOS && (_deviceInfo.contains('Apple M1') ||
         _deviceInfo.contains('Apple M2') ||
         _deviceInfo.contains('Apple M3'));

  /// 获取平台特定的权限配置
  static Map<String, bool> get requiredPermissions {
    final Map<String, bool> permissions = {};

    if (isAndroid) {
      permissions['storage'] = false; // 使用Scoped Storage
      permissions['camera'] = false;
      permissions['notifications'] = true;
      permissions['location'] = false;
      permissions['contacts'] = false;
    } else if (isIOS) {
      permissions['notifications'] = true;
      permissions['camera'] = false;
      permissions['location'] = false;
      permissions['contacts'] = false;
      permissions['photos'] = false;
    }

    return permissions;
  }

  // 私有辅助方法
  static bool _isMacOSSequivalentOrNewer(int major, int minor) {
    // 这里可以实现macOS版本检测
    // 由于dart:io的限制，我们使用一个简化的实现
    return true; // 假设支持macOS 13.6+
  }

  static bool _isLowEndDevice() {
    // 简化的低端设备检测
    return kIsWeb; // Web环境下通常需要性能优化
  }

  static String get _deviceModel {
    // 在实际应用中，可以通过device_info_plus等插件获取
    return ''; // 简化实现
  }

  static String get _deviceInfo {
    // 在实际应用中，可以通过device_info_plus等插件获取
    return ''; // 简化实现
  }
}

enum _PlatformType {
  unknown,
  web,
  android,
  ios,
  macOS,
  windows,
  linux,
}

/// 平台配置类
class PlatformConfig {
  final _PlatformType platform;

  const PlatformConfig(this.platform);

  /// 平台名称
  String get name {
    switch (platform) {
      case _PlatformType.web:
        return 'Web';
      case _PlatformType.android:
        return 'Android';
      case _PlatformType.ios:
        return 'iOS';
      case _PlatformType.macOS:
        return 'macOS';
      case _PlatformType.windows:
        return 'Windows';
      case _PlatformType.linux:
        return 'Linux';
      case _PlatformType.unknown:
        return 'Unknown';
    }
  }

  /// 是否支持手势导航
  bool get supportsGestureNavigation {
    return platform == _PlatformType.android || platform == _PlatformType.ios;
  }

  /// 是否支持桌面通知
  bool get supportsDesktopNotifications {
    return platform == _PlatformType.windows || platform == _PlatformType.linux || platform == _PlatformType.macOS;
  }

  /// 是否支持PWA
  bool get supportsPWA => platform == _PlatformType.web;

  /// 是否需要权限请求
  bool get needsPermissionRequest {
    return platform == _PlatformType.android || platform == _PlatformType.ios;
  }

  /// 文件下载方式
  String get fileDownloadMethod {
    if (platform == _PlatformType.web) {
      return 'web_download';
    } else if (platform == _PlatformType.android) {
      return 'downloads';
    } else {
      return 'file_picker';
    }
  }

  /// 通知方式
  String get notificationMethod {
    if (platform == _PlatformType.web) {
      return 'web_notification';
    } else if (platform == _PlatformType.android) {
      return 'android_notification';
    } else if (platform == _PlatformType.ios) {
      return 'ios_notification';
    } else {
      return 'desktop_notification';
    }
  }

  /// 主题适配方式
  String get themeAdaptation {
    if (platform == _PlatformType.android) {
      return 'material3_dynamic_color';
    } else {
      return 'material3_static';
    }
  }
}