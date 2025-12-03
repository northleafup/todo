import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/todo_repository_impl.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/datasources/database_helper.dart';
import '../../domain/entities/todo.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/todo_repository.dart';
import '../../domain/repositories/category_repository.dart';

// 数据库助手提供者
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

// Repository 提供者
final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return TodoRepositoryImpl(databaseHelper: databaseHelper);
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return CategoryRepositoryImpl(databaseHelper: databaseHelper);
});

// Todo 列表状态
class TodoListState {
  final List<Todo> todos;
  final bool isLoading;
  final String? error;
  final String? selectedCategory;
  final String? selectedPriority;
  final String searchQuery;

  const TodoListState({
    this.todos = const [],
    this.isLoading = false,
    this.error,
    this.selectedCategory,
    this.selectedPriority,
    this.searchQuery = '',
  });

  TodoListState copyWith({
    List<Todo>? todos,
    bool? isLoading,
    String? error,
    String? selectedCategory,
    String? selectedPriority,
    String? searchQuery,
  }) {
    return TodoListState(
      todos: todos ?? this.todos,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedPriority: selectedPriority ?? this.selectedPriority,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  // 获取筛选后的Todo列表
  List<Todo> get filteredTodos {
    List<Todo> filtered = todos;

    // 按分类筛选
    if (selectedCategory != null) {
      filtered = filtered
          .where((todo) => todo.categoryId == selectedCategory)
          .toList();
    }

    // 按优先级筛选
    if (selectedPriority != null) {
      filtered = filtered
          .where((todo) => todo.priority == selectedPriority)
          .toList();
    }

    // 按搜索查询筛选
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where((todo) =>
              todo.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
              (todo.description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false))
          .toList();
    }

    return filtered;
  }

  // 获取统计信息
  Map<String, int> get stats {
    final completed = filteredTodos.where((todo) => todo.isCompleted).length;
    final incomplete = filteredTodos.length - completed;
    final overdue = filteredTodos
        .where((todo) => !todo.isCompleted && todo.isOverdue)
        .length;
    final today = filteredTodos
        .where((todo) => todo.isDueToday)
        .length;

    return {
      'total': filteredTodos.length,
      'completed': completed,
      'incomplete': incomplete,
      'overdue': overdue,
      'today': today,
    };
  }
}

// Todo 列表提供者
class TodoListNotifier extends StateNotifier<TodoListState> {
  final TodoRepository _todoRepository;

  TodoListNotifier(this._todoRepository) : super(const TodoListState());

  // 加载所有Todo
  Future<void> loadTodos() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _todoRepository.getAllTodos();

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (todos) => state = state.copyWith(
        isLoading: false,
        todos: todos,
        error: null,
      ),
    );
  }

  // 添加Todo
  Future<void> addTodo(Todo todo) async {
    state = state.copyWith(isLoading: true);

    final result = await _todoRepository.createTodo(todo);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (newTodo) async {
        final updatedTodos = [...state.todos, newTodo];
        state = state.copyWith(
          isLoading: false,
          todos: updatedTodos,
          error: null,
        );
      },
    );
  }

  // 更新Todo
  Future<void> updateTodo(Todo todo) async {
    state = state.copyWith(isLoading: true);

    final result = await _todoRepository.updateTodo(todo);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (updatedTodo) async {
        final updatedTodos = state.todos.map((t) => t.id == updatedTodo.id ? updatedTodo : t).toList();
        state = state.copyWith(
          isLoading: false,
          todos: updatedTodos,
          error: null,
        );
      },
    );
  }

  // 删除Todo
  Future<void> deleteTodo(String id) async {
    final result = await _todoRepository.deleteTodo(id);

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) async {
        final updatedTodos = state.todos.where((t) => t.id != id).toList();
        state = state.copyWith(
          todos: updatedTodos,
          error: null,
        );
      },
    );
  }

  // 切换Todo完成状态
  Future<void> toggleTodoComplete(String id) async {
    final result = await _todoRepository.toggleTodoComplete(id);

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (updatedTodo) async {
        final updatedTodos = state.todos.map((t) => t.id == updatedTodo.id ? updatedTodo : t).toList();
        state = state.copyWith(
          todos: updatedTodos,
          error: null,
        );
      },
    );
  }

  // 按分类筛选
  void filterByCategory(String? categoryId) {
    state = state.copyWith(selectedCategory: categoryId);
  }

  // 按优先级筛选
  void filterByPriority(String? priority) {
    state = state.copyWith(selectedPriority: priority);
  }

  // 搜索Todo
  void searchTodos(String query) {
    state = state.copyWith(searchQuery: query);
  }

  // 清除所有筛选
  void clearFilters() {
    state = state.copyWith(
      selectedCategory: null,
      selectedPriority: null,
      searchQuery: '',
    );
  }

  // 刷新数据
  Future<void> refresh() async {
    await loadTodos();
  }

  // 清除错误
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Todo 列表提供者实例
final todoListProvider = StateNotifierProvider<TodoListNotifier, TodoListState>((ref) {
  final todoRepository = ref.watch(todoRepositoryProvider);
  return TodoListNotifier(todoRepository);
});

