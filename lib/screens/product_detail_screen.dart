import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:badges/badges.dart' as badges;

import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/product_card.dart';
import '../models/product.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProduct();
    });
  }

  @override
  void didUpdateWidget(ProductDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if the product ID has changed
    if (oldWidget.productId != widget.productId) {
      // Reset quantity when switching to a new product
      _quantity = 1;
      // Use post frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadProduct();
      });
    }
  }

  Future<void> _loadProduct() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await productProvider.loadProduct(widget.productId);
    
    // Load related products from the same category
    if (productProvider.selectedProduct != null) {
      final product = productProvider.selectedProduct!;
      await productProvider.loadProductsByCategory(product.safeCategoryId);
    }
  }

  void _addToCart() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    if (productProvider.selectedProduct == null) return;

    final product = productProvider.selectedProduct!;
    
    // Enhanced validation: Check both stock and lock status
    if (!product.isInStock) {
      _showSnackBar(
        'Sản phẩm đã hết hàng',
        Colors.red,
        Icons.inventory_2,
      );
      return;
    }
    
    if (!product.safeIsActive) {
      _showSnackBar(
        'Sản phẩm này đã bị khóa và không thể mua',
        Colors.orange,
        Icons.lock,
      );
      return;
    }
    
    print('🛒 DEBUG: Adding product ${product.id} to cart - Quantity: $_quantity - Status: ${product.statusText}');
    
    // Add haptic feedback
    HapticFeedback.lightImpact();
    
    final success = await cartProvider.addToCart(product.id, _quantity);
    
    if (mounted) {
    if (success) {
        _showSnackBar(
          'Đã thêm ${product.name} vào giỏ hàng',
          Colors.green,
          Icons.check_circle,
        );
        // Reset quantity after successful add
        setState(() {
          _quantity = 1;
        });
      } else {
        _showSnackBar(
          'Không thể thêm sản phẩm vào giỏ hàng',
          Colors.red,
          Icons.error,
        );
      }
    }
  }

  void _showSnackBar(String message, Color color, IconData icon) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildBreadcrumb(Product product, ProductProvider productProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Reduced padding
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/'),
            child: Text(
              'Trang chủ',
              style: TextStyle(
                color: Colors.blue[600],
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => context.go('/products'),
            child: Text(
              'Sản phẩm',
              style: TextStyle(
                color: Colors.blue[600],
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              product.name,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    return Container(
      width: double.infinity,
      height: 200, // Fixed compact height
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8), // Reduced margins
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildSmartImage(product),
      ),
    );
  }

  Widget _buildSmartImage(Product product) {
    final imageUrl = product.imageUrl?.trim();
    
    // Check if imageUrl is null, empty, or the string "null"
    if (imageUrl == null || imageUrl.isEmpty || imageUrl.toLowerCase() == 'null') {
      return _buildPlaceholderImage(product);
    }

    // Try to load the image with adaptive sizing
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      placeholder: (context, url) => _buildLoadingImage(),
      errorWidget: (context, url, error) {
        return _buildPlaceholderImage(product);
      },
      httpHeaders: const {
        'User-Agent': 'Mozilla/5.0',
      },
    );
  }

  Widget _buildImageError(Product product, String errorMessage) {
    return _buildPlaceholderImage(product);
  }

  Widget _buildLoadingImage() {
    return Container(
      color: Colors.grey[50],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Đang tải hình ảnh...',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(Product product) {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              product.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Chưa có hình ảnh',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInfo(Product product, ProductProvider productProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Name
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 8),

            // Category
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                productProvider.getCategoryName(product.safeCategoryId),
                style: const TextStyle(
                  color: Color(0xFF1976D2),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Price and Stock
            Row(
              children: [
                Text(
                  product.formattedPrice,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const Spacer(),
                _buildStockBadge(product),
              ],
            ),

            const SizedBox(height: 20),

            // Description
            const Text(
              'Mô tả sản phẩm',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.safeDescription,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 20),

            // Product Information (only real data)
            if (product.sku != null || product.safeColor != 'N/A' || product.safeStyle != 'N/A')
              _buildProductSpecs(product),
          ],
          ),
        ),
      );
  }

  Widget _buildStockBadge(Product product) {
    Color backgroundColor;
    Color textColor;
    String text;
    IconData icon;

    if (!product.safeIsActive) {
      backgroundColor = Colors.orange[100]!;
      textColor = Colors.orange[800]!;
      text = 'Đã khóa';
      icon = Icons.lock;
    } else if (!product.isInStock) {
      backgroundColor = Colors.red[100]!;
      textColor = Colors.red[800]!;
      text = 'Hết hàng';
      icon = Icons.inventory_2;
    } else if (product.safeStockQuantity <= 5) {
      backgroundColor = Colors.orange[100]!;
      textColor = Colors.orange[800]!;
      text = 'Còn ít (${product.safeStockQuantity})';
      icon = Icons.warning;
    } else {
      backgroundColor = Colors.green[100]!;
      textColor = Colors.green[800]!;
      text = 'Còn hàng (${product.safeStockQuantity})';
      icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSpecs(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin chi tiết',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (product.sku != null)
                _buildSpecRow('Mã sản phẩm', product.sku!),
              if (product.safeColor != 'N/A')
                _buildSpecRow('Màu sắc', product.safeColor),
              if (product.safeStyle != 'N/A')
                _buildSpecRow('Phong cách', product.safeStyle),
              _buildSpecRow('Số lượng tồn', '${product.safeStockQuantity} sản phẩm'),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          const Text(' : '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
        ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Smart back navigation
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        actions: [
          // Only cart button - no duplicate home button
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              return badges.Badge(
                badgeContent: Text(
                  cartProvider.totalItems.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                showBadge: cartProvider.totalItems > 0,
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () => context.go('/cart'),
                  tooltip: 'Giỏ hàng',
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading) {
            return const LoadingOverlay(
              isLoading: true,
              child: SizedBox.expand(),
            );
          }

          final product = productProvider.selectedProduct;
          if (product == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Không tìm thấy sản phẩm',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.home),
                    label: const Text('Về trang chủ'),
                  ),
                ],
              ),
            );
          }

          final relatedProducts = productProvider.filteredProducts
              .where((p) => p.id != product.id && p.categoryId == product.categoryId)
              .take(4)
              .toList();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumb navigation
                _buildBreadcrumb(product, productProvider),
                
                // Product Image (single image only)
                _buildProductImage(product),
                
                // Product Information
                _buildProductInfo(product, productProvider),
                
                // Quantity Selector (only if available for purchase)
                if (product.isAvailableForPurchase)
                Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        const Text(
                          'Chọn số lượng',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: _quantity > 1 ? () {
                                      setState(() {
                                        _quantity--;
                                      });
                                    } : null,
                                    icon: const Icon(Icons.remove),
                                  ),
                                  Container(
                                    width: 50,
                                    alignment: Alignment.center,
                                    child: Text(
                                      _quantity.toString(),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _quantity < product.safeStockQuantity ? () {
                                      setState(() {
                                        _quantity++;
                                      });
                                    } : null,
                                    icon: const Icon(Icons.add),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Còn ${product.safeStockQuantity} sản phẩm',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Locked product warning
                if (!product.safeIsActive)
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      border: Border.all(color: Colors.orange[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock, color: Colors.orange[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sản phẩm này hiện đang bị khóa và không thể mua',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Related Products (only real data)
                if (relatedProducts.isNotEmpty)
                  Container(
                    color: Colors.grey[50],
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sản phẩm liên quan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 280,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: relatedProducts.length,
                            itemBuilder: (context, index) {
                              final relatedProduct = relatedProducts[index];
                              return Container(
                                width: 200,
                                margin: const EdgeInsets.only(right: 12),
                                child: ProductCard(
                                  product: relatedProduct,
                                  onTap: () {
                                    context.go('/product/${relatedProduct.id}');
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Bottom spacing
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      
      // Simple bottom bar (only if product is available)
      bottomNavigationBar: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          final product = productProvider.selectedProduct;
          if (product == null || !product.isAvailableForPurchase) {
            return const SizedBox.shrink();
          }

          return Container(
            padding: const EdgeInsets.all(16),
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
            child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(
                          'Tổng: ${_quantity} x ${product.formattedPrice}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      Text(
                        '${(product.price * _quantity).toStringAsFixed(0)}đ',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _addToCart,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text(
                      'Thêm vào giỏ',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
              ),
            ),
          );
        },
      ),
    );
  }
} 