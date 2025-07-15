import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedCategoryId;

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

  List<Product> _getFilteredProducts(List<Product> products) {
    var filtered = products;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) =>
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.safeDescription.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Filter by category
    if (_selectedCategoryId != null) {
      filtered = filtered.where((product) => product.categoryId == _selectedCategoryId).toList();
    }

    // Only show active products
    filtered = filtered.where((product) => product.safeIsActive).toList();

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sản phẩm'),
        automaticallyImplyLeading: false,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              return IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.shopping_cart),
                    if (cartProvider.totalItems > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            cartProvider.totalItems > 99 ? '99+' : '${cartProvider.totalItems}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                  onPressed: () => context.go('/cart'),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (productProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${productProvider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final filteredProducts = _getFilteredProducts(productProvider.products);

          return Column(
            children: [
              // Search and Filter Section
              Container(
                padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                    TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm sản phẩm...',
                      prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                                  setState(() => _searchQuery = '');
                        },
                              )
                            : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                        ),
                    const SizedBox(height: 12),
                        
                        // Category Filter
                    if (productProvider.categories.isNotEmpty)
                      DropdownButtonFormField<int?>(
                        value: _selectedCategoryId,
                          decoration: InputDecoration(
                          labelText: 'Danh mục',
                            border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: [
                          const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Tất cả danh mục'),
                            ),
                            ...productProvider.categories.map((category) {
                            return DropdownMenuItem<int?>(
                              value: category.id,
                                child: Text(category.name),
                              );
                          }),
                          ],
                          onChanged: (value) {
                          setState(() => _selectedCategoryId = value);
                        },
                      ),
                  ],
                        ),
              ),

              // Results Count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                          children: [
                    Text(
                      'Tìm thấy ${filteredProducts.length} sản phẩm',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                              ),
                            ),
                    const Spacer(),
                    if (_searchQuery.isNotEmpty || _selectedCategoryId != null)
                      TextButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _selectedCategoryId = null;
                          });
                        },
                        child: const Text('Xóa bộ lọc'),
                            ),
                          ],
                        ),
              ),

              // Products Grid
              Expanded(
                child: filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty || _selectedCategoryId != null
                                  ? 'Không tìm thấy sản phẩm phù hợp'
                                  : 'Chưa có sản phẩm nào',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                    onRefresh: _loadData,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                              childAspectRatio: 0.75,
                            ),
                          itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              return ProductCard(
                              product: filteredProducts[index],
                              onTap: () => context.go('/product/${filteredProducts[index].id}'),
                              );
                            },
                          ),
                  ),
                ),
              ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 