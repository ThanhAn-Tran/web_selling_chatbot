// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Payment _$PaymentFromJson(Map<String, dynamic> json) => Payment(
  id: (json['id'] as num).toInt(),
  orderId: (json['order_id'] as num).toInt(),
  amount: (json['amount'] as num).toDouble(),
  paymentMethod: json['payment_method'] as String,
  transactionCode: json['transaction_code'] as String?,
  status: json['status'] as String,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$PaymentToJson(Payment instance) => <String, dynamic>{
  'id': instance.id,
  'order_id': instance.orderId,
  'amount': instance.amount,
  'payment_method': instance.paymentMethod,
  'transaction_code': instance.transactionCode,
  'status': instance.status,
  'created_at': instance.createdAt?.toIso8601String(),
};

UpdatePaymentStatusRequest _$UpdatePaymentStatusRequestFromJson(
  Map<String, dynamic> json,
) => UpdatePaymentStatusRequest(status: json['status'] as String);

Map<String, dynamic> _$UpdatePaymentStatusRequestToJson(
  UpdatePaymentStatusRequest instance,
) => <String, dynamic>{'status': instance.status};
