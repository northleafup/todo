# Todo 应用 UI 设计规范

## 设计理念

### 1. 现代简约
- 简洁的界面设计
- 清晰的视觉层次
- 现代化的交互体验

### 2. 响应式设计
- 适配多种屏幕尺寸
- 灵活的布局方案
- 一致的用户体验

### 3. 无障碍设计
- 高对比度模式
- 大字体支持
- 键盘导航优化

## 颜色系统

### 主题色
```dart
// 主色调
Color primaryColor = Color(0xFF6750A4);  // Material Purple
Color secondaryColor = Color(0xFF625B71); // Material Purple Variant

// 中性色
Color surfaceColor = Color(0xFFFFFBFE);
Color backgroundColor = Color(0xFFFFFBFE);
Color onSurfaceColor = Color(0xFF1C1B1F);

// 状态色
Color successColor = Color(0xFF4CAF50);  // 绿色 - 完成
Color warningColor = Color(0xFFFF9800);  // 橙色 - 进行中
Color errorColor = Color(0xFFF44336);    // 红色 - 逾期/高优先级
```

### 优先级颜色
```dart
// 高优先级
Color highPriorityColor = Color(0xFFB3261E);
Color highPriorityLightColor = Color(0xFFFFDAD6);

// 中优先级
Color mediumPriorityColor = Color(0xFF7D5700);
Color mediumPriorityLightColor = Color(0xFFFFDDAE);

// 低优先级
Color lowPriorityColor = Color(0xFF146C2E);
Color lowPriorityLightColor = Color(0xFFCEDECC);
```

### 分类颜色预设
```dart
List<Color> categoryColors = [
  Color(0xFF7F5AF0), // 紫色
  Color(0xFF2AB7CA), // 青色
  Color(0xFFFF6B6B), // 红色
  Color(0xFF4ECDC4), // 绿松石
  Color(0xFFFFD93D), // 黄色
  Color(0xFF6BCF7F), // 绿色
  Color(0xFFC56CF0), // 粉紫
  Color(0xFF17C0EB), // 天蓝
];
```

## 字体系统

### 字体族
```dart
// 正文字体
String bodyFontFamily = 'Roboto';

// 标题字体
String headingFontFamily = 'Roboto';

// 代码字体
String codeFontFamily = 'JetBrains Mono';
```

### 字体大小
```dart
// 标题字体
double headline1Size = 32.0;
double headline2Size = 28.0;
double headline3Size = 24.0;
double headline4Size = 20.0;
double headline5Size = 16.0;
double headline6Size = 14.0;

// 正文字体
double bodyText1Size = 16.0;
double bodyText2Size = 14.0;
double subtitle1Size = 16.0;
double subtitle2Size = 14.0;

// 按钮字体
double buttonSize = 14.0;
double captionSize = 12.0;
double overlineSize = 10.0;
```

### 字重
```dart
FontWeight light = FontWeight.w300;
FontWeight regular = FontWeight.w400;
FontWeight medium = FontWeight.w500;
FontWeight semiBold = FontWeight.w600;
FontWeight bold = FontWeight.w700;
```

## 间距系统

### 基础间距单位
```dart
double spacingUnit = 8.0;

// 间距倍数
double spacingXXS = spacingUnit * 0.5;  // 4.0
double spacingXS = spacingUnit * 1;      // 8.0
double spacingSM = spacingUnit * 2;      // 16.0
double spacingMD = spacingUnit * 3;      // 24.0
double spacingLG = spacingUnit * 4;      // 32.0
double spacingXL = spacingUnit * 6;      // 48.0
double spacingXXL = spacingUnit * 8;     // 64.0
```

### 组件间距
```dart
// 页面内边距
EdgeInsets pagePadding = EdgeInsets.all(spacingSM);

// 卡片间距
EdgeInsets cardPadding = EdgeInsets.all(spacingSM);

// 列表项间距
EdgeInsets listItemPadding = EdgeInsets.symmetric(
  horizontal: spacingSM,
  vertical: spacingXS,
);
```

## 圆角系统

### 圆角大小
```dart
double radiusXXS = 4.0;
double radiusXS = 8.0;
double radiusSM = 12.0;
double radiusMD = 16.0;
double radiusLG = 20.0;
double radiusXL = 24.0;
double radiusXXL = 32.0;
```

### 使用场景
```dart
// 按钮圆角
BorderRadius buttonRadius = BorderRadius.circular(radiusSM);

// 卡片圆角
BorderRadius cardRadius = BorderRadius.circular(radiusMD);

// 对话框圆角
BorderRadius dialogRadius = BorderRadius.circular(radiusLG);

// 筛选标签圆角
BorderRadius chipRadius = BorderRadius.circular(radiusXS);
```

## 阴影系统

