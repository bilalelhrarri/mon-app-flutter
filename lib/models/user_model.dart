import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final String gateId;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.gateId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'role': role,
        'gateId': gateId,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory UserModel.fromMap(String id, Map<String, dynamic> map) => UserModel(
        uid: id,
        email: map['email'] ?? '',
        displayName: map['displayName'] ?? '',
        role: map['role'] ?? 'operator',
        gateId: map['gateId'] ?? 'G01',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}