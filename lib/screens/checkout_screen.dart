import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/loading_overlay.dart';
import '../services/checkout_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  String _selectedPaymentMethod = AppConstants.paymentMethods.first;
  
  final CheckoutService _checkoutService = CheckoutService();
  bool _isProcessing = false;
  int? _currentOrderId; // Store order ID after creation
  bool _orderCreated = false; // Track if order has been created
  Map<String, dynamic>? _orderSummary; // Store order details

  @override
  void initState() {
    super.initState();
    // User address not supported in simplified model
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _loadUserData();
    // });
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  // Address field not supported in simplified User model
  // void _loadUserData() {
  //   final authProvider = Provider.of<AuthProvider>(context, listen: false);
  //   if (authProvider.user?.address != null) {
  //     _addressController.text = authProvider.user!.address;
  //   }
  // }

  String _getPaymentMethodDisplayName(String method) {
    return _checkoutService.getPaymentMethodDisplayName(method);
  }

  Icon _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'COD':
        return const Icon(Icons.local_shipping, color: Colors.orange);
      case 'Momo':
        return const Icon(Icons.account_balance_wallet, color: Colors.pink);
      case 'Credit Card':
        return const Icon(Icons.credit_card, color: Colors.blue);
      case 'ZaloPay':
        return const Icon(Icons.payment, color: Colors.cyan);
      default:
        return const Icon(Icons.payment);
    }
  }

  void _createOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    if (cartProvider.isEmpty) {
      _showMessage('Giỏ hàng trống. Vui lòng thêm sản phẩm trước khi đặt hàng.', isError: true);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Store cart summary before order creation (since cart will be cleared)
      final cartSummary = {
        'items': cartProvider.cartItems.map((item) => {
          'name': item.productName,
          'quantity': item.quantity,
          'price': item.price,
          'total': item.total,
        }).toList(),
        'totalAmount': cartProvider.totalAmount,
        'totalItems': cartProvider.totalItems,
      };

      final response = await _checkoutService.createOrderOnly();
      
      if (response.isSuccess && response.data != null) {
        setState(() {
          _currentOrderId = response.data!;
          _orderCreated = true;
          _orderSummary = cartSummary;
        });
        
        _showMessage('✅ Đặt hàng thành công! Order ID: ${response.data}');
        
        // Refresh cart to show it's cleared
        await cartProvider.refreshCart();
      } else {
        _showMessage(response.error ?? 'Đặt hàng thất bại. Vui lòng thử lại.', isError: true);
      }
    } catch (e) {
      _showMessage('Lỗi hệ thống: $e', isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _processPayment() async {
    if (_currentOrderId == null || !_orderCreated) {
      _showMessage('Vui lòng đặt hàng trước khi thanh toán!', isError: true);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final response = await _checkoutService.processPayment(
        orderId: _currentOrderId!,
        paymentMethod: _selectedPaymentMethod,
      );
      
      if (response.isSuccess && response.data != null) {
        final result = response.data!;
        
        _showMessage('🎉 Thanh toán thành công!');
        
        // Navigate to success page with details
        context.pushReplacement('/payment-success', extra: {
          'orderId': result['order_id'],
          'paymentId': result['payment_id'],
          'transactionCode': result['transaction_code'],
          'amount': result['amount'],
        });
      } else {
        _showMessage(response.error ?? 'Thanh toán thất bại. Vui lòng thử lại.', isError: true);
      }
    } catch (e) {
      _showMessage('Lỗi thanh toán: $e', isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_orderCreated ? 'Thanh toán đơn hàng' : 'Đặt hàng'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer3<CartProvider, OrderProvider, AuthProvider>(
        builder: (context, cartProvider, orderProvider, authProvider, child) {
          return LoadingOverlay(
            isLoading: _isProcessing,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Status - Show if order created
                    if (_orderCreated && _currentOrderId != null) 
                      _buildOrderCreatedStatus(),
                    
                    // Order Summary - Show cart items or created order
                    if (!_orderCreated) 
                      _buildCartSummary(cartProvider)
                    else 
                      _buildOrderSummary(),
                    
                    const SizedBox(height: 24),

                    // Shipping Address - Show always
                    _buildShippingAddress(),
                    const SizedBox(height: 24),

                    // Payment Method - Show only after order created
                    if (_orderCreated) ...[
                      _buildPaymentMethodSection(),
                      const SizedBox(height: 24),
                    ],

                    // Order Notes - Show always
                    _buildOrderNotes(),
                    const SizedBox(height: 120), // Space for bottom buttons
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Total amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng thanh toán:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    _orderCreated 
                        ? '${_orderSummary?['totalAmount']?.toStringAsFixed(0) ?? '0'}đ'
                        : cartProvider.formattedTotalAmount,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Action button - Changes based on state
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _getButtonAction(cartProvider),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _orderCreated ? Colors.green : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _getButtonText(),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  VoidCallback? _getButtonAction(CartProvider cartProvider) {
    if (_isProcessing) return null;
    
    if (!_orderCreated) {
      // Step 1: Create Order button
      return cartProvider.isEmpty ? null : _createOrder;
    } else {
      // Step 2: Payment button
      return _processPayment;
    }
  }

  String _getButtonText() {
    if (!_orderCreated) {
      return 'Đặt hàng';
    } else {
      return 'Thanh toán với ${_getPaymentMethodDisplayName(_selectedPaymentMethod)}';
    }
  }

  Widget _buildOrderCreatedStatus() {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 12),
            const Text(
              '✅ Đặt hàng thành công!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mã đơn hàng: #$_currentOrderId',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.payment, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Bước tiếp theo: Chọn phương thức thanh toán để hoàn tất đơn hàng',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(CartProvider cartProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🛒 Giỏ hàng của bạn',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (cartProvider.isEmpty) 
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Giỏ hàng trống',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            else
              ...cartProvider.cartItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.productName} x${item.quantity}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        item.formattedTotalPrice,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            if (!cartProvider.isEmpty) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tổng cộng (${cartProvider.totalItems} sản phẩm):',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    cartProvider.formattedTotalAmount,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    if (_orderSummary == null) return const SizedBox.shrink();
    
    final items = _orderSummary!['items'] as List<dynamic>;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📋 Đơn hàng #$_currentOrderId',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item['name']} x${item['quantity']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      '${item['total'].toStringAsFixed(0)}đ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng cộng (${_orderSummary!['totalItems']} sản phẩm):',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_orderSummary!['totalAmount'].toStringAsFixed(0)}đ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payment, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Chọn phương thức thanh toán',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...AppConstants.paymentMethods.map((method) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _selectedPaymentMethod == method ? Colors.blue[100] : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedPaymentMethod == method ? Colors.blue : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: RadioListTile<String>(
                  title: Row(
                    children: [
                      _getPaymentMethodIcon(method),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getPaymentMethodDisplayName(method),
                          style: TextStyle(
                            fontWeight: _selectedPaymentMethod == method 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  value: method,
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value!;
                    });
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  activeColor: Colors.blue,
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingAddress() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Địa chỉ giao hàng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ giao hàng',
                hintText: 'Nhập địa chỉ chi tiết để giao hàng',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              enabled: !_orderCreated, // Disable after order created
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập địa chỉ giao hàng';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderNotes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lưu ý đặt hàng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Quy trình đặt hàng:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('1. Đặt hàng → Tạo đơn hàng và xóa giỏ hàng'),
                  const Text('2. Chọn phương thức thanh toán'),
                  const Text('3. Thanh toán → Xác nhận đơn hàng và trừ kho'),
                  const Text('4. Thời gian giao hàng: 3-7 ngày làm việc'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 