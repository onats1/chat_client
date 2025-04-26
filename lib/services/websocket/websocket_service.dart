import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../models/chat_message.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final _messageController = StreamController<MessageModel>.broadcast();
  bool _isConnected = false;

  Stream<MessageModel> get messageStream => _messageController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://10.0.2.2:8080'),
      );

      _isConnected = true;
      
      // Listen for incoming messages
      _channel!.stream.listen(
        (dynamic message) {
          final data = jsonDecode(message as String);
          final chatMessage = MessageModel.fromWebSocket(data);
          _messageController.add(chatMessage);
        },
        onError: (error) {
          print('WebSocket error: $error');
          disconnect();
        },
        onDone: () {
          print('WebSocket connection closed');
          disconnect();
        },
      );
    } catch (e) {
      print('Failed to connect to WebSocket server: $e');
      _isConnected = false;
      rethrow;
    }
  }

  void sendMessage(String content) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(content);
    }
  }

  void disconnect() {
    _isConnected = false;
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
} 