import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();

  List<Order> _orders = [];
  List<Order> _allOrders = []; // For admin view
  Order? _selectedOrder;
  bool _isLoading = false;
  String? _error;

  List<Order> get orders => _orders;
  List<Order> get allOrders => _allOrders;
  Order? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUserOrders() async {
    _setLoading(true);
    _clearError();

    final response = await _orderService.getUserOrders();
    
    if (response.isSuccess && response.data != null) {
      _orders = response.data!;
    } else {
      _setError(response.error ?? 'Failed to load orders');
    }
    
    _setLoading(false);
  }

  Future<void> loadOrder(int orderId) async {
    _setLoading(true);
    _clearError();

    final response = await _orderService.getOrder(orderId);
    
    if (response.isSuccess && response.data != null) {
      _selectedOrder = response.data;
    } else {
      _setError(response.error ?? 'Failed to load order');
    }
    
    _setLoading(false);
  }

  Future<bool> createOrder({
    required String shippingAddress,
    required String paymentMethod,
  }) async {
    _setLoading(true);
    _clearError();

    // First, let's see what the raw response looks like
    final rawResponse = await _orderService.createOrderFromCartRaw();
    
    if (rawResponse.isSuccess && rawResponse.data != null) {
      print('OrderProvider: Got raw response: ${rawResponse.data}');
      _setLoading(false);
      return true;
    } else {
      _setError(rawResponse.error ?? 'Failed to create order');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> cancelOrder(int orderId) async {
    _setLoading(true);
    _clearError();

    final response = await _orderService.cancelOrder(orderId);
    
    if (response.isSuccess && response.data != null) {
      _updateOrderInList(response.data!);
      _setLoading(false);
      return true;
    } else {
      _setError(response.error ?? 'Failed to cancel order');
      _setLoading(false);
      return false;
    }
  }

  // Admin methods
  Future<void> loadAllOrders() async {
    _setLoading(true);
    _clearError();

    final response = await _orderService.getAllOrders();
    
    if (response.isSuccess && response.data != null) {
      _allOrders = response.data!;
    } else {
      _setError(response.error ?? 'Failed to load all orders');
    }
    
    _setLoading(false);
  }

  Future<bool> updateOrderStatus(int orderId, String status) async {
    _setLoading(true);
    _clearError();

    final response = await _orderService.updateOrderStatus(
      orderId,
      status,
    );
    
    if (response.isSuccess && response.data != null) {
      _updateOrderInList(response.data!);
      _updateOrderInAllOrders(response.data!);
      _setLoading(false);
      return true;
    } else {
      _setError(response.error ?? 'Failed to update order status');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> markOrderAsProcessing(int orderId) async {
    return await updateOrderStatus(orderId, 'Processing');
  }

  Future<bool> markOrderAsShipped(int orderId) async {
    return await updateOrderStatus(orderId, 'Shipped');
  }

  Future<bool> markOrderAsDelivered(int orderId) async {
    return await updateOrderStatus(orderId, 'Delivered');
  }

  // Filter methods
  List<Order> getOrdersByStatus(String status) {
    return _orders.where((order) => order.status == status).toList();
  }

  List<Order> getPendingOrders() {
    return getOrdersByStatus('Pending');
  }

  List<Order> getProcessingOrders() {
    return getOrdersByStatus('Processing');
  }

  List<Order> getShippedOrders() {
    return getOrdersByStatus('Shipped');
  }

  List<Order> getDeliveredOrders() {
    return getOrdersByStatus('Delivered');
  }

  List<Order> getCancelledOrders() {
    return getOrdersByStatus('Cancelled');
  }

  // Admin filter methods
  List<Order> getAllOrdersByStatus(String status) {
    return _allOrders.where((order) => order.status == status).toList();
  }

  List<Order> getAllPendingOrders() {
    return getAllOrdersByStatus('Pending');
  }

  List<Order> getAllProcessingOrders() {
    return getAllOrdersByStatus('Processing');
  }

  List<Order> getAllShippedOrders() {
    return getAllOrdersByStatus('Shipped');
  }

  List<Order> getAllDeliveredOrders() {
    return getAllOrdersByStatus('Delivered');
  }

  // Helper methods
  Order? getOrderById(int orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  void _updateOrderInList(Order updatedOrder) {
    final index = _orders.indexWhere((order) => order.id == updatedOrder.id);
    if (index != -1) {
      _orders[index] = updatedOrder;
    }
    
    if (_selectedOrder?.id == updatedOrder.id) {
      _selectedOrder = updatedOrder;
    }
    
    notifyListeners();
  }

  void _updateOrderInAllOrders(Order updatedOrder) {
    final index = _allOrders.indexWhere((order) => order.id == updatedOrder.id);
    if (index != -1) {
      _allOrders[index] = updatedOrder;
    }
    
    notifyListeners();
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
} 