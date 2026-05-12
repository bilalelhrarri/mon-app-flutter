import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AppState extends ChangeNotifier {
  UserModel? user;
  bool isLoading = true;

  final AuthService _auth = AuthService();

  AppState() {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    isLoading = true;
    notifyListeners();
    user = await _auth.currentUser();
    isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    isLoading = true;
    notifyListeners();
    user = await _auth.signIn(email, password);
    isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.signOut();
    user = null;
    notifyListeners();
  }
}