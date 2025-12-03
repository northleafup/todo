# 项目目录结构

```
beautiful_todo/
├── README.md                           # 项目说明文档
├── DEVELOPMENT_PLAN.md                 # 开发计划
├── UI_DESIGN_SPEC.md                   # UI设计规范
├── PROJECT_STRUCTURE.md               # 项目结构说明
├── pubspec.yaml                       # 项目依赖配置
├── analysis_options.yaml              # 代码分析配置
├── l10n.yaml                          # 国际化配置
├── build.yaml                         # 代码生成配置
├── assets/                            # 静态资源
│   ├── images/                        # 图片资源
│   │   ├── icons/                     # 图标
│   │   └── illustrations/             # 插图
│   └── fonts/                         # 字体文件
├── lib/                               # 源代码目录
│   ├── main.dart                      # 应用入口
│   ├── app.dart                       # 应用配置
│   ├── core/                          # 核心模块
│   │   ├── constants/                 # 常量定义
│   │   │   ├── app_constants.dart
│   │   │   ├── color_constants.dart
│   │   │   ├── size_constants.dart
│   │   │   └── route_constants.dart
│   │   ├── utils/                     # 工具类
│   │   │   ├── date_utils.dart
│   │   │   ├── string_utils.dart
│   │   │   ├── validation_utils.dart
│   │   │   └── notification_utils.dart
│   │   ├── extensions/                # 扩展方法
│   │   │   ├── string_extensions.dart
│   │   │   ├── date_extensions.dart
│   │   │   └── color_extensions.dart
│   │   ├── errors/                    # 错误处理
│   │   │   ├── exceptions.dart
│   │   │   └── failures.dart
│   │   └── themes/                    # 主题配置
│   │       ├── app_theme.dart
│   │       ├── light_theme.dart
│   │       ├── dark_theme.dart
│   │       └── theme_data.dart
│   ├── data/                          # 数据层
│   │   ├── models/                    # 数据模型
│   │   │   ├── todo.dart
│   │   │   ├── category.dart
│   │   │   ├── priority.dart
│   │   │   └── statistics.dart
│   │   ├── datasources/               # 数据源
│   │   │   ├── local/
│   │   │   │   ├── todo_local_datasource.dart
│   │   │   │   └── category_local_datasource.dart
│   │   │   └── remote/ (未来可能需要)
│   │   ├── repositories/              # 仓库实现
│   │   │   ├── todo_repository_impl.dart
│   │   │   └── category_repository_impl.dart
│   │   └── services/                  # 服务类
│   │       ├── database_service.dart
│   │       ├── notification_service.dart
│   │       └── storage_service.dart
│   ├── domain/                        # 业务逻辑层
│   │   ├── entities/                  # 业务实体
│   │   │   ├── todo.dart
│   │   │   ├── category.dart
│   │   │   └── priority.dart
│   │   ├── repositories/              # 仓库接口
│   │   │   ├── todo_repository.dart
│   │   │   └── category_repository.dart
│   │   └── usecases/                  # 用例
│   │       ├── todos/
│   │       │   ├── add_todo_usecase.dart
│   │       │   ├── update_todo_usecase.dart
│   │       │   ├── delete_todo_usecase.dart
│   │       │   ├── get_todos_usecase.dart
│   │       │   └── toggle_todo_status_usecase.dart
│   │       └── categories/
│   │           ├── add_category_usecase.dart
│   │           ├── update_category_usecase.dart
│   │           ├── delete_category_usecase.dart
│   │           └── get_categories_usecase.dart
│   ├── presentation/                  # 表现层
│   │   ├── providers/                 # 状态管理
│   │   │   ├── todo_provider.dart
│   │   │   ├── category_provider.dart
│   │   │   ├── statistics_provider.dart
│   │   │   └── theme_provider.dart
│   │   ├── pages/                     # 页面
│   │   │   ├── home/
│   │   │   │   ├── home_page.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── welcome_header.dart
│   │   │   │       ├── stats_card.dart
│   │   │   │       └── category_filter.dart
│   │   │   ├── add_todo/
│   │   │   │   ├── add_todo_page.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── todo_form.dart
│   │   │   │       ├── priority_selector.dart
│   │   │   │       └── category_selector.dart
│   │   │   ├── edit_todo/
│   │   │   │   ├── edit_todo_page.dart
│   │   │   │   └── widgets/
│   │   │   │       └── todo_form.dart
│   │   │   ├── todo_detail/
│   │   │   │   ├── todo_detail_page.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── detail_header.dart
│   │   │   │       └── action_buttons.dart
│   │   │   ├── statistics/
│   │   │   │   ├── statistics_page.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── completion_chart.dart
│   │   │   │       ├── category_chart.dart
│   │   │   │       └── trend_chart.dart
│   │   │   ├── categories/
│   │   │   │   ├── categories_page.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── category_form.dart
│   │   │   │       └── category_list.dart
│   │   │   └── settings/
│   │   │       ├── settings_page.dart
│   │   │       └── widgets/
│   │   │           ├── theme_selector.dart
│   │   │           └── language_selector.dart
│   │   ├── widgets/                   # 通用组件
│   │   │   ├── common/
│   │   │   │   ├── custom_button.dart
│   │   │   │   ├── custom_text_field.dart
│   │   │   │   ├── loading_widget.dart
│   │   │   │   ├── empty_state_widget.dart
│   │   │   │   ├── error_widget.dart
│   │   │   │   ├── dialog_widget.dart
│   │   │   │   └── app_bar_widget.dart
│   │   │   ├── todo_card/
│   │   │   │   ├── todo_card.dart
│   │   │   │   ├── todo_checkbox.dart
│   │   │   │   └── todo_actions.dart
│   │   │   ├── category_chip/
│   │   │   │   ├── category_chip.dart
│   │   │   │   └── category_color_picker.dart
│   │   │   ├── priority_indicator/
│   │   │   │   └── priority_indicator.dart
│   │   │   └── date_picker/
│   │   │       ├── custom_date_picker.dart
│   │   │       └── date_display.dart
│   │   ├── routes/                    # 路由配置
│   │   │   ├── app_router.dart
│   │   │   ├── route_names.dart
│   │   │   └── route_generator.dart
│   │   └── themes/                    # 主题相关
│   │       ├── app_colors.dart
│   │       ├── app_text_styles.dart
│   │       └── app_dimensions.dart
│   └── l10n/                          # 国际化文件
│       ├── app_en.arb                 # 英文
│       ├── app_zh.arb                 # 中文
│       └── app_localizations.dart     # 生成的本地化文件
├── test/                              # 测试目录
│   ├── unit/                          # 单元测试
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── repositories/
│   │   │   └── services/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── providers/
│   │       └── widgets/
│   ├── widget/                        # 组件测试
│   │   └── widgets/
│   ├── integration/                   # 集成测试
│   │   ├── app_test.dart
│   │   └── e2e_test.dart
│   ├── test_utils.dart               # 测试工具
│   └── mock_data.dart                # 模拟数据
├── tools/                             # 开发工具
│   ├── build_runner/                 # 代码生成配置
│   └── scripts/                       # 构建脚本
│       ├── build.sh
│       └── test.sh
├── android/                           # Android 平台配置
│   ├── app/
│   │   ├── src/
│   │   │   └── main/
│   │   │       ├── kotlin/
│   │   │       └── res/
│   │   └── build.gradle
│   └── build.gradle
├── macos/                             # macOS 平台配置
│   ├── Runner/
│   │   ├── Assets.xcassets/
│   │   └── MainFlutterWindow.swift
│   └── Podfile
├── linux/                             # Linux 平台配置
│   ├── flutter/
│   │   ├── CMakeLists.txt
│   │   └── my_application.cc
│   └── CMakeLists.txt
└── .gitignore                         # Git 忽略文件
```

