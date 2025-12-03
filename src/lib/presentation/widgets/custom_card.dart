import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final Clip? clipBehavior;

  const CustomCard({
    Key? key,
    required this.child,
    this.margin,
    this.padding,
    this.color,
    this.elevation,
    this.borderRadius,
    this.onTap,
    this.onLongPress,
    this.border,
    this.boxShadow,
    this.clipBehavior,
  }) : super(key: key);

  factory CustomCard.primary({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return CustomCard(
      key: key,
      child: child,
      margin: margin,
      padding: padding,
      onTap: onTap,
      onLongPress: onLongPress,
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
    );
  }

  factory CustomCard.secondary({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return CustomCard(
      key: key,
      child: child,
      margin: margin,
      padding: padding,
      onTap: onTap,
      onLongPress: onLongPress,
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
    );
  }

  factory CustomCard.tertiary({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return CustomCard(
      key: key,
      child: child,
      margin: margin,
      padding: padding,
      onTap: onTap,
      onLongPress: onLongPress,
      elevation: 1,
      borderRadius: BorderRadius.circular(8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultMargin = margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    final defaultPadding = padding ?? const EdgeInsets.all(16);
    final defaultElevation = elevation ?? 2;
    final defaultBorderRadius = borderRadius ?? BorderRadius.circular(16);

    Widget cardWidget = Card(
      elevation: defaultElevation,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: defaultBorderRadius,
      ),
      shadowColor: theme.shadowColor,
      margin: defaultMargin,
      clipBehavior: clipBehavior ?? Clip.none,
      child: Container(
        padding: defaultPadding,
        child: child,
      ),
    );

    if (onTap != null || onLongPress != null) {
      cardWidget = InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: defaultBorderRadius,
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}

class TodoCard extends StatelessWidget {
  final String title;
  final String? description;
  final bool isCompleted;
  final String priority;
  final String? category;
  final DateTime? dueDate;
  final Color? categoryColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggleComplete;
  final Widget? trailing;

  const TodoCard({
    Key? key,
    required this.title,
    this.description,
    required this.isCompleted,
    required this.priority,
    this.category,
    this.dueDate,
    this.categoryColor,
    this.onTap,
    this.onLongPress,
    this.onToggleComplete,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CustomCard.primary(
      onTap: onTap,
      onLongPress: onLongPress,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 完成状态复选框
              Checkbox(
                value: isCompleted,
                onChanged: onToggleComplete != null
                    ? (value) => onToggleComplete!()
                    : null,
                activeColor: AppTheme.getPriorityColor(priority),
              ),
              const SizedBox(width: 8),

              // 标题和描述
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: isCompleted
                            ? colorScheme.onSurface.withOpacity(0.6)
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // 优先级指示器
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.getPriorityColor(priority),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // 底部信息行
          const SizedBox(height: 8),
          Row(
            children: [
              // 分类标签
              if (category != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (categoryColor ?? AppTheme.customColors['mediumPriority'])
                        ?.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: categoryColor ?? AppTheme.customColors['mediumPriority']!,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    category!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: categoryColor ?? AppTheme.customColors['mediumPriority'],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // 截止日期
              if (dueDate != null) ...[
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(dueDate!),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],

              const Spacer(),

              // 额外的尾部组件
              if (trailing != null) trailing!,
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todoDate = DateTime(date.year, date.month, date.day);

    if (todoDate.isAtSameMomentAs(today)) {
      return '今天';
    } else if (todoDate.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
      return '明天';
    } else if (todoDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      return '昨天';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}

class CategoryCard extends StatelessWidget {
  final String name;
  final String color;
  final String icon;
  final int todoCount;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const CategoryCard({
    Key? key,
    required this.name,
    required this.color,
    required this.icon,
    required this.todoCount,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CustomCard.secondary(
      onTap: onTap,
      onLongPress: onLongPress,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分类图标和名称
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _parseColor(color).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _getIconData(icon),
                  color: _parseColor(color),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Todo数量
          Text(
            '$todoCount 个任务',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF6750A4);
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'work':
        return Icons.work;
      case 'personal':
        return Icons.person;
      case 'shopping':
        return Icons.shopping_cart;
      case 'health':
        return Icons.favorite;
      case 'education':
        return Icons.school;
      case 'finance':
        return Icons.account_balance;
      case 'travel':
        return Icons.flight;
      case 'home':
        return Icons.home;
      case 'family':
        return Icons.people;
      default:
        return Icons.category;
    }
  }
}