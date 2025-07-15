import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../widgets/loading_overlay.dart';
import '../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    context.go('/login');
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;
          
          if (user == null) {
            return const Center(
              child: Text('Không thể tải thông tin người dùng'),
            );
          }

          return LoadingOverlay(
            isLoading: authProvider.isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Profile Header
                  _buildProfileHeader(user),
                  const SizedBox(height: 32),

                  // Account Actions
                  _buildAccountActions(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue[100],
              child: Text(
                user.username[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.displayName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '@${user.username}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: user.isAdmin ? Colors.red[100] : Colors.blue[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user.isAdmin ? 'Quản trị viên' : 'Khách hàng',
                style: TextStyle(
                  color: user.isAdmin ? Colors.red[800] : Colors.blue[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tài khoản ID: ${user.id}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActions() {
    return Column(
      children: [
        // Quick Actions
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.shopping_bag, color: Colors.blue),
                title: const Text('Đơn hàng của tôi'),
                subtitle: const Text('Xem lịch sử đặt hàng'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => context.go('/orders'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.shopping_cart, color: Colors.green),
                title: const Text('Giỏ hàng'),
                subtitle: const Text('Xem giỏ hàng hiện tại'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => context.go('/cart'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.chat, color: Colors.orange),
                title: const Text('Trợ lý AI'),
                subtitle: const Text('Chat với trợ lý mua sắm'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => context.go('/chat'),
              ),
              // Admin only section
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (!authProvider.isAdmin) return const SizedBox.shrink();
                  
                  return Column(
                    children: [
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.admin_panel_settings, color: Colors.red),
                        title: const Text('Quản trị'),
                        subtitle: const Text('Truy cập bảng điều khiển admin'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => context.go('/admin'),
                      ),

                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Account Settings
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.security, color: Colors.grey),
                title: const Text('Bảo mật'),
                subtitle: const Text('Thay đổi mật khẩu'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tính năng sẽ được cập nhật sớm')),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications, color: Colors.grey),
                title: const Text('Thông báo'),
                subtitle: const Text('Cài đặt thông báo'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tính năng sẽ được cập nhật sớm')),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.help, color: Colors.grey),
                title: const Text('Trợ giúp'),
                subtitle: const Text('Hướng dẫn sử dụng'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tính năng sẽ được cập nhật sớm')),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Logout Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showLogoutDialog,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
} 