import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure(this.message, [this.statusCode]);

  @override
  List<Object?> get props => [message, statusCode];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'A server error occurred.', super.statusCode]);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed.', super.statusCode]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Please check your internet connection.', super.statusCode]);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Unable to read or write local cache.', super.statusCode]);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation failed.', super.statusCode]);
}
