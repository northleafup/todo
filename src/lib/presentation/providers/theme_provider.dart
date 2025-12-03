import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/themes/app_theme.dart';
import '../../core/constants/app_constants.dart';
import 'context_provider.dart';

// 主题模式枚举
enum AppThemeMode { light, dark, system }

// 主题提供者状态
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  // 加载保存的主题模式
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString('theme_mode');

      if (savedTheme != null) {
        switch (savedTheme) {
          case AppConstants.lightThemeKey:
            state = ThemeMode.light;
            break;
          case AppConstants.darkThemeKey:
            state = ThemeMode.dark;
            break;
          case AppConstants.systemThemeKey:
          default:
            state = ThemeMode.system;
            break;
        }
      }
    } catch (e) {
      // 如果加载失败，使用系统主题
      state = ThemeMode.system;
    }
  }

  // 切换主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeString;

      switch (mode) {
        case ThemeMode.light:
          themeString = AppConstants.lightThemeKey;
          break;
        case ThemeMode.dark:
          themeString = AppConstants.darkThemeKey;
          break;
        case ThemeMode.system:
        default:
          themeString = AppConstants.systemThemeKey;
          break;
      }

      await prefs.setString('theme_mode', themeString);
    } catch (e) {
      // 如果保存失败，继续使用新模式
    }
  }

  // 切换到亮色主题
  Future<void> setLightMode() async {
    await setThemeMode(ThemeMode.light);
  }

  // 切换到暗色主题
  Future<void> setDarkMode() async {
    await setThemeMode(ThemeMode.dark);
  }

  // 切换到系统主题
  Future<void> setSystemMode() async {
    await setThemeMode(ThemeMode.system);
  }

  // 获取当前主题模式的显示名称
  String get currentThemeDisplayName {
    switch (state) {
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  // 检查是否是当前主题模式
  bool isCurrentMode(ThemeMode mode) {
    return state == mode;
  }
}

// 主题提供者
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

// 当前主题数据提供者
final currentThemeProvider = Provider<ThemeData>((ref) {
  final themeMode = ref.watch(themeProvider);
  final context = ref.watch(contextProvider);

  switch (themeMode) {
    case ThemeMode.light:
      return AppTheme.lightTheme;
    case ThemeMode.dark:
      return AppTheme.darkTheme;
    case ThemeMode.system:
    default:
      final brightness = MediaQuery.of(context).platformBrightness;
      return brightness == Brightness.dark
          ? AppTheme.darkTheme
          : AppTheme.lightTheme;
  }
});

