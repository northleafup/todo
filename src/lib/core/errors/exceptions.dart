abstract class AppException implements Exception {
  final String message;
  final String code;

  const AppException(this.message, this.code);

  @override
  String toString() => 'AppException: $message (Code: $code)';
}

class DatabaseException extends AppException {
  const DatabaseException(String message, {String code = 'DATABASE_ERROR'})
      : super(message, code);
}

class CacheException extends AppException {
  const CacheException(String message, {String code = 'CACHE_ERROR'})
      : super(message, code);
}

class NetworkException extends AppException {
  const NetworkException(String message, {String code = 'NETWORK_ERROR'})
      : super(message, code);
}

class ValidationException extends AppException {
  const ValidationException(String message, {String code = 'VALIDATION_ERROR'})
      : super(message, code);
}

class NotificationException extends AppException {
  const NotificationException(String message, {String code = 'NOTIFICATION_ERROR'})
      : super(message, code);
}

class ReminderException extends AppException {
  const ReminderException(String message, {String code = 'REMINDER_ERROR'})
      : super(message, code);
}

class SyncException extends AppException {
  const SyncException(String message, {String code = 'SYNC_ERROR'})
      : super(message, code);
}

class NotFoundException extends AppException {
  const NotFoundException(String message, {String code = 'NOT_FOUND'})
      : super(message, code);
}

class PermissionDeniedException extends AppException {
  const PermissionDeniedException(String message,
      {String code = 'PERMISSION_DENIED'})
      : super(message, code);
}