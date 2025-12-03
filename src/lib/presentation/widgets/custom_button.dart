import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/themes/app_theme.dart';
import '../../core/constants/app_constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Widget? child;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BorderSide? side;
  final OutlinedBorder? shape;
  final bool enableFeedback;
  final bool autofocus;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.style,
    this.child,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
    this.height,
    this.borderRadius,
    this.backgroundColor,
    this.foregroundColor,
    this.side,
    this.shape,
    this.enableFeedback = true,
    this.autofocus = false,
  }) : super(key: key);

  factory CustomButton.primary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isFullWidth = false,
    EdgeInsetsGeometry? padding,
    double? height,
  }) {
    return CustomButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      padding: padding,
      height: height,
      backgroundColor: null,
      foregroundColor: null,
    );
  }

  factory CustomButton.secondary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isFullWidth = false,
    EdgeInsetsGeometry? padding,
    double? height,
  }) {
    return CustomButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      padding: padding,
      height: height,
      backgroundColor: null,
      foregroundColor: null,
    );
  }

  factory CustomButton.outlined({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isFullWidth = false,
    EdgeInsetsGeometry? padding,
    double? height,
    Color? borderColor,
  }) {
    return CustomButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      padding: padding,
      height: height,
      side: BorderSide(color: borderColor ?? AppTheme.primaryColor),
      backgroundColor: Colors.transparent,
    );
  }

  factory CustomButton.text({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    Color? textColor,
    EdgeInsetsGeometry? padding,
  }) {
    return CustomButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      padding: padding,
      backgroundColor: Colors.transparent,
      foregroundColor: textColor,
      side: BorderSide.none,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 默认样式
    ButtonStyle defaultStyle = ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 2,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      minimumSize: isFullWidth ? Size(double.infinity, height ?? 48) : null,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        side: side ?? BorderSide.none,
      ),
    );

    // 合并自定义样式
    final effectiveStyle = style?.merge(defaultStyle) ?? defaultStyle;

    Widget buttonChild = child ??
        Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: foregroundColor ?? (backgroundColor != null ? null : colorScheme.onPrimary),
          ),
        );

    // 如果正在加载，显示加载指示器
    if (isLoading) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                foregroundColor ?? colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '加载中...',
            style: theme.textTheme.labelSmall?.copyWith(
              color: foregroundColor ?? colorScheme.onPrimary,
            ),
          ),
        ],
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: effectiveStyle,
      child: buttonChild,
    ).animate().scaleXY(
          duration: AppConstants.shortAnimationDuration,
          begin: isLoading ? 1.0 : 0.95,
          end: 1.0,
        );
  }
}

class FloatingActionButtonCustom extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? child;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool enableFeedback;
  final bool autofocus;
  final bool mini;

  const FloatingActionButtonCustom({
    Key? key,
    this.onPressed,
    this.child,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.enableFeedback = true,
    this.autofocus = false,
    this.mini = false,
  }) : super(key: key);

  factory FloatingActionButtonCustom.primary({
    Key? key,
    required VoidCallback onPressed,
    required Widget child,
    String? tooltip,
  }) {
    return FloatingActionButtonCustom(
      key: key,
      onPressed: onPressed,
      child: child,
      tooltip: tooltip,
      backgroundColor: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: backgroundColor ?? colorScheme.primary,
      foregroundColor: foregroundColor ?? colorScheme.onPrimary,
      elevation: elevation,
      enableFeedback: enableFeedback,
      autofocus: autofocus,
      mini: mini,
      child: child,
    ).animate().scale(
          duration: AppConstants.mediumAnimationDuration,
          curve: Curves.elasticOut,
        );
  }
}

class IconButtonCustom extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double? iconSize;
  final Color? color;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final String? semanticLabel;
  final bool enableFeedback;
  final bool autofocus;

  const IconButtonCustom({
    Key? key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.iconSize,
    this.color,
    this.backgroundColor,
    this.padding,
    this.semanticLabel,
    this.enableFeedback = true,
    this.autofocus = false,
  }) : super(key: key);

  factory IconButtonCustom.primary({
    Key? key,
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    double? iconSize,
  }) {
    return IconButtonCustom(
      key: key,
      icon: icon,
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: iconSize,
    );
  }

  factory IconButtonCustom.filled({
    Key? key,
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    Color? backgroundColor,
    Color? iconColor,
    double? iconSize,
  }) {
    return IconButtonCustom(
      key: key,
      icon: icon,
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: backgroundColor,
      color: iconColor,
      iconSize: iconSize,
      padding: const EdgeInsets.all(12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color effectiveBackgroundColor = backgroundColor ?? Colors.transparent;
    Color effectiveColor = color ?? colorScheme.onSurface;

    if (backgroundColor != null) {
      effectiveColor = color ?? colorScheme.onPrimary;
    }

    Widget button = Container(
      decoration: backgroundColor != null
          ? BoxDecoration(
              color: effectiveBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: iconSize,
          color: effectiveColor,
        ),
        tooltip: tooltip,
        padding: padding,
        splashRadius: 24,
        visualDensity: VisualDensity.compact,
      ),
    );

    return button
        .animate(target: onPressed != null ? 1 : 0)
        .scaleXY(
          duration: AppConstants.shortAnimationDuration,
          curve: Curves.easeOutBack,
        )
        .shimmer(
          duration: const Duration(milliseconds: 1500),
          color: Colors.white.withOpacity(0.3),
        );
  }
}

class FilterChipCustom extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final Widget? avatar;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? checkmarkColor;
  final EdgeInsetsGeometry? padding;
  final ShapeBorder? shape;

  const FilterChipCustom({
    Key? key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.avatar,
    this.backgroundColor,
    this.selectedColor,
    this.checkmarkColor,
    this.padding,
    this.shape,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      avatar: avatar,
      backgroundColor: backgroundColor ?? colorScheme.surfaceVariant,
      selectedColor: selectedColor ?? colorScheme.primaryContainer,
      checkmarkColor: checkmarkColor ?? colorScheme.onPrimaryContainer,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: shape as OutlinedBorder? ?? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: selected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    ).animate().scaleXY(
          duration: AppConstants.shortAnimationDuration,
          curve: Curves.easeOutBack,
        );
  }
}

class ActionChipCustom extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? avatar;
  final Color? backgroundColor;
  final Color? shadowColor;
  final EdgeInsetsGeometry? padding;

  const ActionChipCustom({
    Key? key,
    required this.label,
    this.onPressed,
    this.avatar,
    this.backgroundColor,
    this.shadowColor,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ActionChip(
      label: Text(label),
      onPressed: onPressed,
      avatar: avatar,
      backgroundColor: backgroundColor ?? colorScheme.secondaryContainer,
      shadowColor: shadowColor,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: colorScheme.onSecondaryContainer,
        fontWeight: FontWeight.w500,
      ),
    ).animate().scaleXY(
          duration: AppConstants.shortAnimationDuration,
          curve: Curves.easeOutBack,
        );
  }
}