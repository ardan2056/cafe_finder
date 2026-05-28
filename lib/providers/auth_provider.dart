import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _userEmail;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get userEmail => _userEmail;

  Future<void> login({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 700));

    _userEmail = email;
    _isLoggedIn = true;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> register({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 900));

    _userEmail = email;
    _isLoggedIn = true;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 400));

    _userEmail = null;
    _isLoggedIn = false;
    _isLoading = false;
    notifyListeners();
  }
}
