import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();

  Future<ApiResponse<LoginResponse>> login(LoginRequest request) async {
    final response = await _apiService.post<LoginResponse>(
      ApiConstants.login,
      body: request.toJson(),
      includeAuth: false,
      fromJson: (dynamic json) => LoginResponse.fromJson(json as Map<String, dynamic>),
    );
    
    if (response.isSuccess && response.data != null) {
      print('AuthService: Login successful for user: ${response.data!.user?.username}');
    }
    
    return response;
  }

  Future<ApiResponse<Map<String, dynamic>>> register(RegisterRequest request) async {
    return await _apiService.post<Map<String, dynamic>>(
      ApiConstants.register,
      body: request.toJson(),
      includeAuth: false,
    );
  }

  Future<void> saveAuthData(LoginResponse loginResponse) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, loginResponse.accessToken);
    
    // Handle nullable userId and role
    if (loginResponse.userId != null) {
      await prefs.setInt(AppConstants.userIdKey, loginResponse.userId!);
    }
    if (loginResponse.role != null) {
      await prefs.setInt(AppConstants.userRoleKey, loginResponse.role!);
    }
    
    print('AuthService: Saved - UserID: ${loginResponse.userId}, Role: ${loginResponse.role}');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey) != null;
  }

  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.userIdKey);
  }

  Future<int?> getCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.userRoleKey);
  }

  Future<bool> isAdmin() async {
    final role = await getCurrentUserRole();
    return role == AppConstants.adminRole;
  }

  Future<bool> isCustomer() async {
    final role = await getCurrentUserRole();
    return role == AppConstants.customerRole;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.userRoleKey);
  }

  // Admin-only methods
  Future<ApiResponse<List<User>>> getAllUsers({
    int skip = 0,
    int limit = 100,
  }) async {
    return await _apiService.get<List<User>>(
      ApiConstants.users,
      queryParams: {'skip': skip, 'limit': limit},
      fromJson: (dynamic json) {
        try {
          if (json is List) {
            return json.map((item) {
              if (item is Map<String, dynamic>) {
                return User.fromJson(item);
              }
              throw Exception('Invalid user item format');
            }).toList();
          }
          return <User>[];
        } catch (e) {
          print('AuthService: Error parsing users: $e');
          return <User>[];
        }
      },
    );
  }
} 