import 'package:json_annotation/json_annotation.dart';
import 'product.dart';

part 'conversation.g.dart';

@JsonSerializable()
class Conversation {
  @JsonKey(name: 'conversation_id')
  final int? id;
  @JsonKey(name: 'user_id')
  final int? userId;
  final String message;
  final String? response;
  @JsonKey(name: 'message_type')
  final String messageType; // "user" or "assistant"
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'timestamp')
  final DateTime? timestamp; // Alternative timestamp field
  final List<Product>? products; // Product recommendations
  final String? intent;
  @JsonKey(name: 'actions_performed')
  final List<String>? actionsPerformed;

  Conversation({
    this.id,
    this.userId,
    required this.message,
    this.response,
    required this.messageType,
    this.createdAt,
    this.timestamp,
    this.products,
    this.intent,
    this.actionsPerformed,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    try {
      // Handle different timestamp field names
      DateTime? parsedCreatedAt;
      if (json['created_at'] != null) {
        parsedCreatedAt = json['created_at'] is String
            ? DateTime.tryParse(json['created_at'])
            : null;
      } else if (json['timestamp'] != null) {
        parsedCreatedAt = json['timestamp'] is String
            ? DateTime.tryParse(json['timestamp'])
            : null;
      }

      return Conversation(
        id: json['conversation_id'] as int? ?? json['id'] as int?,
        userId: json['user_id'] as int?,
        message: json['message'] as String? ?? '',
        response: json['response'] as String?,
        messageType: json['message_type'] as String? ?? 'user',
        createdAt: parsedCreatedAt,
        timestamp: parsedCreatedAt,
        products: json['products'] != null
            ? (json['products'] as List?)?.map((p) {
                try {
                  return Product.fromJson(p as Map<String, dynamic>);
                } catch (e) {
                  print('Error parsing product in conversation: $e');
                  return null;
                }
              }).where((p) => p != null).cast<Product>().toList()
            : null,
        intent: json['intent'] as String?,
        actionsPerformed: (json['actions_performed'] as List?)
            ?.map((e) => e as String)
            .toList(),
      );
    } catch (e) {
      print('Error parsing conversation: $e');
      print('JSON data: $json');
      
      // Return a safe fallback conversation
      return Conversation(
        id: json['conversation_id'] as int? ?? json['id'] as int? ?? 0,
        userId: json['user_id'] as int? ?? 0,
        message: json['message'] as String? ?? 'Error parsing message',
        response: json['response'] as String?,
        messageType: json['message_type'] as String? ?? 'user',
        createdAt: DateTime.now(),
        intent: json['intent'] as String?,
        actionsPerformed: [],
      );
    }
  }

  Map<String, dynamic> toJson() => _$ConversationToJson(this);

  bool get isUserMessage => messageType == 'user';
  bool get isAssistantMessage => messageType == 'assistant';
  
  // Safe getters with fallbacks
  int get safeId => id ?? 0;
  int get safeUserId => userId ?? 0;
  DateTime get safeCreatedAt => createdAt ?? timestamp ?? DateTime.now();
}

@JsonSerializable()
class ChatRequest {
  final String message;

  ChatRequest({
    required this.message,
  });

  factory ChatRequest.fromJson(Map<String, dynamic> json) => _$ChatRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ChatRequestToJson(this);
}

@JsonSerializable()
class ChatAction {
  final String type; // "add_to_cart", "view_product", etc.
  final Map<String, dynamic> data;

  ChatAction({
    required this.type,
    required this.data,
  });

  factory ChatAction.fromJson(Map<String, dynamic> json) => _$ChatActionFromJson(json);
  Map<String, dynamic> toJson() => _$ChatActionToJson(this);
}

@JsonSerializable()
class ChatResponse {
  final String response;
  final dynamic products; // Can be List<Product> or single Product Map
  final List<ChatAction> actions;
  @JsonKey(name: 'actions_performed')
  final List<String>? actionsPerformed;
  @JsonKey(name: 'conversation_id')
  final int? conversationId;
  final String? intent;

