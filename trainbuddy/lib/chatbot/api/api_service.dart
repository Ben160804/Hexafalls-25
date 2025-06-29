import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://surfing-media-marked-everything.trycloudflare.com/prompt';

  Future<String> sendMessage(String sessionId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_id': sessionId,
          'prompt': content,
        }),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final botResponse = responseData['response'] ?? 'No response received';
        
        // Ensure the response is properly formatted for markdown
        return _formatBotResponse(botResponse);
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  String _formatBotResponse(String response) {
    // Clean up the response and ensure proper markdown formatting
    String formattedResponse = response.trim();
    
    // If the response doesn't contain markdown, format it nicely
    if (!formattedResponse.contains('**') && 
        !formattedResponse.contains('*') && 
        !formattedResponse.contains('#') &&
        !formattedResponse.contains('-') &&
        !formattedResponse.contains('`')) {
      
      // Split into sentences and format as a list if it's long
      final sentences = formattedResponse.split('. ');
      if (sentences.length > 2) {
        formattedResponse = sentences.map((sentence) => '- ${sentence.trim()}').join('\n');
      }
    }
    
    return formattedResponse;
  }
}