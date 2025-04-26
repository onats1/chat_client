import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chat_client/main.dart' as app;
import 'package:chat_client/services/chat_provider.dart';
import 'package:provider/provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Chat Screen Tests', () {
    testWidgets('Send 10 messages test', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Get the ChatProvider instance using Provider.of
      final BuildContext context = tester.element(find.byType(MaterialApp));
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      // Wait for the connection to be established
      int retryCount = 0;
      const maxRetries = 5;
      while (!chatProvider.isConnected && retryCount < maxRetries) {
        await Future.delayed(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        retryCount++;
      }

      // Check if we're connected
      expect(chatProvider.isConnected, true, reason: 'Failed to establish connection after $maxRetries attempts');
      expect(chatProvider.error, null, reason: 'Connection error occurred: ${chatProvider.error}');

      // Find the text input field and send button
      final textField = find.byType(TextField);
      
      // Send 10 messages
      for (int i = 0; i < 10; i++) {
        // Type a message
        await tester.enterText(textField, 'Test message $i');
        await tester.pumpAndSettle();

        // Find and tap the send button (it's the last IconButton in the Row)
        final sendButton = find.byType(IconButton).last;
        await tester.tap(sendButton);
        await tester.pumpAndSettle();

        // Wait a bit between messages
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Wait for all messages to be processed
      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Verify that messages appear in the list
      final messageTexts = find.textContaining('Test message');
      expect(messageTexts, findsWidgets);

      // Verify connection is still active
      expect(chatProvider.isConnected, true, reason: 'Connection was lost during test');
      expect(chatProvider.error, null, reason: 'Error occurred during test: ${chatProvider.error}');
    });
  });
} 