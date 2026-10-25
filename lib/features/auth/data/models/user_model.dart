import 'package:flutter/foundation.dart';

/// Typed User entity matching backend Better Auth and /api/v1/auth/me contract.
@immutable
class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'MEMBER',
    this.emailVerified = false,
    this.image,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final bool emailVerified;
  final String? image;
  final DateTime? createdAt;

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isMember => role.toUpperCase() == 'MEMBER';
  bool get isStaff =>
      role.toUpperCase() == 'STAFF' || role.toUpperCase() == 'TECHNICIAN';
  bool get isStaffOrAdmin => isAdmin || isStaff;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['createdAt'] != null) {
      parsedDate = DateTime.tryParse(json['createdAt'].toString());
    }

    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
      role: (json['role'] as String? ?? 'MEMBER').toUpperCase(),
      emailVerified: json['emailVerified'] as bool? ?? false,
      image: json['image'] as String?,
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'emailVerified': emailVerified,
      'image': image,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    bool? emailVerified,
    String? image,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      emailVerified: emailVerified ?? this.emailVerified,
      image: image ?? this.image,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          role == other.role;

  @override
  int get hashCode => Object.hash(id, name, email, role);

  @override
  String toString() =>
      'UserModel(id: $id, name: $name, email: $email, role: $role)';
}
