import 'package:flutter/material.dart';

class OrderDetailScreen extends StatelessWidget {
  final int orderId;
  
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng'),
      ),
      body: Center(
        child: Text(
          'Order Detail Screen\nOrder ID: $orderId\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
} 