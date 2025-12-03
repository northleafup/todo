import 'package:dartz/dartz.dart';
import '../entities/category.dart';
import '../../core/errors/failures.dart';

abstract class CategoryRepository {
  /// 获取所有分类
  Future<Either<Failure, List<Category>>> getAllCategories();

  /// 根据ID获取分类
  Future<Either<Failure, Category>> getCategoryById(String id);

  /// 根据名称获取分类
  Future<Either<Failure, Category>> getCategoryByName(String name);

  /// 创建新分类
  Future<Either<Failure, Category>> createCategory(Category category);

  /// 更新分类
  Future<Either<Failure, Category>> updateCategory(Category category);

  /// 删除分类
  Future<Either<Failure, void>> deleteCategory(String id);

  /// 检查分类名称是否已存在
  Future<Either<Failure, bool>> isCategoryNameExists(String name, {String? excludeId});

  /// 获取默认分类
  Future<Either<Failure, List<Category>>> getDefaultCategories();

  /// 获取自定义分类
  Future<Either<Failure, List<Category>>> getCustomCategories();

  /// 获取分类及其Todo数量
  Future<Either<Failure, List<Map<String, dynamic>>>> getCategoriesWithTodoCount();

  /// 搜索分类（根据名称）
  Future<Either<Failure, List<Category>>> searchCategories(String query);

  /// 获取分类总数
  Future<Either<Failure, int>> getCategoryCount();

  /// 获取默认分类数量
  Future<Either<Failure, int>> getDefaultCategoryCount();

  /// 获取自定义分类数量
  Future<Either<Failure, int>> getCustomCategoryCount();

  /// 验证分类名称
  Future<Either<Failure, bool>> validateCategoryName(String name);

  /// 重置为默认分类
  Future<Either<Failure, void>> resetToDefaultCategories();

  /// 获取最近创建的分类（最近7天）
  Future<Either<Failure, List<Category>>> getRecentCategories();
}