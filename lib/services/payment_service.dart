import '../models/payment.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final ApiService _apiService = ApiService();

  Future<ApiResponse<List<Payment>>> getUserPayments() async {
    return await _apiService.get<List<Payment>>(
      ApiConstants.payments,
      fromJson: (dynamic json) => (json as List).map((item) => Payment.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  Future<ApiResponse<Payment>> getPayment(int paymentId) async {
    return await _apiService.get<Payment>(
      '${ApiConstants.payments}/$paymentId',
      fromJson: (dynamic json) => Payment.fromJson(json as Map<String, dynamic>),
    );
  }

  // Create Payment - NEW METHOD for complete flow
  Future<ApiResponse<Map<String, dynamic>>> createPayment(int orderId, String paymentMethod) async {
    return await _apiService.post<Map<String, dynamic>>(
      ApiConstants.payments,
      body: {
        'order_id': orderId,
        'payment_method': paymentMethod,
      },
      fromJson: (dynamic json) {
        print('PaymentService: Create payment response: $json');
        try {
          if (json is Map<String, dynamic>) {
            return json;
          }
          return {};
        } catch (e) {
          print('PaymentService: Error parsing create payment response: $e');
          rethrow;
        }
      },
    );
  }

  // Confirm Payment - CRITICAL METHOD for complete flow
  Future<ApiResponse<Map<String, dynamic>>> confirmPayment(int paymentId) async {
    return await _apiService.put<Map<String, dynamic>>(
      '${ApiConstants.payments}/$paymentId/status',
      body: {
        'payment_status': 'Paid', // KEY: Use "Paid" not "Confirmed"
      },
      fromJson: (dynamic json) {
        print('PaymentService: Confirm payment response: $json');
        try {
          if (json is Map<String, dynamic>) {
            return json;
          }
          return {"message": "Payment status updated successfully"};
        } catch (e) {
          print('PaymentService: Error parsing confirm payment response: $e');
          rethrow;
        }
      },
    );
  }

  // Complete checkout flow - MAIN METHOD
  Future<ApiResponse<Map<String, dynamic>>> completeCheckout({
    required int orderId,
    required String paymentMethod,
  }) async {
    try {
      print('PaymentService: Starting complete checkout flow...');
      
      // Step 1: Create payment
      print('PaymentService: Creating payment for order $orderId with method $paymentMethod');
      final createResponse = await createPayment(orderId, paymentMethod);
      
      if (!createResponse.isSuccess || createResponse.data == null) {
        return ApiResponse.error(createResponse.error ?? 'Failed to create payment');
      }

      final paymentData = createResponse.data!;
      final paymentId = paymentData['payment_id'] as int?;
      
      if (paymentId == null) {
        return ApiResponse.error('No payment_id in response');
      }

      print('PaymentService: Payment created with ID: $paymentId');

      // Step 2: Confirm payment (CRITICAL STEP)
      print('PaymentService: Confirming payment $paymentId');
      final confirmResponse = await confirmPayment(paymentId);
      
      if (!confirmResponse.isSuccess) {
        return ApiResponse.error(confirmResponse.error ?? 'Failed to confirm payment');
      }

      print('PaymentService: Payment confirmed successfully!');

      // Return complete result
      return ApiResponse.success({
        'success': true,
        'order_id': orderId,
        'payment_id': paymentId,
        'transaction_code': paymentData['transaction_code'],
        'amount': paymentData['amount'],
      });

    } catch (e) {
      print('PaymentService: Complete checkout failed: $e');
      return ApiResponse.error('Checkout failed: $e');
    }
  }

  Future<ApiResponse<Payment>> updatePaymentStatus(int paymentId, UpdatePaymentStatusRequest request) async {
    return await _apiService.post<Payment>(
      '${ApiConstants.payments}/$paymentId/update-status',
      body: request.toJson(),
      fromJson: (dynamic json) => Payment.fromJson(json as Map<String, dynamic>),
    );
  }

  // Helper methods
  Future<ApiResponse<Payment>> markPaymentAsPaid(int paymentId) async {
    final request = UpdatePaymentStatusRequest(status: 'Paid');
    return await updatePaymentStatus(paymentId, request);
  }

  Future<ApiResponse<Payment>> markPaymentAsFailed(int paymentId) async {
    final request = UpdatePaymentStatusRequest(status: 'Failed');
    return await updatePaymentStatus(paymentId, request);
  }

  Future<ApiResponse<Payment>> markPaymentAsRefunded(int paymentId) async {
    final request = UpdatePaymentStatusRequest(status: 'Refunded');
    return await updatePaymentStatus(paymentId, request);
  }

  // Filter methods
  Future<ApiResponse<List<Payment>>> getPaymentsByStatus(String status) async {
    final response = await getUserPayments();
    if (response.isSuccess && response.data != null) {
      final filteredPayments = response.data!.where((payment) => payment.status == status).toList();
      return ApiResponse.success(filteredPayments);
    }
    return response;
  }

  Future<ApiResponse<List<Payment>>> getUnpaidPayments() async {
    return await getPaymentsByStatus('Unpaid');
  }

  Future<ApiResponse<List<Payment>>> getPaidPayments() async {
    return await getPaymentsByStatus('Paid');
  }

  Future<ApiResponse<List<Payment>>> getFailedPayments() async {
    return await getPaymentsByStatus('Failed');
  }

  Future<ApiResponse<List<Payment>>> getRefundedPayments() async {
    return await getPaymentsByStatus('Refunded');
  }

  // Payment method helpers
  List<String> getSupportedPaymentMethods() {
    return AppConstants.paymentMethods;
  }

  String getPaymentMethodDisplayName(String paymentMethod) {
    switch (paymentMethod) {
      case 'Momo':
        return 'Ví MoMo';
      case 'COD':
        return 'Thanh toán khi nhận hàng';
      case 'Credit Card':
        return 'Thẻ tín dụng';
      case 'ZaloPay':
        return 'Ví ZaloPay';
      default:
        return paymentMethod;
    }
  }

  bool isOnlinePaymentMethod(String paymentMethod) {
    return ['Momo', 'Credit Card', 'ZaloPay'].contains(paymentMethod);
  }

  bool isCashOnDelivery(String paymentMethod) {
    return paymentMethod == 'COD';
  }
} 