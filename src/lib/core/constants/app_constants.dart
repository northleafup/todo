/// 应用常量定义
class AppConstants {
  // 应用信息
  static const String appName = 'Beautiful Todo';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // 数据库名称
  static const String databaseName = 'todos.db';
  static const String databaseVersion = '1';

  // 表名
  static const String todosTable = 'todos';
  static const String categoriesTable = 'categories';

  // 默认值
  static const int defaultPageSize = 20;
  static const int maxRetryAttempts = 3;
  static const Duration defaultTimeout = Duration(seconds: 30);

  // 主题相关
  static const String lightThemeKey = 'light';
  static const String darkThemeKey = 'dark';
  static const String systemThemeKey = 'system';

  // 同步相关
  static const Duration syncInterval = Duration(minutes: 5);
  static const Duration heartbeatInterval = Duration(seconds: 10);
  static const Duration lockTimeout = Duration(seconds: 60);

  // 文件扩展名
  static const List<String> databaseExtensions = ['.db', '.sqlite', '.sqlite3'];
  
  // 支持的导出格式
  static const List<String> supportedExportFormats = ['json', 'csv', 'markdown'];

  // UI相关
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 250);

  // 分类默认值
  static const List<String> defaultCategoryIcons = [
    'work',
    'personal',
    'shopping',
    'health',
    'education',
    'finance',
    'travel',
    'home',
  ];

  static const List<String> defaultCategoryColors = [
    '#FF6B6B', // 红色
    '#4ECDC4', // 青色
    '#45B7D1', // 蓝色
    '#96CEB4', // 绿色
    '#FFEAA7', // 黄色
    '#DDA0DD', // 紫色
    '#F4A460', // 棕色
    '#808080', // 灰色
  ];
}

class ApiConstants {
  // API端点
  static const String baseUrl = 'https://api.beautiful-todo.com/v1';
  
  // 超时设置
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // 重试设置
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);
}

class StorageConstants {
  // SharedPreferences键
  static const String firstLaunchKey = 'first_launch';
  static const String onboardingCompletedKey = 'onboarding_completed';
  static const String lastUsedVersionKey = 'last_used_version';
  
  // 安全存储键前缀
  static const String syncPrefix = 'sync_';
  static const String settingsPrefix = 'settings_';
  static const String cachePrefix = 'cache_';
}

class NotificationConstants {
  // 渠道ID
  static const String defaultChannelId = 'todo_reminders';
  static const String defaultChannelName = 'Todo提醒';
  static const String defaultChannelDescription = 'Todo任务的提醒通知';
  
  // 通知ID范围
  static const int minNotificationId = 1000;
  static const int maxNotificationId = 9999;
  
  // 提醒时间
  static const List<int> reminderMinutes = [
    0,      // 即时
    5,      // 5分钟后
    15,     // 15分钟后
    30,     // 30分钟后
    60,     // 1小时后
    120,    // 2小时后
    1440,   // 1天后
    2880,   // 2天后
    10080,  // 1周后
  ];
}

class UIConstants {
  // 间距
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  
  // 圆角
  static const double radiusSM = 4.0;
  static const double radiusMD = 8.0;
  static const double radiusLG = 12.0;
  static const double radiusXL = 16.0;
  
  // 字体大小
  static const double fontSizeXS = 12.0;
  static const double fontSizeSM = 14.0;
  static const double fontSizeMD = 16.0;
  static const double fontSizeLG = 18.0;
  static const double fontSizeXL = 20.0;
  static const double fontSizeXXL = 24.0;
  
  // 图标大小
  static const double iconSizeSM = 16.0;
  static const double iconSizeMD = 24.0;
  static const double iconSizeLG = 32.0;
  
  // 按钮高度
  static const double buttonHeightSM = 32.0;
  static const double buttonHeightMD = 40.0;
  static const double buttonHeightLG = 48.0;
}
