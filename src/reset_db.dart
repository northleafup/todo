import 'lib/core/services/database_config_service.dart';

void main() async {
  print('重置数据库配置...');
  await DatabaseConfigService.resetDatabaseConfig();
  print('配置已重置');
}