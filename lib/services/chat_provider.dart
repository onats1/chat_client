import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import 'grpc/grpc_service.dart';
import 'websocket/websocket_service.dart';

enum ChatProtocol { grpc, websocket }

class ChatProvider extends ChangeNotifier {
  final GrpcService _grpcService = GrpcService();
  final WebSocketService _webSocketService = WebSocketService();
  
  ChatProtocol _currentProtocol = ChatProtocol.websocket;
  List<MessageModel> _messages = [];
  bool _isConnected = false;
  String? _error;

  // Getters
  ChatProtocol get currentProtocol => _currentProtocol;
  List<MessageModel> get messages => _messages;
  bool get isConnected => _isConnected;
  String? get error => _error;

  ChatProvider() {
    _setupMessageListeners();
  }

  void _setupMessageListeners() {
    _grpcService.messageStream.listen(_handleNewMessage);
    _webSocketService.messageStream.listen(_handleNewMessage);
  }

  void _handleNewMessage(MessageModel message) {
    _messages.add(message);
    notifyListeners();
  }

  Future<void> connect() async {
    try {
      _error = null;
      if (_currentProtocol == ChatProtocol.grpc) {
        await _grpcService.connect();
      } else {
        await _webSocketService.connect();
      }
      _isConnected = true;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isConnected = false;
      notifyListeners();
    }
  }

  void sendMessage(String content) {
    if (!_isConnected) return;

    final message = MessageModel(
      userId: 'Me',
      content: content,
      timestamp: DateTime.now(),
      isSelf: true,
    );
    _messages.add(message);

    if (_currentProtocol == ChatProtocol.grpc) {
      _grpcService.sendMessage(content);
    } else {
      _webSocketService.sendMessage(content);
    }
    
    notifyListeners();
  }

  Future<void> switchProtocol(ChatProtocol protocol) async {
    if (protocol == _currentProtocol) return;

    disconnect();
    _messages.clear();
    _currentProtocol = protocol;
    await connect();
    notifyListeners();
  }

  void disconnect() {
    if (_currentProtocol == ChatProtocol.grpc) {
      _grpcService.disconnect();
    } else {
      _webSocketService.disconnect();
    }
    _isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _grpcService.dispose();
    _webSocketService.dispose();
    super.dispose();
  }
} 