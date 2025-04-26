import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_chat_bubble/bubble_type.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_1.dart';
import 'package:intl/intl.dart';
import '../services/chat_provider.dart';
import '../models/chat_message.dart';
import '../components/metrics_dashboard.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Connect when screen loads
    Future.microtask(() => context.read<ChatProvider>().connect());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    context.read<ChatProvider>().sendMessage(_messageController.text.trim());
    _messageController.clear();
    
    // Scroll to bottom after sending message
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Research'),
        actions: [
          Consumer<ChatProvider>(
            builder: (context, provider, child) {
              return DropdownButton<ChatProtocol>(
                value: provider.currentProtocol,
                items: ChatProtocol.values.map((protocol) {
                  return DropdownMenuItem(
                    value: protocol,
                    child: Text(protocol.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (protocol) {
                  if (protocol != null) {
                    provider.switchProtocol(protocol);
                  }
                },
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          const MetricsDashboard(),
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, child) {
                if (provider.error != null) {
                  return Center(
                    child: Text(
                      'Error: ${provider.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    final message = provider.messages[index];
                    return _buildMessageBubble(message);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message) {
    final isSystem = message.isSystem;
    final isSelf = message.isSelf;
    
    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Center(
          child: Text(
            message.content,
            style: const TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment:
            isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            message.userId,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          ChatBubble(
            clipper: ChatBubbleClipper1(type: isSelf ? BubbleType.sendBubble : BubbleType.receiverBubble),
            alignment: isSelf ? Alignment.topRight : Alignment.topLeft,
            margin: const EdgeInsets.only(top: 4),
            backGroundColor: isSelf ? Colors.blue : Colors.grey[200],
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isSelf ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelf ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 50),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          return Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                  ),
                  enabled: provider.isConnected,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: provider.isConnected ? _sendMessage : null,
                color: Theme.of(context).primaryColor,
              ),
            ],
          );
        },
      ),
    );
  }
} 