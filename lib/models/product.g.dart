// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
  id: (json['product_id'] as num).toInt(),
  name: json['name'] as String,
  description: json['description'] as String?,
  price: (json['price'] as num).toDouble(),
  stockQuantity: (json['stock'] as num?)?.toInt(),
  categoryId: (json['category_id'] as num?)?.toInt(),
  imageUrl: json['image_url'] as String?,
  sku: json['sku'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  isActive: json['is_locked'] as bool?,
  color: json['color'] as String?,
  style: json['style'] as String?,
  quantity: (json['quantity'] as num?)?.toInt(),
  subtotal: (json['subtotal'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
  'product_id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'price': instance.price,
  'stock': instance.stockQuantity,
  'category_id': instance.categoryId,
  'image_url': instance.imageUrl,
  'sku': instance.sku,
  'created_at': instance.createdAt?.toIso8601String(),
  'is_locked': instance.isActive,
  'color': instance.color,
  'style': instance.style,
  'quantity': instance.quantity,
  'subtotal': instance.subtotal,
};

CreateProductRequest _$CreateProductRequestFromJson(
  Map<String, dynamic> json,
) => CreateProductRequest(
  name: json['name'] as String,
  description: json['description'] as String,
  price: (json['price'] as num).toDouble(),
  stock: (json['stock'] as num).toInt(),
  categoryId: (json['category_id'] as num).toInt(),
  imageUrl: json['image_url'] as String?,
  sku: json['sku'] as String?,
  isLocked: json['is_locked'] as bool? ?? false,
);

Map<String, dynamic> _$CreateProductRequestToJson(
  CreateProductRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
  'price': instance.price,
  'stock': instance.stock,
  'category_id': instance.categoryId,
  'image_url': instance.imageUrl,
  'sku': instance.sku,
  'is_locked': instance.isLocked,
};

UpdateProductRequest _$UpdateProductRequestFromJson(
  Map<String, dynamic> json,
) => UpdateProductRequest(
  name: json['name'] as String?,
  description: json['description'] as String?,
  price: (json['price'] as num?)?.toDouble(),
  stock: (json['stock'] as num?)?.toInt(),
  categoryId: (json['category_id'] as num?)?.toInt(),
  imageUrl: json['image_url'] as String?,
  sku: json['sku'] as String?,
  isLocked: json['is_locked'] as bool?,
);

Map<String, dynamic> _$UpdateProductRequestToJson(
  UpdateProductRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
  'price': instance.price,
  'stock': instance.stock,
  'category_id': instance.categoryId,
  'image_url': instance.imageUrl,
  'sku': instance.sku,
  'is_locked': instance.isLocked,
};

ProductSearchParams _$ProductSearchParamsFromJson(Map<String, dynamic> json) =>
    ProductSearchParams(
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 100,
      categoryId: (json['category_id'] as num?)?.toInt(),
      minPrice: (json['min_price'] as num?)?.toDouble(),
      maxPrice: (json['max_price'] as num?)?.toDouble(),
      search: json['search'] as String?,
    );

Map<String, dynamic> _$ProductSearchParamsToJson(
  ProductSearchParams instance,
) => <String, dynamic>{
  'skip': instance.skip,
  'limit': instance.limit,
  'category_id': instance.categoryId,
  'min_price': instance.minPrice,
  'max_price': instance.maxPrice,
  'search': instance.search,
};
