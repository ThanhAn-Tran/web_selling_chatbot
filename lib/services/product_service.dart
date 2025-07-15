import '../models/product.dart';
import '../models/category.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  final ApiService _apiService = ApiService();

  // Category methods
  Future<ApiResponse<List<Category>>> getCategories() async {
    return await _apiService.get<List<Category>>(
      ApiConstants.categories,
      includeAuth: false,
      fromJson: (json) {
        try {
          if (json is List) {
            return json.map((item) => Category.fromJson(item as Map<String, dynamic>)).toList();
          }
          return <Category>[];
        } catch (e) {
          print('ProductService: Error parsing categories: $e');
          return <Category>[];
        }
      },
    );
  }

  Future<ApiResponse<Category?>> createCategory(CreateCategoryRequest request) async {
    return await _apiService.post<Category?>(
      ApiConstants.categories,
      body: request.toJson(),
      fromJson: (dynamic json) {
        try {
          if (json is Map<String, dynamic>) {
            return Category.fromJson(json);
          }
          throw Exception('Invalid category data format');
        } catch (e) {
          print('ProductService: Error parsing created category: $e');
          return null;
        }
      },
    );
  }

  Future<ApiResponse<Category?>> updateCategory(int categoryId, UpdateCategoryRequest request) async {
    return await _apiService.put<Category?>(
      '${ApiConstants.categories}/$categoryId',
      body: request.toJson(),
      fromJson: (dynamic json) {
        try {
          if (json is Map<String, dynamic>) {
            return Category.fromJson(json);
          }
          throw Exception('Invalid category data format');
        } catch (e) {
          print('ProductService: Error parsing updated category: $e');
          return null;
        }
      },
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> deleteCategory(int categoryId) async {
    return await _apiService.delete<Map<String, dynamic>>(
      '${ApiConstants.categories}/$categoryId',
    );
  }

  // Product methods
  Future<ApiResponse<List<Product>>> getProducts({
    ProductSearchParams? searchParams,
  }) async {
    return await _apiService.get<List<Product>>(
      ApiConstants.products,
      queryParams: searchParams?.toQueryParams(),
      includeAuth: false,
      fromJson: (json) {
        try {
          if (json is List) {
            return json.map((item) => Product.fromJson(item as Map<String, dynamic>)).toList();
          }
          return <Product>[];
        } catch (e) {
          print('ProductService: Error parsing products: $e');
          return <Product>[];
        }
      },
    );
  }

  Future<ApiResponse<Product?>> getProduct(int productId) async {
    return await _apiService.get<Product?>(
      '${ApiConstants.products}/$productId',
      includeAuth: false,
      fromJson: (dynamic json) {
        try {
          if (json is Map<String, dynamic>) {
            return Product.fromJson(json);
          }
          throw Exception('Invalid product data format');
        } catch (e) {
          print('ProductService: Error parsing product: $e');
          return null;
        }
      },
    );
  }

  Future<ApiResponse<Product?>> createProduct(CreateProductRequest request) async {
    return await _apiService.post<Product?>(
      ApiConstants.products,
      body: request.toJson(),
      fromJson: (dynamic json) {
        try {
          if (json is Map<String, dynamic>) {
            return Product.fromJson(json);
          }
          throw Exception('Invalid product data format');
        } catch (e) {
          print('ProductService: Error parsing created product: $e');
          return null;
        }
      },
    );
  }

  Future<ApiResponse<Product?>> updateProduct(int productId, UpdateProductRequest request) async {
    // Debug: Check what we're about to send
    final formFields = request.toFormFields();
    print('🐛 DEBUG: Product Update Request for ID $productId');
    print('📋 DEBUG: Form fields: $formFields');
    
    // Validate that we have data to send
    if (!request.hasValidFields()) {
      print('❌ ERROR: No valid fields to update for product $productId');
      return ApiResponse.error('No fields to update');
    }
    
    print('✅ DEBUG: Sending ${formFields.length} fields to API as multipart form');
    
    return await _apiService.putMultipart<Product?>(
      '${ApiConstants.products}/$productId',
      fields: formFields,
      fromJson: (dynamic json) {
        try {
          print('🔍 DEBUG: Attempting to parse product response...');
          print('🔍 DEBUG: Raw JSON: $json');
          
          if (json is Map<String, dynamic>) {
            // Check if this is a success message response
            if (json.containsKey('message') && json['message'] == 'Product updated successfully') {
              print('✅ DEBUG: Product update success message received');
              return null; // Return null to indicate success but no product data
            }
            
            // Try to parse as Product if it has the required fields
            if (json.containsKey('product_id') || json.containsKey('id')) {
              print('🔍 DEBUG: JSON contains product data, attempting Product.fromJson...');
              final product = Product.fromJson(json);
              print('✅ DEBUG: Product parsed successfully: ${product.name}');
              return product;
            } else {
              print('⚠️ DEBUG: JSON does not contain product data, treating as success');
              return null; // Success but no product data
            }
          } else {
            print('❌ DEBUG: JSON is not Map<String, dynamic>, type: ${json.runtimeType}');
            throw Exception('Invalid product data format: expected Map but got ${json.runtimeType}');
          }
        } catch (e, stackTrace) {
          print('❌ ProductService: Error parsing updated product: $e');
          print('❌ ProductService: Stack trace: $stackTrace');
          return null;
        }
      },
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> deleteProduct(int productId) async {
    return await _apiService.delete<Map<String, dynamic>>(
      '${ApiConstants.products}/$productId',
    );
  }

  // Admin-specific methods
  Future<ApiResponse<Product?>> toggleProductStatus(int productId, bool isActive) async {
    return await _apiService.put<Product?>(
      '${ApiConstants.products}/$productId/status',
      body: {'is_active': isActive},
      fromJson: (dynamic json) {
        try {
          if (json is Map<String, dynamic>) {
            return Product.fromJson(json);
          }
          throw Exception('Invalid product data format');
        } catch (e) {
          print('ProductService: Error parsing toggled product: $e');
          return null;
        }
      },
    );
  }

  Future<ApiResponse<Product?>> lockProduct(int productId) async {
    return await toggleProductStatus(productId, false);
  }

  Future<ApiResponse<Product?>> unlockProduct(int productId) async {
    return await toggleProductStatus(productId, true);
  }

  // Search methods
  Future<ApiResponse<List<Product>>> searchProducts({
    String? search,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    int skip = 0,
    int limit = 20,
  }) async {
    final searchParams = ProductSearchParams(
      search: search,
      categoryId: categoryId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      skip: skip,
      limit: limit,
    );

    return await getProducts(searchParams: searchParams);
  }

  Future<ApiResponse<List<Product>>> getProductsByCategory(int categoryId) async {
    return await searchProducts(categoryId: categoryId);
  }

  Future<ApiResponse<List<Product>>> getFeaturedProducts() async {
    return await getProducts(
      searchParams: ProductSearchParams(limit: 10),
    );
  }
} 