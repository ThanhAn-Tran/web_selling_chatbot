import '../models/conversation.dart';
import '../models/product.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class ChatbotService {
  static final ChatbotService _instance = ChatbotService._internal();
  factory ChatbotService() => _instance;
  ChatbotService._internal();

  final ApiService _apiService = ApiService();

  /// Main chat endpoint - sends message and gets AI response with products
  Future<ApiResponse<ChatResponse>> sendMessage(String message) async {
    return await _apiService.post<ChatResponse>(
      ApiConstants.chatbotChat,
      body: {'message': message},
      fromJson: (dynamic json) {
        print('ChatbotService: Chat response: $json');
        try {
          if (json is Map<String, dynamic>) {
            // Use the improved ChatResponse.fromJson method
            return ChatResponse.fromJson(json);
          }
          throw Exception('Invalid response format: expected Map<String, dynamic>');
        } catch (e) {
          print('ChatbotService: Error parsing chat response: $e');
          print('ChatbotService: JSON data: $json');
          
          // Return safe fallback
          return ChatResponse(
            response: 'Sorry, there was an error processing your request. Please try again.',
            products: [],
            actions: [],
            actionsPerformed: [],
            conversationId: null,
            intent: null,
          );
        }
      },
    );
  }

  /// Get conversation history for current user
  Future<ApiResponse<ChatHistoryResponse>> getChatHistory({int limit = 20}) async {
    return await _apiService.get<ChatHistoryResponse>(
      '${ApiConstants.chatbotHistory}?limit=$limit',
      fromJson: (dynamic json) {
        print('ChatbotService: History response: $json');
        try {
          if (json is Map<String, dynamic>) {
            final conversationsList = json['conversation_history'] as List?;
            final conversations = <Conversation>[];
            
            if (conversationsList != null) {
              for (final turnData in conversationsList) {
                if (turnData is! Map<String, dynamic>) continue;

                // Create a Conversation for the user message
                final userMessage = turnData['user_message'] as String?;
                if (userMessage != null && userMessage.trim().isNotEmpty) {
                  conversations.add(
                    Conversation.fromJson({
                      ...turnData,
                      'message': userMessage,
                      'response': null,
                      'message_type': 'user',
                    }),
                  );
                }

                // Create a separate Conversation for the bot response
                final botResponse = turnData['bot_response'] as String?;
                if (botResponse != null && botResponse.trim().isNotEmpty) {
                  // The bot's conversation object should also contain the original user message for context
                  conversations.add(
                    Conversation.fromJson({
                      ...turnData,
                      'message': userMessage ?? '', // The user message that prompted this response
                      'response': botResponse,
                      'message_type': 'assistant',
                    }),
                  );
                }
              }
            }
            
            return ChatHistoryResponse(
              conversations: conversations,
              totalMessages: json['total_messages'] as int? ?? conversations.length,
              userId: json['user_id'] as int? ?? 0,
            );
          }
          throw Exception('Invalid history response format');
        } catch (e) {
          print('ChatbotService: Error parsing history: $e');
          // Return empty history instead of failing
          return ChatHistoryResponse(
            conversations: [],
            totalMessages: 0,
            userId: 0,
          );
        }
      },
    );
  }

  /// Product search with natural language
  Future<ApiResponse<ProductSearchResponse>> searchProducts(String query) async {
    return await _apiService.post<ProductSearchResponse>(
      ApiConstants.chatbotSearch,
      body: {'message': query},
      fromJson: (dynamic json) {
        print('ChatbotService: Product search response: $json');
        try {
          if (json is Map<String, dynamic>) {
            return ProductSearchResponse(
              query: json['query'] as String? ?? query,
              products: json['products'] != null
                  ? (json['products'] as List).map((p) => Product.fromJson(p)).toList()
                  : [],
              totalFound: json['total_found'] as int? ?? 0,
              parsedParameters: json['parsed_parameters'] != null
                  ? SearchParameters.fromJson(json['parsed_parameters'])
                  : null,
            );
          }
          throw Exception('Invalid search response format');
        } catch (e) {
          print('ChatbotService: Error parsing search response: $e');
          rethrow;
        }
      },
    );
  }

  /// Add product to cart via chatbot
  Future<ApiResponse<Map<String, dynamic>>> addToCartViaChat(int productId, {int quantity = 1}) async {
    return await _apiService.post<Map<String, dynamic>>(
      '${ApiConstants.chatbotAddToCart}/$productId',
      body: {'quantity': quantity},
      fromJson: (dynamic json) {
        print('ChatbotService: Add to cart response: $json');
        if (json is Map<String, dynamic>) {
          return json;
        }
        return {"message": "Added to cart successfully"};
      },
    );
  }

  /// Get cart contents via chatbot
  Future<ApiResponse<Map<String, dynamic>>> getCartContents() async {
    return await _apiService.get<Map<String, dynamic>>(
      ApiConstants.chatbotCart,
      fromJson: (dynamic json) {
        print('ChatbotService: Cart contents: $json');
        if (json is Map<String, dynamic>) {
          return json;
        }
        return {};
      },
    );
  }

  /// Quick chat without full conversation context
  Future<ApiResponse<ChatResponse>> quickChat(String message) async {
    return await _apiService.post<ChatResponse>(
      ApiConstants.chatbotQuickChat,
      body: {'message': message},
      fromJson: (dynamic json) {
        print('ChatbotService: Quick chat response: $json');
        try {
          if (json is Map<String, dynamic>) {
            return ChatResponse(
              response: json['response'] as String? ?? '',
              products: json['products'] != null 
                  ? (json['products'] as List).map((p) => Product.fromJson(p)).toList()
                  : [],
              actions: [],
            );
          }
          throw Exception('Invalid quick chat response format');
        } catch (e) {
          print('ChatbotService: Error parsing quick chat response: $e');
          rethrow;
        }
      },
    );
  }

  // Helper methods for common interactions
  Future<ApiResponse<ChatResponse>> askAboutProducts(String productQuery) async {
    return await sendMessage('Tôi đang tìm $productQuery');
  }

  Future<ApiResponse<ChatResponse>> askForRecommendations() async {
    return await sendMessage('Bạn có thể gợi ý một số sản phẩm hay cho tôi không?');
  }

  Future<ApiResponse<ChatResponse>> askAboutPriceRange(String productType, String priceRange) async {
    return await sendMessage('Tôi muốn tìm $productType trong khoảng giá $priceRange');
  }

  Future<ApiResponse<ChatResponse>> askAboutCart() async {
    return await sendMessage('Cho tôi xem giỏ hàng của tôi');
  }

  Future<ApiResponse<ChatResponse>> askForHelp() async {
    return await sendMessage('Bạn có thể giúp tôi tìm sản phẩm phù hợp không?');
  }

  // Message formatting helpers
  String formatProductListMessage(List<Product> products) {
    if (products.isEmpty) {
      return 'Không tìm thấy sản phẩm nào phù hợp.';
    }

    final buffer = StringBuffer('Tôi tìm thấy ${products.length} sản phẩm:\n\n');
    for (final product in products.take(5)) {
      buffer.writeln('• ${product.name} - ${product.formattedPrice}');
    }

    if (products.length > 5) {
      buffer.writeln('\n... và ${products.length - 5} sản phẩm khác.');
    }

    return buffer.toString();
  }

  bool isProductRecommendationResponse(ChatResponse response) {
    return response.products.isNotEmpty;
  }

  bool hasActionableActions(ChatResponse response) {
    return response.actions.isNotEmpty;
  }

  /// Reset/clear chat history on the backend
  Future<ApiResponse<Map<String, dynamic>>> resetChat() async {
    return await _apiService.post<Map<String, dynamic>>(
      ApiConstants.chatbotReset,
      fromJson: (dynamic json) {
        print('ChatbotService: Reset chat response: $json');
        if (json is Map<String, dynamic>) {
          return json;
        }
        return {"message": "Chat reset successfully"};
      },
    );
  }
} 