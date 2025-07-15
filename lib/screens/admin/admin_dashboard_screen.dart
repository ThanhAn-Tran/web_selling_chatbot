import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/order_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAdminAccess();
      _loadDashboardData();
    });
  }

  void _checkAdminAccess() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAdmin) {
      context.go('/');
      return;
    }
  }

  Future<void> _loadDashboardData() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    await Future.wait([
      productProvider.loadProducts(),
      productProvider.loadCategories(),
      orderProvider.loadAllOrders(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAdmin) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Truy cập bị từ chối'),
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.security, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Bạn không có quyền truy cập trang này',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          );
        }

    return Scaffold(
      appBar: AppBar(
            title: const Text('Admin Dashboard'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/'),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await authProvider.logout();
                  if (mounted) {
                    context.go('/login');
                  }
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _loadDashboardData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xin chào, ${authProvider.user?.username ?? 'Admin'}!',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Chào mừng bạn đến với trang quản trị',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Stats
                  const Text(
                    'Thống kê nhanh',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Consumer2<ProductProvider, OrderProvider>(
                    builder: (context, productProvider, orderProvider, child) {
                      return Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Sản phẩm',
                              '${productProvider.products.length}',
                              Icons.inventory,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Đơn hàng',
                              '${orderProvider.allOrders.length}',
                              Icons.shopping_cart,
                              Colors.green,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions
                  const Text(
                    'Quản lý',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _buildActionCard(
                        'Quản lý sản phẩm',
                        'Thêm, sửa, xóa sản phẩm',
                        Icons.inventory_2,
                        Colors.blue,
                        () => context.go('/admin/products'),
                      ),
                      _buildActionCard(
                        'Quản lý đơn hàng',
                        'Xem và cập nhật đơn hàng',
                        Icons.assignment,
                        Colors.green,
                        () => context.go('/admin/orders'),
                      ),
                      _buildActionCard(
                        'Quản lý người dùng',
                        'Xem danh sách người dùng',
                        Icons.people,
                        Colors.orange,
                        () => context.go('/admin/users'),
                      ),
                      _buildActionCard(
                        'Về trang chủ',
                        'Quay lại trang chủ',
                        Icons.home,
                        Colors.purple,
                        () => context.go('/'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
          textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 