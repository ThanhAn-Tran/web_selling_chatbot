import 'package:json_annotation/json_annotation.dart';
import 'product.dart';

part 'cart.g.dart';

@JsonSerializable()
class CartItem {
  @JsonKey(name: 'cart_item_id')
  final int id;
  @JsonKey(name: 'product_id')
  final int productId;
  @JsonKey(name: 'product_name')
  final String productName;
  final double price;
  final int quantity;
  final double total;
  @JsonKey(name: 'image_url')
  final String? imageUrl;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.total,
    this.imageUrl,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => _$CartItemFromJson(json);
  Map<String, dynamic> toJson() => _$CartItemToJson(this);

  // Use the 'total' from the API directly
  double get totalPrice => total;
  String get formattedTotalPrice => '${total.toStringAsFixed(0)}đ';
  
  // Backwards compatibility for product card
  Product get product => Product(
    id: productId,
    name: productName,
    price: price,
    imageUrl: imageUrl,
    description: '',
    stockQuantity: 1, // Assume in stock
    categoryId: 0,
  );
}

@JsonSerializable()
class Cart {
  @JsonKey(name: 'cart_id')
  final int id;
  final List<CartItem> items;
  @JsonKey(name: 'total_amount')
  final double totalAmount;

  Cart({
    required this.id,
    required this.items,
    required this.totalAmount,
  });

  factory Cart.fromJson(Map<String, dynamic> json) => _$CartFromJson(json);
  Map<String, dynamic> toJson() => _$CartToJson(this);

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  
  String get formattedTotalAmount => '${totalAmount.toStringAsFixed(0)}đ';
  
  bool get isEmpty => items.isEmpty;
}

@JsonSerializable()
class AddToCartRequest {
  @JsonKey(name: 'product_id')
  final int productId;
  final int quantity;

  AddToCartRequest({
    required this.productId,
    required this.quantity,
  });

  factory AddToCartRequest.fromJson(Map<String, dynamic> json) => _$AddToCartRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AddToCartRequestToJson(this);
}

@JsonSerializable()
class UpdateCartItemRequest {
  final int quantity;

  UpdateCartItemRequest({
    required this.quantity,
  });

  factory UpdateCartItemRequest.fromJson(Map<String, dynamic> json) => _$UpdateCartItemRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateCartItemRequestToJson(this);
} 