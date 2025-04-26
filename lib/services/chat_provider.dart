import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import 'grpc/grpc_service.dart';
import 'websocket/websocket_service.dart';
import 'metrics/metrics_service.dart';

enum ChatProtocol { grpc, websocket }

class ChatProvider extends ChangeNotifier {
  final GrpcService _grpcService = GrpcService();
  final WebSocketService _webSocketService = WebSocketService();
  final MetricsService _metricsService = MetricsService();
  
  ChatProtocol _currentProtocol = ChatProtocol.websocket;
  List<MessageModel> _messages = [];
  bool _isConnected = false;
  String? _error;

  // Getters
  ChatProtocol get currentProtocol => _currentProtocol;
  List<MessageModel> get messages => _messages;
  bool get isConnected => _isConnected;
  String? get error => _error;
  MetricsService get metricsService => _metricsService;

  ChatProvider() {
    _setupMessageListeners();
  }

  void _setupMessageListeners() {
    _grpcService.messageStream.listen(_handleNewMessage);
    _webSocketService.messageStream.listen(_handleNewMessage);
  }

  void _handleNewMessage(MessageModel message) {
    _messages.add(message);
    
    // Record metrics for received message
    _metricsService.recordMessageReceived(
      sentTime: message.timestamp,
      receivedTime: DateTime.now(),
      messageSize: message.content.length,
      protocol: _currentProtocol == ChatProtocol.grpc ? 'grpc' : 'websocket',
    );
    
    notifyListeners();
  }

  Future<void> connect() async {
    try {
      _error = null;
      final startTime = DateTime.now();
      
      if (_currentProtocol == ChatProtocol.grpc) {
        await _grpcService.connect();
      } else {
        await _webSocketService.connect();
      }
      
      final connectionTime = DateTime.now().difference(startTime).inMilliseconds.toDouble();
      _metricsService.recordConnection(
        protocol: _currentProtocol == ChatProtocol.grpc ? 'grpc' : 'websocket',
        connectionTime: connectionTime,
      );
      
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

    // Record metrics for sent message
    _metricsService.recordMessageSent(
      sentTime: message.timestamp,
      messageSize: content.length,
      protocol: _currentProtocol == ChatProtocol.grpc ? 'grpc' : 'websocket',
    );

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
    
    _metricsService.recordDisconnection(
      protocol: _currentProtocol == ChatProtocol.grpc ? 'grpc' : 'websocket',
    );
    
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