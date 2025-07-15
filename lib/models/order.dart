import 'package:json_annotation/json_annotation.dart';
import 'product.dart';
import 'payment.dart';

part 'order.g.dart';

// Helper functions for safe JSON parsing
int intFromJson(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double doubleFromJson(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

double? doubleFromJsonNullable(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

@JsonSerializable()
class OrderItem {
  final int id;
  @JsonKey(name: 'order_id')
  final int orderId;
  @JsonKey(name: 'product_id')
  final int productId;
  final String? product_name;
  final int quantity;
  final double price;
  final double? total;
  final Product? product;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    this.product_name,
    required this.quantity,
    required this.price,
    this.total,
    this.product,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => _$OrderItemFromJson(json);
  Map<String, dynamic> toJson() => _$OrderItemToJson(this);

  double get totalPrice => total ?? (price * quantity);
  String get formattedTotalPrice => '${totalPrice.toStringAsFixed(0)}đ';
  String get formattedPrice => '${price.toStringAsFixed(0)}đ';
  String get displayName => product_name ?? product?.name ?? 'Sản phẩm #$productId';
  
  // Backwards compatibility with Product
  Product get productInfo => product ?? Product(
    id: productId,
    name: product_name ?? 'Sản phẩm #$productId',
    description: '',
    price: price,
    imageUrl: '',
    categoryId: 0,
    stockQuantity: 0,
  );
}

@JsonSerializable()
class Order {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  final String status; // "Pending", "Processing", "Shipped", "Delivered", "Cancelled"
  @JsonKey(name: 'total_amount')
  final double totalAmount;
  @JsonKey(name: 'shipping_address')
  final String? shippingAddress;
  @JsonKey(name: 'payment_method')
  final String? paymentMethod;
  final List<OrderItem>? items;
  final List<Payment>? payments;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  Order({
    required this.id,
    required this.userId,
    required this.status,
    required this.totalAmount,
    this.shippingAddress,
    this.paymentMethod,
    this.items,
    this.payments,
    this.createdAt,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);

  String get formattedTotalAmount => '${totalAmount.toStringAsFixed(0)}đ';
  
  int get totalItems => items?.fold<int>(0, (sum, item) => sum + item.quantity) ?? 0;
  
  bool get isPending => status == 'Pending';
  bool get isProcessing => status == 'Processing';
  bool get isShipped => status == 'Shipped';
  bool get isDelivered => status == 'Delivered';
  bool get isCancelled => status == 'Cancelled';
  
  bool get canCancel => isPending || isProcessing;
  
  String get statusDisplayName {
    switch (status) {
      case 'Pending':
        return 'Đang chờ';
      case 'Processing':
        return 'Đang xử lý';
      case 'Shipped':
        return 'Đã gửi';
      case 'Delivered':
        return 'Đã giao';
      case 'Cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }
}

@JsonSerializable()
class CreateOrderRequest {
  @JsonKey(name: 'shipping_address')
  final String shippingAddress;
  @JsonKey(name: 'payment_method')
  final String paymentMethod; // "Momo", "COD", "Credit Card", "ZaloPay"

  CreateOrderRequest({
    required this.shippingAddress,
    required this.paymentMethod,
  });

  factory CreateOrderRequest.fromJson(Map<String, dynamic> json) => _$CreateOrderRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateOrderRequestToJson(this);
}

@JsonSerializable()
class UpdateOrderStatusRequest {
  final String status;

  UpdateOrderStatusRequest({
    required this.status,
  });

  factory UpdateOrderStatusRequest.fromJson(Map<String, dynamic> json) => _$UpdateOrderStatusRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateOrderStatusRequestToJson(this);
} 