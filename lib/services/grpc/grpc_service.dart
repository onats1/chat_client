import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:grpc/grpc.dart';
import 'package:fixnum/fixnum.dart';
import '../../models/chat_message.dart';
import 'generated/chat.pb.dart' as grpc;
import 'generated/chat.pbgrpc.dart';

class GrpcService {
  ClientChannel? _channel;
  ChatServiceClient? _client;
  StreamController<grpc.ChatMessage>? _requestController;
  ResponseStream<grpc.ChatMessage>? _responseStream;
  final _messageController = StreamController<MessageModel>.broadcast();
  bool _isConnected = false;

  Stream<MessageModel> get messageStream => _messageController.stream;
  bool get isConnected => _isConnected;

  String get _grpcHost {
    if (kIsWeb) {
      // Web platform uses window.location.hostname
      return 'localhost';
    } else if (Platform.isAndroid) {
      // Android emulator can access host machine via 10.0.2.2
      return '10.0.2.2';
    } else if (Platform.isIOS) {
      // iOS simulator can access host machine via localhost
      return 'localhost';
    } else {
      // Default to localhost for other platforms
      return 'localhost';
    }
  }

  Future<void> connect() async {
    try {
      _channel = ClientChannel(
        _grpcHost,
        port: 50051,
        options: const ChannelOptions(
          credentials: ChannelCredentials.insecure(),
        ),
      );

      _client = ChatServiceClient(_channel!);
      _requestController = StreamController<grpc.ChatMessage>();
      
      // Start bidirectional stream
      _responseStream = _client!.chat(_requestController!.stream);
      _isConnected = true;

      // Send connection message
      _messageController.add(
        MessageModel.system('Connected to gRPC chat server'),
      );

      // Listen for incoming messages
      _responseStream!.listen(
        (message) {
          final chatMessage = MessageModel(
            userId: message.userId,
            content: message.content,
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              message.timestamp.toInt(),
            ),
            isSelf: false,
          );
          _messageController.add(chatMessage);
        },
        onError: (error) {
          print('gRPC error: $error');
          disconnect();
        },
        onDone: () {
          print('gRPC stream closed');
          disconnect();
        },
      );
    } catch (e) {
      print('Failed to connect to gRPC server: $e');
      _isConnected = false;
      rethrow;
    }
  }

  void sendMessage(String content) {
    if (_client != null && _isConnected && _requestController != null) {
      final message = grpc.ChatMessage()
        ..userId = ''  // Server will set this
        ..content = content
        ..timestamp = Int64(DateTime.now().millisecondsSinceEpoch);
      
      _requestController!.add(message);
    }
  }

  void disconnect() {
    _isConnected = false;
    _requestController?.close();
    _requestController = null;
    _responseStream?.cancel();
    _responseStream = null;
    _channel?.shutdown();
    _channel = null;
    _client = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
} 