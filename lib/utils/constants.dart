class ApiConstants {
  static const String baseUrl = 'http://localhost:8000';
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  
  // User endpoints
  static const String userProfile = '/users/profile';
  static const String users = '/users';
  
  // Category endpoints
  static const String categories = '/categories';
  
  // Product endpoints
  static const String products = '/products';
  
  // Admin-specific endpoints
  static const String adminUsers = '/admin/users';
  static const String adminProducts = '/admin/products';
  static const String adminOrders = '/admin/orders';
  static const String adminCategories = '/admin/categories';
  static const String adminStats = '/admin/stats';
  
  // Cart endpoints - Updated to match new API
  static const String cart = '/cart';
  static const String addToCart = '/cart/items';
  static const String updateCartItem = '/cart/items';
  static const String removeCartItem = '/cart/items';
  static const String clearCart = '/cart/clear';
  
  // Order endpoints
  static const String orders = '/orders';
  static const String createOrder = '/orders';
  static const String allOrders = '/orders';
  
  // Payment endpoints
  static const String payments = '/payments';
  
  // Chatbot endpoints
  static const String chatbotChat = '/chatbot/chat';
  static const String chatbotHistory = '/chatbot/history';
  static const String chatbotSearch = '/chatbot/product-search';
  static const String chatbotAddToCart = '/chatbot/add-to-cart';
  static const String chatbotCart = '/chatbot/cart-contents';
  static const String chatbotQuickChat = '/chatbot/quick-chat';
  static const String chatbotReset = '/chatbot/reset';
}

class AppConstants {
  static const String appName = 'E-Commerce Shop';
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  
  // Payment methods
  static const List<String> paymentMethods = [
    'COD',
    'Momo',
    'Credit Card',
    'ZaloPay',
  ];
  
  // Order statuses
  static const List<String> orderStatuses = [
    'Pending',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled',
  ];
  
  // Payment statuses
  static const List<String> paymentStatuses = [
    'Unpaid',
    'Paid',
    'Failed',
    'Refunded',
  ];
  
  // User roles
  static const int customerRole = 1;
  static const int adminRole = 3;
} 