import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/notification_service.dart';
import '../../core/themes/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../widgets/custom_button.dart';

/// 提醒设置组件 - 用于配置任务提醒时间
class ReminderSettingsWidget extends StatefulWidget {
  final ReminderTime currentReminderTime;
  final DateTime? dueTime;
  final ValueChanged<ReminderTime> onReminderTimeChanged;
  final bool enabled;

  const ReminderSettingsWidget({
    Key? key,
    required this.currentReminderTime,
    this.dueTime,
    required this.onReminderTimeChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<ReminderSettingsWidget> createState() => _ReminderSettingsWidgetState();
}

class _ReminderSettingsWidgetState extends State<ReminderSettingsWidget> {
  ReminderTime _selectedReminderTime = ReminderTime.before15m;

  @override
  void initState() {
    super.initState();
    _selectedReminderTime = widget.currentReminderTime;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  color: widget.enabled
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.4),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '任务提醒',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: widget.enabled
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 提醒时间选项
            ...ReminderTime.values.map((time) {
              final isSelected = _selectedReminderTime == time;
              final isEnabled = widget.enabled && time != ReminderTime.none && widget.dueTime != null;

              return _buildReminderOption(
                context: context,
                reminderTime: time,
                isSelected: isSelected,
                isEnabled: isEnabled,
                timeDisplay: _getTimeDisplay(time),
              );
            }).toList(),

            const SizedBox(height: 12),

            // 预览提醒时间
            if (_selectedReminderTime != ReminderTime.none && widget.dueTime != null)
              _buildReminderPreview(context),
          ],
        ),
      ),
    ).animate().fadeIn(duration: AppConstants.shortAnimationDuration);
  }

  Widget _buildReminderOption({
    required BuildContext context,
    required ReminderTime reminderTime,
    required bool isSelected,
    required bool isEnabled,
    required String timeDisplay,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: isEnabled
            ? () {
                setState(() {
                  _selectedReminderTime = reminderTime;
                });
                widget.onReminderTimeChanged(reminderTime);
              }
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.6),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeDisplay,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (reminderTime != ReminderTime.none)
                      Text(
                        _getReminderDescription(reminderTime),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? colorScheme.onPrimaryContainer.withOpacity(0.8)
                              : colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderPreview(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final reminderDateTime = _selectedReminderTime.calculateReminderTime(widget.dueTime!);
    if (reminderDateTime == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.secondary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            size: 16,
            color: colorScheme.secondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '将在 ${_formatDateTime(reminderDateTime)} 提醒您',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeDisplay(ReminderTime time) {
    switch (time) {
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

  String _getReminderDescription(ReminderTime time) {
    switch (time) {
      case ReminderTime.none:
        return '';
      case ReminderTime.onTime:
        return '任务到期时提醒';
      case ReminderTime.before5m:
        return '任务到期前5分钟提醒';
      case ReminderTime.before15m:
        return '任务到期前15分钟提醒';
      case ReminderTime.before30m:
        return '任务到期前30分钟提醒';
      case ReminderTime.before1h:
        return '任务到期前1小时提醒';
      case ReminderTime.before1d:
        return '任务到期前1天提醒';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminderDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (reminderDate.isAtSameMomentAs(today)) {
      // 今天
      return '今天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (reminderDate.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
      // 明天
      return '明天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (reminderDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      // 昨天
      return '昨天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      // 其他日期
      return '${dateTime.month}月${dateTime.day}日 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// 每日总结提醒设置组件
class DailySummaryReminderWidget extends StatefulWidget {
  final TimeOfDay? currentTime;
  final ValueChanged<TimeOfDay?> onTimeChanged;

  const DailySummaryReminderWidget({
    Key? key,
    this.currentTime,
    required this.onTimeChanged,
  }) : super(key: key);

  @override
  State<DailySummaryReminderWidget> createState() => _DailySummaryReminderWidgetState();
}

class _DailySummaryReminderWidgetState extends State<DailySummaryReminderWidget> {
  bool _isDailyReminderEnabled = false;

  @override
  void initState() {
    super.initState();
    _isDailyReminderEnabled = widget.currentTime != null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.today_outlined,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '每日任务总结',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: Text(
                '启用每日总结提醒',
                style: theme.textTheme.bodyLarge,
              ),
              subtitle: Text(
                '每天固定时间查看任务完成情况',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              value: _isDailyReminderEnabled,
              onChanged: (value) {
                setState(() {
                  _isDailyReminderEnabled = value;
                  if (!value) {
                    widget.onTimeChanged(null);
                  }
                });
              },
              activeColor: colorScheme.primary,
            ),

            if (_isDailyReminderEnabled) ...[
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  '提醒时间',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: widget.currentTime != null
                    ? Text(
                        '${widget.currentTime!.hour.toString().padLeft(2, '0')}:${widget.currentTime!.minute.toString().padLeft(2, '0')}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : Text(
                        '选择提醒时间',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                trailing: Icon(
                  Icons.access_time,
                  color: colorScheme.primary,
                ),
                onTap: () => _selectTime(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: AppConstants.shortAnimationDuration);
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: widget.currentTime ?? const TimeOfDay(hour: 20, minute: 0),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      widget.onTimeChanged(picked);
    }
  }
}

/// 通知权限请求组件
class NotificationPermissionWidget extends StatelessWidget {
  final bool hasPermission;
  final VoidCallback onRequestPermission;

  const NotificationPermissionWidget({
    Key? key,
    required this.hasPermission,
    required this.onRequestPermission,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (hasPermission) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: colorScheme.errorContainer,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  color: colorScheme.error,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '通知权限未开启',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '为了及时提醒您完成任务，请开启通知权限。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 16),
            CustomButton.primary(
              text: '开启通知权限',
              onPressed: onRequestPermission,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: AppConstants.shortAnimationDuration);
  }
}