import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UserModel?> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user != null) {
        final userModel = await _getUserFromFirestore(result.user!.uid);
        print('✅ signIn success, user: ${userModel?.role}');
        return userModel;
      }
    } catch (e) {
      print('❌ Login error: $e');
    }
    return null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> currentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      return await _getUserFromFirestore(user.uid);
    }
    return null;
  }

  Future<UserModel?> _getUserFromFirestore(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      print('📄 Document exists: ${doc.exists}');
      print('📄 Document data: ${doc.data()}');
      if (doc.exists) {
        return UserModel.fromMap(uid, doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('❌ Firestore error: $e');
    }
    return null;
  }
}