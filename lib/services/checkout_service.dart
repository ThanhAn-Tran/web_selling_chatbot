import 'order_service.dart';
import 'payment_service.dart';
import 'cart_service.dart';
import 'api_service.dart';

class CheckoutService {
  static final CheckoutService _instance = CheckoutService._internal();
  factory CheckoutService() => _instance;
  CheckoutService._internal();

  final OrderService _orderService = OrderService();
  final PaymentService _paymentService = PaymentService();
  final CartService _cartService = CartService();

  /// Complete checkout flow: Cart → Order → Payment → Stock Reduction
  /// 
  /// Steps:
  /// 1. Create order from cart (cart items → order items, cart cleared)
  /// 2. Create payment for the order
  /// 3. Confirm payment (this triggers stock reduction and order confirmation)
  /// 
  /// Returns success result with order_id, payment_id, and transaction_code
  Future<ApiResponse<Map<String, dynamic>>> completeCheckout({
    required String paymentMethod,
    String? shippingAddress,
  }) async {
    try {
      print('CheckoutService: Starting complete checkout flow...');
      
      // Step 1: Create order from cart
      print('CheckoutService: Creating order from cart...');
      final orderResponse = await _orderService.createOrderFromCartAndGetId();
      
      if (!orderResponse.isSuccess || orderResponse.data == null) {
        return ApiResponse.error(orderResponse.error ?? 'Failed to create order');
      }
      
      final orderId = orderResponse.data!;
      print('CheckoutService: Order created successfully with ID: $orderId');
      
      // Step 2 & 3: Create and confirm payment (PaymentService handles both)
      print('CheckoutService: Processing payment...');
      final paymentResponse = await _paymentService.completeCheckout(
        orderId: orderId,
        paymentMethod: paymentMethod,
      );
      
      if (!paymentResponse.isSuccess || paymentResponse.data == null) {
        return ApiResponse.error(paymentResponse.error ?? 'Payment processing failed');
      }
      
      final result = paymentResponse.data!;
      print('CheckoutService: ✅ Complete checkout successful!');
      print('CheckoutService: Order ID: ${result['order_id']}');
      print('CheckoutService: Payment ID: ${result['payment_id']}');
      print('CheckoutService: Transaction Code: ${result['transaction_code']}');
      
      return ApiResponse.success({
        'success': true,
        'message': 'Checkout completed successfully',
        'order_id': result['order_id'],
        'payment_id': result['payment_id'],
        'transaction_code': result['transaction_code'],
        'amount': result['amount'],
      });
      
    } catch (e) {
      print('CheckoutService: ❌ Complete checkout failed: $e');
      return ApiResponse.error('Checkout failed: $e');
    }
  }

  /// Create order only (for "Đặt hàng" button)
  Future<ApiResponse<int>> createOrderOnly() async {
    try {
      print('CheckoutService: Creating order only...');
      final response = await _orderService.createOrderFromCartAndGetId();
      
      if (response.isSuccess && response.data != null) {
        print('CheckoutService: ✅ Order created with ID: ${response.data}');
      }
      
      return response;
    } catch (e) {
      print('CheckoutService: ❌ Create order failed: $e');
      return ApiResponse.error('Failed to create order: $e');
    }
  }

  /// Process payment for existing order (for "Thanh Toán" button)
  Future<ApiResponse<Map<String, dynamic>>> processPayment({
    required int orderId,
    required String paymentMethod,
  }) async {
    try {
      print('CheckoutService: Processing payment for order $orderId...');
      final response = await _paymentService.completeCheckout(
        orderId: orderId,
        paymentMethod: paymentMethod,
      );
      
      if (response.isSuccess && response.data != null) {
        print('CheckoutService: ✅ Payment processed successfully');
      }
      
      return response;
    } catch (e) {
      print('CheckoutService: ❌ Process payment failed: $e');
      return ApiResponse.error('Payment processing failed: $e');
    }
  }

  /// Get cart summary for checkout validation
  Future<bool> hasCartItems() async {
    try {
      final cartResponse = await _cartService.getCart();
      if (cartResponse.isSuccess && cartResponse.data != null) {
        return cartResponse.data!.items.isNotEmpty;
      }
      return false;
    } catch (e) {
      print('CheckoutService: Error checking cart: $e');
      return false;
    }
  }

  /// Helper method to get supported payment methods
  List<String> getSupportedPaymentMethods() {
    return _paymentService.getSupportedPaymentMethods();
  }

  /// Helper method to get payment method display name
  String getPaymentMethodDisplayName(String method) {
    return _paymentService.getPaymentMethodDisplayName(method);
  }

  /// Helper method to check if payment method is online
  bool isOnlinePaymentMethod(String method) {
    return _paymentService.isOnlinePaymentMethod(method);
  }
} 