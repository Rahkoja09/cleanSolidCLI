import 'package:equatable/equatable.dart';

class AuthEntity extends Equatable {
  final String? id;
  final String? email;
  final String? fullName;
  final String? photoUrl;
  final DateTime? createdAt;

  const AuthEntity({
    this.id,
    this.email,
    this.fullName,
    this.photoUrl,
    this.createdAt,
  });

  AuthEntity copyWith({
    String? id,
    String? email,
    String? fullName,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return AuthEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, email, fullName, photoUrl, createdAt];
}