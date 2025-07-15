import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _error;
  bool _disposed = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get error => _error;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isCustomer => _user?.isCustomer ?? false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> checkAuthStatus() async {
    _setLoading(true);
    _isLoggedIn = await _authService.isLoggedIn();
    
    if (_isLoggedIn) {
      // Create basic user from stored data if available
      final userId = await _authService.getCurrentUserId();
      final userRole = await _authService.getCurrentUserRole();
      
      if (userId != null && userRole != null) {
        _user = User(
          id: userId,
          username: 'User', // Placeholder
          role: userRole,
        );
        print('AuthProvider: Restored user from storage - ID: $userId, Role: $userRole');
      }
    }
    
    _setLoading(false);
    _safeNotifyListeners();
  }

  Future<bool> login(String username, String password) async {
    if (_isLoading) return false;

    _setLoading(true);
    _error = null;

    try {
      final loginRequest = LoginRequest(username: username, password: password);
      final response = await _authService.login(loginRequest);

      if (response.isSuccess && response.data != null) {
        final loginResponse = response.data!;
        
        // Save auth data
        await _authService.saveAuthData(loginResponse);
        
        // Use the User object from the response
        if (loginResponse.user != null) {
          _user = loginResponse.user!;
          _isLoggedIn = true;
          
          _setLoading(false);
          _safeNotifyListeners();
          return true;
        } else {
          _error = 'Thông tin người dùng không hợp lệ';
          _setLoading(false);
          _safeNotifyListeners();
          return false;
        }
      } else {
        _error = response.error ?? 'Đăng nhập thất bại';
        _setLoading(false);
        _safeNotifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Lỗi kết nối: $e';
      _setLoading(false);
      _safeNotifyListeners();
      return false;
    }
  }

  Future<bool> register(RegisterRequest request) async {
    _setLoading(true);
    _clearError();

    final response = await _authService.register(request);
    
    if (response.isSuccess) {
      _setLoading(false);
      return true;
    } else {
      _setError(response.error ?? 'Registration failed');
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _isLoggedIn = false;
    _clearError();
    _safeNotifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    _safeNotifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _safeNotifyListeners();
  }

  void _clearError() {
    _error = null;
    _safeNotifyListeners();
  }

  void clearError() {
    _clearError();
  }
} 