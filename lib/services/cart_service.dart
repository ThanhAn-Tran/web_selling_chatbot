import '../models/cart.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final ApiService _apiService = ApiService();

  Future<ApiResponse<Cart>> getCart() async {
    return await _apiService.get<Cart>(
      ApiConstants.cart,
      fromJson: (json) {
        print('CartService: Raw cart response: $json');
        try {
          if (json is Map<String, dynamic>) {
            return Cart.fromJson(json);
          } else {
            // Return empty cart if no data
            return Cart(
              id: 0,
              items: [],
              totalAmount: 0.0,
            );
          }
        } catch (e) {
          print('CartService: Error parsing cart: $e');
          print('CartService: JSON data: $json');
          return Cart(
            id: 0,
            items: [],
            totalAmount: 0.0,
          );
        }
      },
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> addToCart(AddToCartRequest request) async {
    return await _apiService.post<Map<String, dynamic>>(
      ApiConstants.addToCart,
      body: request.toJson(),
      fromJson: (dynamic json) {
        print('CartService: Add to cart response: $json');
        try {
          if (json is Map<String, dynamic>) {
            return json;
          }
          return {"message": "Item added to cart successfully"};
        } catch (e) {
          print('CartService: Error parsing add to cart response: $e');
          rethrow;
        }
      },
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> updateCartItem(int itemId, UpdateCartItemRequest request) async {
    return await _apiService.put<Map<String, dynamic>>(
      '${ApiConstants.updateCartItem}/$itemId',
      body: request.toJson(),
      fromJson: (dynamic json) {
        print('CartService: Update cart item response: $json');
        try {
          if (json is Map<String, dynamic>) {
            return json;
          }
          return {"message": "Cart item quantity updated successfully"};
        } catch (e) {
          print('CartService: Error parsing update response: $e');
          rethrow;
        }
      },
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> removeCartItem(int itemId) async {
    return await _apiService.delete<Map<String, dynamic>>(
      '${ApiConstants.removeCartItem}/$itemId',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> clearCart() async {
    return await _apiService.delete<Map<String, dynamic>>(
      ApiConstants.clearCart,
    );
  }

  // Helper methods
  Future<ApiResponse<Map<String, dynamic>>> addProductToCart(int productId, int quantity) async {
    final request = AddToCartRequest(productId: productId, quantity: quantity);
    return await addToCart(request);
  }

  Future<ApiResponse<Map<String, dynamic>>> updateCartItemQuantity(int itemId, int quantity) async {
    final request = UpdateCartItemRequest(quantity: quantity);
    return await updateCartItem(itemId, request);
  }

  Future<ApiResponse<Map<String, dynamic>>> incrementCartItem(int itemId, int currentQuantity) async {
    return await updateCartItemQuantity(itemId, currentQuantity + 1);
  }

  Future<ApiResponse<Map<String, dynamic>>> decrementCartItem(int itemId, int currentQuantity) async {
    if (currentQuantity <= 1) {
      return await removeCartItem(itemId);
    }
    return await updateCartItemQuantity(itemId, currentQuantity - 1);
  }

  // Calculate cart totals (kept for backwards compatibility)
  double calculateCartTotal(List<CartItem> cartItems) {
    return cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  int calculateTotalItems(List<CartItem> cartItems) {
    return cartItems.fold(0, (sum, item) => sum + item.quantity);
  }
} 