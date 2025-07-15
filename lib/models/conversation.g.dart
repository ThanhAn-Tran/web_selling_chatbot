// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Conversation _$ConversationFromJson(Map<String, dynamic> json) => Conversation(
  id: (json['conversation_id'] as num?)?.toInt(),
  userId: (json['user_id'] as num?)?.toInt(),
  message: json['message'] as String,
  response: json['response'] as String?,
  messageType: json['message_type'] as String,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  timestamp: json['timestamp'] == null
      ? null
      : DateTime.parse(json['timestamp'] as String),
  products: (json['products'] as List<dynamic>?)
      ?.map((e) => Product.fromJson(e as Map<String, dynamic>))
      .toList(),
  intent: json['intent'] as String?,
  actionsPerformed: (json['actions_performed'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$ConversationToJson(Conversation instance) =>
    <String, dynamic>{
      'conversation_id': instance.id,
      'user_id': instance.userId,
      'message': instance.message,
      'response': instance.response,
      'message_type': instance.messageType,
      'created_at': instance.createdAt?.toIso8601String(),
      'timestamp': instance.timestamp?.toIso8601String(),
      'products': instance.products,
      'intent': instance.intent,
      'actions_performed': instance.actionsPerformed,
    };

ChatRequest _$ChatRequestFromJson(Map<String, dynamic> json) =>
    ChatRequest(message: json['message'] as String);

Map<String, dynamic> _$ChatRequestToJson(ChatRequest instance) =>
    <String, dynamic>{'message': instance.message};

ChatAction _$ChatActionFromJson(Map<String, dynamic> json) => ChatAction(
  type: json['type'] as String,
  data: json['data'] as Map<String, dynamic>,
);

Map<String, dynamic> _$ChatActionToJson(ChatAction instance) =>
    <String, dynamic>{'type': instance.type, 'data': instance.data};

ChatResponse _$ChatResponseFromJson(Map<String, dynamic> json) => ChatResponse(
  response: json['response'] as String,
  products: json['products'],
  actions: (json['actions'] as List<dynamic>)
      .map((e) => ChatAction.fromJson(e as Map<String, dynamic>))
      .toList(),
  actionsPerformed: (json['actions_performed'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  conversationId: (json['conversation_id'] as num?)?.toInt(),
  intent: json['intent'] as String?,
);

Map<String, dynamic> _$ChatResponseToJson(ChatResponse instance) =>
    <String, dynamic>{
      'response': instance.response,
      'products': instance.products,
      'actions': instance.actions,
      'actions_performed': instance.actionsPerformed,
      'conversation_id': instance.conversationId,
      'intent': instance.intent,
    };

ChatHistoryResponse _$ChatHistoryResponseFromJson(Map<String, dynamic> json) =>
    ChatHistoryResponse(
      conversations: (json['conversation_history'] as List<dynamic>)
          .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalMessages: (json['total_messages'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
    );

Map<String, dynamic> _$ChatHistoryResponseToJson(
  ChatHistoryResponse instance,
) => <String, dynamic>{
  'conversation_history': instance.conversations,
  'total_messages': instance.totalMessages,
  'user_id': instance.userId,
};

ProductSearchResponse _$ProductSearchResponseFromJson(
  Map<String, dynamic> json,
) => ProductSearchResponse(
  query: json['query'] as String,
  products: (json['products'] as List<dynamic>)
      .map((e) => Product.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalFound: (json['total_found'] as num).toInt(),
  parsedParameters: json['parsed_parameters'] == null
      ? null
      : SearchParameters.fromJson(
          json['parsed_parameters'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$ProductSearchResponseToJson(
  ProductSearchResponse instance,
) => <String, dynamic>{
  'query': instance.query,
  'products': instance.products,
  'total_found': instance.totalFound,
  'parsed_parameters': instance.parsedParameters,
};

SearchParameters _$SearchParametersFromJson(
  Map<String, dynamic> json,
) => SearchParameters(
  minPrice: (json['min_price'] as num?)?.toDouble(),
  maxPrice: (json['max_price'] as num?)?.toDouble(),
  colors: (json['colors'] as List<dynamic>?)?.map((e) => e as String).toList(),
  styles: (json['styles'] as List<dynamic>?)?.map((e) => e as String).toList(),
  productTypes: (json['product_types'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  keywords: (json['keywords'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$SearchParametersToJson(SearchParameters instance) =>
    <String, dynamic>{
      'min_price': instance.minPrice,
      'max_price': instance.maxPrice,
      'colors': instance.colors,
      'styles': instance.styles,
      'product_types': instance.productTypes,
      'keywords': instance.keywords,
    };

SearchProductsRequest _$SearchProductsRequestFromJson(
  Map<String, dynamic> json,
) => SearchProductsRequest(query: json['query'] as String);

Map<String, dynamic> _$SearchProductsRequestToJson(
  SearchProductsRequest instance,
) => <String, dynamic>{'query': instance.query};

ChatAddToCartRequest _$ChatAddToCartRequestFromJson(
  Map<String, dynamic> json,
) => ChatAddToCartRequest(
  productId: (json['product_id'] as num).toInt(),
  quantity: (json['quantity'] as num).toInt(),
);

Map<String, dynamic> _$ChatAddToCartRequestToJson(
  ChatAddToCartRequest instance,
) => <String, dynamic>{
  'product_id': instance.productId,
  'quantity': instance.quantity,
};
