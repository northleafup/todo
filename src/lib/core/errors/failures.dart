import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String code;

  const Failure(this.message, this.code);

  @override
  List<Object> get props => [message, code];
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(String message, {String code = 'DATABASE_FAILURE'})
      : super(message, code);
}

class CacheFailure extends Failure {
  const CacheFailure(String message, {String code = 'CACHE_FAILURE'})
      : super(message, code);
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message, {String code = 'NETWORK_FAILURE'})
      : super(message, code);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message, {String code = 'VALIDATION_FAILURE'})
      : super(message, code);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(String message, {String code = 'NOT_FOUND_FAILURE'})
      : super(message, code);
}

class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure(String message,
      {String code = 'PERMISSION_DENIED_FAILURE'})
      : super(message, code);
}

class UnknownFailure extends Failure {
  const UnknownFailure(String message, {String code = 'UNKNOWN_FAILURE'})
      : super(message, code);
}