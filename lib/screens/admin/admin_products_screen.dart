import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await Future.wait([
      productProvider.loadProducts(),
      productProvider.loadCategories(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          // Debug Test Button
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _testToggleStatus,
            tooltip: 'Test Toggle Status (Debug)',
          ),
          // Raw API Test Button
          IconButton(
            icon: const Icon(Icons.api),
            onPressed: _testRawAPICall,
            tooltip: 'Test Raw API Call',
          ),
                      IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showCreateProductDialog,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Consumer2<AuthProvider, ProductProvider>(
        builder: (context, authProvider, productProvider, child) {
          if (!authProvider.isAdmin) {
            return const Center(
              child: Text('Access Denied - Admin Only'),
            );
          }

          if (productProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (productProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${productProvider.error}'),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (productProvider.products.isEmpty) {
            return const Center(
              child: Text('No products found'),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: productProvider.products.length,
              itemBuilder: (context, index) {
                final product = productProvider.products[index];
                return _buildProductTile(product, productProvider);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateProductDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProductTile(Product product, ProductProvider productProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: product.safeIsActive ? Colors.green : Colors.red,
          child: Icon(
            product.safeIsActive ? Icons.check : Icons.lock,
            color: Colors.white,
          ),
        ),
        title: Text(product.name),
        subtitle: Text('${product.price.toStringAsFixed(0)}đ - Stock: ${product.safeStockQuantity}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditProductDialog(product);
                break;
              case 'toggle':
                _toggleProductStatus(product);
                break;
              case 'delete':
                _deleteProduct(product.id);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(
              value: 'toggle',
              child: Text(product.safeIsActive ? 'Lock' : 'Unlock'),
            ),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateProductDialog() async {
    await showDialog(
      context: context,
      builder: (context) => _ProductFormDialog(
        title: 'Create Product',
        onSave: _createProduct,
      ),
    );
  }

  Future<void> _showEditProductDialog(Product product) async {
    await showDialog(
      context: context,
      builder: (context) => _ProductFormDialog(
        title: 'Edit Product',
        product: product,
        onSave: (productData) => _updateProduct(product.id, productData),
      ),
    );
  }

  Future<void> _createProduct(Map<String, dynamic> productData) async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    final request = CreateProductRequest(
      name: productData['name'] as String,
      description: productData['description'] as String? ?? '',
      price: productData['price'] as double,
      imageUrl: productData['imageUrl'] as String? ?? '',
      categoryId: productData['categoryId'] as int,
      stock: productData['stockQuantity'] as int,
      isLocked: false,
    );

    final success = await productProvider.createProduct(request);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Product created successfully' : productProvider.error ?? 'Failed to create product'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _updateProduct(int productId, Map<String, dynamic> productData) async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    // Find the existing product to preserve the isLocked status
    final existingProduct = productProvider.products.firstWhere((p) => p.id == productId);
    
    final request = UpdateProductRequest(
      name: productData['name'] as String,
      description: productData['description'] as String? ?? '',
      price: productData['price'] as double,
      imageUrl: productData['imageUrl'] as String? ?? '',
      categoryId: productData['categoryId'] as int,
      stock: productData['stockQuantity'] as int,
      isLocked: !existingProduct.safeIsActive,
    );

    final success = await productProvider.updateProduct(productId, request);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Product updated successfully' : productProvider.error ?? 'Failed to update product'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteProduct(int productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final success = await productProvider.deleteProduct(productId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Product deleted successfully' : productProvider.error ?? 'Failed to delete product'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleProductStatus(Product product) async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final success = await productProvider.toggleProductStatus(product.id, !product.safeIsActive);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Product status updated' : productProvider.error ?? 'Failed to update status'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _testToggleStatus() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await _loadData();
    if (productProvider.products.isNotEmpty) {
      print('🧪 TEST: About to test toggle status...');
      print('🧪 TEST: Available products: ${productProvider.products.length}');
      print('🧪 TEST: First product: ${productProvider.products[0].name}');
      print('🧪 TEST: Current status: ${productProvider.products[0].safeIsActive}');
      
      await _toggleProductStatus(productProvider.products[0]);
    } else {
      print('❌ TEST: No products available for testing');
    }
  }

  // Add a simple raw API test
  Future<void> _testRawAPICall() async {
    print('🧪 RAW API TEST: Starting...');
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    if (productProvider.products.isNotEmpty) {
      final product = productProvider.products[0];
      print('🧪 RAW API TEST: Testing with product ${product.id}: ${product.name}');
      
      // Create minimal request
      final minimalRequest = UpdateProductRequest(
        isLocked: product.safeIsActive, // isLocked is inverse of isActive
      );
      
      print('🧪 RAW API TEST: Minimal request created');
      final success = await productProvider.updateProduct(product.id, minimalRequest);
      print('🧪 RAW API TEST: Result: $success');
      
      if (!success) {
        print('❌ RAW API TEST: Failed - ${productProvider.error}');
      }
    }
  }
}

class _ProductFormDialog extends StatefulWidget {
  final String title;
  final Product? product;
  final Function(Map<String, dynamic>) onSave;

  const _ProductFormDialog({
    required this.title,
    this.product,
    required this.onSave,
  });

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _stockController = TextEditingController();
  int _selectedCategoryId = 1;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.safeDescription;
      _priceController.text = widget.product!.price.toString();
      _imageUrlController.text = widget.product!.imageUrl ?? '';
      _stockController.text = widget.product!.safeStockQuantity.toString();
      _selectedCategoryId = widget.product!.safeCategoryId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Price is required';
                  if (double.tryParse(value!) == null) return 'Invalid price';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Stock is required';
                  if (int.tryParse(value!) == null) return 'Invalid stock';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL (optional)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'name': _nameController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'stockQuantity': int.parse(_stockController.text),
        'imageUrl': _imageUrlController.text,
        'categoryId': _selectedCategoryId,
      });
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _stockController.dispose();
    super.dispose();
  }
} 