### 阴影级别
```dart
// 轻微阴影
List<BoxShadow> lightShadow = [
  BoxShadow(
    color: Colors.black.withOpacity(0.1),
    blurRadius: 4,
    offset: Offset(0, 2),
  ),
];

// 中等阴影
List<BoxShadow> mediumShadow = [
  BoxShadow(
    color: Colors.black.withOpacity(0.15),
    blurRadius: 8,
    offset: Offset(0, 4),
  ),
];

// 深度阴影
List<BoxShadow> deepShadow = [
  BoxShadow(
    color: Colors.black.withOpacity(0.2),
    blurRadius: 16,
    offset: Offset(0, 8),
  ),
];
```

## 组件设计规范

### 1. Todo 卡片
```dart
class TodoCard extends StatelessWidget {
  // 尺寸规范
  static const double minHeight = 80.0;
  static const double maxHeight = 120.0;

  // 间距规范
  static const EdgeInsets padding = EdgeInsets.all(16.0);
  static const double spacing = 8.0;

  // 颜色规范
  static const Color completedColor = Color(0xFFE8F5E9);
  static const Color highPriorityColor = Color(0xFFFFEBEE);
}
```

### 2. 分类标签
```dart
class CategoryChip extends StatelessWidget {
  // 尺寸规范
  static const double height = 32.0;
  static const double iconSize = 16.0;

  // 圆角规范
  static const BorderRadius borderRadius = BorderRadius.all(
    Radius.circular(16.0),
  );

  // 内边距规范
  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: 12.0,
    vertical: 6.0,
  );
}
```

### 3. 浮动按钮
```dart
class AddTodoFab extends StatelessWidget {
  // 尺寸规范
  static const double size = 56.0;
  static const double iconSize = 24.0;

  // 位置规范
  static const EdgeInsets margin = EdgeInsets.all(16.0);
  static const double bottom = 24.0;
  static const double right = 24.0;
}
```

## 动画规范

### 1. 时长规范
```dart
// 快速动画
Duration fastDuration = Duration(milliseconds: 150);

// 标准动画
Duration normalDuration = Duration(milliseconds: 300);

// 慢速动画
Duration slowDuration = Duration(milliseconds: 500);

// 页面切换动画
Duration pageTransitionDuration = Duration(milliseconds: 250);
```

### 2. 缓动函数
```dart
// 标准缓动
Curve standardCurve = Curves.easeInOut;

// 弹性缓动
Curve elasticCurve = Curves.elasticOut;

// 回弹缓动
Curve bounceCurve = Curves.bounceOut;
```

### 3. 动画类型
```dart
// 淡入淡出
class FadeAnimation extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const FadeAnimation({
    Key? key,
    required this.child,
    this.duration = normalDuration,
  }) : super(key: key);
}

// 滑动动画
class SlideAnimation extends StatelessWidget {
  final Widget child;
  final Offset begin;
  final Duration duration;

  const SlideAnimation({
    Key? key,
    required this.child,
    this.begin = const Offset(0, 0.3),
    this.duration = normalDuration,
  }) : super(key: key);
}
```

## 响应式断点

### 屏幕尺寸分类
```dart
class ScreenBreakpoints {
  static const double mobile = 600.0;
  static const double tablet = 840.0;
  static const double desktop = 1200.0;
}

// 布局适配
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < ScreenBreakpoints.mobile) {
      return MobileLayout();
    } else if (constraints.maxWidth < ScreenBreakpoints.desktop) {
      return TabletLayout();
    } else {
      return DesktopLayout();
    }
  },
)
```

## 图标规范

### 图标尺寸
```dart
double iconXS = 16.0;
double iconSM = 20.0;
double iconMD = 24.0;
double iconLG = 32.0;
double iconXL = 48.0;
```

### 图标颜色
```dart
// 主要图标
Color primaryIconColor = Color(0xFF1C1B1F);

// 次要图标
Color secondaryIconColor = Color(0xFF49454F);

// 禁用图标
Color disabledIconColor = Color(0xFFCAC4D0);

// 选中图标
Color selectedIconColor = Color(0xFF6750A4);
```

## 状态管理 UI 规范

### 加载状态
```dart
// 加载指示器
class LoadingIndicator extends StatelessWidget {
  static const double size = 24.0;
  static const Color color = Color(0xFF6750A4);
}
```

### 空状态
```dart
class EmptyState extends StatelessWidget {
  // 图标尺寸
  static const double iconSize = 64.0;

  // 文字样式
  static const TextStyle titleStyle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w500,
    color: Color(0xFF49454F),
  );

  static const TextStyle descStyle = TextStyle(
    fontSize: 14.0,
    color: Color(0xFF49454F),
  );
}
```

### 错误状态
```dart
class ErrorState extends StatelessWidget {
  // 颜色规范
  static const Color iconColor = Color(0xFFB3261E);
  static const Color textColor = Color(0xFF49454F);
}
```

## 无障碍设计

### 最小触摸目标
```dart
double minTouchTargetSize = 44.0;
```

### 颜色对比度
- 正常文本: 4.5:1
- 大文本: 3:1
- 非文本元素: 3:1

### 语义化标签
```dart
Semantics(
  label: '添加新的待办事项',
  hint: '点击创建新的待办事项',
  button: true,
  child: FloatingActionButton(...),
)
```