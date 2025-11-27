import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role; // 'admin' or 'staff'
  final String fullName;
  final String phone;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.fullName,
    required this.phone,
    required this.isActive,
    required this.createdAt,
    this.lastLogin,
  });

  // Factory constructor to create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'staff',
      fullName: data['fullName'] ?? '',
      phone: data['phone'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLogin: data['lastLogin'] != null
          ? (data['lastLogin'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'fullName': fullName,
      'phone': phone,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
    };
  }

  // Check if user is admin
  bool get isAdmin => role == 'admin';

  // Check if user is staff
  bool get isStaff => role == 'staff';

  // Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? role,
    String? fullName,
    String? phone,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}