## 目录说明

### 1. 核心模块 (lib/core/)
- **constants/**: 应用常量，包括颜色、尺寸、路由等
- **utils/**: 工具类，提供通用的功能方法
- **extensions/**: Dart 扩展方法，增强原生类型功能
- **errors/**: 错误处理相关的类和异常
- **themes/**: 主题配置，包括明暗主题

### 2. 数据层 (lib/data/)
- **models/**: 数据模型，对应数据库表结构
- **datasources/**: 数据源，包括本地和远程数据源
- **repositories/**: 仓库接口的具体实现
- **services/**: 各种服务类，如数据库服务、通知服务等

### 3. 业务逻辑层 (lib/domain/)
- **entities/**: 业务实体，定义核心业务对象
- **repositories/**: 仓库接口，定义数据访问抽象
- **usecases/**: 用例，封装具体的业务逻辑

### 4. 表现层 (lib/presentation/)
- **providers/**: 状态管理，使用 Riverpod 进行状态管理
- **pages/**: 页面组件，每个页面包含相关的子组件
- **widgets/**: 通用组件，可在多个页面复用
- **routes/**: 路由配置，管理应用页面导航

### 5. 测试目录 (test/)
- **unit/**: 单元测试，测试独立的函数和类
- **widget/**: 组件测试，测试 UI 组件的行为
- **integration/**: 集成测试，测试多个组件的交互
- **e2e/**: 端到端测试，测试完整的用户流程

## 命名规范

### 1. 文件命名
- 使用小写字母和下划线
- 文件名要能体现其功能和用途
- 类文件与类名保持一致（使用驼峰命名）

### 2. 目录命名
- 使用小写字母和下划线
- 目录名要能反映其包含的内容类型
- 功能相似的文件放在同一目录下

### 3. 类命名
- 使用大驼峰命名法（PascalCase）
- 类名要能清晰表达其职责
- Widget 类以 "Widget" 结尾（可选）

### 4. 方法命名
- 使用小驼峰命名法（camelCase）
- 方法名要能描述其执行的操作
- 布尔类型返回值的方法以 "is" 或 "has" 开头

## 代码组织原则

### 1. 单一职责原则
- 每个类和模块只负责一个功能
- 避免创建过于复杂的类

### 2. 依赖倒置原则
- 高层模块不依赖低层模块
- 通过接口进行解耦

### 3. 开闭原则
- 对扩展开放，对修改关闭
- 通过抽象和接口实现扩展

### 4. 关注点分离
- UI 逻辑与业务逻辑分离
- 数据访问与业务逻辑分离

这个结构遵循了 Clean Architecture 原则，确保代码的可维护性和可测试性。