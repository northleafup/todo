import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/themes/app_theme.dart';
import 'core/services/notification_service.dart';
import 'core/services/task_reminder_manager.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/context_provider.dart';
import 'presentation/pages/app_init_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化通知服务
  try {
    await NotificationService().initialize();
    await TaskReminderManager().initialize();
  } catch (e) {
    print('初始化通知服务失败: $e');
  }

  runApp(
    const ProviderScope(
      child: BeautifulTodoApp(),
    ),
  );
}

class BeautifulTodoApp extends ConsumerWidget {
  const BeautifulTodoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Beautiful Todo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AppInitPage(),
      builder: (context, child) {
        return ProviderScope(
          overrides: [
            // 重写context provider以提供当前的BuildContext
            contextProvider.overrideWithValue(context),
          ],
          child: child!,
        );
      },
    );
  }
}