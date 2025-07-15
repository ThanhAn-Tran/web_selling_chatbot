import '../models/order.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final ApiService _apiService = ApiService();

  Future<ApiResponse<List<Order>>> getUserOrders() async {
    return await _apiService.get<List<Order>>(
      ApiConstants.orders,
      fromJson: (dynamic json) {
        try {
          if (json is List) {
            return json.map((item) {
              if (item is Map<String, dynamic>) {
                return Order.fromJson(item);
              }
              throw Exception('Invalid order item format');
            }).toList();
          }
          return <Order>[];
        } catch (e) {
          print('OrderService: Error parsing orders: $e');
          return <Order>[];
        }
      },
    );
  }

  Future<ApiResponse<Order>> getOrder(int orderId) async {
    return await _apiService.get<Order>(
      '${ApiConstants.orders}/$orderId',
      fromJson: (dynamic json) => Order.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<Order>> createOrder(CreateOrderRequest request) async {
    return await _apiService.post<Order>(
      ApiConstants.createOrder,
      body: request.toJson(),
      fromJson: (dynamic json) => Order.fromJson(json as Map<String, dynamic>),
    );
  }

  // Create Order From Cart - UPDATED for complete flow
  Future<ApiResponse<int>> createOrderFromCartAndGetId() async {
    return await _apiService.post<int>(
      ApiConstants.createOrder,
      fromJson: (dynamic json) {
        print('OrderService: Create order response: $json');
        try {
          if (json is Map<String, dynamic>) {
            final orderId = json['order_id'] as int?;
            if (orderId != null) {
              print('OrderService: Order created with ID: $orderId');
              return orderId;
            }
          }
          throw Exception('No order_id in response');
        } catch (e) {
          print('OrderService: Error parsing order ID: $e');
          print('OrderService: JSON data: $json');
          rethrow;
        }
      },
    );
  }

  Future<ApiResponse<Order>> updateOrderStatus(int orderId, String status) async {
    return await _apiService.put<Order>(
      '${ApiConstants.orders}/$orderId/status',
      body: {'status': status},
      fromJson: (dynamic json) => Order.fromJson(json as Map<String, dynamic>),
    );
  }

  // Admin methods
  Future<ApiResponse<List<Order>>> getAllOrders({
    int skip = 0,
    int limit = 100,
  }) async {
    return await _apiService.get<List<Order>>(
      ApiConstants.allOrders,
      queryParams: {'skip': skip, 'limit': limit},
      fromJson: (dynamic json) {
        try {
          if (json is List) {
            return json.map((item) {
              if (item is Map<String, dynamic>) {
                return Order.fromJson(item);
              }
              throw Exception('Invalid order item format');
            }).toList();
          }
          return <Order>[];
        } catch (e) {
          print('OrderService: Error parsing all orders: $e');
          return <Order>[];
        }
      },
    );
  }

  // Helper methods
  Future<ApiResponse<Map<String, dynamic>>> createOrderFromCartRaw() async {
    return await _apiService.post<Map<String, dynamic>>(
      ApiConstants.createOrder,
      fromJson: (dynamic json) {
        print('OrderService: Raw order response: $json');
        print('OrderService: Response type: ${json.runtimeType}');
        return json as Map<String, dynamic>;
      },
    );
  }

  Future<ApiResponse<Order>> createOrderFromCart() async {
    return await _apiService.post<Order>(
      ApiConstants.createOrder,
      fromJson: (dynamic json) {
        print('OrderService: Raw order response: $json');
        try {
          return Order.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          print('OrderService: Error parsing Order: $e');
          print('OrderService: JSON data: $json');
          rethrow;
        }
      },
    );
  }

  Future<ApiResponse<Order>> cancelOrder(int orderId) async {
    final request = UpdateOrderStatusRequest(status: 'Cancelled');
    return await updateOrderStatus(orderId, request.status);
  }

  Future<ApiResponse<Order>> markOrderAsProcessing(int orderId) async {
    final request = UpdateOrderStatusRequest(status: 'Processing');
    return await updateOrderStatus(orderId, request.status);
  }

  Future<ApiResponse<Order>> markOrderAsShipped(int orderId) async {
    final request = UpdateOrderStatusRequest(status: 'Shipped');
    return await updateOrderStatus(orderId, request.status);
  }

  Future<ApiResponse<Order>> markOrderAsDelivered(int orderId) async {
    final request = UpdateOrderStatusRequest(status: 'Delivered');
    return await updateOrderStatus(orderId, request.status);
  }

  // Filter and search methods
  Future<ApiResponse<List<Order>>> getOrdersByStatus(String status) async {
    final response = await getUserOrders();
    if (response.isSuccess && response.data != null) {
      final filteredOrders = response.data!.where((order) => order.status == status).toList();
      return ApiResponse.success(filteredOrders);
    }
    return response;
  }

  Future<ApiResponse<List<Order>>> getPendingOrders() async {
    return await getOrdersByStatus('Pending');
  }

  Future<ApiResponse<List<Order>>> getProcessingOrders() async {
    return await getOrdersByStatus('Processing');
  }

  Future<ApiResponse<List<Order>>> getDeliveredOrders() async {
    return await getOrdersByStatus('Delivered');
  }
} 