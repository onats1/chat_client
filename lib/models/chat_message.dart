import 'dart:io';

class MessageModel {
  final String userId;
  final String content;
  final DateTime timestamp;
  final bool isSystem;
  final bool isSelf;

  MessageModel({
    required this.userId,
    required this.content,
    required this.timestamp,
    this.isSystem = false,
    this.isSelf = false,
  });

  factory MessageModel.fromGrpc(dynamic grpcMessage) {
    return MessageModel(
      userId: grpcMessage.userId,
      content: grpcMessage.content,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        int.parse(grpcMessage.timestamp.toString()),
      ),
      isSelf: false,
    );
  }

  factory MessageModel.fromWebSocket(Map<String, dynamic> json) {
    final userId = json['userId']?.toString() ?? 'Unknown';
    final content = json['content']?.toString() ?? '';
    final timestamp = json['timestamp'] is int 
        ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
        : DateTime.now();
    
    return MessageModel(
      userId: userId,
      content: content,
      timestamp: timestamp,
      isSystem: json['type'] == 'system',
      isSelf: false,
    );
  }

  factory MessageModel.system(String content) {
    return MessageModel(
      userId: 'System',
      content: content,
      timestamp: DateTime.now(),
      isSystem: true,
      isSelf: false,
    );
  }
} 