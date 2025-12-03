import 'package:dartz/dartz.dart';
import '../entities/todo.dart';
import '../../core/errors/failures.dart';

abstract class TodoRepository {
  /// 获取所有Todo
  Future<Either<Failure, List<Todo>>> getAllTodos();

  /// 根据ID获取Todo
  Future<Either<Failure, Todo>> getTodoById(String id);

  /// 根据分类ID获取Todo列表
  Future<Either<Failure, List<Todo>>> getTodosByCategory(String categoryId);

  /// 获取已完成Todo列表
  Future<Either<Failure, List<Todo>>> getCompletedTodos();

  /// 获取未完成Todo列表
  Future<Either<Failure, List<Todo>>> getIncompleteTodos();

  /// 获取逾期Todo列表
  Future<Either<Failure, List<Todo>>> getOverdueTodos();

  /// 获取今天到期的Todo列表
  Future<Either<Failure, List<Todo>>> getTodayTodos();

  /// 获取即将到期的Todo列表（3天内）
  Future<Either<Failure, List<Todo>>> getUpcomingTodos();

  /// 根据优先级获取Todo列表
  Future<Either<Failure, List<Todo>>> getTodosByPriority(String priority);

  /// 搜索Todo（根据标题和描述）
  Future<Either<Failure, List<Todo>>> searchTodos(String query);

  /// 创建新Todo
  Future<Either<Failure, Todo>> createTodo(Todo todo);

  /// 更新Todo
  Future<Either<Failure, Todo>> updateTodo(Todo todo);

  /// 删除Todo
  Future<Either<Failure, void>> deleteTodo(String id);

  /// 切换Todo完成状态
  Future<Either<Failure, Todo>> toggleTodoComplete(String id);

  /// 批量删除Todo
  Future<Either<Failure, void>> deleteMultipleTodos(List<String> ids);

  /// 批量切换Todo完成状态
  Future<Either<Failure, List<Todo>>> toggleMultipleTodosComplete(
      List<String> ids, bool isCompleted);

  /// 获取Todo统计信息
  Future<Either<Failure, Map<String, int>>> getTodoStats();

  /// 清除所有已完成Todo
  Future<Either<Failure, void>> clearCompletedTodos();

  /// 获取Todo总数
  Future<Either<Failure, int>> getTodoCount();

  /// 获取已完成Todo数量
  Future<Either<Failure, int>> getCompletedTodoCount();

  /// 获取未完成Todo数量
  Future<Either<Failure, int>> getIncompleteTodoCount();

  /// 根据日期范围获取Todo列表
  Future<Either<Failure, List<Todo>>> getTodosByDateRange(
      DateTime startDate, DateTime endDate);

  /// 获取最近创建的Todo（最近7天）
  Future<Either<Failure, List<Todo>>> getRecentTodos();
}