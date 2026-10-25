import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String username;
  final String displayName;
  final String? email;
  final String? avatarUrl;

  const UserEntity({
    required this.id,
    required this.username,
    required this.displayName,
    this.email,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [id, username, displayName, email, avatarUrl];
}