// 分类列表状态
class CategoryListState {
  final List<Category> categories;
  final bool isLoading;
  final String? error;

  const CategoryListState({
    this.categories = const [],
    this.isLoading = false,
    this.error,
  });

  CategoryListState copyWith({
    List<Category>? categories,
    bool? isLoading,
    String? error,
  }) {
    return CategoryListState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  // 获取分类名称映射
  Map<String, String> get categoryNames {
    return {
      for (var category in categories) category.id: category.name,
    };
  }

  // 获取分类颜色映射
  Map<String, Color> get categoryColors {
    return {
      for (var category in categories)
        category.id: _parseColor(category.color),
    };
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF6750A4);
    }
  }
}

// 分类列表提供者
class CategoryListNotifier extends StateNotifier<CategoryListState> {
  final CategoryRepository _categoryRepository;

  CategoryListNotifier(this._categoryRepository) : super(const CategoryListState());

  // 加载所有分类
  Future<void> loadCategories() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _categoryRepository.getAllCategories();

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (categories) => state = state.copyWith(
        isLoading: false,
        categories: categories,
        error: null,
      ),
    );
  }

  // 添加分类
  Future<void> addCategory(Category category) async {
    state = state.copyWith(isLoading: true);

    final result = await _categoryRepository.createCategory(category);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (newCategory) async {
        final updatedCategories = [...state.categories, newCategory];
        state = state.copyWith(
          isLoading: false,
          categories: updatedCategories,
          error: null,
        );
      },
    );
  }

  // 更新分类
  Future<void> updateCategory(Category category) async {
    final result = await _categoryRepository.updateCategory(category);

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (updatedCategory) async {
        final updatedCategories = state.categories
            .map((c) => c.id == updatedCategory.id ? updatedCategory : c)
            .toList();
        state = state.copyWith(
          categories: updatedCategories,
          error: null,
        );
      },
    );
  }

  // 删除分类
  Future<void> deleteCategory(String id) async {
    final result = await _categoryRepository.deleteCategory(id);

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) async {
        final updatedCategories = state.categories.where((c) => c.id != id).toList();
        state = state.copyWith(
          categories: updatedCategories,
          error: null,
        );
      },
    );
  }

  // 刷新数据
  Future<void> refresh() async {
    await loadCategories();
  }

  // 清除错误
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// 分类列表提供者实例
final categoryListProvider = StateNotifierProvider<CategoryListNotifier, CategoryListState>((ref) {
  final categoryRepository = ref.watch(categoryRepositoryProvider);
  return CategoryListNotifier(categoryRepository);
});

// 当前日期提供者
final currentDateProvider = Provider<DateTime>((ref) {
  return DateTime.now();
});

// 应用统计提供者
final appStatsProvider = Provider<Map<String, int>>((ref) {
  final todoState = ref.watch(todoListProvider);
  return todoState.stats;
});

// 获取指定分类的颜色
final categoryColorProvider = Provider.family<Color?, String>((ref, categoryId) {
  final categoryState = ref.watch(categoryListProvider);
  final category = categoryState.categories
      .where((c) => c.id == categoryId)
      .firstOrNull;

  if (category == null) return null;

  try {
    return Color(int.parse(category.color.replaceAll('#', '0xFF')));
  } catch (e) {
    return const Color(0xFF6750A4);
  }
});

// 获取指定分类的名称
final categoryNameProvider = Provider.family<String?, String>((ref, categoryId) {
  final categoryState = ref.watch(categoryListProvider);
  final category = categoryState.categories
      .where((c) => c.id == categoryId)
      .firstOrNull;

  return category?.name;
});