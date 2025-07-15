import 'package:flutter/foundation.dart';
import '../models/conversation.dart';
import '../models/product.dart';
import '../services/chatbot_service.dart';
import 'cart_provider.dart';

class Message {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<Product> products;
  final List<ChatAction> actions;

  Message({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.products = const [],
    this.actions = const [],
  });
}

class ChatbotProvider extends ChangeNotifier {
  final ChatbotService _chatbotService = ChatbotService();
  CartProvider cartProvider;

  List<Conversation> _conversations = [];
  bool _isLoading = false;
  bool _isTyping = false;
  String? _error;
  List<Product> _lastRecommendations = [];

  List<Conversation> get conversations => _conversations;
  bool get isLoading => _isLoading || _isTyping;
  bool get isTyping => _isTyping;
  String? get error => _error;
  bool get hasMessages => _conversations.isNotEmpty;
  List<Product> get lastRecommendations => _lastRecommendations;

  ChatbotProvider(this.cartProvider);

  /// Load chat history from server
  Future<void> loadChatHistory() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _chatbotService.getChatHistory();
      
      if (response.isSuccess && response.data != null) {
        final historyResponse = response.data!;
        _conversations = historyResponse.conversations;
        
        print('ChatbotProvider: Loaded ${_conversations.length} conversations');
        
        // Validate and clean up conversations
        _conversations = _conversations.where((conv) {
          return conv.message.isNotEmpty || (conv.response?.isNotEmpty ?? false);
        }).toList();
        
        print('ChatbotProvider: ${_conversations.length} valid conversations after cleanup');
        notifyListeners();
      } else {
        final errorMsg = response.error ?? 'Failed to load chat history';
        print('ChatbotProvider: History loading failed: $errorMsg');
        _setError(errorMsg);
      }
    } catch (e) {
      final errorMsg = 'Error loading chat history: ${e.toString()}';
      print('ChatbotProvider: Exception: $errorMsg');
      _setError(errorMsg);
    }
    
    _setLoading(false);
  }

  /// Send message to AI chatbot
 Future<void> sendMessage(String message) async {
  if (message.trim().isEmpty) return;

  // Add user message locally for immediate UI feedback
  final userConversation = Conversation(
    id: DateTime.now().millisecondsSinceEpoch,
    userId: null,
    message: message,
    messageType: 'user',
    createdAt: DateTime.now(),
  );

  _conversations.add(userConversation);
  notifyListeners();

  _setTyping(true);
  _clearError();

  try {
    final response = await _chatbotService.sendMessage(message);
    _setTyping(false);

    if (response.isSuccess && response.data != null) {
      final chatResponse = response.data!;
      final hasSlotFilling = chatResponse.actions.any((a) => a.type == 'slot_filling');

      // ⚠️ Chỉ thêm assistantConversation nếu không phải slot_filling
      if (!hasSlotFilling) {
        final assistantConversation = Conversation(
          id: DateTime.now().millisecondsSinceEpoch + 1,
          userId: null,
          message: message,
          response: chatResponse.response,
          messageType: 'assistant',
          createdAt: DateTime.now(),
          products: chatResponse.productList,
          intent: chatResponse.intent,
          actionsPerformed: chatResponse.actionsPerformed,
        );

        _conversations.add(assistantConversation);
      }

      _lastRecommendations = chatResponse.productList;

      // Xử lý các hành động (ví dụ: slot_filling sẽ được thêm trong hàm này)
      await _processActions(chatResponse);
    } else {
      // Trường hợp phản hồi không thành công
      final errorConversation = Conversation(
        id: DateTime.now().millisecondsSinceEpoch + 1,
        userId: null,
        message: message,
        response: 'Xin lỗi, tôi không thể xử lý yêu cầu của bạn lúc này. Vui lòng thử lại sau.',
        messageType: 'assistant',
        createdAt: DateTime.now(),
      );

      _conversations.add(errorConversation);
      _setError(response.error ?? 'Failed to send message');
    }
  } catch (e) {
    _setTyping(false);
    _setError('Network error: ${e.toString()}');

    final errorConversation = Conversation(
      id: DateTime.now().millisecondsSinceEpoch + 1,
      userId: null,
      message: message,
      response: 'Có lỗi xảy ra khi kết nối. Vui lòng kiểm tra kết nối mạng và thử lại.',
      messageType: 'assistant',
      createdAt: DateTime.now(),
    );

    _conversations.add(errorConversation);
  }

  notifyListeners();
}


  /// Quick product search without full conversation context
  Future<void> searchProducts(String query) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _chatbotService.searchProducts(query);
      
      if (response.isSuccess && response.data != null) {
        final searchResponse = response.data!;
        
        // Create conversation entry showing search results
        final searchConversation = Conversation(
          id: DateTime.now().millisecondsSinceEpoch,
          userId: 0,
          message: query,
          response: _formatSearchResults(searchResponse),
          messageType: 'assistant',
          createdAt: DateTime.now(),
          products: searchResponse.products,
        );
        
        _conversations.add(searchConversation);
        _lastRecommendations = searchResponse.products;
      } else {
        _setError(response.error ?? 'Failed to search products');
      }
    } catch (e) {
      _setError('Search error: ${e.toString()}');
    }
    
    _setLoading(false);
    notifyListeners();
  }

  /// Add product to cart via chatbot
  Future<bool> addProductToCartFromChat(int productId, {int quantity = 1}) async {
    try {
      final response = await _chatbotService.addToCartViaChat(productId, quantity: quantity);
      
      if (response.isSuccess) {
        // Add confirmation message to chat
        final confirmationConversation = Conversation(
          id: DateTime.now().millisecondsSinceEpoch,
          userId: 0,
          message: 'Thêm sản phẩm vào giỏ hàng',
          response: 'Đã thêm sản phẩm vào giỏ hàng thành công! 🛒',
          messageType: 'assistant',
          createdAt: DateTime.now(),
        );
        
        _conversations.add(confirmationConversation);
        notifyListeners();
        return true;
      } else {
        _setError('Không thể thêm sản phẩm vào giỏ hàng: ${response.error}');
        return false;
      }
    } catch (e) {
      _setError('Cart error: ${e.toString()}');
      return false;
    }
  }

  /// Quick actions for common requests
  Future<void> askForRecommendations() async {
    await sendMessage('Bạn có thể gợi ý một số sản phẩm hay cho tôi không?');
  }

  Future<void> askAboutProducts(String productQuery) async {
    await sendMessage('Tôi đang tìm $productQuery');
  }

  Future<void> askAboutPriceRange(String productType, String priceRange) async {
    await sendMessage('Tôi muốn tìm $productType trong khoảng giá $priceRange');
  }

  Future<void> askForHelp() async {
    await sendMessage('Bạn có thể giúp tôi tìm sản phẩm phù hợp không?');
  }

  Future<void> askAboutCart() async {
    await sendMessage('Cho tôi xem giỏ hàng của tôi');
  }

  /// Clear chat history
  Future<void> clearChatHistory({bool resetBackend = false}) async {
    if (resetBackend) {
      try {
        final response = await _chatbotService.resetChat();
        if (!response.isSuccess) {
          _setError(response.error ?? 'Failed to reset chat');
        }
      } catch (e) {
        _setError('Network error: ${e.toString()}');
      }
    }
    _conversations.clear();
    _lastRecommendations.clear();
    _clearError();
    notifyListeners();
  }

  void clearChat() {
    clearChatHistory();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setTyping(bool typing) {
    _isTyping = typing;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    if (error != null) {
      print('ChatbotProvider Error: $error');
    }
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  Future<void> _processActions(ChatResponse chatResponse) async {
    final actions = chatResponse.actions;
    print('ChatbotProvider: Processing ${actions.length} actions');
    
    for (final action in actions) {
      final type = action.type;
      final data = action.data;
      print('ChatbotProvider: Processing action: $action');
      switch (type) {
        // Cart operations
        case 'add_to_cart':
          final productId = data['product_id'] as int?;
          final quantity = data['quantity'] as int? ?? 1;
          if (productId != null) {
            await addProductToCartFromChat(productId, quantity: quantity);
          }
          break;
        case 'remove_from_cart':
          print('ChatbotProvider: Remove from cart action detected');
          final productId = data['product_id'] as int?;
          print('ChatbotProvider: Remove product $productId from cart');
          break;
        case 'view_cart':
          print('ChatbotProvider: View cart action detected');
          cartProvider.updateCartFromChatbot(chatResponse.productList);
          break;
        case 'search_products':
          print('ChatbotProvider: Product search action detected');
          final searchQuery = data['query'] as String?;
          if (searchQuery != null) {
            print('ChatbotProvider: Search performed for: $searchQuery');
          }
          break;
        case 'friendly_chat':
          print('ChatbotProvider: Friendly chat action detected');
          final intent = data['intent'] as String?;
          print('ChatbotProvider: Friendly chat intent: $intent');
          break;
        case 'product_consultation':
        case 'consultation':
          print('ChatbotProvider: Product consultation action detected');
          final consultationType = data['consultation_type'] as String?;
          final recommendation = data['recommendation'] as String?;
          print('ChatbotProvider: Consultation type: $consultationType');
          break;
        case 'slot_filling':
          print('ChatbotProvider: Slot filling action detected');
          final slot = data['slot'];
          final prompt = data['prompt'];
          print('ChatbotProvider: Missing slot: $slot, prompt: $prompt');

          // Chỉ thêm prompt nếu khác response cuối cùng đã hiển thị
          if (prompt != null && prompt is String) {
            final lastResponse = _conversations.isNotEmpty
                ? _conversations.last.response
                : null;

            if (lastResponse != prompt) {
              final slotPromptConversation = Conversation(
                id: DateTime.now().millisecondsSinceEpoch,
                userId: 0,
                message: '',
                response: prompt,
                messageType: 'assistant',
                createdAt: DateTime.now(),
              );
              _conversations.add(slotPromptConversation);
              notifyListeners();
            } else {
              print('ChatbotProvider: Prompt already displayed, skipping duplicate.');
            }
          }
          break;

        case 'product_view':
          print('ChatbotProvider: Product view action detected');
          break;
        case 'error':
          print('ChatbotProvider: Error action detected');
          final errorMessage = data['message'] as String?;
          if (errorMessage != null) {
            _setError('Chatbot Error: $errorMessage');
          }
          break;
        default:
          print('ChatbotProvider: Unknown action type: $type');
          print('ChatbotProvider: Action data: $data');
          break;
      }
    }
  }

  String _formatSearchResults(ProductSearchResponse searchResponse) {
    if (searchResponse.products.isEmpty) {
      return 'Không tìm thấy sản phẩm nào phù hợp với "${searchResponse.query}".';
    }

    final buffer = StringBuffer();
    buffer.writeln('Tìm thấy ${searchResponse.totalFound} sản phẩm cho "${searchResponse.query}":');
    buffer.writeln();

    for (final product in searchResponse.products.take(5)) {
      buffer.writeln('• ${product.name}');
      buffer.writeln('  Giá: ${product.formattedPrice}');
      buffer.writeln();
    }

    if (searchResponse.totalFound > 5) {
      buffer.writeln('... và ${searchResponse.totalFound - 5} sản phẩm khác.');
    }

    return buffer.toString().trim();
  }

  // Get suggested quick actions based on context
  List<String> getSuggestedQuickActions() {
    return [
      'Gợi ý sản phẩm hot',
      'Tìm quần áo nam',
      'Tìm quần áo nữ',
      'Sản phẩm dưới 500k',
      'Thời gian giao hàng',
      'Phương thức thanh toán',
    ];
  }

  // Execute quick action
  Future<void> executeQuickAction(String action) async {
    switch (action) {
      case 'Gợi ý sản phẩm hot':
        await askForRecommendations();
        break;
      case 'Tìm quần áo nam':
        await askAboutProducts('quần áo nam');
        break;
      case 'Tìm quần áo nữ':
        await askAboutProducts('quần áo nữ');
        break;
      case 'Sản phẩm dưới 500k':
        await askAboutPriceRange('sản phẩm', 'dưới 500k');
        break;
      case 'Thời gian giao hàng':
        await sendMessage('Thời gian giao hàng như thế nào?');
        break;
      case 'Phương thức thanh toán':
        await sendMessage('Có những phương thức thanh toán nào?');
        break;
      default:
        await sendMessage(action);
        break;
    }
  }
} 