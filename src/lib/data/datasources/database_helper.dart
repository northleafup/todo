import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/constants/database_constants.dart';
import '../../core/services/database_config_service.dart';
import '../../core/errors/exceptions.dart' as app_exceptions;

class DatabaseHelper {
  static Database? _database;
  static const String _databaseName = DatabaseConstants.databaseName;
  static const int _databaseVersion = DatabaseConstants.databaseVersion;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      // 使用自定义的数据库配置服务获取路径
      final path = await DatabaseConfigService.getDatabasePath();

      print('数据库路径: $path'); // 调试信息

      // 尝试使用更兼容的数据库初始化方式
      Database db;
      try {
        db = await openDatabase(
          path,
          version: _databaseVersion,
          onCreate: _createTables,
          onUpgrade: _onUpgrade,
          onOpen: _onOpen,
        );
      } catch (e) {
        print('标准数据库初始化失败，尝试备用方案: $e');
        // 备用方案：使用更简单的数据库配置
        final dbPath = await _getFallbackDatabasePath();
        db = await openDatabase(
          dbPath,
          version: _databaseVersion,
          onCreate: _createTables,
          onUpgrade: _onUpgrade,
          onOpen: _onOpen,
        );
      }

      return db;
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to initialize database: $e');
    }
  }

  // 备用数据库路径
  Future<String> _getFallbackDatabasePath() async {
    final dbDir = await getDatabasesPath();
    return join(dbDir, _databaseName);
  }

  Future<void> _onOpen(Database db) async {
    // 数据库打开时的额外初始化逻辑
    print('数据库已成功打开');
  }

  Future<void> _createTables(Database db, int version) async {
    try {
      await db.execute(DatabaseConstants.createCategoryTable);
      await db.execute(DatabaseConstants.createTodoTable);

      // 插入默认分类
      await _insertDefaultCategories(db);
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to create tables: $e');
    }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final now = DateTime.now().toIso8601String();
    final defaultCategories = [
      {
        'id': 'cat_1',
        'name': '工作',
        'color': '#45B7D1',
        'icon': 'work',
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'cat_2',
        'name': '个人',
        'color': '#96CEB4',
        'icon': 'personal',
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'cat_3',
        'name': '购物',
        'color': '#FF6B6B',
        'icon': 'shopping',
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'cat_4',
        'name': '健康',
        'color': '#FFEAA7',
        'icon': 'health',
        'created_at': now,
        'updated_at': now,
      },
    ];

    for (final category in defaultCategories) {
      await db.insert(
        DatabaseConstants.categoryTable,
        category,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 数据库升级逻辑
    // 例如：添加新表、修改表结构等
    if (oldVersion < 2) {
      // 示例：添加新表
      // await db.execute('CREATE TABLE new_table (...)');
    }
  }

  Future<int> insert(String table, Map<String, dynamic> values) async {
    try {
      final db = await database;
      return await db.insert(
        table,
        values,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to insert into $table: $e');
    }
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await database;
      return await db.query(
        table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to query $table: $e');
    }
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    try {
      final db = await database;
      return await db.update(table, values, where: where, whereArgs: whereArgs);
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to update $table: $e');
    }
  }

  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    try {
      final db = await database;
      return await db.delete(table, where: where, whereArgs: whereArgs);
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to delete from $table: $e');
    }
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    try {
      final db = await database;
      return await db.rawQuery(sql, arguments);
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to execute raw query: $e');
    }
  }

  Future<int> rawUpdate(String sql, [List<Object?>? arguments]) async {
    try {
      final db = await database;
      return await db.rawUpdate(sql, arguments);
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to execute raw update: $e');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.delete(DatabaseConstants.todoTable);
      await db.delete(DatabaseConstants.categoryTable);

      // 重新插入默认分类
      await _insertDefaultCategories(db);
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to clear all data: $e');
    }
  }
}