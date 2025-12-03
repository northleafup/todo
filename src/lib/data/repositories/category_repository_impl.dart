import 'package:dartz/dartz.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../../core/constants/database_constants.dart';
import '../datasources/database_helper.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final DatabaseHelper databaseHelper;

  CategoryRepositoryImpl({required this.databaseHelper});

  @override
  Future<Either<Failure, List<Category>>> getAllCategories() async {
    try {
      final result = await databaseHelper.query(
        DatabaseConstants.categoryTable,
        orderBy: '${DatabaseConstants.columnName} ASC',
      );

      final categories = result
          .map((categoryMap) => CategoryModel.fromMap(categoryMap).toEntity())
          .toList();

      return Right(categories);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Category>> getCategoryById(String id) async {
    try {
      final result = await databaseHelper.query(
        DatabaseConstants.categoryTable,
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: [id],
      );

      if (result.isEmpty) {
        return const Left(NotFoundFailure('Category not found'));
      }

      final category = CategoryModel.fromMap(result.first).toEntity();
      return Right(category);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Category>> getCategoryByName(String name) async {
    try {
      final result = await databaseHelper.query(
        DatabaseConstants.categoryTable,
        where: '${DatabaseConstants.columnName} = ?',
        whereArgs: [name],
      );

      if (result.isEmpty) {
        return const Left(NotFoundFailure('Category not found'));
      }

      final category = CategoryModel.fromMap(result.first).toEntity();
      return Right(category);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Category>> createCategory(Category category) async {
    try {
      // 检查名称是否已存在
      final existsResult = await isCategoryNameExists(category.name);
      final exists = existsResult.fold((failure) => false, (exists) => exists);

      if (exists) {
        return const Left(ValidationFailure('Category name already exists'));
      }

      final categoryModel = CategoryModel.fromEntity(category);
      await databaseHelper.insert(
        DatabaseConstants.categoryTable,
        categoryModel.toMap(),
      );
      return Right(category);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Category>> updateCategory(Category category) async {
    try {
      // 检查名称是否已被其他分类使用
      final existsResult = await isCategoryNameExists(category.name, excludeId: category.id);
      final exists = existsResult.fold((failure) => false, (exists) => exists);

      if (exists) {
        return const Left(ValidationFailure('Category name already exists'));
      }

      final categoryModel = CategoryModel.fromEntity(category);
      await databaseHelper.update(
        DatabaseConstants.categoryTable,
        categoryModel.toMap(),
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: [category.id],
      );
      return Right(category);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(String id) async {
    try {
      // 检查是否是默认分类
      final categoryResult = await getCategoryById(id);
      final category = categoryResult.fold(
        (failure) => null,
        (category) => category,
      );

      if (category != null && category.isDefault) {
        return const Left(PermissionDeniedFailure('Cannot delete default categories'));
      }

      // 检查是否有Todo使用此分类
      final todoCountResult = await databaseHelper.query(
        DatabaseConstants.todoTable,
        columns: ['COUNT(*) as count'],
        where: '${DatabaseConstants.columnCategoryId} = ?',
        whereArgs: [id],
      );

      final todoCount = todoCountResult.first['count'] as int;
      if (todoCount > 0) {
        return const Left(ValidationFailure('Cannot delete category with existing todos'));
      }

      await databaseHelper.delete(
        DatabaseConstants.categoryTable,
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
  Future<Either<Failure, bool>> isCategoryNameExists(String name, {String? excludeId}) async {
    try {
      String whereClause = '${DatabaseConstants.columnName} = ?';
      List<Object?> whereArgs = [name];

      if (excludeId != null) {
        whereClause += ' AND ${DatabaseConstants.columnId} != ?';
        whereArgs.add(excludeId);
      }

      final result = await databaseHelper.query(
        DatabaseConstants.categoryTable,
        columns: ['COUNT(*) as count'],
        where: whereClause,
        whereArgs: whereArgs,
      );

      final count = result.first['count'] as int;
      return Right(count > 0);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getDefaultCategories() async {
    try {
      final result = await databaseHelper.query(
        DatabaseConstants.categoryTable,
        where: '${DatabaseConstants.columnId} LIKE ?',
        whereArgs: ['cat_%'],
        orderBy: '${DatabaseConstants.columnName} ASC',
      );

      final categories = result
          .map((categoryMap) => CategoryModel.fromMap(categoryMap).toEntity())
          .toList();

      return Right(categories);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getCustomCategories() async {
    try {
      final result = await databaseHelper.query(
        DatabaseConstants.categoryTable,
        where: '${DatabaseConstants.columnId} NOT LIKE ?',
        whereArgs: ['cat_%'],
        orderBy: '${DatabaseConstants.columnName} ASC',
      );

      final categories = result
          .map((categoryMap) => CategoryModel.fromMap(categoryMap).toEntity())
          .toList();

      return Right(categories);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getCategoriesWithTodoCount() async {
    try {
      final result = await databaseHelper.rawQuery('''
        SELECT
          c.${DatabaseConstants.columnId},
          c.${DatabaseConstants.columnName},
          c.${DatabaseConstants.columnColor},
          c.${DatabaseConstants.columnIcon},
          COALESCE(COUNT(t.${DatabaseConstants.columnId}), 0) as todo_count
        FROM ${DatabaseConstants.categoryTable} c
        LEFT JOIN ${DatabaseConstants.todoTable} t ON c.${DatabaseConstants.columnId} = t.${DatabaseConstants.columnCategoryId}
        GROUP BY c.${DatabaseConstants.columnId}
        ORDER BY c.${DatabaseConstants.columnName} ASC
      ''');

      return Right(result.cast<Map<String, dynamic>>());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> searchCategories(String query) async {
    try {
      final result = await databaseHelper.query(
        DatabaseConstants.categoryTable,
        where: '${DatabaseConstants.columnName} LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: '${DatabaseConstants.columnName} ASC',
      );

      final categories = result
          .map((categoryMap) => CategoryModel.fromMap(categoryMap).toEntity())
          .toList();

      return Right(categories);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getCategoryCount() async {
    try {
      final result = await databaseHelper.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseConstants.categoryTable}',
      );
      return Right(result.first['count'] as int);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getDefaultCategoryCount() async {
    try {
      final result = await databaseHelper.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseConstants.categoryTable} WHERE ${DatabaseConstants.columnId} LIKE ?',
        ['cat_%'],
      );
      return Right(result.first['count'] as int);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getCustomCategoryCount() async {
    try {
      final result = await databaseHelper.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseConstants.categoryTable} WHERE ${DatabaseConstants.columnId} NOT LIKE ?',
        ['cat_%'],
      );
      return Right(result.first['count'] as int);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> validateCategoryName(String name) async {
    try {
      if (name.trim().isEmpty) {
        return const Left(ValidationFailure('Category name cannot be empty'));
      }

      if (name.length > 50) {
        return const Left(ValidationFailure('Category name too long'));
      }

      // 检查是否包含特殊字符
      final validPattern = RegExp(r'^[a-zA-Z0-9\u4e00-\u9fa5\s]+$');
      if (!validPattern.hasMatch(name)) {
        return const Left(ValidationFailure('Category name contains invalid characters'));
      }

      return const Right(true);
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> resetToDefaultCategories() async {
    try {
      // 删除所有自定义分类
      await databaseHelper.delete(
        DatabaseConstants.categoryTable,
        where: '${DatabaseConstants.columnId} NOT LIKE ?',
        whereArgs: ['cat_%'],
      );

      // 将所有使用自定义分类的Todo设置为无分类
      await databaseHelper.update(
        DatabaseConstants.todoTable,
        {DatabaseConstants.columnCategoryId: null},
        where: '${DatabaseConstants.columnCategoryId} NOT LIKE ?',
        whereArgs: ['cat_%'],
      );

      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getRecentCategories() async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final result = await databaseHelper.query(
        DatabaseConstants.categoryTable,
        where: '${DatabaseConstants.columnCreatedAt} >= ? AND ${DatabaseConstants.columnId} NOT LIKE ?',
        whereArgs: [sevenDaysAgo.toIso8601String(), 'cat_%'],
        orderBy: '${DatabaseConstants.columnCreatedAt} DESC',
      );

      final categories = result
          .map((categoryMap) => CategoryModel.fromMap(categoryMap).toEntity())
          .toList();

      return Right(categories);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }
}