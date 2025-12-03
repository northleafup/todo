import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../errors/exceptions.dart';
import '../constants/app_constants.dart';

/// 通知服务 - 负责处理应用内通知和系统通知
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  StreamController<NotificationResponse>? _notificationController;

  /// 初始化通知服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 初始化时区数据
      tz_data.initializeTimeZones();

      // Android初始化设置
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS初始化设置
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // 初始化插件
      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // 请求权限
      await _requestPermissions();

      // 创建通知流控制器
      _notificationController = StreamController<NotificationResponse>.broadcast();

      _isInitialized = true;
    } catch (e) {
      throw NotificationException('初始化通知服务失败: $e');
    }
  }

  /// 请求通知权限
  Future<bool> _requestPermissions() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final bool? grantedNotificationPermission =
          await androidImplementation?.requestNotificationsPermission();

      return grantedNotificationPermission ?? true;
    } catch (e) {
      return false;
    }
  }

  /// 处理通知点击事件
  void _onNotificationTapped(NotificationResponse response) {
    _notificationController?.add(response);
  }

  /// 获取通知点击流
  Stream<NotificationResponse> get notificationStream {
    return _notificationController?.stream ??
           StreamController<NotificationResponse>.broadcast().stream;
  }

  /// 设置任务提醒
  Future<void> scheduleTaskReminder({
    required int id,
    required String title,
    required String description,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);

      await _notifications.zonedSchedule(
        id,
        title,
        description,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            '任务提醒',
            channelDescription: '任务到期提醒通知',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            styleInformation: BigTextStyleInformation(''),
            enableVibration: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      throw NotificationException('设置任务提醒失败: $e');
    }
  }

  /// 取消任务提醒
  Future<void> cancelTaskReminder(int id) async {
    try {
      await _notifications.cancel(id);
    } catch (e) {
      throw NotificationException('取消任务提醒失败: $e');
    }
  }

  /// 取消所有提醒
  Future<void> cancelAllReminders() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      throw NotificationException('取消所有提醒失败: $e');
    }
  }

  /// 获取待发送的通知列表
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      throw NotificationException('获取待发送通知失败: $e');
    }
  }

  /// 显示即时通知
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _notifications.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'instant_notifications',
            '即时通知',
            channelDescription: '应用即时通知',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      throw NotificationException('显示即时通知失败: $e');
    }
  }

  /// 显示任务完成通知
  Future<void> showTaskCompletionNotification({
    required String taskTitle,
    required String completionTime,
  }) async {
    await showInstantNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: '任务已完成！',
      body: '$taskTitle\n完成时间: $completionTime',
      payload: 'task_completed',
    );
  }

  /// 显示任务过期通知
  Future<void> showTaskOverdueNotification({
    required String taskTitle,
    required String dueDate,
  }) async {
    await showInstantNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: '任务已过期',
      body: '$taskTitle\n到期时间: $dueDate',
      payload: 'task_overdue',
    );
  }

  /// 设置每日任务总结提醒
  Future<void> scheduleDailySummary({
    required TimeOfDay time,
    required int id,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      // 如果今天的时间已过，则安排到明天
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notifications.zonedSchedule(
        id,
        '每日任务总结',
        '点击查看今日任务完成情况',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_summary',
            '每日总结',
            channelDescription: '每日任务总结提醒',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'daily_summary',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      throw NotificationException('设置每日总结提醒失败: $e');
    }
  }

  /// 检查权限状态
  Future<bool> areNotificationsEnabled() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      return await androidImplementation?.areNotificationsEnabled() ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 打开应用通知设置
  Future<void> openNotificationSettings() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.createNotificationChannelGroup(
        AndroidNotificationChannelGroup(
          'task_notifications',
          '任务通知',
        ),
      );
    } catch (e) {
      throw NotificationException('打开通知设置失败: $e');
    }
  }

  /// 更新现有通知
  Future<void> updateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await cancelTaskReminder(id);
    await showInstantNotification(id: id, title: title, body: body, payload: payload);
  }

  /// 清理资源
  void dispose() {
    _notificationController?.close();
    _notificationController = null;
  }
}

/// 时间段枚举
enum ReminderTime {
  none,      // 不提醒
  onTime,    // 准时提醒
  before5m,  // 提前5分钟
  before15m, // 提前15分钟
  before30m, // 提前30分钟
  before1h,  // 提前1小时
  before1d,  // 提前1天
}

/// 提醒时间扩展方法
extension ReminderTimeExtension on ReminderTime {
  /// 获取提醒时间描述
  String get description {
    switch (this) {
      case ReminderTime.none:
        return '不提醒';
      case ReminderTime.onTime:
        return '准时提醒';
      case ReminderTime.before5m:
        return '提前5分钟';
      case ReminderTime.before15m:
        return '提前15分钟';
      case ReminderTime.before30m:
        return '提前30分钟';
      case ReminderTime.before1h:
        return '提前1小时';
      case ReminderTime.before1d:
        return '提前1天';
    }
  }

  /// 计算提醒时间
  DateTime? calculateReminderTime(DateTime dueTime) {
    switch (this) {
      case ReminderTime.none:
        return null;
      case ReminderTime.onTime:
        return dueTime;
      case ReminderTime.before5m:
        return dueTime.subtract(const Duration(minutes: 5));
      case ReminderTime.before15m:
        return dueTime.subtract(const Duration(minutes: 15));
      case ReminderTime.before30m:
        return dueTime.subtract(const Duration(minutes: 30));
      case ReminderTime.before1h:
        return dueTime.subtract(const Duration(hours: 1));
      case ReminderTime.before1d:
        return dueTime.subtract(const Duration(days: 1));
    }
  }

  /// 获取提醒时间的小时数
  int get hours {
    switch (this) {
      case ReminderTime.none:
      case ReminderTime.onTime:
        return 0;
      case ReminderTime.before5m:
        return 0;
      case ReminderTime.before15m:
        return 0;
      case ReminderTime.before30m:
        return 0;
      case ReminderTime.before1h:
        return 1;
      case ReminderTime.before1d:
        return 24;
    }
  }
}

/// 时间OfDay的扩展，用于每日总结提醒
extension TimeOfDayExtension on TimeOfDay {
  /// 转换为分钟数
  int get totalMinutes => hour * 60 + minute;

  /// 从分钟数创建TimeOfDay
  static TimeOfDay fromMinutes(int minutes) {
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }
}