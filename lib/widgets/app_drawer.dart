import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      authProvider.user?.displayName ?? 'Khách hàng',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      authProvider.user?.roleDisplayName ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Trang chủ'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/');
                },
              ),
              ListTile(
                leading: const Icon(Icons.inventory_2),
                title: const Text('Sản phẩm'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/products');
                },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_cart),
                title: const Text('Giỏ hàng'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/cart');
                },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_bag),
                title: const Text('Đơn hàng'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/orders');
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat),
                title: const Text('Trợ lý AI'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/chat');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Hồ sơ'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/profile');
                },
              ),
              if (authProvider.isAdmin) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: const Text('Quản trị'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/admin');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.inventory),
                  title: const Text('Quản lý sản phẩm'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/admin/products');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.list_alt),
                  title: const Text('Quản lý đơn hàng'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/admin/orders');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Quản lý người dùng'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/admin/users');
                  },
                ),
              ],
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Đăng xuất',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await authProvider.logout();
                  context.go('/login');
                },
              ),
            ],
          );
        },
      ),
    );
  }
} 