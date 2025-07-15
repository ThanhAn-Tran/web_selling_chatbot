import 'package:flutter/foundation.dart';
import '../models/cart.dart';
import '../models/product.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService = CartService();

  Cart? _cart;
  bool _isLoading = false;
  String? _error;
  
  // Loading state flags
  bool _cartLoaded = false;
  bool _cartLoading = false;

  Cart? get cart => _cart;
  List<CartItem> get cartItems => _cart?.items ?? [];
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalItems => _cart?.totalItems ?? 0;
  double get totalAmount => _cart?.totalAmount ?? 0.0;
  String get formattedTotalAmount => _cart?.formattedTotalAmount ?? '0đ';
  bool get isEmpty => _cart?.isEmpty ?? true;

  Future<void> loadCart() async {
    if (_cartLoaded || _cartLoading) return;
    
    _setLoading(true);
    _cartLoading = true;
    _clearError();

    final response = await _cartService.getCart();
    
    if (response.isSuccess && response.data != null) {
      _cart = response.data!;
      _cartLoaded = true;
    } else {
      _setError(response.error ?? 'Failed to load cart');
    }
    
    _cartLoading = false;
    _setLoading(false);
  }

  Future<void> refreshCart() async {
    _cartLoaded = false;
    await loadCart();
  }

  Future<bool> addToCart(int productId, int quantity) async {
    _clearError();

    // Optimistic update - show immediate feedback in UI
    _optimisticallyAddToCart(productId, quantity);

    final response = await _cartService.addProductToCart(productId, quantity);
    
    if (response.isSuccess) {
      // Refresh with actual server data
      await refreshCart();
      return true;
    } else {
      // Rollback optimistic update on error
      await refreshCart();
      _setError(response.error ?? 'Failed to add item to cart');
      return false;
    }
  }

  Future<bool> updateCartItemQuantity(int itemId, int quantity) async {
    _clearError();

    // Find the item for optimistic update
    final itemIndex = cartItems.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) return false;

    final originalQuantity = cartItems[itemIndex].quantity;
    
    // Optimistic update
    _optimisticallyUpdateQuantity(itemId, quantity);

    final response = await _cartService.updateCartItemQuantity(itemId, quantity);
    
    if (response.isSuccess) {
      // Refresh with actual server data
      await refreshCart();
      return true;
    } else {
      // Rollback optimistic update
      _optimisticallyUpdateQuantity(itemId, originalQuantity);
      _setError(response.error ?? 'Failed to update cart item');
      return false;
    }
  }

  Future<bool> incrementItem(int itemId) async {
    final item = cartItems.firstWhere((item) => item.id == itemId);
    return await updateCartItemQuantity(itemId, item.quantity + 1);
  }

  Future<bool> decrementItem(int itemId) async {
    final item = cartItems.firstWhere((item) => item.id == itemId);
    
    if (item.quantity <= 1) {
      return await removeItem(itemId);
    } else {
      return await updateCartItemQuantity(itemId, item.quantity - 1);
    }
  }

  Future<bool> removeItem(int itemId) async {
    _clearError();

    // Find item for optimistic removal
    final itemIndex = cartItems.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) return false;

    final removedItem = cartItems[itemIndex];
    
    // Optimistic removal
    _optimisticallyRemoveItem(itemId);

    final response = await _cartService.removeCartItem(itemId);
    
    if (response.isSuccess) {
      // Server confirmed removal, keep UI as is
      await refreshCart();
      return true;
    } else {
      // Rollback - restore the item
      _optimisticallyRestoreItem(removedItem, itemIndex);
      _setError(response.error ?? 'Failed to remove item from cart');
      return false;
    }
  }

  Future<bool> clearCart() async {
    _setLoading(true);
    _clearError();

    final response = await _cartService.clearCart();
    
    if (response.isSuccess) {
      _cart = Cart(id: 0, items: [], totalAmount: 0.0);
      _setLoading(false);
      return true;
    } else {
      _setError(response.error ?? 'Failed to clear cart');
      _setLoading(false);
      return false;
    }
  }

  // Helper methods
  bool isProductInCart(int productId) {
    return cartItems.any((item) => item.productId == productId);
  }

  CartItem? getCartItemByProductId(int productId) {
    try {
      return cartItems.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  int getProductQuantityInCart(int productId) {
    final item = getCartItemByProductId(productId);
    return item?.quantity ?? 0;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  /// Manually updates the cart state from chatbot response to avoid a network call
  void updateCartFromChatbot(List<Product> products) {
    _setLoading(true);
    _clearError();

    try {
      final cartItems = products.map((product) {
        // The chatbot response might not have all cart-specific fields,
        // so we create CartItem with the available product data.
        final itemTotal = product.subtotal ?? (product.price * (product.quantity ?? 1));
        return CartItem(
          id: product.id, // Assuming product ID can be used as item ID temporarily
          productId: product.id,
          productName: product.name,
          quantity: product.quantity ?? 1,
          price: product.price,
          imageUrl: product.imageUrl,
          total: itemTotal,
        );
      }).toList();

      final totalAmount = cartItems.fold<double>(0.0, (sum, item) => sum + item.total);

      _cart = Cart(
        id: _cart?.id ?? 0, // Preserve existing cart ID if available
        items: cartItems,
        totalAmount: totalAmount,
      );

      _cartLoaded = true; // Mark cart as loaded
    } catch (e) {
      _setError('Failed to update cart from chatbot: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods for optimistic updates
  void _optimisticallyAddToCart(int productId, int quantity) {
    if (_cart == null) return;

    // Check if product already in cart
    final existingItemIndex = _cart!.items.indexWhere((item) => item.productId == productId);
    
    if (existingItemIndex != -1) {
      // Create new CartItem with updated quantity
      final existingItem = _cart!.items[existingItemIndex];
      final newQuantity = existingItem.quantity + quantity;
      final newTotal = existingItem.price * newQuantity;
      
      final updatedItem = CartItem(
        id: existingItem.id,
        productId: existingItem.productId,
        productName: existingItem.productName,
        price: existingItem.price,
        quantity: newQuantity,
        total: newTotal,
        imageUrl: existingItem.imageUrl,
      );
      
      _cart!.items[existingItemIndex] = updatedItem;
    } else {
      // Add new item (simplified - in real implementation you'd need product details)
      print('Optimistically adding new product $productId (quantity: $quantity)');
      // Note: For full implementation, you'd need to pass Product data or fetch it
    }
    
    _updateCartTotal();
    notifyListeners();
  }

  void _optimisticallyUpdateQuantity(int itemId, int newQuantity) {
    if (_cart == null) return;

    final itemIndex = _cart!.items.indexWhere((item) => item.id == itemId);
    if (itemIndex != -1) {
      if (newQuantity <= 0) {
        _cart!.items.removeAt(itemIndex);
      } else {
        final existingItem = _cart!.items[itemIndex];
        final newTotal = existingItem.price * newQuantity;
        
        final updatedItem = CartItem(
          id: existingItem.id,
          productId: existingItem.productId,
          productName: existingItem.productName,
          price: existingItem.price,
          quantity: newQuantity,
          total: newTotal,
          imageUrl: existingItem.imageUrl,
        );
        
        _cart!.items[itemIndex] = updatedItem;
      }
      _updateCartTotal();
      notifyListeners();
    }
  }

  void _optimisticallyRemoveItem(int itemId) {
    if (_cart == null) return;

    _cart!.items.removeWhere((item) => item.id == itemId);
    _updateCartTotal();
    notifyListeners();
  }

  void _optimisticallyRestoreItem(CartItem item, int index) {
    if (_cart == null) return;

    _cart!.items.insert(index, item);
    _updateCartTotal();
    notifyListeners();
  }

  void _updateCartTotal() {
    if (_cart == null) return;
    
    final newTotal = _cart!.items.fold<double>(
      0.0,
      (sum, item) => sum + item.total,
    );
    
    // Create new Cart with updated total
    _cart = Cart(
      id: _cart!.id,
      items: _cart!.items,
      totalAmount: newTotal,
    );
  }
} 