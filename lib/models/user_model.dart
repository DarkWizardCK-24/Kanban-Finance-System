import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String uid;
  final String name;
  final String email;
  final String phone;
  final DateTime dateOfBirth;
  final int age;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.dateOfBirth,
    required this.age,
    required this.createdAt,
    required this.updatedAt,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  static int calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final dob = (map['dateOfBirth'] as Timestamp).toDate();
    return UserModel(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      dateOfBirth: dob,
      age: calculateAge(dob),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'age': age,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
  }) {
    final dob = dateOfBirth ?? this.dateOfBirth;
    return UserModel(
      id: id,
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dob,
      age: calculateAge(dob),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
