import 'dart:async';
import 'package:flutter/foundation.dart';

class MessageMetric {
  final DateTime sentTime;
  final DateTime? receivedTime;
  final int messageSize;
  final String protocol;
  final bool isSuccess;

  MessageMetric({
    required this.sentTime,
    this.receivedTime,
    required this.messageSize,
    required this.protocol,
    required this.isSuccess,
  });

  double? get latency {
    if (receivedTime == null) return null;
    return receivedTime!.difference(sentTime).inMilliseconds.toDouble();
  }
}

class ConnectionMetric {
  final DateTime timestamp;
  final String protocol;
  final bool isConnected;
  final double connectionTime;

  ConnectionMetric({
    required this.timestamp,
    required this.protocol,
    required this.isConnected,
    required this.connectionTime,
  });
}

class MetricsService extends ChangeNotifier {
  final List<MessageMetric> _messageMetrics = [];
  final List<ConnectionMetric> _connectionMetrics = [];
  final Map<String, int> _disconnectionCount = {
    'grpc': 0,
    'websocket': 0,
  };
  
  // Getters
  List<MessageMetric> get messageMetrics => List.unmodifiable(_messageMetrics);
  List<ConnectionMetric> get connectionMetrics => List.unmodifiable(_connectionMetrics);
  Map<String, int> get disconnectionCount => Map.unmodifiable(_disconnectionCount);

  // Message Metrics
  void recordMessageSent({
    required DateTime sentTime,
    required int messageSize,
    required String protocol,
  }) {
    _messageMetrics.add(MessageMetric(
      sentTime: sentTime,
      messageSize: messageSize,
      protocol: protocol,
      isSuccess: true,
    ));
    notifyListeners();
  }

  void recordMessageReceived({
    required DateTime sentTime,
    required DateTime receivedTime,
    required int messageSize,
    required String protocol,
  }) {
    final metric = _messageMetrics.firstWhere(
      (m) => m.sentTime == sentTime && m.protocol == protocol,
      orElse: () => MessageMetric(
        sentTime: sentTime,
        messageSize: messageSize,
        protocol: protocol,
        isSuccess: true,
      ),
    );
    
    if (!_messageMetrics.contains(metric)) {
      _messageMetrics.add(metric);
    }
    
    // Update the received time
    final index = _messageMetrics.indexOf(metric);
    _messageMetrics[index] = MessageMetric(
      sentTime: metric.sentTime,
      receivedTime: receivedTime,
      messageSize: metric.messageSize,
      protocol: metric.protocol,
      isSuccess: true,
    );
    
    notifyListeners();
  }

  // Connection Metrics
  void recordConnection({
    required String protocol,
    required double connectionTime,
  }) {
    _connectionMetrics.add(ConnectionMetric(
      timestamp: DateTime.now(),
      protocol: protocol,
      isConnected: true,
      connectionTime: connectionTime,
    ));
    notifyListeners();
  }

  void recordDisconnection({
    required String protocol,
  }) {
    _connectionMetrics.add(ConnectionMetric(
      timestamp: DateTime.now(),
      protocol: protocol,
      isConnected: false,
      connectionTime: 0,
    ));
    _disconnectionCount[protocol] = (_disconnectionCount[protocol] ?? 0) + 1;
    notifyListeners();
  }

  // Analytics
  double getAverageLatency(String protocol) {
    final protocolMetrics = _messageMetrics
        .where((m) => m.protocol == protocol && m.latency != null);
    if (protocolMetrics.isEmpty) return 0;
    
    final totalLatency = protocolMetrics
        .map((m) => m.latency!)
        .reduce((a, b) => a + b);
    return totalLatency / protocolMetrics.length;
  }

  double getAverageMessageSize(String protocol) {
    final protocolMetrics = _messageMetrics
        .where((m) => m.protocol == protocol);
    if (protocolMetrics.isEmpty) return 0;
    
    final totalSize = protocolMetrics
        .map((m) => m.messageSize)
        .reduce((a, b) => a + b);
    return totalSize / protocolMetrics.length;
  }

  double getMessageThroughput(String protocol) {
    final protocolMetrics = _messageMetrics
        .where((m) => m.protocol == protocol && m.receivedTime != null);
    if (protocolMetrics.isEmpty) return 0;
    
    final firstMessage = protocolMetrics
        .map((m) => m.sentTime)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final lastMessage = protocolMetrics
        .map((m) => m.receivedTime!)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    
    final durationSeconds = lastMessage.difference(firstMessage).inSeconds;
    if (durationSeconds == 0) return 0;
    
    return protocolMetrics.length / durationSeconds;
  }

  double getAverageConnectionTime(String protocol) {
    final protocolMetrics = _connectionMetrics
        .where((m) => m.protocol == protocol && m.isConnected);
    if (protocolMetrics.isEmpty) return 0;
    
    final totalTime = protocolMetrics
        .map((m) => m.connectionTime)
        .reduce((a, b) => a + b);
    return totalTime / protocolMetrics.length;
  }

  void clearMetrics() {
    _messageMetrics.clear();
    _connectionMetrics.clear();
    _disconnectionCount.clear();
    notifyListeners();
  }
} 