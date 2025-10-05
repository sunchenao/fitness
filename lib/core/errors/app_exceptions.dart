abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code, super.originalError});
}

class SensorException extends AppException {
  const SensorException(super.message, {super.code, super.originalError});
}

class PermissionException extends AppException {
  const PermissionException(super.message, {super.code, super.originalError});
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.originalError});
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});
}

class ExerciseException extends AppException {
  const ExerciseException(super.message, {super.code, super.originalError});
}

// 错误处理工具类
class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    } else if (error is Exception) {
      return error.toString();
    } else {
      return '未知错误: $error';
    }
  }

  static AppException handleError(dynamic error) {
    if (error is AppException) {
      return error;
    } else if (error.toString().contains('database')) {
      return DatabaseException('数据库操作失败', originalError: error);
    } else if (error.toString().contains('sensor')) {
      return SensorException('传感器访问失败', originalError: error);
    } else if (error.toString().contains('permission')) {
      return PermissionException('权限访问被拒绝', originalError: error);
    } else if (error.toString().contains('network') || error.toString().contains('connection')) {
      return NetworkException('网络连接失败', originalError: error);
    } else {
      return AppException('操作失败', originalError: error);
    }
  }
}