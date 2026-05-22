import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

enum UserRole { trainer, member }

@immutable
class User extends Equatable {
  const User({
    required this.id,
    required this.role,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.assignedTrainerId,
  });

  final String id;
  final UserRole role;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? assignedTrainerId;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        role: UserRole.values.firstWhere(
          (r) => r.name == json['role'],
          orElse: () => UserRole.member,
        ),
        name: json['name'] as String,
        email: json['email'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        assignedTrainerId: json['assignedTrainerId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
        'assignedTrainerId': assignedTrainerId,
      };

  User copyWith({
    String? id,
    UserRole? role,
    String? name,
    String? email,
    String? avatarUrl,
    String? assignedTrainerId,
  }) =>
      User(
        id: id ?? this.id,
        role: role ?? this.role,
        name: name ?? this.name,
        email: email ?? this.email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        assignedTrainerId: assignedTrainerId ?? this.assignedTrainerId,
      );

  @override
  List<Object?> get props => [id, role, name, email, avatarUrl, assignedTrainerId];
}
