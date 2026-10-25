import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}

class LoginWithEmailEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginWithEmailEvent({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class RegisterWithEmailEvent extends AuthEvent {
  final String username;
  final String email;
  final String password;
  final String displayName;

  const RegisterWithEmailEvent({
    required this.username,
    required this.email,
    required this.password,
    required this.displayName,
  });

  @override
  List<Object?> get props => [username, email, password, displayName];
}

class SignInWithGoogleEvent extends AuthEvent {
  final String? idToken;
  final String? email;
  final String? displayName;
  final String? avatarUrl;

  const SignInWithGoogleEvent({
    this.idToken,
    this.email,
    this.displayName,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [idToken, email, displayName, avatarUrl];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}
