import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  bool _isCheckingAuth = true; // Cek status login saat app dibuka
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isCheckingAuth => _isCheckingAuth;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _checkAuthState();
  }

  /// Cek apakah user sudah login sebelumnya
  Future<void> _checkAuthState() async {
    _isCheckingAuth = true;
    notifyListeners();
    try {
      _user = await AuthService.checkAuthState();
    } catch (e) {
      _user = null;
    }
    _isCheckingAuth = false;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await AuthService.signIn(email, password);
      if (user != null) {
        _user = user;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = 'Login gagal. Coba lagi.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String npm,
    String role = 'mahasiswa',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await AuthService.register(
        email: email,
        password: password,
        name: name,
        npm: npm,
        role: role,
      );
      if (user != null) {
        _user = user;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = 'Registrasi gagal. Coba lagi.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await AuthService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await AuthService.signOut();
    _user = null;
    notifyListeners();
  }

  Future<bool> updateProfilePhoto(String base64Photo) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await AuthService.updateProfilePhoto(base64Photo);
      _user = AuthService.currentUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui foto profil.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
