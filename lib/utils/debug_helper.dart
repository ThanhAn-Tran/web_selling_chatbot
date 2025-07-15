import 'package:flutter/foundation.dart';

class DebugHelper {
  static void log(String message) {
    if (kDebugMode) {
      print('[DEBUG] $message');
    }
  }

  static void logAuthState(String action, {String? username, int? role, bool? isLoggedIn}) {
    if (kDebugMode) {
      print('[AUTH] $action - Username: $username, Role: $role, LoggedIn: $isLoggedIn');
    }
  }

  static void logNavigation(String from, String to) {
    if (kDebugMode) {
      print('[NAV] $from -> $to');
    }
  }

  static void logApiCall(String endpoint, String method, {int? statusCode, String? error}) {
    if (kDebugMode) {
      print('[API] $method $endpoint - Status: $statusCode, Error: $error');
    }
  }
} 