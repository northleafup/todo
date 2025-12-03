import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/database_config_service.dart';
import 'database_setup_page.dart';
import 'home_page.dart';

class AppInitPage extends StatefulWidget {
  const AppInitPage({super.key});

  @override
  State<AppInitPage> createState() => _AppInitPageState();
}

class _AppInitPageState extends State<AppInitPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isChecking = false;
  bool _needsSetup = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();

    _checkInitializationStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkInitializationStatus() async {
    setState(() => _isChecking = true);

    try {
      // 检查是否是首次启动
      final isFirstLaunch = await DatabaseConfigService.isFirstLaunch;

      print('首次启动检查结果: $isFirstLaunch'); // 调试信息

      if (isFirstLaunch) {
        setState(() {
          _needsSetup = true;
        });
        print('显示数据库设置页面'); // 调试信息
      } else {
        _navigateToHome();
      }
    } catch (e) {
      print('检查初始化状态失败: $e');
      setState(() {
        _needsSetup = true;
      });
    } finally {
      setState(() => _isChecking = false);
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const HomePage(),
      ),
    );
  }

  void _navigateToSetup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const DatabaseSetupPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isChecking) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: colorScheme.primary,
              )
                  .animate(controller: _animationController)
                  .rotate(duration: 1000.ms, curve: Curves.linear),
              const SizedBox(height: 24),
              Text(
                '正在检查应用状态...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
                  .animate(controller: _animationController)
                  .fadeIn(delay: 200.ms),
            ],
          ),
        ),
      );
    }

    if (_needsSetup) {
      return const DatabaseSetupPage();
    }

    // 如果不需要设置，但这里不应该到达，因为已经在_checkInitializationStatus中导航了
    return const HomePage();
  }
}