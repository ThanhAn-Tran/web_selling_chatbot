import 'package:json_annotation/json_annotation.dart';

part 'product.g.dart';

@JsonSerializable()
class Product {
  @JsonKey(name: 'product_id')
  final int id;
  final String name;
  final String? description; // Made nullable for cart items
  final double price;
  @JsonKey(name: 'stock')
  final int? stockQuantity; // Made nullable for cart items
  @JsonKey(name: 'category_id')
  final int? categoryId; // Made nullable for cart items
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  final String? sku;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'is_locked')
  final bool? isActive; // This will now map to is_locked from API
  // Additional fields for product details
  final String? color;
  final String? style;
  // Additional fields for cart items
  final int? quantity;
  final double? subtotal;

  Product({
    required this.id,
    required this.name,
    this.description, // No longer required
    required this.price,
    this.stockQuantity, // No longer required
    this.categoryId, // No longer required
    this.imageUrl,
    this.sku,
    this.createdAt,
    this.isActive, // Added for admin functionality
    this.color, // For product details
    this.style, // For product details
    this.quantity, // For cart items
    this.subtotal, // For cart items
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Extract image URL from different possible sources
    String? extractedImageUrl;
    
    // First try: check for image_url field
    if (json.containsKey('image_url') && json['image_url'] != null) {
      extractedImageUrl = json['image_url'].toString();
    }
    // Second try: check for image_path field  
    else if (json.containsKey('image_path') && json['image_path'] != null) {
      extractedImageUrl = json['image_path'].toString();
    }
    // Third try: check for images array
    else if (json.containsKey('images') && json['images'] is List && (json['images'] as List).isNotEmpty) {
      final images = json['images'] as List;
      final firstImage = images[0];
      if (firstImage is Map<String, dynamic> && firstImage.containsKey('image_url')) {
        extractedImageUrl = firstImage['image_url'].toString();
      }
    }
    
    // Convert local file paths to web URLs or null
    if (extractedImageUrl != null) {
      // Check if it's a local file path
      if (extractedImageUrl.contains('D:\\') || extractedImageUrl.contains('C:\\') || extractedImageUrl.contains('assets\\')) {
        // Convert to web URL - assuming assets are served from /assets/
        if (extractedImageUrl.contains('assets\\')) {
          extractedImageUrl = extractedImageUrl
              .replaceAll('D:\\LapTrinhMobile\\Web-flutter-chatbot\\web_selling_chatbot\\', '/')
              .replaceAll('\\', '/');
        } else {
          // For other local paths, set to null for now
          extractedImageUrl = null;
        }
      }
      // Check for "null" string
      else if (extractedImageUrl.toLowerCase() == 'null') {
        extractedImageUrl = null;
      }
    }
    
    // Create a modified JSON with the extracted image URL
    final modifiedJson = Map<String, dynamic>.from(json);
    modifiedJson['image_url'] = extractedImageUrl;
    
    return _$ProductFromJson(modifiedJson);
  }
  
  Map<String, dynamic> toJson() => _$ProductToJson(this);

  String get formattedPrice => '${price.toStringAsFixed(0)}đ';
  bool get isInStock => (stockQuantity ?? 0) > 0;
  bool get isAvailableForPurchase => isInStock && safeIsActive; // ✅ New getter: in stock AND not locked
  String get displayImageUrl => imageUrl ?? 'assets/images/placeholder.png';
  
  // Safe getters with defaults
  String get safeDescription => description ?? 'Product description';
  int get safeStockQuantity => stockQuantity ?? 0;
  int get safeCategoryId => categoryId ?? 1;
  String get safeColor => color ?? 'N/A';
  String get safeStyle => style ?? 'N/A';
  bool get safeIsActive => !(isActive ?? false); // ✅ isActive now maps to is_locked, so invert it
  
  // Admin status helpers
  bool get isLocked => !safeIsActive;
  String get statusText => safeIsActive ? 'Hoạt động' : 'Đã khóa';
}

@JsonSerializable()
class CreateProductRequest {
  final String name;
  final String description;
  final double price;
  @JsonKey(name: 'stock')
  final int stock;
  @JsonKey(name: 'category_id')
  final int categoryId;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  final String? sku;
  @JsonKey(name: 'is_locked')
  final bool? isLocked;

  CreateProductRequest({
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    this.imageUrl,
    this.sku,
    this.isLocked = false,
  });

  factory CreateProductRequest.fromJson(Map<String, dynamic> json) => _$CreateProductRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateProductRequestToJson(this);
}

