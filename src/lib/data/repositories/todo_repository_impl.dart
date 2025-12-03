import 'package:dartz/dartz.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../../core/constants/database_constants.dart';
import '../datasources/database_helper.dart';
import '../models/todo_model.dart';

class TodoRepositoryImpl implements TodoRepository {
  final DatabaseHelper databaseHelper;

  TodoRepositoryImpl({required this.databaseHelper});

  @override
  Future<Either<Failure, List<Todo>>> getAllTodos() async {
    try {
      final result = await databaseHelper.query(
        DatabaseConstants.todoTable,
        orderBy: '${DatabaseConstants.columnCreatedAt} DESC',
      );

      final todos = result
          .map((todoMap) => TodoModel.fromMap(todoMap).toEntity())
          .toList();

      return Right(todos);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Todo>> getTodoById(String id) async {
    try {
      final result = await databaseHelper.query(
        DatabaseConstants.todoTable,
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: [id],
      );

      if (result.isEmpty) {
        return const Left(NotFoundFailure('Todo not found'));
      }

      final todo = TodoModel.fromMap(result.first).toEntity();
      return Right(todo);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Todo>>> getTodosByCategory(String categoryId) async {
    try {
      final result = await databaseHelper.query(
        DatabaseConstants.todoTable,
        where: '${DatabaseConstants.columnCategoryId} = ?',
        whereArgs: [categoryId],
        orderBy: '${DatabaseConstants.columnCreatedAt} DESC',
      );

      final todos = result
          .map((todoMap) => TodoModel.fromMap(todoMap).toEntity())
          .toList();

      return Right(todos);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Todo>>> getCompletedTodos() async {
    try {
      final result = await databaseHelper.query(
        DatabaseConstants.todoTable,
        where: '${DatabaseConstants.columnIsCompleted} = ?',
        whereArgs: [1],
        orderBy: '${DatabaseConstants.columnUpdatedAt} DESC',
      );

      final todos = result
          .map((todoMap) => TodoModel.fromMap(todoMap).toEntity())
          .toList();

      return Right(todos);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Todo>>> getIncompleteTodos() async {
    try {
      final result = await databaseHelper.query(
        DatabaseConstants.todoTable,
        where: '${DatabaseConstants.columnIsCompleted} = ?',
        whereArgs: [0],
        orderBy: '${DatabaseConstants.columnCreatedAt} DESC',
      );

      final todos = result
          .map((todoMap) => TodoModel.fromMap(todoMap).toEntity())
          .toList();

      return Right(todos);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Todo>>> getOverdueTodos() async {
    try {
      final now = DateTime.now().toIso8601String();
      final result = await databaseHelper.query(
        DatabaseConstants.todoTable,
        where: '${DatabaseConstants.columnIsCompleted} = ? AND ${DatabaseConstants.columnDueDate} < ?',
        whereArgs: [0, now],
        orderBy: '${DatabaseConstants.columnDueDate} ASC',
      );

      final todos = result
          .map((todoMap) => TodoModel.fromMap(todoMap).toEntity())
          .toList();

      return Right(todos);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Todo>>> getTodayTodos() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final result = await databaseHelper.query(
        DatabaseConstants.todoTable,
        where: '${DatabaseConstants.columnDueDate} >= ? AND ${DatabaseConstants.columnDueDate} < ?',
        whereArgs: [today.toIso8601String(), tomorrow.toIso8601String()],
        orderBy: '${DatabaseConstants.columnDueDate} ASC',
      );

      final todos = result
          .map((todoMap) => TodoModel.fromMap(todoMap).toEntity())
          .toList();

      return Right(todos);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Todo>>> getUpcomingTodos() async {
    try {
      final now = DateTime.now();
      final threeDaysLater = now.add(const Duration(days: 3));

      final result = await databaseHelper.query(
        DatabaseConstants.todoTable,
        where: '${DatabaseConstants.columnIsCompleted} = ? AND ${DatabaseConstants.columnDueDate} <= ? AND ${DatabaseConstants.columnDueDate} > ?',
        whereArgs: [0, threeDaysLater.toIso8601String(), now.toIso8601String()],
        orderBy: '${DatabaseConstants.columnDueDate} ASC',
      );

      final todos = result
          .map((todoMap) => TodoModel.fromMap(todoMap).toEntity())
          .toList();

      return Right(todos);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Todo>>> getTodosByPriority(String priority) async {
    try {
      final result = await databaseHelper.query(
        DatabaseConstants.todoTable,
        where: '${DatabaseConstants.columnPriority} = ?',
        whereArgs: [priority],
        orderBy: '${DatabaseConstants.columnCreatedAt} DESC',
      );

      final todos = result
          .map((todoMap) => TodoModel.fromMap(todoMap).toEntity())
          .toList();

      return Right(todos);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Todo>>> searchTodos(String query) async {
    try {
      final result = await databaseHelper.query(
        DatabaseConstants.todoTable,
        where: '${DatabaseConstants.columnTitle} LIKE ? OR ${DatabaseConstants.columnDescription} LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: '${DatabaseConstants.columnCreatedAt} DESC',
      );

      final todos = result
          .map((todoMap) => TodoModel.fromMap(todoMap).toEntity())
          .toList();

      return Right(todos);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Todo>> createTodo(Todo todo) async {
    try {
      final todoModel = TodoModel.fromEntity(todo);
      await databaseHelper.insert(DatabaseConstants.todoTable, todoModel.toMap());
      return Right(todo);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Todo>> updateTodo(Todo todo) async {
    try {
      final todoModel = TodoModel.fromEntity(todo);
      await databaseHelper.update(
        DatabaseConstants.todoTable,
        todoModel.toMap(),
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: [todo.id],
      );
      return Right(todo);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTodo(String id) async {
    try {
      await databaseHelper.delete(
        DatabaseConstants.todoTable,
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: [id],
      );
      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Todo>> toggleTodoComplete(String id) async {
    try {
      final todoResult = await getTodoById(id);
      return todoResult.fold(
        (failure) => Left(failure),
        (todo) async {
          final updatedTodo = todo.copyWith(
            isCompleted: !todo.isCompleted,
            updatedAt: DateTime.now(),
          );
          return await updateTodo(updatedTodo);
        },
      );
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMultipleTodos(List<String> ids) async {
    try {
      if (ids.isEmpty) {
        return const Right(null);
      }

      final placeholders = List.filled(ids.length, '?').join(',');
      await databaseHelper.delete(
        DatabaseConstants.todoTable,
        where: '${DatabaseConstants.columnId} IN ($placeholders)',
        whereArgs: ids,
      );
      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Todo>>> toggleMultipleTodosComplete(
      List<String> ids, bool isCompleted) async {
    try {
      if (ids.isEmpty) {
        return const Right([]);
      }

      final placeholders = List.filled(ids.length, '?').join(',');
      final updatedAt = DateTime.now().toIso8601String();

      await databaseHelper.update(
        DatabaseConstants.todoTable,
        {
          DatabaseConstants.columnIsCompleted: isCompleted ? 1 : 0,
          DatabaseConstants.columnUpdatedAt: updatedAt,
        },
        where: '${DatabaseConstants.columnId} IN ($placeholders)',
        whereArgs: ids,
      );

      // 获取更新后的todos
      final result = await databaseHelper.query(
        DatabaseConstants.todoTable,
        where: '${DatabaseConstants.columnId} IN ($placeholders)',
        whereArgs: ids,
      );

      final todos = result
          .map((todoMap) => TodoModel.fromMap(todoMap).toEntity())
          .toList();

      return Right(todos);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> getTodoStats() async {
    try {
      final allResult = await databaseHelper.rawQuery(
        'SELECT COUNT(*) as total FROM ${DatabaseConstants.todoTable}',
      );
      final completedResult = await databaseHelper.rawQuery(
        'SELECT COUNT(*) as completed FROM ${DatabaseConstants.todoTable} WHERE ${DatabaseConstants.columnIsCompleted} = 1',
      );
      final overdueResult = await databaseHelper.rawQuery(
        'SELECT COUNT(*) as overdue FROM ${DatabaseConstants.todoTable} WHERE ${DatabaseConstants.columnIsCompleted} = 0 AND ${DatabaseConstants.columnDueDate} < ?',
        [DateTime.now().toIso8601String()],
      );

      final stats = {
        'total': allResult.first['total'] as int,
        'completed': completedResult.first['completed'] as int,
        'incomplete': (allResult.first['total'] as int) - (completedResult.first['completed'] as int),
        'overdue': overdueResult.first['overdue'] as int,
      };

      return Right(stats);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearCompletedTodos() async {
    try {
      await databaseHelper.delete(
        DatabaseConstants.todoTable,
        where: '${DatabaseConstants.columnIsCompleted} = ?',
        whereArgs: [1],
      );
      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getTodoCount() async {
    try {
      final result = await databaseHelper.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseConstants.todoTable}',
      );
      return Right(result.first['count'] as int);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getCompletedTodoCount() async {
    try {
      final result = await databaseHelper.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseConstants.todoTable} WHERE ${DatabaseConstants.columnIsCompleted} = 1',
      );
      return Right(result.first['count'] as int);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getIncompleteTodoCount() async {
    try {
      final result = await databaseHelper.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseConstants.todoTable} WHERE ${DatabaseConstants.columnIsCompleted} = 0',
      );
      return Right(result.first['count'] as int);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Todo>>> getTodosByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final result = await databaseHelper.query(
        DatabaseConstants.todoTable,
        where: '${DatabaseConstants.columnCreatedAt} >= ? AND ${DatabaseConstants.columnCreatedAt} <= ?',
        whereArgs: [
          startDate.toIso8601String(),
          endDate.toIso8601String(),
        ],
        orderBy: '${DatabaseConstants.columnCreatedAt} DESC',
      );

      final todos = result
          .map((todoMap) => TodoModel.fromMap(todoMap).toEntity())
          .toList();

      return Right(todos);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Todo>>> getRecentTodos() async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final result = await databaseHelper.query(
        DatabaseConstants.todoTable,
        where: '${DatabaseConstants.columnCreatedAt} >= ?',
        whereArgs: [sevenDaysAgo.toIso8601String()],
        orderBy: '${DatabaseConstants.columnCreatedAt} DESC',
      );

      final todos = result
          .map((todoMap) => TodoModel.fromMap(todoMap).toEntity())
          .toList();

      return Right(todos);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }
}