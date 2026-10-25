import 'package:bookies/domain/entities/user_entity.dart';

class User {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;

  User({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
  });

  UserEntity toDomain() => UserEntity(
        id: id,
        username: username,
        displayName: displayName,
        avatarUrl: avatarUrl,
      );

  factory User.fromDomain(UserEntity entity) => User(
        id: entity.id,
        username: entity.username,
        displayName: entity.displayName,
        avatarUrl: entity.avatarUrl,
      );

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
    };
  }
}