@JsonSerializable()
class UpdateProductRequest {
  final String? name;
  final String? description;
  final double? price;
  @JsonKey(name: 'stock')
  final int? stock;
  @JsonKey(name: 'category_id')
  final int? categoryId;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  final String? sku;
  @JsonKey(name: 'is_locked')
  final bool? isLocked;

  UpdateProductRequest({
    this.name,
    this.description,
    this.price,
    this.stock,
    this.categoryId,
    this.imageUrl,
    this.sku,
    this.isLocked,
  });

  factory UpdateProductRequest.fromJson(Map<String, dynamic> json) => _$UpdateProductRequestFromJson(json);
  
  Map<String, dynamic> toJson() => _$UpdateProductRequestToJson(this);

  /// Creates a filtered JSON that only includes non-null fields
  /// This prevents sending empty fields to the API
  Map<String, dynamic> toFilteredJson() {
    final Map<String, dynamic> data = {};
    
    print('🔍 DEBUG: Creating filtered JSON...');
    
    // Only add fields that have actual values
    if (name != null && name!.isNotEmpty) {
      data['name'] = name;
      print('  ✅ Adding name: $name');
    }
    if (description != null && description!.isNotEmpty) {
      data['description'] = description;
      print('  ✅ Adding description: $description');
    }
    if (price != null) {
      data['price'] = price;
      print('  ✅ Adding price: $price');
    }
    if (stock != null) {
      data['stock'] = stock;
      print('  ✅ Adding stock: $stock');
    }
    if (categoryId != null) {
      data['category_id'] = categoryId;
      print('  ✅ Adding category_id: $categoryId');
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      data['image_url'] = imageUrl;
      print('  ✅ Adding image_url: $imageUrl');
    }
    if (sku != null && sku!.isNotEmpty) {
      data['sku'] = sku;
      print('  ✅ Adding sku: $sku');
    }
    if (isLocked != null) {
      data['is_locked'] = isLocked;
      print('  ✅ Adding is_locked: $isLocked');
    }
    
    print('🔍 DEBUG: Final filtered data: $data');
    return data;
  }

  /// Creates form fields for multipart request
  Map<String, String> toFormFields() {
    final Map<String, String> fields = {};
    
    print('📋 DEBUG: Creating form fields...');
    
    // Only add fields that have actual values
    if (name != null && name!.isNotEmpty) {
      fields['name'] = name!;
      print('  ✅ Adding form field name: $name');
    }
    if (description != null && description!.isNotEmpty) {
      fields['description'] = description!;
      print('  ✅ Adding form field description: $description');
    }
    if (price != null) {
      fields['price'] = price!.toString();
      print('  ✅ Adding form field price: $price');
    }
    if (stock != null) {
      fields['stock'] = stock!.toString();
      print('  ✅ Adding form field stock: $stock');
    }
    if (categoryId != null) {
      fields['category_id'] = categoryId!.toString();
      print('  ✅ Adding form field category_id: $categoryId');
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      fields['image_url'] = imageUrl!;
      print('  ✅ Adding form field image_url: $imageUrl');
    }
    if (sku != null && sku!.isNotEmpty) {
      fields['sku'] = sku!;
      print('  ✅ Adding form field sku: $sku');
    }
    if (isLocked != null) {
      fields['is_locked'] = isLocked!.toString();
      print('  ✅ Adding form field is_locked: $isLocked');
    }
    
    print('📋 DEBUG: Final form fields: $fields');
    return fields;
  }

  /// Validates that at least one field is present for update
  bool hasValidFields() {
    return (name != null && name!.isNotEmpty) ||
           (description != null && description!.isNotEmpty) ||
           price != null ||
           stock != null ||
           categoryId != null ||
           (imageUrl != null && imageUrl!.isNotEmpty) ||
           (sku != null && sku!.isNotEmpty) ||
           isLocked != null;
  }
}

@JsonSerializable()
class ProductSearchParams {
  final int skip;
  final int limit;
  @JsonKey(name: 'category_id')
  final int? categoryId;
  @JsonKey(name: 'min_price')
  final double? minPrice;
  @JsonKey(name: 'max_price')
  final double? maxPrice;
  final String? search;

  ProductSearchParams({
    this.skip = 0,
    this.limit = 100,
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.search,
  });

  factory ProductSearchParams.fromJson(Map<String, dynamic> json) => _$ProductSearchParamsFromJson(json);
  Map<String, dynamic> toJson() => _$ProductSearchParamsToJson(this);

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'skip': skip,
      'limit': limit,
    };
    
    if (categoryId != null) params['category_id'] = categoryId;
    if (minPrice != null) params['min_price'] = minPrice;
    if (maxPrice != null) params['max_price'] = maxPrice;
    if (search != null && search!.isNotEmpty) params['search'] = search;
    
    return params;
  }
} 