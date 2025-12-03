import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/notification_service.dart';
import '../storage/secure_storage.dart';
import '../../domain/entities/todo.dart';
import '../errors/exceptions.dart';

/// 任务提醒管理器 - 负责管理任务的提醒设置和自动触发
class TaskReminderManager {
  static final TaskReminderManager _instance = TaskReminderManager._internal();
  factory TaskReminderManager() => _instance;
  TaskReminderManager._internal();

  final NotificationService _notificationService = NotificationService();
  final Uuid _uuid = const Uuid();

  Timer? _checkTimer;
  bool _isInitialized = false;

  /// 初始化提醒管理器
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _notificationService.initialize();
      await _restoreReminders();
      _startPeriodicCheck();
      _isInitialized = true;
    } catch (e) {
      throw ReminderException('初始化提醒管理器失败: $e');
    }
  }

  /// 设置任务提醒
  Future<void> setTaskReminder({
    required Todo todo,
    ReminderTime reminderTime = ReminderTime.onTime,
  }) async {
    try {
      // 先取消现有的提醒
      await cancelTaskReminder(todo.id);

      // 如果不需要提醒则返回
      if (reminderTime == ReminderTime.none || todo.dueTime == null) {
        return;
      }

      // 计算提醒时间
      final reminderDateTime = reminderTime.calculateReminderTime(todo.dueTime!);
      if (reminderDateTime == null || reminderDateTime.isBefore(DateTime.now())) {
        // 如果提醒时间已过，发送即时通知
        await _notificationService.showTaskOverdueNotification(
          taskTitle: todo.title,
          dueDate: _formatDateTime(todo.dueTime!),
        );
        return;
      }

      // 设置新的提醒
      await _notificationService.scheduleTaskReminder(
        id: _generateNotificationId(todo.id),
        title: '任务提醒',
        description: '任务 "${todo.title}" 即将到期',
        scheduledTime: reminderDateTime,
        payload: _createPayload(todo.id, reminderTime.name),
      );

      // 保存提醒设置
      await _saveReminderSetting(todo.id, reminderTime.name);
    } catch (e) {
      throw ReminderException('设置任务提醒失败: $e');
    }
  }

  /// 取消任务提醒
  Future<void> cancelTaskReminder(String todoId) async {
    try {
      final notificationId = _generateNotificationId(todoId);
      await _notificationService.cancelTaskReminder(notificationId);
      await _removeReminderSetting(todoId);
    } catch (e) {
      throw ReminderException('取消任务提醒失败: $e');
    }
  }

  /// 批量设置提醒
  Future<void> setBatchReminders({
    required List<Todo> todos,
    ReminderTime defaultReminderTime = ReminderTime.before15m,
  }) async {
    for (final todo in todos) {
      if (todo.dueTime != null && !todo.isCompleted) {
        await setTaskReminder(
          todo: todo,
          reminderTime: defaultReminderTime,
        );
      }
    }
  }

  /// 更新任务提醒
  Future<void> updateTaskReminder({
    required Todo oldTodo,
    required Todo newTodo,
  }) async {
    try {
      // 如果任务已完成，取消提醒
      if (newTodo.isCompleted) {
        await cancelTaskReminder(newTodo.id);
        await _notificationService.showTaskCompletionNotification(
          taskTitle: newTodo.title,
          completionTime: _formatDateTime(DateTime.now()),
        );
        return;
      }

      // 如果截止时间改变，重新设置提醒
      if (oldTodo.dueTime != newTodo.dueTime) {
        final reminderTime = await getReminderTime(newTodo.id);
        await setTaskReminder(
          todo: newTodo,
          reminderTime: reminderTime,
        );
      }
    } catch (e) {
      throw ReminderException('更新任务提醒失败: $e');
    }
  }

  /// 获取任务的提醒设置
  Future<ReminderTime> getReminderTime(String todoId) async {
    try {
      final reminderTimeString = await SecureStorage.getString('reminder_${todoId}');
      if (reminderTimeString == null) {
        return ReminderTime.before15m; // 默认提前15分钟提醒
      }

      return ReminderTime.values.firstWhere(
        (time) => time.name == reminderTimeString,
        orElse: () => ReminderTime.before15m,
      );
    } catch (e) {
      return ReminderTime.before15m;
    }
  }

  /// 检查过期任务并发送通知
  Future<void> checkOverdueTasks(List<Todo> todos) async {
    try {
      final now = DateTime.now();

      for (final todo in todos) {
        if (todo.dueTime != null &&
            !todo.isCompleted &&
            todo.dueTime!.isBefore(now) &&
            !await _wasOverdueNotificationSent(todo.id)) {

          await _notificationService.showTaskOverdueNotification(
            taskTitle: todo.title,
            dueDate: _formatDateTime(todo.dueTime!),
          );

          await _markOverdueNotificationSent(todo.id);
        }
      }
    } catch (e) {
      throw ReminderException('检查过期任务失败: $e');
    }
  }

  /// 设置每日任务总结提醒
  Future<void> setDailySummaryReminder({
    required TimeOfDay time,
  }) async {
    try {
      await _notificationService.scheduleDailySummary(
        time: time,
        id: 999999, // 特殊ID用于每日总结
      );

      await SecureStorage.setString(
        'daily_summary_time',
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      );
    } catch (e) {
      throw ReminderException('设置每日总结提醒失败: $e');
    }
  }

  /// 获取每日总结提醒时间
  Future<TimeOfDay?> getDailySummaryTime() async {
    try {
      final timeString = await SecureStorage.getString('daily_summary_time');
      if (timeString == null) return null;

      final parts = timeString.split(':');
      if (parts.length != 2) return null;

      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);

      if (hour == null || minute == null) return null;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  /// 取消每日总结提醒
  Future<void> cancelDailySummaryReminder() async {
    try {
      await _notificationService.cancelTaskReminder(999999);
      await SecureStorage.remove('daily_summary_time');
    } catch (e) {
      throw ReminderException('取消每日总结提醒失败: $e');
    }
  }

  /// 获取所有待发送的通知
  Future<List<Map<String, dynamic>>> getPendingReminders() async {
    try {
      final pendingNotifications = await _notificationService.getPendingNotifications();

      return pendingNotifications.map((notification) => {
        'id': notification.id,
        'title': notification.title,
        'body': notification.body,
        'payload': notification.payload,
      }).toList();
    } catch (e) {
      throw ReminderException('获取待发送提醒失败: $e');
    }
  }

  /// 清除所有提醒
  Future<void> clearAllReminders() async {
    try {
      await _notificationService.cancelAllReminders();
      await _clearAllReminderSettings();
    } catch (e) {
      throw ReminderException('清除所有提醒失败: $e');
    }
  }

  /// 检查通知权限
  Future<bool> isNotificationPermissionGranted() async {
    return await _notificationService.areNotificationsEnabled();
  }

  /// 请求通知权限
  Future<void> requestNotificationPermission() async {
    try {
      await _notificationService.initialize();
    } catch (e) {
      throw ReminderException('请求通知权限失败: $e');
    }
  }

  /// 处理通知点击事件
  void handleNotificationTap(Function(String payload) onNotificationTapped) {
    _notificationService.notificationStream.listen((response) {
      final payload = response.payload;
      if (payload != null) {
        onNotificationTapped(payload);
      }
    });
  }

  // 私有方法

  /// 生成通知ID
  int _generateNotificationId(String todoId) {
    // 使用todoId的hashCode确保一致性
    return todoId.hashCode.abs() % 100000;
  }

  /// 创建通知负载
  String _createPayload(String todoId, String reminderTime) {
    return '{"todo_id":"$todoId","reminder_time":"$reminderTime"}';
  }

  /// 保存提醒设置
  Future<void> _saveReminderSetting(String todoId, String reminderTime) async {
    await SecureStorage.setString('reminder_${todoId}', reminderTime);
  }

  /// 移除提醒设置
  Future<void> _removeReminderSetting(String todoId) async {
    await SecureStorage.remove('reminder_${todoId}');
  }

  /// 恢复提醒设置
  Future<void> _restoreReminders() async {
    // 这里可以从存储中恢复之前的提醒设置
    // 由于需要具体的任务列表，这个方法在实际使用时需要传入任务列表
  }

  /// 启动定期检查
  void _startPeriodicCheck() {
    // 每30分钟检查一次过期任务
    _checkTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      _performPeriodicCheck();
    });
  }

  /// 执行定期检查
  Future<void> _performPeriodicCheck() async {
    try {
      // 这个方法需要访问当前的任务列表
      // 在实际实现时，需要传入任务列表或通过依赖注入获取
    } catch (e) {
      print('定期检查失败: $e');
    }
  }

  /// 检查过期通知是否已发送
  Future<bool> _wasOverdueNotificationSent(String todoId) async {
    final key = 'overdue_notified_${todoId}';
    return await SecureStorage.getBool(key: key) ?? false;
  }

  /// 标记过期通知已发送
  Future<void> _markOverdueNotificationSent(String todoId) async {
    final key = 'overdue_notified_${todoId}';
    await SecureStorage.setBool(key: key, value: true);
  }

  /// 清除过期通知标记（任务重新激活时调用）
  Future<void> _clearOverdueNotificationMark(String todoId) async {
    final key = 'overdue_notified_${todoId}';
    await SecureStorage.remove(key);
  }

  /// 清除所有提醒设置
  Future<void> _clearAllReminderSettings() async {
    // 这里需要清除所有提醒相关的设置
    // 实际实现时需要遍历所有任务并清除其提醒设置
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 清理资源
  void dispose() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }
}

/// SecureStorage扩展方法
extension SecureStorageExtension on SecureStorage {
  static Future<String?> getString(String key) async {
    return await SecureStorage.read(key: key);
  }

  static Future<void> setString(String key, String value) async {
    await SecureStorage.write(key: key, value: value);
  }

  static Future<bool?> getBool(String key) async {
    final value = await SecureStorage.read(key: key);
    return value == 'true';
  }

  static Future<void> setBool(String key, bool value) async {
    await SecureStorage.write(key: key, value: value.toString());
  }

  static Future<void> remove(String key) async {
    await SecureStorage.delete(key: key);
  }
}