  ChatResponse({
    required this.response,
    required this.products,
    required this.actions,
    this.actionsPerformed,
    this.conversationId,
    this.intent,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    try {
      print('ChatResponse.fromJson: $json');
      
      // Parse products with error handling for different field names
      // Handle both single product object and list of products
      dynamic productsData = json['products'];
      List<Product> productList = [];
      
      if (productsData != null) {
        if (productsData is List) {
          // Handle list of products (existing behavior)
          for (final productData in productsData) {
          try {
            if (productData is Map<String, dynamic>) {
               final normalizedProductData = Map<String, dynamic>.from(productData);
               
               // Map API field names to expected field names
               if (normalizedProductData.containsKey('ProductID')) {
                 normalizedProductData['product_id'] = normalizedProductData['ProductID'];
               }
               if (normalizedProductData.containsKey('Name')) {
                 normalizedProductData['name'] = normalizedProductData['Name'];
               }
               if (normalizedProductData.containsKey('Price')) {
                 normalizedProductData['price'] = normalizedProductData['Price'];
               }
               if (normalizedProductData.containsKey('Description')) {
                 normalizedProductData['description'] = normalizedProductData['Description'];
               }
               if (normalizedProductData.containsKey('CategoryID')) {
                 normalizedProductData['category_id'] = normalizedProductData['CategoryID'];
               }
               if (normalizedProductData.containsKey('Stock')) {
                 normalizedProductData['stock'] = normalizedProductData['Stock'];
               }
               if (normalizedProductData.containsKey('ImageURL')) {
                 normalizedProductData['image_url'] = normalizedProductData['ImageURL'];
               }
               if (normalizedProductData.containsKey('SKU')) {
                 normalizedProductData['sku'] = normalizedProductData['SKU'];
               }
               if (normalizedProductData.containsKey('CreatedAt')) {
                 normalizedProductData['created_at'] = normalizedProductData['CreatedAt'];
               }
                if (normalizedProductData.containsKey('Color')) {
                  normalizedProductData['color'] = normalizedProductData['Color'];
                }
                if (normalizedProductData.containsKey('Style')) {
                  normalizedProductData['style'] = normalizedProductData['Style'];
                }
               
               // Handle cart-specific fields
               if (normalizedProductData.containsKey('Quantity')) {
                 normalizedProductData['quantity'] = normalizedProductData['Quantity'];
               }
               if (normalizedProductData.containsKey('SubTotal')) {
                 normalizedProductData['subtotal'] = normalizedProductData['SubTotal'];
               }
              
              final product = Product.fromJson(normalizedProductData);
              productList.add(product);
            }
          } catch (e) {
            print('Error parsing individual product: $e');
            print('Product data: $productData');
            // Continue with other products
            }
          }
        } else if (productsData is Map<String, dynamic>) {
          // Handle single product object (new product_view feature)
          try {
            final normalizedProductData = Map<String, dynamic>.from(productsData);
            
            // Map API field names to expected field names
            if (normalizedProductData.containsKey('ProductID')) {
              normalizedProductData['product_id'] = normalizedProductData['ProductID'];
            }
            if (normalizedProductData.containsKey('Name')) {
              normalizedProductData['name'] = normalizedProductData['Name'];
            }
            if (normalizedProductData.containsKey('Price')) {
              normalizedProductData['price'] = normalizedProductData['Price'];
            }
            if (normalizedProductData.containsKey('Description')) {
              normalizedProductData['description'] = normalizedProductData['Description'];
            }
            if (normalizedProductData.containsKey('CategoryID')) {
              normalizedProductData['category_id'] = normalizedProductData['CategoryID'];
            }
            if (normalizedProductData.containsKey('Stock')) {
              normalizedProductData['stock'] = normalizedProductData['Stock'];
            }
            if (normalizedProductData.containsKey('ImageURL')) {
              normalizedProductData['image_url'] = normalizedProductData['ImageURL'];
            }
            if (normalizedProductData.containsKey('SKU')) {
              normalizedProductData['sku'] = normalizedProductData['SKU'];
            }
            if (normalizedProductData.containsKey('CreatedAt')) {
              normalizedProductData['created_at'] = normalizedProductData['CreatedAt'];
            }
            if (normalizedProductData.containsKey('Color')) {
              normalizedProductData['color'] = normalizedProductData['Color'];
            }
            if (normalizedProductData.containsKey('Style')) {
              normalizedProductData['style'] = normalizedProductData['Style'];
            }
            
            final product = Product.fromJson(normalizedProductData);
            productList.add(product);
          } catch (e) {
            print('Error parsing single product: $e');
            print('Product data: $productsData');
          }
        }
      }

      // Parse actions performed
      List<String> actionsList = [];
      if (json['actions_performed'] != null && json['actions_performed'] is List) {
        actionsList = (json['actions_performed'] as List)
            .map((action) => action.toString())
            .toList();
      }

      // Convert actions_performed to ChatAction objects
      List<ChatAction> chatActions = actionsList.map((actionType) => ChatAction(
        type: actionType,
        data: {},
      )).toList();

      return ChatResponse(
        response: json['response'] as String? ?? '',
        products: productList,
        actionsPerformed: actionsList,
        conversationId: json['conversation_id'] as int?,
        intent: json['intent'] as String?,
        actions: chatActions,
      );
    } catch (e) {
      print('Error in ChatResponse.fromJson: $e');
      print('JSON: $json');
      
      // Return safe fallback
      return ChatResponse(
        response: json['response'] as String? ?? 'Sorry, there was an error processing the response.',
        products: [],
        actions: [],
        actionsPerformed: [],
        conversationId: json['conversation_id'] as int?,
        intent: json['intent'] as String?,
      );
    }
  }

  Map<String, dynamic> toJson() => _$ChatResponseToJson(this);
  
  // Helper methods for easier access
  List<Product> get productList {
    if (products is List<Product>) {
      return products as List<Product>;
    }
    return [];
  }
  
  bool get hasProducts => productList.isNotEmpty;
  bool get isProductView => actionsPerformed?.contains('product_view') == true;
  bool get isProductSearch => actionsPerformed?.contains('search_products') == true;
}

@JsonSerializable()
class ChatHistoryResponse {
  @JsonKey(name: 'conversation_history')
  final List<Conversation> conversations;
  @JsonKey(name: 'total_messages')
  final int totalMessages;
  @JsonKey(name: 'user_id')
  final int userId;

