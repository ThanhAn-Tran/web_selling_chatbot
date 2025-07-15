import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/order_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/loading_overlay.dart';
import '../models/order.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.isAdmin) {
      await orderProvider.loadAllOrders();
    } else {
      await orderProvider.loadUserOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Chờ xử lý'),
            Tab(text: 'Đang xử lý'),
            Tab(text: 'Đã gửi'),
            Tab(text: 'Đã giao'),
            Tab(text: 'Đã hủy'),
          ],
        ),
      ),
      body: Consumer2<OrderProvider, AuthProvider>(
        builder: (context, orderProvider, authProvider, child) {
          return LoadingOverlay(
            isLoading: orderProvider.isLoading,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(authProvider.isAdmin ? orderProvider.allOrders : orderProvider.orders),
                _buildOrderList(authProvider.isAdmin ? orderProvider.getAllPendingOrders() : orderProvider.getPendingOrders()),
                _buildOrderList(authProvider.isAdmin ? orderProvider.getAllProcessingOrders() : orderProvider.getProcessingOrders()),
                _buildOrderList(authProvider.isAdmin ? orderProvider.getAllShippedOrders() : orderProvider.getShippedOrders()),
                _buildOrderList(authProvider.isAdmin ? orderProvider.getAllDeliveredOrders() : orderProvider.getDeliveredOrders()),
                _buildOrderList(orderProvider.getCancelledOrders()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderList(List<Order> orders) {
    if (orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Không có đơn hàng nào',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _OrderCard(
            order: order,
            onTap: () => context.go('/order/${order.id}'),
            onStatusUpdate: (newStatus) async {
              final orderProvider = Provider.of<OrderProvider>(context, listen: false);
              await orderProvider.updateOrderStatus(order.id, newStatus);
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  final Function(String) onStatusUpdate;

  const _OrderCard({
    required this.order,
    required this.onTap,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đơn hàng #${order.id}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt ?? DateTime.now()),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(order.status),
                ],
              ),
              const SizedBox(height: 12),

              // Order Items Summary
              Text(
                '${order.totalItems} sản phẩm',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),

              // Payment Method and Total
              Row(
                children: [
                  Icon(
                    _getPaymentIcon(order.paymentMethod ?? 'COD'),
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getPaymentMethodDisplayName(order.paymentMethod ?? 'COD'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    order.formattedTotalAmount,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Shipping Address
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.shippingAddress ?? 'Không có địa chỉ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Admin Actions
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (!authProvider.isAdmin || order.isCancelled || order.isDelivered) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    children: [
                      const SizedBox(height: 12),
                      const Divider(),
                      Row(
                        children: [
                          if (order.isPending) ...[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => onStatusUpdate('Processing'),
                                child: const Text('Xử lý'),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (order.isProcessing) ...[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => onStatusUpdate('Shipped'),
                                child: const Text('Giao hàng'),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (order.isShipped) ...[
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => onStatusUpdate('Delivered'),
                                child: const Text('Đã giao'),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (order.canCancel)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _showCancelDialog(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Hủy'),
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case 'Pending':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
      case 'Processing':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        break;
      case 'Shipped':
        backgroundColor = Colors.purple[100]!;
        textColor = Colors.purple[800]!;
        break;
      case 'Delivered':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case 'Cancelled':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getStatusDisplayName(status),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'Pending':
        return 'Chờ xử lý';
      case 'Processing':
        return 'Đang xử lý';
      case 'Shipped':
        return 'Đã gửi';
      case 'Delivered':
        return 'Đã giao';
      case 'Cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  IconData _getPaymentIcon(String paymentMethod) {
    switch (paymentMethod) {
      case 'COD':
        return Icons.local_shipping;
      case 'Momo':
        return Icons.account_balance_wallet;
      case 'Credit Card':
        return Icons.credit_card;
      case 'ZaloPay':
        return Icons.payment;
      default:
        return Icons.payment;
    }
  }

  String _getPaymentMethodDisplayName(String method) {
    switch (method) {
      case 'COD':
        return 'COD';
      case 'Momo':
        return 'MoMo';
      case 'Credit Card':
        return 'Thẻ tín dụng';
      case 'ZaloPay':
        return 'ZaloPay';
      default:
        return method;
    }
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hủy đơn hàng'),
          content: Text('Bạn có chắc chắn muốn hủy đơn hàng #${order.id}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Không'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onStatusUpdate('Cancelled');
              },
              child: const Text('Hủy đơn hàng', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
} 