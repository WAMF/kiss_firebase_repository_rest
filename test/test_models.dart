import 'package:googleapis/firestore/v1.dart';
import 'package:kiss_firebase_repository_rest/kiss_firebase_repository_rest.dart';
import 'package:meta/meta.dart';

/// Test model for a simple user object
@immutable
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.age,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      age: json['age'] as int?,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : null,
    );
  }

  final String id;
  final String name;
  final String email;
  final int? age;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (age != null) 'age': age,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    int? age,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.age == age &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, email, age, createdAt);
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, age: $age, createdAt: $createdAt)';
  }
}

/// Test converters for User model
class UserFirestoreConverters {
  static Document toFirestore(User user, String? id) {
    return RepositoryFirestoreRestApi.fromJson(json: user.toJson(), id: id);
  }

  static User fromFirestore(Document document) {
    final json = RepositoryFirestoreRestApi.toJson(document);
    return User.fromJson(json);
  }
}
