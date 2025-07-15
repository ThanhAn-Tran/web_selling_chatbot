import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  @JsonKey(name: 'user_id')
  final int id;
  final String username;
  final int role; // 1=Customer, 3=Admin
  final String? email;  // Now from API
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  User({
    required this.id,
    required this.username,
    required this.role,
    this.email,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  String get roleDisplayName {
    switch (role) {
      case 1:
        return 'Customer';
      case 3:
        return 'Admin';
      default:
        return 'Unknown';
    }
  }

  bool get isAdmin => role == 3;
  bool get isCustomer => role == 1;
  
  // Provide default values for UI display
  String get displayName => username;
  String get fullName => isAdmin ? 'Administrator' : 'Customer';
  String get phone => '';
  String get address => '';
}

@JsonSerializable()
class LoginRequest {
  final String username;
  final String password;

  LoginRequest({
    required this.username,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) => _$LoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class RegisterRequest {
  final String username;
  final String password;
  final int role;

  RegisterRequest({
    required this.username,
    required this.password,
    this.role = 1, // Default to Customer
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) => _$RegisterRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

@JsonSerializable()
class LoginResponse {
  @JsonKey(name: 'access_token')
  final String accessToken;
  @JsonKey(name: 'token_type')
  final String tokenType;
  final User? user;  // User object is nested

  LoginResponse({
    required this.accessToken,
    required this.tokenType,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => _$LoginResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);

  // Helper getters for backward compatibility
  int? get userId => user?.id;
  int? get role => user?.role;
} 