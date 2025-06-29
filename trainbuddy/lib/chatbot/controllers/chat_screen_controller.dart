import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:trainbuddy/chatbot/models/message_model.dart';
import 'package:uuid/uuid.dart';

import 'package:rxdart/rxdart.dart';
import '../api/api_service.dart';


class ChatController extends GetxController {
  final ApiService apiService = ApiService();
  final RxList<Message> messages = <Message>[].obs;
  final RxBool isLoading = false.obs;
  final TextEditingController messageController = TextEditingController();
  late String sessionId;

  @override
  void onInit() {
    super.onInit();
    sessionId = const Uuid().v4();
  }

  Future<void> sendMessage(String content) async {
    if (content.isEmpty) return;

    isLoading.value = true;
    messages.add(Message(
      sender: 'User',
      content: content,
      timestamp: DateTime.now(),
    ));

    try {
      final botResponse = await apiService.sendMessage(sessionId, content);
      
      // Validate and clean the bot response
      final cleanedResponse = _cleanBotResponse(botResponse);
      
      messages.add(Message(
        sender: 'Bot',
        content: cleanedResponse,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      // Add error message to chat
      messages.add(Message(
        sender: 'Bot',
        content: '**Sorry, I encountered an error.**\n\nPlease try again or check your connection.',
        timestamp: DateTime.now(),
      ));
      
      Get.snackbar(
        'Error', 
        'Failed to send message: $e', 
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  String _cleanBotResponse(String response) {
    if (response.isEmpty) {
      return '**No response received.**\n\nPlease try asking your question again.';
    }
    
    // Remove any HTML tags that might be in the response
    String cleaned = response.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Ensure proper line breaks for markdown
    cleaned = cleaned.replaceAll('\n\n', '\n').trim();
    
    // If the response is very short, make it more prominent
    if (cleaned.length < 50 && !cleaned.contains('**')) {
      cleaned = '**$cleaned**';
    }
    
    return cleaned;
  }

  @override
  void onClose() {
    messageController.dispose();
    messages.clear();
    super.onClose();
  }
}