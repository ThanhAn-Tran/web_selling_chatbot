import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/category.dart' as models;
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();

  List<Product> _products = [];
  List<models.Category> _categories = [];
  List<Product> _filteredProducts = [];
  Product? _selectedProduct;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  int? _selectedCategoryId;
  double? _minPrice;
  double? _maxPrice;
  
  // Loading state flags
  bool _categoriesLoaded = false;
  bool _featuredProductsLoaded = false;
  bool _categoriesLoading = false;
  bool _featuredProductsLoading = false;

  List<Product> get products => _products;
  List<models.Category> get categories => _categories;
  List<Product> get filteredProducts => _filteredProducts;
  Product? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  int? get selectedCategoryId => _selectedCategoryId;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;

  Future<void> loadProducts() async {
    _setLoading(true);
    _clearError();

    final response = await _productService.getProducts();
    
    if (response.isSuccess && response.data != null) {
      _products = response.data!;
      _filteredProducts = _products;
    } else {
      _setError(response.error ?? 'Failed to load products');
    }
    
    _setLoading(false);
  }

  Future<void> loadCategories() async {
    if (_categoriesLoaded || _categoriesLoading) return;
    
    _categoriesLoading = true;
    final response = await _productService.getCategories();
    
    if (response.isSuccess && response.data != null) {
      _categories = response.data!;
      _categoriesLoaded = true;
      notifyListeners();
    }
    _categoriesLoading = false;
  }

  Future<void> loadProduct(int productId) async {
    _setLoading(true);
    _clearError();

    final response = await _productService.getProduct(productId);
    
    if (response.isSuccess && response.data != null) {
      _selectedProduct = response.data;
    } else {
      _setError(response.error ?? 'Failed to load product');
    }
    
    _setLoading(false);
  }

  Future<void> searchProducts({
    String? search,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
  }) async {
    _setLoading(true);
    _clearError();

    _searchQuery = search ?? '';
    _selectedCategoryId = categoryId;
    _minPrice = minPrice;
    _maxPrice = maxPrice;

    final response = await _productService.searchProducts(
      search: search,
      categoryId: categoryId,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
    
    if (response.isSuccess && response.data != null) {
      _filteredProducts = response.data!;
    } else {
      _setError(response.error ?? 'Failed to search products');
    }
    
    _setLoading(false);
  }

  Future<void> loadProductsByCategory(int categoryId) async {
    await searchProducts(categoryId: categoryId);
  }

  Future<void> loadFeaturedProducts() async {
    if (_featuredProductsLoaded || _featuredProductsLoading) return;
    
    _setLoading(true);
    _featuredProductsLoading = true;
    _clearError();

    final response = await _productService.getFeaturedProducts();
    
    if (response.isSuccess && response.data != null) {
      _filteredProducts = response.data!;
      _featuredProductsLoaded = true;
    } else {
      _setError(response.error ?? 'Failed to load featured products');
    }
    
    _featuredProductsLoading = false;
    _setLoading(false);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setCategoryFilter(int? categoryId) {
    _selectedCategoryId = categoryId;
    _applyFilters();
  }

  void setPriceRange(double? minPrice, double? maxPrice) {
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _applyFilters();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategoryId = null;
    _minPrice = null;
    _maxPrice = null;
    _filteredProducts = _products;
    notifyListeners();
  }

  void _applyFilters() {
    _filteredProducts = _products.where((product) {
      bool matchesSearch = _searchQuery.isEmpty || 
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.safeDescription.toLowerCase().contains(_searchQuery.toLowerCase());
      
      bool matchesCategory = _selectedCategoryId == null || 
          product.categoryId == _selectedCategoryId;
      
      bool matchesPrice = (_minPrice == null || product.price >= _minPrice!) &&
          (_maxPrice == null || product.price <= _maxPrice!);
      
      return matchesSearch && matchesCategory && matchesPrice;
    }).toList();
    
    notifyListeners();
  }

  // Admin methods
  Future<bool> createProduct(CreateProductRequest request) async {
    _setLoading(true);
    _clearError();

    final response = await _productService.createProduct(request);
    
    if (response.isSuccess && response.data != null) {
      _products.add(response.data!);
      _applyFilters();
      _setLoading(false);
      return true;
    } else {
      _setError(response.error ?? 'Failed to create product');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateProduct(int productId, UpdateProductRequest request) async {
    _setLoading(true);
    _clearError();

    print('🔄 DEBUG: Updating product $productId');
    print('📤 DEBUG: Update fields: ${request.toFormFields()}');
    
    // Validate before sending
    if (!request.hasValidFields()) {
      print('❌ ERROR: No valid fields to update for product $productId');
      _setError('No fields to update');
      _setLoading(false);
      return false;
    }

    final response = await _productService.updateProduct(productId, request);
    
    if (response.isSuccess) {
      // API returned success - either with product data or just success message
      if (response.data != null) {
        // Update with returned product data
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = response.data!;
        _applyFilters();
        }
        print('✅ DEBUG: Product updated with returned data');
      } else {
        // Success message only - refresh product list to get updated data
        print('✅ DEBUG: Product updated successfully (message only)');
        await loadProducts(); // Refresh the product list
      }
      _setLoading(false);
      return true;
    } else {
      print('❌ DEBUG: API Error: ${response.error}');
      _setError(response.error ?? 'Failed to update product');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteProduct(int productId) async {
    _setLoading(true);
    _clearError();

    final response = await _productService.deleteProduct(productId);
    
    if (response.isSuccess) {
      _products.removeWhere((p) => p.id == productId);
      _applyFilters();
      _setLoading(false);
      return true;
    } else {
      _setError(response.error ?? 'Failed to delete product');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> createCategory(models.CreateCategoryRequest request) async {
    _setLoading(true);
    _clearError();

    final response = await _productService.createCategory(request);
    
    if (response.isSuccess && response.data != null) {
      _categories.add(response.data!);
      _setLoading(false);
      return true;
    } else {
      _setError(response.error ?? 'Failed to create category');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> toggleProductStatus(int productId, bool isActive) async {
    _setLoading(true);
    _clearError();
    
    print('🔄 DEBUG: Toggling product $productId status to $isActive');

    try {
      // Find the existing product to preserve all its data
      final existingProduct = _products.firstWhere((p) => p.id == productId);
      print('✅ DEBUG: Found existing product: ${existingProduct.name}');
      
      // Create update request with ALL required fields
      // Note: isLocked is the INVERSE of isActive (locked = !active)
      final request = UpdateProductRequest(
        name: existingProduct.name,
        description: existingProduct.safeDescription,
        price: existingProduct.price,
        stock: existingProduct.safeStockQuantity, // ✅ Updated field name
        categoryId: existingProduct.safeCategoryId,
        imageUrl: existingProduct.imageUrl,
        isLocked: !isActive, // ✅ Updated field name and inverted logic
      );
      
      // Validate before sending
      if (!request.hasValidFields()) {
        print('❌ ERROR: Invalid update request - no fields to update');
        _setError('No valid data to update');
        _setLoading(false);
        return false;
      }
      
      print('📤 DEBUG: Sending update request with ${request.toFormFields().length} fields');

      final response = await _productService.updateProduct(productId, request);
      
      if (response.isSuccess) {
        // API returned success - either with product data or just success message
        if (response.data != null) {
          // Update with returned product data
          final index = _products.indexWhere((p) => p.id == productId);
          if (index != -1) {
            _products[index] = response.data!;
            _applyFilters();
          }
          print('✅ DEBUG: Product status updated with returned data');
        } else {
          // Success message only - refresh product list to get updated data
          print('✅ DEBUG: Product status updated successfully (message only)');
          await loadProducts(); // Refresh the product list
        }
        _setLoading(false);
        return true;
      } else {
        print('❌ DEBUG: API Error: ${response.error}');
        _setError(response.error ?? 'Failed to toggle product status');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('❌ DEBUG: Exception in toggleProductStatus: $e');
      _setError('Error finding product: $e');
      _setLoading(false);
      return false;
    }
  }

  models.Category? getCategoryById(int categoryId) {
    try {
      return _categories.firstWhere((category) => category.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  String getCategoryName(int categoryId) {
    final category = getCategoryById(categoryId);
    return category?.name ?? 'Unknown Category';
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