// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderItem _$OrderItemFromJson(Map<String, dynamic> json) => OrderItem(
  id: (json['id'] as num).toInt(),
  orderId: (json['order_id'] as num).toInt(),
  productId: (json['product_id'] as num).toInt(),
  product_name: json['product_name'] as String?,
  quantity: (json['quantity'] as num).toInt(),
  price: (json['price'] as num).toDouble(),
  total: (json['total'] as num?)?.toDouble(),
  product: json['product'] == null
      ? null
      : Product.fromJson(json['product'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OrderItemToJson(OrderItem instance) => <String, dynamic>{
  'id': instance.id,
  'order_id': instance.orderId,
  'product_id': instance.productId,
  'product_name': instance.product_name,
  'quantity': instance.quantity,
  'price': instance.price,
  'total': instance.total,
  'product': instance.product,
};

Order _$OrderFromJson(Map<String, dynamic> json) => Order(
  id: (json['id'] as num).toInt(),
  userId: (json['user_id'] as num).toInt(),
  status: json['status'] as String,
  totalAmount: (json['total_amount'] as num).toDouble(),
  shippingAddress: json['shipping_address'] as String?,
  paymentMethod: json['payment_method'] as String?,
  items: (json['items'] as List<dynamic>?)
      ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  payments: (json['payments'] as List<dynamic>?)
      ?.map((e) => Payment.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$OrderToJson(Order instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'status': instance.status,
  'total_amount': instance.totalAmount,
  'shipping_address': instance.shippingAddress,
  'payment_method': instance.paymentMethod,
  'items': instance.items,
  'payments': instance.payments,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

CreateOrderRequest _$CreateOrderRequestFromJson(Map<String, dynamic> json) =>
    CreateOrderRequest(
      shippingAddress: json['shipping_address'] as String,
      paymentMethod: json['payment_method'] as String,
    );

Map<String, dynamic> _$CreateOrderRequestToJson(CreateOrderRequest instance) =>
    <String, dynamic>{
      'shipping_address': instance.shippingAddress,
      'payment_method': instance.paymentMethod,
    };

UpdateOrderStatusRequest _$UpdateOrderStatusRequestFromJson(
  Map<String, dynamic> json,
) => UpdateOrderStatusRequest(status: json['status'] as String);

Map<String, dynamic> _$UpdateOrderStatusRequestToJson(
  UpdateOrderStatusRequest instance,
) => <String, dynamic>{'status': instance.status};
