class DatabaseConstants {
  static const String databaseName = 'todo_app.db';
  static const int databaseVersion = 1;

  // 表名
  static const String todoTable = 'todos';
  static const String categoryTable = 'categories';

  // Todo表字段
  static const String columnId = 'id';
  static const String columnTitle = 'title';
  static const String columnDescription = 'description';
  static const String columnIsCompleted = 'is_completed';
  static const String columnPriority = 'priority';
  static const String columnCategoryId = 'category_id';
  static const String columnDueDate = 'due_date';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  // Category表字段
  static const String columnName = 'name';
  static const String columnColor = 'color';
  static const String columnIcon = 'icon';

  // 创建表的SQL语句
  static const String createTodoTable = '''
    CREATE TABLE $todoTable (
      $columnId TEXT PRIMARY KEY,
      $columnTitle TEXT NOT NULL,
      $columnDescription TEXT,
      $columnIsCompleted INTEGER NOT NULL DEFAULT 0,
      $columnPriority TEXT NOT NULL DEFAULT 'medium',
      $columnCategoryId TEXT,
      $columnDueDate TEXT,
      $columnCreatedAt TEXT NOT NULL,
      $columnUpdatedAt TEXT NOT NULL,
      FOREIGN KEY ($columnCategoryId) REFERENCES $categoryTable ($columnId)
    )
  ''';

  static const String createCategoryTable = '''
    CREATE TABLE $categoryTable (
      $columnId TEXT PRIMARY KEY,
      $columnName TEXT NOT NULL UNIQUE,
      $columnColor TEXT NOT NULL,
      $columnIcon TEXT NOT NULL,
      $columnCreatedAt TEXT NOT NULL,
      $columnUpdatedAt TEXT NOT NULL
    )
  ''';

  // 优先级常量
  static const String priorityHigh = 'high';
  static const String priorityMedium = 'medium';
  static const String priorityLow = 'low';
}