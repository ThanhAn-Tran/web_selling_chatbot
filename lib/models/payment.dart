import 'package:json_annotation/json_annotation.dart';

part 'payment.g.dart';

@JsonSerializable()
class Payment {
  final int id;
  @JsonKey(name: 'order_id')
  final int orderId;
  final double amount;
  @JsonKey(name: 'payment_method')
  final String paymentMethod; // "Momo", "COD", "Credit Card", "ZaloPay"
  @JsonKey(name: 'transaction_code')
  final String? transactionCode;
  final String status; // "Unpaid", "Paid", "Failed", "Refunded"
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  Payment({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.paymentMethod,
    this.transactionCode,
    required this.status,
    this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentToJson(this);

  String get formattedAmount => '${amount.toStringAsFixed(0)}đ';
  
  bool get isUnpaid => status == 'Unpaid';
  bool get isPaid => status == 'Paid';
  bool get isFailed => status == 'Failed';
  bool get isRefunded => status == 'Refunded';
  
  String get statusDisplayName {
    switch (status) {
      case 'Unpaid':
        return 'Chưa thanh toán';
      case 'Paid':
        return 'Đã thanh toán';
      case 'Failed':
        return 'Thanh toán thất bại';
      case 'Refunded':
        return 'Đã hoàn tiền';
      default:
        return status;
    }
  }
  
  String get paymentMethodDisplayName {
    switch (paymentMethod) {
      case 'Momo':
        return 'Ví MoMo';
      case 'COD':
        return 'Thanh toán khi nhận hàng';
      case 'Credit Card':
        return 'Thẻ tín dụng';
      case 'ZaloPay':
        return 'Ví ZaloPay';
      default:
        return paymentMethod;
    }
  }
}

@JsonSerializable()
class UpdatePaymentStatusRequest {
  final String status;

  UpdatePaymentStatusRequest({
    required this.status,
  });

  factory UpdatePaymentStatusRequest.fromJson(Map<String, dynamic> json) => _$UpdatePaymentStatusRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdatePaymentStatusRequestToJson(this);
} 