  ChatHistoryResponse({
    required this.conversations,
    required this.totalMessages,
    required this.userId,
  });

  factory ChatHistoryResponse.fromJson(Map<String, dynamic> json) => _$ChatHistoryResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ChatHistoryResponseToJson(this);
}

@JsonSerializable()
class ProductSearchResponse {
  final String query;
  final List<Product> products;
  @JsonKey(name: 'total_found')
  final int totalFound;
  @JsonKey(name: 'parsed_parameters')
  final SearchParameters? parsedParameters;

  ProductSearchResponse({
    required this.query,
    required this.products,
    required this.totalFound,
    this.parsedParameters,
  });

  factory ProductSearchResponse.fromJson(Map<String, dynamic> json) => _$ProductSearchResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ProductSearchResponseToJson(this);
}

@JsonSerializable()
class SearchParameters {
  @JsonKey(name: 'min_price')
  final double? minPrice;
  @JsonKey(name: 'max_price')
  final double? maxPrice;
  final List<String>? colors;
  final List<String>? styles;
  @JsonKey(name: 'product_types')
  final List<String>? productTypes;
  final List<String>? keywords;

  SearchParameters({
    this.minPrice,
    this.maxPrice,
    this.colors,
    this.styles,
    this.productTypes,
    this.keywords,
  });

  factory SearchParameters.fromJson(Map<String, dynamic> json) => _$SearchParametersFromJson(json);
  Map<String, dynamic> toJson() => _$SearchParametersToJson(this);
}

@JsonSerializable()
class SearchProductsRequest {
  final String query;

  SearchProductsRequest({
    required this.query,
  });

  factory SearchProductsRequest.fromJson(Map<String, dynamic> json) => _$SearchProductsRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SearchProductsRequestToJson(this);
}

@JsonSerializable()
class ChatAddToCartRequest {
  @JsonKey(name: 'product_id')
  final int productId;
  final int quantity;

  ChatAddToCartRequest({
    required this.productId,
    required this.quantity,
  });

  factory ChatAddToCartRequest.fromJson(Map<String, dynamic> json) => _$ChatAddToCartRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ChatAddToCartRequestToJson(this);
} 