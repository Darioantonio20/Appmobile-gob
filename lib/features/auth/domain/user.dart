import 'package:flutter/foundation.dart';

/// The logged-in encuestador (field surveyor). Kept intentionally small —
/// add fields here as the real backend's `/auth/me` payload is confirmed.
@immutable
class User {
  const User({required this.id, required this.name, required this.email});

  final String id;
  final String name;
  final String email;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};

  @override
  bool operator ==(Object other) => other is User && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
